$repoPath = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
Write-Verbose "repoPath:$repoPath"
. $repoPath\tests\TestRunner.ps1 {
    $repoPath = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
    . $repoPath\tests\TestUtils.ps1
    $ModuleName = Split-Path $repoPath -Leaf
    $ModuleScriptName = 'SharedSitecore.SitecoreDocker.psm1'
    $ModuleManifestName = 'SharedSitecore.SitecoreDocker.psd1'
    $ModuleScriptPath = "$repoPath\src\$ModuleName\$ModuleScriptName"
    $ModuleManifestPath = "$repoPath\src\$\ModuleName\$ModuleManifestName"

    if (!(Get-Module PSScriptAnalyzer -ErrorAction SilentlyContinue)) {
        Install-Module -Name PSScriptAnalyzer -Repository PSGallery -Force
    }

    Describe 'Module Tests' {
        $repoPath = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
        $ModuleName = Split-Path $repoPath -Leaf
        $ModuleScriptName = "$ModuleName.psm1"
        $ModuleScriptPath = "$repoPath\src\$ModuleName\$ModuleScriptName"

        It 'imports successfully' {
            $repoPath = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
            $ModuleName = Split-Path $repoPath -Leaf
            $ModuleScriptPath = "$repoPath\src\$ModuleName\$ModuleName.psm1"

            Write-Verbose "Import-Module -Name $($ModuleScriptPath)"
            { Import-Module -Name $ModuleScriptPath -ErrorAction Stop } | Should -Not -Throw
        }

        It 'passes default PSScriptAnalyzer rules' {
            $repoPath = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
            $ModuleName = Split-Path $repoPath -Leaf
            $ModuleScriptPath = "$repoPath\src\$ModuleName\$ModuleName.psm1"

            Invoke-ScriptAnalyzer -Path $ModuleScriptPath | Should -BeNullOrEmpty
        }
    }

    Describe 'Module Manifest Tests' {
        It 'passes Test-ModuleManifest' {
            $repoPath = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
            $ModuleName = Split-Path $repoPath -Leaf
            $ModuleManifestName = "$ModuleName.psd1"
            $ModuleManifestPath = "$repoPath\src\$ModuleName\$ModuleManifestName"

            Write-Output $ModuleManifestPath
            Test-ModuleManifest -Path $ModuleManifestPath | Should -Not -BeNullOrEmpty
            $? | Should -Be $true
        }
    }
}