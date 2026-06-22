param(
    [Parameter(Mandatory = $true)]
    [int]$Number,

    [string]$LeetCodeNumber = "-",

    [string]$Title,

    [Parameter(Mandatory = $true)]
    [string]$Url,

    [string]$Language = "python"
)

function Get-TrackerFiles {
    return @("Readme.md", "Progress.md")
}

function Convert-ToSlug {
    param([string]$Value)

    $slug = $Value.ToLower()
    $slug = $slug -replace "[^a-z0-9]+", "-"
    $slug = $slug.Trim("-")
    return $slug
}

function Get-TitleFromUrl {
    param([string]$ProblemUrl)

    if ($ProblemUrl -match "/problems/([^/]+)/") {
        $slugFromUrl = $matches[1]
        $words = $slugFromUrl -split "-"
        return (($words | ForEach-Object {
            if ($_.Length -gt 0) {
                $_.Substring(0, 1).ToUpper() + $_.Substring(1)
            }
        }) -join " ")
    }

    throw "Could not derive title from URL: $ProblemUrl"
}

function Get-Extension {
    param([string]$SelectedLanguage)

    switch ($SelectedLanguage.ToLower()) {
        "python" { return "py" }
        "javascript" { return "js" }
        "java" { return "java" }
        "cpp" { return "cpp" }
        default { throw "Unsupported language: $SelectedLanguage" }
    }
}

function Set-TrackerRow {
    param(
        [string]$TrackerPath,
        [string]$FolderName,
        [string]$Extension,
        [string]$Row
    )

    $marker = "<!-- PROBLEM_ROWS -->"
    $solutionPath = "./problems/$FolderName/solution.$Extension"
    $lines = [System.Collections.Generic.List[string]]::new()

    if (Test-Path $TrackerPath) {
        foreach ($line in (Get-Content -Path $TrackerPath -Encoding utf8)) {
            $lines.Add($line)
        }
    }

    if (-not $lines.Contains($marker)) {
        $lines.Add($marker)
    }

    $existingIndex = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Contains($solutionPath)) {
            $existingIndex = $i
            break
        }
    }

    if ($existingIndex -ge 0) {
        $lines[$existingIndex] = $Row
    }
    else {
        $markerIndex = $lines.IndexOf($marker)
        $lines.Insert($markerIndex, $Row)
    }

    Set-Content -Path $TrackerPath -Value ($lines -join "`r`n") -Encoding utf8
}

$numberText = "{0:D3}" -f $Number
$resolvedTitle = if ([string]::IsNullOrWhiteSpace($Title)) { Get-TitleFromUrl -ProblemUrl $Url } else { $Title }
$slug = Convert-ToSlug -Value $resolvedTitle
$extension = Get-Extension -SelectedLanguage $Language
$folderName = "$numberText-$slug"
$problemDir = Join-Path "problems" $folderName
$readmePath = Join-Path $problemDir "README.md"
$solutionPath = Join-Path $problemDir "solution.$extension"

if (Test-Path $problemDir) {
    throw "Problem folder already exists: $problemDir"
}

New-Item -ItemType Directory -Path $problemDir -Force | Out-Null

$readmeTemplate = @(
    "# $resolvedTitle",
    "",
    "- LeetCode No: $LeetCodeNumber",
    "- Problem: $Url",
    "- Status: In Progress",
    "- Approach Used: TBD",
    "",
    "## Approach",
    "",
    "Write a short explanation here:",
    "",
    "- main idea",
    "- time complexity",
    "- space complexity",
    "",
    "## Complexity",
    "",
    '- Time: `O(?)`',
    '- Space: `O(?)`'
) -join "`r`n"

Set-Content -Path $readmePath -Value $readmeTemplate -Encoding utf8

switch ($Language.ToLower()) {
    "python" {
        $solutionTemplate = @(
            "# Update the method name and parameters to match LeetCode before submitting.",
            "class Solution:",
            "    pass"
        ) -join "`r`n"
    }
    "javascript" {
        $solutionTemplate = "// Update the function name and parameters to match LeetCode before submitting."
    }
    "java" {
        $solutionTemplate = @(
            "// Update the class methods to match LeetCode before submitting.",
            "class Solution {",
            "}"
        ) -join "`r`n"
    }
    "cpp" {
        $solutionTemplate = @(
            "// Update the class methods to match LeetCode before submitting.",
            "class Solution {",
            "};"
        ) -join "`r`n"
    }
}

Set-Content -Path $solutionPath -Value $solutionTemplate -Encoding utf8

$newRow = "| $LeetCodeNumber | [$resolvedTitle]($Url) | In Progress | TBD | [Code](./problems/$folderName/solution.$extension) |"

foreach ($trackerPath in Get-TrackerFiles) {
    Set-TrackerRow -TrackerPath $trackerPath -FolderName $folderName -Extension $extension -Row $newRow
}

Write-Host "Created $problemDir"
