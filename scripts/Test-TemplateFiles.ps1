<#
.SYNOPSIS
Validates PolicyVault template YAML files and Azure DevOps WIQL sanity rules.

.DESCRIPTION
Recursively scans the supplied path for YAML template files, validates that each
file parses as YAML, and applies lightweight WIQL checks to Azure DevOps
templates. The WIQL checks verify required clauses, balanced brackets and
parentheses, unmatched single quotes, and unsupported control characters.

.PARAMETER Path
The file or directory to validate. Defaults to the repository root. When a
directory is supplied, the script scans supported YAML files under that path.

.EXAMPLE
./scripts/Test-TemplateFiles.ps1

.EXAMPLE
./scripts/Test-TemplateFiles.ps1 -Path ./azure-devops
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$Path = (Split-Path -Path $PSScriptRoot -Parent)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$validationRoot = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $Path).Path)
$repositoryRoot = Split-Path -Path $PSScriptRoot -Parent
$ignoredTopLevelDirectories = @('.git', '.github', 'dist', 'scripts')
$supportedExtensions = @('.yml', '.yaml')

function Get-RelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath,

        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    $normalizedBasePath = [IO.Path]::GetFullPath($BasePath)
    $normalizedTargetPath = [IO.Path]::GetFullPath($TargetPath)

    if ($normalizedTargetPath.StartsWith($normalizedBasePath + [IO.Path]::DirectorySeparatorChar)) {
        return $normalizedTargetPath.Substring($normalizedBasePath.Length + 1)
    }

    return $normalizedTargetPath
}

function Get-TemplateFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScanPath
    )

    $resolvedItem = Get-Item -LiteralPath $ScanPath
    $files = New-Object System.Collections.Generic.List[string]

    if ($resolvedItem -is [IO.FileInfo]) {
        if ($supportedExtensions -contains $resolvedItem.Extension) {
            $files.Add($resolvedItem.FullName)
        }

        return $files
    }

    $topLevelEntries = Get-ChildItem -LiteralPath $resolvedItem.FullName -Force | Sort-Object Name
    foreach ($entry in $topLevelEntries) {
        if ($entry.PSIsContainer) {
            if ($resolvedItem.FullName -eq $repositoryRoot -and $ignoredTopLevelDirectories -contains $entry.Name) {
                continue
            }

            Get-ChildItem -LiteralPath $entry.FullName -Recurse -File | Where-Object {
                $supportedExtensions -contains $_.Extension
            } | ForEach-Object {
                $files.Add($_.FullName)
            }

            continue
        }

        if ($supportedExtensions -contains $entry.Extension) {
            $files.Add($entry.FullName)
        }
    }

    return $files
}

function Get-PropertyValue {
    param(
        [object]$Object,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if ($null -eq $Object) {
        return $null
    }

    if ($Object -is [System.Collections.IDictionary]) {
        if ($Object.Contains($Name)) {
            return $Object[$Name]
        }

        return $null
    }

    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }

    return $property.Value
}

function Ensure-ConvertFromYaml {
    if (Get-Command -Name ConvertFrom-Yaml -ErrorAction SilentlyContinue) {
        return
    }

    try {
        Install-Module -Name powershell-yaml -Scope CurrentUser -Force -ErrorAction Stop
    }
    catch {
        return
    }

    Import-Module powershell-yaml -ErrorAction SilentlyContinue
}

function ConvertFrom-TemplateYaml {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    Ensure-ConvertFromYaml

    if (Get-Command -Name ConvertFrom-Yaml -ErrorAction SilentlyContinue) {
        return Get-Content -LiteralPath $FilePath -Raw | ConvertFrom-Yaml
    }

    $rubyCommand = @'
require "json"
require "yaml"

path = ENV.fetch("TEMPLATE_FILE")
content = File.read(path)
document = YAML.safe_load(content, permitted_classes: [], permitted_symbols: [], aliases: false)
puts JSON.generate(document)
'@

    $previousTemplateFile = $env:TEMPLATE_FILE
    try {
        $env:TEMPLATE_FILE = $FilePath
        $output = & ruby -e $rubyCommand 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw ($output -join [Environment]::NewLine)
        }
    }
    finally {
        $env:TEMPLATE_FILE = $previousTemplateFile
    }

    if ([string]::IsNullOrWhiteSpace(($output -join ''))) {
        return $null
    }

    return ($output -join [Environment]::NewLine) | ConvertFrom-Json
}

