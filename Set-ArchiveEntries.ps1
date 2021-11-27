#Set-StrictMode -Version Latest
#####################################################
# Set-ArchiveEntries
#####################################################
<#PSScriptInfo

.VERSION 0.1
.GUID 0c402367-ae6c-40a2-bd9a-bffec897d71f

.AUTHOR David Walker, Sitecore Dave, Radical Dave

.COMPANYNAME David Walker, Sitecore Dave, Radical Dave

.COPYRIGHT David Walker, Sitecore Dave, Radical Dave

.TAGS powershell archive files entries zip update set

.LICENSEURI https://github.com/SharedSitecore/ConvertTo-Sitecore-WDP/blob/main/LICENSE

.PROJECTURI https://github.com/SharedSitecore/ConvertTo-Sitecore-WDP

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES

#>

<# 

.DESCRIPTION 
 PowerShell script to search/remove entries/files in Zip package

.PARAMETER name
Path of package

#> 
#####################################################
# Set-ArchiveEntries
#####################################################
Param(
	[Parameter(Mandatory=$true)]
	[string] $path,
	[Parameter(Mandatory=$true)]
	[string[]] $search
)
function Set-ArchiveEntries
{
	Param(
		[Parameter(Mandatory=$true)]
		[string] $path,	
		[Parameter(Mandatory=$true)]
		[string[]] $search,	
		[Parameter(Mandatory=$false)]
		[string[]] $source
	)
	$ProgressPreference = "SilentlyContinue"
	$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
	Write-Verbose "#####################################################"
	Write-Verbose "# $PSScriptName $path $search"

	$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch
	$StopWatch.Start()

	$results = @()	
	try {
		if (($path.IndexOf("/") -eq -1) -or (-not (Test-Path $path)) ) {
			if (Test-Path (Join-Path (Get-Location) $path)) {
				$path = Join-Path (Get-Location) $path
				Write-Verbose "path:$path"
			}
			if (!(Test-Path $path)) {
				throw "ERROR Set-ArchiveEntries - file not found: $path"
			}
		}
		
		$file = (Split-Path $path -leaf).Replace('.zip', '')
		Write-Verbose "file:$file"
		$tempPath = Join-Path $ENV:TEMP $PSScriptName
		Write-Verbose "tempPath:$tempPath"
		$tempPackagePath = Join-Path $tempPath $file
		Write-Verbose "tempPackagePath:$tempPackagePath"
		if (Test-Path $tempPackagePath) { Remove-Item $tempPackagePath -Recurse -Force }
		if (!(Test-Path $tempPackagePath)) { New-Item $tempPackagePath -ItemType Directory | Out-Null }

		Add-Type -AssemblyName System.IO.Compression
		$stream = New-Object IO.FileStream($path, [IO.FileMode]::Open)
		$zip = New-Object IO.Compression.ZipArchive($stream, [IO.Compression.ZipArchiveMode]::Update)

		$i = 0
		$search.foreach({
			$i++;
			$query = $_
			Write-Verbose "query:$query"

			$value = ''
			if ($source -and $source.Length -gt $value -1) { $value = $source[$i]}
			Write-Verbose "value:$value"

			$queryResults = @()
			($zip.Entries | Where-Object { $_.FullName -Like $query }) | ForEach-Object {
				Write-Host "Found:$($_.FullName)"
				if ($value -ne '' -or $_.Length -gt 0) {
					$_.Delete()
					Write-Verbose "Deleted:$($_.FullName)"
					$newEntry = $zip.CreateEntry($_);
					Write-Verbose "newEntry:$newEntry"
					
					if($value -and (Test-Path $value)) {
						Write-Verbose "writer open"
						$writer = New-Object IO.FileStream($newEntry, [IO.FileMode]::Open)
						$writer.Write("$(Get-Content $value)")
						$writer.Close()
						$writer.Dispose()
						Write-Verbose "writer open"
					} elseif ($value) {
						Write-Verbose "writer closed"
						$writer = $newEntry.Open()						
						$writer.Write($value)
						$writer.Close()
						$writer.Dispose()
						Write-Verbose "writer closed"
					}					
					
					Write-Host "Set:$($_.FullName)=$source"
					$queryResults += $_
				}
			}
			Write-Verbose "query.count:$($queryResults.Length)"
			$results += $queryResults
		})
		Write-Verbose "files:$results"

		$zips = @()
		if ($file -ne 'package') { #SearchStax.zip causes issues
			($zip.Entries | Where-Object { $_.Name -Like '*.zip' }) | ForEach-Object { 
				Write-Host "Found:$($_.FullName)"
				[IO.Compression.ZipFileExtensions]::ExtractToFile($_,"$tempPackagePath\$_",$Overwrite)
				$zips += $_
			}
		}

		if ($zip) {	$zip.Dispose() }
		if ($stream) {
			$stream.Close()
			$stream.Dispose()
		}
	
		Write-Verbose "zips:$zips"

		if ($zips) {
			$tempFolder = $tempPackagePath
			($zips | Where-Object { $_.Name -Like '*.zip' }) | ForEach-Object {
				$tempZipPath = "$tempFolder\$($_.FullName)"
				$resultsNested = Set-ArchiveEntries $tempZipPath $search
			
				if ($resultsNested.count -gt 0) { 
					Write-Verbose "Changes made to $tempZipPath. Updating $path"
				 	$compress = @{
				 		Path = "$tempZipPath"
				 		DestinationPath = $path }
			
				 	#Compress-Archive -Path $destination\temp\metadata\* -Update -DestinationPath $path -Force
				 	Compress-Archive -Update @compress
				 	Write-Verbose "$path updated."
				}

				$results += $resultsNested
			}
		}
		if (Test-Path $tempPackagePath) { Remove-Item $tempPackagePath -Recurse -Force }
	}
	catch {
		Write-Error "ERROR Set-ArchiveEntries $($path) $($search):$_"

		if ($zip) {	$zip.Dispose() }
		if ($stream) {
			$stream.Close()
			$stream.Dispose()
		}
	}
	Write-Verbose "results:$results"
	Write-Verbose "results.count:$($results.Length)"
	return $results
}
#cls
Set-ArchiveEntries $path $search