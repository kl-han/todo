# Registers quadrant-agent as a per-user logon task (no administrator
# access required — the task runs in the interactive user session, which
# is a hard requirement: a Windows Service in Session 0 cannot observe
# the user's desktop).
#
# Usage:  powershell -ExecutionPolicy Bypass -File register-startup-task.ps1
# Remove: schtasks /Delete /TN "QuadrantAgent" /F

$exe = Join-Path $env:LOCALAPPDATA 'QuadrantTodo\quadrant_agent.exe'
if (-not (Test-Path $exe)) {
    Write-Error "quadrant_agent.exe not found at $exe; install it first."
    exit 1
}

$action = New-ScheduledTaskAction -Execute $exe -Argument 'run'
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit ([TimeSpan]::Zero)

Register-ScheduledTask -TaskName 'QuadrantAgent' `
    -Action $action -Trigger $trigger -Settings $settings -Force
Write-Output 'quadrant-agent will start at logon for the current user.'
