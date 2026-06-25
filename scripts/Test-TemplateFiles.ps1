<#
.SYNOPSIS
Validates PolicyVault template YAML files and Azure DevOps WIQL sanity rules.

.DESCRIPTION
Recursively scans the supplied path for YAML template files, validates that each
file parses as YAML, and applies lightweight WIQL checks to Azure DevOps
templates. Azure DevOps templates are also validated against the repository
JSON schema. The WIQL checks verify required clauses, balanced brackets and
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
$templateSchemaPath = Join-Path -Path $repositoryRoot -ChildPath 'schemas/template-catalog-entry.schema.json'
$ignoredTopLevelDirectories = @('.git', '.github', 'dist', 'scripts')
$powerShellYamlVersion = '0.4.12'
$supportedExtensions = @('.yml', '.yaml')

if (-not (Test-Path -LiteralPath $templateSchemaPath -PathType Leaf)) {
    throw "Template schema file was not found at '$templateSchemaPath'."
}

if (-not (Get-Command -Name Test-Json -ErrorAction SilentlyContinue)) {
    throw 'Test-Json is unavailable in this PowerShell runtime. PowerShell 7+ is required for schema validation.'
}

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
        Install-Module -Name powershell-yaml -RequiredVersion $powerShellYamlVersion -Scope CurrentUser -Force -ErrorAction Stop
    }
    catch {
        throw "ConvertFrom-Yaml is unavailable and powershell-yaml $powerShellYamlVersion could not be installed. $($_.Exception.Message)"
    }

    Import-Module powershell-yaml -RequiredVersion $powerShellYamlVersion -ErrorAction Stop

    if (-not (Get-Command -Name ConvertFrom-Yaml -ErrorAction SilentlyContinue)) {
        throw "ConvertFrom-Yaml is still unavailable after installing/importing powershell-yaml $powerShellYamlVersion."
    }
}

function ConvertFrom-TemplateYaml {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    Ensure-ConvertFromYaml

    return Get-Content -LiteralPath $FilePath -Raw | ConvertFrom-Yaml
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
    if ($normalizedQuery -notmatch '\bSELECT\b') {
        $errors.Add('must contain a SELECT clause')
    }

    if ($normalizedQuery -notmatch '\bFROM\s+WORKITEM(?:S|LINKS)\b') {
        $errors.Add('must query FROM WorkItems or FROM WorkItemLinks')
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
    $relativePath = Get-RelativePath -BasePath $repositoryRoot -TargetPath $file
    $isAzureDevOpsTemplateFile = $relativePath -match '^azure-devops[\\/].+\.ya?ml$'

    try {
        $document = ConvertFrom-TemplateYaml -FilePath $file
    }
    catch {
        $errors.Add("${relativePath}: invalid YAML syntax ($($_.Exception.Message))")
        continue
    }

    if ($null -eq $document -and $isAzureDevOpsTemplateFile) {
        $errors.Add("${relativePath}: template document must not be empty")
        continue
    }

    if ($isAzureDevOpsTemplateFile) {
        try {
            $documentJson = $document | ConvertTo-Json -Depth 100
            $schemaValidationResult = $documentJson | Test-Json -SchemaFile $templateSchemaPath -ErrorAction Stop
        }
        catch {
            $errors.Add("${relativePath}: schema validation failed ($($_.Exception.Message))")
            continue
        }

        if (-not $schemaValidationResult) {
            $errors.Add("${relativePath}: does not conform to template schema '$templateSchemaPath'")
            continue
        }
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
        $errors.Add("${relativePath}: source.query must be a non-empty WIQL string")
        continue
    }

    foreach ($message in (Get-WiqlValidationErrors -Query $query)) {
        $errors.Add("${relativePath}: $message")
    }
}

if ($errors.Count -eq 0) {
    Write-Host "Validated $($files.Count) template YAML file(s)."
    exit 0
}

Write-Error "Template validation failed:`n- $($errors -join "`n- ")"
