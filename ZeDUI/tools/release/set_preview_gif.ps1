#Requires -Version 7.0
<#
.SYNOPSIS
    Puts the animated thumbnail on the Workshop item after an upload (Nov 3 2026, punch list 81).

.DESCRIPTION
    The game's uploader only takes preview.png, and every Upload puts that still back as the item's thumbnail. This
    step sets the animated GIF (ZeDUI/workshop/thumbnail/year_1993_dark_animated.gif: frame 1 is the still) as the
    item's preview through SteamCMD, Valve's command-line uploader. Run it after every Upload, as the release's last
    step (RELEASE_CHECKLIST.md, step 16b).

    It writes a SteamCMD item file with the appid, the item's id and the preview file only: no content folder, no
    title, no description, no change note, so the item's files and page text are left as the Upload made them.

    The director signs off every upload, and this changes the live item too: the director runs it, or build runs it on
    his word.

    One time, by the director:
      1. Install SteamCMD: download steamcmd.zip from Valve (developer.valvesoftware.com/wiki/SteamCMD), unzip it to
         C:\steamcmd, run C:\steamcmd\steamcmd.exe once and let it update, then type quit.
      2. Log in once by hand: C:\steamcmd\steamcmd.exe +login <steam account name> (password and Steam Guard code
         when it asks), then quit. SteamCMD keeps the login, so this script never needs the password.
    Logging in with SteamCMD signs the Steam client out on this PC: run it when nobody is in the game, then sign the
    Steam client back in.

    First run on the unlisted test item (-ItemId), and check its files and page text are untouched, before the real
    item.

.PARAMETER SteamUser
    The Steam account name SteamCMD logged in as (or the ZED_STEAM_USER environment variable).

.PARAMETER ItemId
    The Workshop item to update. Default: the id= line of Zomboid/Workshop/ZeD-UI/workshop.txt.

.PARAMETER Gif
    The animated preview. Default: ZeDUI/workshop/thumbnail/year_1993_dark_animated.gif. Steam takes up to 1 MB.

.PARAMETER SteamCmd
    Path to steamcmd.exe. Default: C:\steamcmd\steamcmd.exe.

.PARAMETER DryRun
    Checks everything and prints the item file and the command, runs nothing.

.EXAMPLE
    pwsh -File ZeDUI/tools/release/set_preview_gif.ps1 -SteamUser hermit -DryRun
.EXAMPLE
    pwsh -File ZeDUI/tools/release/set_preview_gif.ps1 -SteamUser hermit -ItemId <test item id>
#>
[CmdletBinding()]
param(
    [string]$SteamUser = $env:ZED_STEAM_USER,
    [string]$ItemId,
    [string]$Gif,
    [string]$SteamCmd = 'C:\steamcmd\steamcmd.exe',
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
function Fail([string]$msg) { Write-Host "REFUSED: $msg" -ForegroundColor Red; exit 1 }

$ModRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$Zomboid = [IO.Path]::GetFullPath((Join-Path $ModRoot '../..'))
$WsTxt   = Join-Path $Zomboid 'Workshop/ZeD-UI/workshop.txt'
$AppId   = '108600'                                                   # Project Zomboid

# the item
if (-not $ItemId) {
    if (-not (Test-Path -LiteralPath $WsTxt)) { Fail "no -ItemId and no $WsTxt (upload once from the game first)" }
    $m = Select-String -LiteralPath $WsTxt -Pattern '^id=(\d+)' | Select-Object -First 1
    if (-not $m) { Fail "workshop.txt has no id= line yet (upload once from the game first)" }
    $ItemId = $m.Matches[0].Groups[1].Value
}
if ($ItemId -notmatch '^\d+$') { Fail "the item id must be a number: '$ItemId'" }

# the picture: a GIF, square, at most 1 MB
$Gif = if ($Gif) { [IO.Path]::GetFullPath((Join-Path $ModRoot $Gif)) } else { Join-Path $ModRoot 'ZeDUI/workshop/thumbnail/year_1993_dark_animated.gif' }
if (-not (Test-Path -LiteralPath $Gif)) { Fail "no preview at $Gif" }
$bytes = [IO.File]::ReadAllBytes($Gif)
if ($bytes.Length -gt 1MB) { Fail ("{0:N0} KB is over Steam's 1 MB for a preview" -f ($bytes.Length / 1KB)) }
$sig = [Text.Encoding]::ASCII.GetString($bytes, 0, 6)
if ($sig -notin @('GIF87a', 'GIF89a')) { Fail "$Gif is not a GIF" }
$w = [BitConverter]::ToUInt16($bytes, 6); $h = [BitConverter]::ToUInt16($bytes, 8)
if ($w -ne $h) { Fail "the preview should be square (it is $w x $h)" }

# the item file: the preview only (forward slashes: the item file treats backslashes as escapes)
$Vdf = Join-Path ([IO.Path]::GetTempPath()) "zed_preview_$ItemId.vdf"
$gifPath = $Gif -replace '\\', '/'
$body = @"
"workshopitem"
{
	"appid"		"$AppId"
	"publishedfileid"		"$ItemId"
	"previewfile"		"$gifPath"
}
"@
Set-Content -LiteralPath $Vdf -Value $body -Encoding utf8NoBOM -NoNewline

Write-Host ("item {0}  |  preview {1}  ({2} x {3}, {4:N0} KB)" -f $ItemId, $Gif, $w, $h, ($bytes.Length / 1KB))
Write-Host "item file $Vdf :"; Write-Host $body
if (-not $SteamUser) { Fail "no -SteamUser (or ZED_STEAM_USER): the account SteamCMD logged in as" }
$cmd = @('+login', $SteamUser, '+workshop_build_item', $Vdf, '+quit')
Write-Host ("command: {0} {1}" -f $SteamCmd, ($cmd -join ' '))
if ($DryRun) { Write-Host 'dry run: nothing sent.' -ForegroundColor Cyan; exit 0 }

if (-not (Test-Path -LiteralPath $SteamCmd)) {
    Fail "no SteamCMD at ${SteamCmd}: install it once (see this script's header), or pass -SteamCmd"
}
Write-Host 'This signs the Steam client out on this PC. Nobody in the game? Continuing in 5 s (Ctrl+C to stop).' -ForegroundColor Yellow
Start-Sleep -Seconds 5
& $SteamCmd @cmd
$code = $LASTEXITCODE
Remove-Item -LiteralPath $Vdf -ErrorAction SilentlyContinue
if ($code -ne 0) { Fail "SteamCMD ended with exit code $code (a login prompt means the one-time login is needed)" }
Write-Host "done: check the item page, the Workshop grid and the Steam app (https://steamcommunity.com/sharedfiles/filedetails/?id=$ItemId), then sign the Steam client back in." -ForegroundColor Green
