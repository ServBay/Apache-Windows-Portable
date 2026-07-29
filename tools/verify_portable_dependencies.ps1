[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Root,

    [string] $Dumpbin = "dumpbin.exe"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$resolvedRoot = (Resolve-Path -LiteralPath $Root).Path
$binaryExtensions = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase
)
@(".exe", ".dll", ".so") | ForEach-Object {
    [void] $binaryExtensions.Add($_)
}

$packagedFiles = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase
)
$allFiles = @(Get-ChildItem -LiteralPath $resolvedRoot -Recurse -File)
foreach ($file in $allFiles) {
    [void] $packagedFiles.Add($file.Name)
}

$systemDirectories = @(
    (Join-Path $env:SystemRoot "System32"),
    (Join-Path $env:SystemRoot "SysWOW64")
)

function Test-SystemDependency {
    param([Parameter(Mandatory = $true)][string] $Name)

    if ($Name -match "^(api-ms-win-|ext-ms-win-)") {
        return $true
    }

    foreach ($directory in $systemDirectories) {
        if (Test-Path -LiteralPath (Join-Path $directory $Name)) {
            return $true
        }
    }

    return $false
}

$binaries = @(
    $allFiles | Where-Object {
        $binaryExtensions.Contains($_.Extension)
    }
)
$missing = [System.Collections.Generic.List[object]]::new()

foreach ($binary in $binaries) {
    $dumpOutput = @(& $Dumpbin /nologo /dependents $binary.FullName 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "dumpbin failed for $($binary.FullName):`n$($dumpOutput -join [Environment]::NewLine)"
    }

    $dependencies = @(
        foreach ($line in $dumpOutput) {
            if ($line -match "^\s*([A-Za-z0-9_.+-]+\.(?:dll|so))\s*$") {
                $Matches[1]
            }
        }
    ) | Sort-Object -Unique

    foreach ($dependency in $dependencies) {
        if ($packagedFiles.Contains($dependency)) {
            continue
        }
        if (Test-SystemDependency -Name $dependency) {
            continue
        }

        $missing.Add(
            [PSCustomObject]@{
                Binary = $binary.FullName.Substring($resolvedRoot.Length).TrimStart("\")
                Dependency = $dependency
            }
        )
    }
}

if ($missing.Count -gt 0) {
    $missingReport = $missing |
        Sort-Object Dependency, Binary |
        Format-Table -AutoSize |
        Out-String
    Write-Error "Missing packaged runtime dependencies:`n$missingReport" -ErrorAction Continue
    exit 1
}

Write-Host "Verified runtime dependency closure for $($binaries.Count) packaged binaries."