function Test-InvalidWiqlCharacter {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Query
    )

    foreach ($character in $Query.ToCharArray()) {
        $codePoint = [int][char]$character
        if ($codePoint -eq 9 -or $codePoint -eq 10 -or $codePoint -eq 13) {
            continue
        }

        if ($codePoint -lt 32 -or $codePoint -gt 126) {
            return $true
        }
    }

    return $false
}

function Get-BalancedTokenErrors {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Query
    )

    $errors = New-Object System.Collections.Generic.List[string]
    $stack = New-Object System.Collections.Generic.List[string]
    $inString = $false
    $index = 0

    while ($index -lt $Query.Length) {
        $character = $Query[$index]

        if ($character -eq "'") {
            if ($inString -and ($index + 1) -lt $Query.Length -and $Query[$index + 1] -eq "'") {
                $index += 2
                continue
            }

            $inString = -not $inString
            $index += 1
            continue
        }

        if (-not $inString) {
            switch ($character) {
                '[' {
                    $stack.Add('[')
                    break
                }
                '(' {
                    $stack.Add('(')
                    break
                }
                ']' {
                    if ($stack.Count -eq 0 -or $stack[$stack.Count - 1] -ne '[') {
                        $errors.Add('contains a closing ] without a matching opening [')
                    }
                    else {
                        $stack.RemoveAt($stack.Count - 1)
                    }
                    break
                }
                ')' {
                    if ($stack.Count -eq 0 -or $stack[$stack.Count - 1] -ne '(') {
                        $errors.Add('contains a closing ) without a matching opening (')
                    }
                    else {
                        $stack.RemoveAt($stack.Count - 1)
                    }
                    break
                }
            }
        }

        $index += 1
    }

    if ($inString) {
        $errors.Add('contains an unmatched single quote')
    }

    for ($stackIndex = $stack.Count - 1; $stackIndex -ge 0; $stackIndex -= 1) {
        $token = $stack[$stackIndex]
        $expected = if ($token -eq '[') { ']' } else { ')' }
        $errors.Add("contains an opening $token without a matching closing $expected")
    }

    return $errors
}

function Get-WiqlValidationErrors {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Query
    )

    $errors = New-Object System.Collections.Generic.List[string]

    if (Test-InvalidWiqlCharacter -Query $Query) {
        $errors.Add('contains non-ASCII or control characters that WIQL does not handle reliably')
    }

    $normalizedQuery = $Query.ToUpperInvariant()
    if (-not $normalizedQuery.Contains('SELECT')) {
        $errors.Add('must contain a SELECT clause')
    }

    if (-not $normalizedQuery.Contains('FROM WORKITEMS')) {
        $errors.Add('must query FROM WorkItems')
    }

    foreach ($error in (Get-BalancedTokenErrors -Query $Query)) {
        if (-not $errors.Contains($error)) {
            $errors.Add($error)
        }
    }

    return $errors
}

$errors = New-Object System.Collections.Generic.List[string]
$files = @(Get-TemplateFiles -ScanPath $validationRoot)

if ($files.Count -eq 0) {
    Write-Error "No template YAML files were found under '$validationRoot'."
    exit 1
}

foreach ($file in $files) {
    try {
        $document = ConvertFrom-TemplateYaml -FilePath $file
    }
    catch {
        $errors.Add("$(Get-RelativePath -BasePath $repositoryRoot -TargetPath $file): invalid YAML syntax ($($_.Exception.Message))")
        continue
    }

    if ($null -eq $document) {
        continue
    }

    $source = Get-PropertyValue -Object $document -Name 'source'
    $platform = Get-PropertyValue -Object $source -Name 'platform'
    if ($platform -ne 'azure-devops') {
        continue
    }

    $query = Get-PropertyValue -Object $source -Name 'query'
    if ([string]::IsNullOrWhiteSpace($query)) {
        $errors.Add("$(Get-RelativePath -BasePath $repositoryRoot -TargetPath $file): source.query must be a non-empty WIQL string")
        continue
    }

    foreach ($message in (Get-WiqlValidationErrors -Query $query)) {
        $errors.Add("$(Get-RelativePath -BasePath $repositoryRoot -TargetPath $file): $message")
    }
}

if ($errors.Count -eq 0) {
    Write-Host "Validated $($files.Count) template YAML file(s)."
    exit 0
}

Write-Error "Template validation failed:`n- $($errors -join "`n- ")"
