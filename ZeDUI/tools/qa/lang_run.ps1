# ZeDUI/tools/qa/lang_run.ps1  (Nov 2 2026, QA; punch list 62): one of ZeD's machine-translated languages in game.
# Sets the game's language in options.ini (the game reads it at launch), runs lang_check.txt at 4K, puts the language back.
#   pwsh -File ZeDUI/tools/qa/lang_run.ps1 -Lang TR      (any of the game's language codes that ZeD has a draft for; Nov 3 2026: all 27)
param([Parameter(Mandatory)][ValidateSet("EN", "TR", "CN", "PTBR", "PT", "ES", "ES_MX", "AR", "ES_CL", "FR", "DE", "IT", "CA", "NL", "DA", "NO", "FI", "PL", "CS", "HU", "RO", "RU", "UA", "CH", "JP", "KO", "TH", "ID")][string]$Lang, [string]$Manifest = "lang_check.txt")
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$ini = "C:\Users\you\Zomboid\options.ini"
$text = Get-Content -Raw $ini
$was = if ($text -match '(?m)^language=(.*)$') { $Matches[1].Trim() } else { "EN" }
try {
    Set-Content -Path $ini -Value ($text -replace '(?m)^language=.*$', "language=$Lang") -NoNewline
    & pwsh -File (Join-Path $here "zedqa_run.ps1") -Manifest (Join-Path $here $Manifest) -Mode fullscreen4k -Report ("pl62_lang_" + $Lang + $(if ($Manifest -ne "lang_check.txt") { "_" + [IO.Path]::GetFileNameWithoutExtension($Manifest) } else { "" }))
}
finally {
    $now = Get-Content -Raw $ini
    Set-Content -Path $ini -Value ($now -replace '(?m)^language=.*$', "language=$was") -NoNewline
    Write-Output "language put back to $was"
}
