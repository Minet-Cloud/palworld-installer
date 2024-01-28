$ErrorActionPreference = "Stop"

$ProcessNames = @("PalServer", "PalServer-Win64-Test-Cmd")
foreach ($ProcessName in $ProcessNames) {
    if (Get-Process $ProcessName -ErrorAction SilentlyContinue) {
        Write-Host "$ProcessName is already running."
        exit
    }
}

$DirectoryPath = "C:\Program Files\PalServer\"
if (-not (Test-Path -Path $directoryPath)) {
    New-Item -ItemType Directory -Path $directoryPath | Out-Null
}

Write-Host "Start download vc_redist.x64.exe..."
$VcUrl = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
$VcOutput = "C:\Program Files\PalServer\vc_redist.x64.exe"
Invoke-WebRequest -Uri $VcUrl -OutFile $VcOutput
Write-Host "Installing vc_redist.x64.exe..."
Start-Process -FilePath $VcOutput -Args '/install', '/quiet', '/norestart' -Wait
Remove-Item -Path $VcOutput

Write-Host "Start download dxwebsetup.exe..."
$DxUrl = "https://download.microsoft.com/download/1/7/1/1718CCC4-6315-4D8E-9543-8E28A4E18C4C/dxwebsetup.exe"
$DxOutput = "C:\Program Files\PalServer\dxwebsetup.exe"
Invoke-WebRequest -Uri $DxUrl -OutFile $DxOutput
Write-Host "Installing dxwebsetup.exe..."
Start-Process -FilePath $DxOutput -Args '/Q' -Wait
Remove-Item -Path $DxOutput

Write-Host "Start download steamcmd.zip..."
$StUrl = "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip"
$StOutput = "C:\Program Files\PalServer\steamcmd.zip"
$StUnzipPath = "C:\Program Files\PalServer\steam\"
Invoke-WebRequest -Uri $StUrl -OutFile $StOutput
Expand-Archive -LiteralPath $StOutput -DestinationPath $StUnzipPath -Force
Remove-Item -Path $StOutput

Write-Host "Running steamcmd.exe..."
Set-Location -Path $StUnzipPath
Start-Process ".\steamcmd.exe" -ArgumentList "+login anonymous +app_update 2394010 validate +quit" -Wait

Write-Host "Setting scheduled task..."
$TaskName = "PalServerAutoStart"
$TaskDescription = "Automatically starts PalServer on system startup and restarts on failure."
$TaskExecutable = "C:\Program Files\PalServer\steam\steamapps\common\PalServer\PalServer.exe"
$TaskAction = New-ScheduledTaskAction -Execute $TaskExecutable
$TaskTrigger = New-ScheduledTaskTrigger -AtStartup
$TaskPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

$RestartInterval = New-TimeSpan -Minutes 1
$RestartCount = 3
$TaskSettings = New-ScheduledTaskSettingsSet -RestartInterval $RestartInterval -RestartCount $RestartCount
Register-ScheduledTask -TaskName $TaskName -Description $TaskDescription -Action $TaskAction -Trigger $TaskTrigger -Principal $TaskPrincipal -Settings $TaskSettings -Force | Out-Null

Write-Host "Running PalServer.exe..."
Start-ScheduledTask -TaskName $TaskName
Write-Host "PalServer deploy success!"
