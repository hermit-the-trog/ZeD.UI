# QA b9 (Nov 8 2026): the respawn check on the local test server (admin joined from the main menu), then the server
# stopped by its saved PID. Lines go to b9_rsp_run.log as they happen (stall_watch.ps1 watches it).
# mp_server.ps1 -Start runs through Start-Process -Wait with its output to a file: piped, the server it starts keeps
# the pipe open and the pipeline never ends (the stall of Nov 8 17:16).
$env:ZEDQA_NOSTEAM = "1"
$Qa = $PSScriptRoot
$Log = Join-Path $Qa "b9_rsp_run.log"
function L($s) { "$(Get-Date -Format 'HH:mm:ss') $s" | Add-Content $Log }
"== $(Get-Date -Format 'HH:mm:ss') start" | Set-Content $Log
$srvOut = Join-Path $Qa "b9_rsp_srv.log"
# the staged beta 9 (Build's, for the upload) is held aside for this dev-code run and put back after
$Ws = "C:\Users\you\Zomboid\Workshop\ZeD-UI"
if (Test-Path "$Ws\Contents") { Rename-Item "$Ws\Contents" "Contents.hold"; L "staged Contents held aside" }
try {
    $sp = Start-Process pwsh -ArgumentList "-NoProfile", "-File", "$Qa\mp_server.ps1", "-Start", "-Mods", "ZeD_UI;ZeDQAShim", "-Set", "DoLuaChecksum=false" -RedirectStandardOutput $srvOut -NoNewWindow -PassThru; $sp.WaitForExit()
    L "server start exit $($sp.ExitCode): $((Get-Content $srvOut -Tail 2) -join ' | ')"
    & pwsh -NoProfile -File "$Qa\zedqa_run.ps1" -Mp -Mode windowed -Width 1280 -Height 800 -Manifest "$Qa\b9_rsp_mp.txt" -Report b9_respawn_mp 2>&1 | ForEach-Object { L "run $_" }
} finally {
    $stopOut = Join-Path $Qa "b9_rsp_stop.log"
    Start-Process pwsh -ArgumentList "-NoProfile", "-File", "$Qa\mp_server.ps1", "-Stop" -RedirectStandardOutput $stopOut -NoNewWindow -PassThru | ForEach-Object { $_.WaitForExit() }
    L "server stop: $((Get-Content $stopOut -Tail 1) -join ' ')"
    if (Test-Path "$Ws\Contents.hold") { Rename-Item "$Ws\Contents.hold" "Contents"; L "staged Contents put back" }
    "== $(Get-Date -Format 'HH:mm:ss') end" | Add-Content $Log
}
