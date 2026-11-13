# ZeDUI/tools/qa/lang_run.ps1  (Nov 2 2026, QA; punch list 62): one of ZeD's machine-translated languages in game.
# Sets the game's language in options.ini (the game reads it at launch), runs the manifest you name at 4K, puts the language back.
#   pwsh -File ZeDUI/tools/qa/lang_run.ps1 -Lang TR -Manifest <file>      (any of the game's language codes that ZeD has a draft for; Nov 3 2026: all 27)
param([Parameter(Mandatory)][ValidateSet("EN", "TR", "CN", "PTBR", "PT", "ES", "ES_MX", "AR", "ES_CL", "FR", "DE", "IT", "CA", "NL", "DA", "NO", "FI", "PL", "CS", "HU", "RO", "RU", "UA", "CH", "JP", "KO", "TH", "ID")][string]$Lang, [Parameter(Mandatory)][string]$Manifest)   # (Nov 12 2026: no default manifest; lang_check.txt is archived, i18n_guard.py check 5 replaced it)
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$ini = "$($env:USERPROFILE)\Zomboid\options.ini"
$text = Get-Content -Raw $ini
$was = if ($text -match '(?m)^language=(.*)$') { $Matches[1].Trim() } else { "EN" }
try {
    Set-Content -Path $ini -Value ($text -replace '(?m)^language=.*$', "language=$Lang") -NoNewline
    & pwsh -File (Join-Path $here "zedqa_run.ps1") -Manifest (Join-Path $here $Manifest) -Mode fullscreen4k -Report ("pl62_lang_" + $Lang + "_" + [IO.Path]::GetFileNameWithoutExtension($Manifest))
}
finally {
    $now = Get-Content -Raw $ini
    Set-Content -Path $ini -Value ($now -replace '(?m)^language=.*$', "language=$was") -NoNewline
    Write-Output "language put back to $was"
}
