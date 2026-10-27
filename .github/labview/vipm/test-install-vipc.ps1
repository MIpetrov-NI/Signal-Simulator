$ErrorActionPreference = 'Stop'
$tokens = $null
$parseErrors = $null
$installer = Join-Path $PSScriptRoot 'install-vipc.ps1'
$ast = [System.Management.Automation.Language.Parser]::ParseFile($installer, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count -gt 0) { throw ($parseErrors | Out-String) }

$names = @('Split-VipmPackageSpec', 'Get-NumericVersionKey', 'Test-VipmInstalledSpecs')
foreach ($name in $names) {
    $definition = $ast.Find({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name
    }, $true)
    if (-not $definition) { throw "Missing installer function '$name'." }
    . ([scriptblock]::Create($definition.Extent.Text))
}

$VipmExe = 'Invoke-TestVipm'
$GlobalFlags = @('--labview-version', '2026', '--labview-bitness', '64')
$script:listOutput = @()
$script:listExit = 0
function Invoke-TestVipm {
    $expected = @('--labview-version', '2026', '--labview-bitness', '64', 'list', '--installed')
    if (($args -join '|') -ne ($expected -join '|')) { throw 'Incorrect installed-package query.' }
    $global:LASTEXITCODE = $script:listExit
    $script:listOutput
}

$script:passed = 0
function Assert-Installed {
    param([string] $Name, [string[]] $Specs, [string[]] $Output, [bool] $Expected, [int] $ExitCode = 0)
    $script:listOutput = $Output
    $script:listExit = $ExitCode
    $actual = Test-VipmInstalledSpecs $Specs
    if ($actual -isnot [bool] -or $actual -ne $Expected) {
        throw "$Name failed: expected $Expected, got '$actual'."
    }
    $script:passed++
    Write-Host "PASS: $Name"
}

Assert-Installed 'Exact installed version' @('ni_protobuf_types@1.0.0.1') @('  ni_protobuf_types v1.0.0.1') $true
Assert-Installed 'Missing package' @('ni_protobuf_types@1.0.0.1') @('Installed packages (0):') $false
Assert-Installed 'Wrong version' @('ni_protobuf_types@1.0.0.1') @('  ni_protobuf_types v1.0.0.2') $false
Assert-Installed 'Unpinned package' @('ni_protobuf_types') @('  ni_protobuf_types v1.0.0.1') $true
Assert-Installed 'Minimum version satisfied' @('ni_protobuf_types>=1.0.0.1') @('  ni_protobuf_types v1.0.0.2') $true
Assert-Installed 'Minimum version unsatisfied' @('ni_protobuf_types>=1.0.0.2') @('  ni_protobuf_types v1.0.0.1') $false
Assert-Installed 'Mixed complete and missing requirements' @('a@1.0', 'b@2.0') @('  a v1.0') $false
Assert-Installed 'Listing failure is not success' @('a@1.0') @('  a v1.0') $false 3
Assert-Installed 'Unrecognized listing fails closed' @('a@1.0') @('Successfully installed 1 package:') $false
Assert-Installed 'Case-insensitive package names' @('NI_PROTOBUF_TYPES@1.0.0.1') @('  ni_protobuf_types v1.0.0.1') $true
Assert-Installed 'No required packages' @() @() $true

$required = @(
    'ni_lib_utf_junit_report@1.0.1.43',
    'ni_lib_junit_results_api@1.0.1.6',
    'ni_lib_simple_xml@1.0.0.4',
    'jki_lib_caraya@1.4.4.148',
    'ni_measurement_plugin_sdk@3.5.4.1'
)
$recovered = @(
    'Using LabVIEW 2026 (64-bit)',
    'Installed packages (5):',
    '  ni_lib_utf_junit_report v1.0.1.43',
    '  ni_lib_junit_results_api v1.0.1.6',
    '  ni_lib_simple_xml v1.0.0.4',
    '  jki_lib_caraya v1.4.4.148',
    '  ni_measurement_plugin_sdk v3.5.4.1'
)
Assert-Installed 'Recovered test tooling and project dependency' $required $recovered $true
Write-Host "$script:passed offline dependency-validation tests passed."
