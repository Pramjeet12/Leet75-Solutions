param(
    [Parameter(Mandatory = $true)]
    [int]$Number,

    [Parameter(Mandatory = $true)]
    [string]$LeetCodeNumber,

    [Parameter(Mandatory = $true)]
    [string]$Approach,

    [string]$Status = "Done",

    [string]$Url,

    [string]$Title
)

function Get-TrackerFiles {
    return @("Readme.md", "Progress.md")
}

function Get-ProblemDirectory {
    param([int]$ProblemNumber)

    $prefix = "{0:D3}-*" -f $ProblemNumber
    $directory = Get-ChildItem -Path "problems" -Directory | Where-Object { $_.Name -like $prefix } | Select-Object -First 1

    if (-not $directory) {
        throw "Could not find problem folder for number $ProblemNumber"
    }

    return $directory
}

function Get-ProblemTitleFromFolder {
    param([string]$FolderName)

    $nameWithoutPrefix = $FolderName.Substring(4)
    $words = $nameWithoutPrefix -split "-"
    return (($words | ForEach-Object {
        if ($_.Length -gt 0) {
            $_.Substring(0, 1).ToUpper() + $_.Substring(1)
        }
    }) -join " ")
}

function Update-ReadmeLine {
    param(
        [System.Collections.Generic.List[string]]$Lines,
        [string]$Prefix,
        [string]$Value
    )

    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i].StartsWith($Prefix)) {
            $Lines[$i] = "$Prefix$Value"
            return
        }
    }

    $insertIndex = 1
    [void]$Lines.Insert($insertIndex, "$Prefix$Value")
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

    foreach ($line in (Get-Content -Path $TrackerPath -Encoding utf8)) {
        $lines.Add($line)
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

$problemDirectory = Get-ProblemDirectory -ProblemNumber $Number
$folderName = $problemDirectory.Name
$solutionFile = Get-ChildItem -Path $problemDirectory.FullName -Filter "solution.*" | Select-Object -First 1

if (-not $solutionFile) {
    throw "Could not find solution file inside $($problemDirectory.FullName)"
}

$resolvedTitle = if ([string]::IsNullOrWhiteSpace($Title)) {
    Get-ProblemTitleFromFolder -FolderName $folderName
}
else {
    $Title
}

$problemReadmePath = Join-Path $problemDirectory.FullName "README.md"
$readmeLines = [System.Collections.Generic.List[string]]::new()
foreach ($line in (Get-Content -Path $problemReadmePath -Encoding utf8)) {
    $readmeLines.Add($line)
}

if (-not [string]::IsNullOrWhiteSpace($Url)) {
    Update-ReadmeLine -Lines $readmeLines -Prefix "- Problem: " -Value $Url
}

Update-ReadmeLine -Lines $readmeLines -Prefix "- LeetCode No: " -Value $LeetCodeNumber
Update-ReadmeLine -Lines $readmeLines -Prefix "- Status: " -Value $Status
Update-ReadmeLine -Lines $readmeLines -Prefix "- Approach Used: " -Value $Approach

Set-Content -Path $problemReadmePath -Value ($readmeLines -join "`r`n") -Encoding utf8

$resolvedUrl = if ([string]::IsNullOrWhiteSpace($Url)) {
    (($readmeLines | Where-Object { $_ -like "- Problem: *" } | Select-Object -First 1) -replace "^- Problem: ", "")
}
else {
    $Url
}

$row = "| $LeetCodeNumber | [$resolvedTitle]($resolvedUrl) | $Status | $Approach | [Code](./problems/$folderName/$($solutionFile.Name)) |"

foreach ($trackerPath in Get-TrackerFiles) {
    Set-TrackerRow -TrackerPath $trackerPath -FolderName $folderName -Extension $solutionFile.Extension.TrimStart(".") -Row $row
}

Write-Host "Updated $folderName"
