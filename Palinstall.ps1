# Define the path to PalServer.exe
$palServerPath = "C:\Program Files (x86)\Steam\steamapps\common\PalServer"
$palServerExe = "$palServerPath\PalServer.exe" # Update this path
$defaultSteamCmdPath = "C:\SteamCMD" # Default steamcmd installation path

# Function to download and unzip steamcmd if not installed
function Install-SteamCmd {
    $steamCmdZipUrl = "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip"
    $steamCmdZipPath = "$defaultSteamCmdPath\steamcmd.zip"
    $webClient = New-Object System.Net.WebClient
    
    # Create the directory if it doesn't exist
    if (-not (Test-Path $defaultSteamCmdPath)) {
        New-Item -Path $defaultSteamCmdPath -ItemType Directory
    }

    # Download and unzip steamcmd
    $webClient.DownloadFile($steamCmdZipUrl, $steamCmdZipPath)
    Expand-Archive -Path $steamCmdZipPath -DestinationPath $defaultSteamCmdPath -Force
    Remove-Item -Path $steamCmdZipPath # Clean up ZIP file after extraction
}

# Function to check if steamcmd is installed
function Get-SteamCmdInstalled {
    $isInPath = Get-Command steamcmd -ErrorAction SilentlyContinue
    $existsInDefaultLocation = Test-Path "$defaultSteamCmdPath\steamcmd.exe"

    if ($isInPath) {
        Write-Host "steamcmd is installed."
    } else {
        if (-not $existsInDefaultLocation) {
            Write-Host "steamcmd not found. Installing..."
            Install-SteamCmd
            # Add the default location to the PATH for this session
            $env:Path += ";$defaultSteamCmdPath"
        }
    }
}

# Function to check and update the game server
function Update-GameServer {
    Write-Host "Checking for updates..."
    & steamcmd +login anonymous +app_update 2394010 +quit
}

# Function to start the game server
function Start-GameServer {
    $arguments = "-log -nosteam -useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS"
    Start-Process -FilePath $palServerExe -ArgumentList $arguments -NoNewWindow
}

# Function to check if the server is running
function Get-ServerRunning {
    $process = Get-Process PalServer -ErrorAction SilentlyContinue
    return $null -ne $process
}

# Function to get current timestamp
function Get-Timestamp {
    return Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

function Backup-ServerData {
    $sourcePath = "$palServerPath\Pal\Saved\"
    $backupParentPath = "$palServerPath\Pal\Backups"
    $backupPath = "$backupParentPath\Saved-Backup-" + (Get-Date -Format "yyyyMMddHHmmss")
    Write-Host "Backing up server data to $backupPath..."
    # Create the directory if it doesn't exist
    if (-not (Test-Path $backupParentPath)) {
        New-Item -Path $backupParentPath -ItemType Directory
    }
    # Create the directory if it doesn't exist
    Copy-Item -Path $sourcePath -Destination $backupPath -Recurse -Force
}

# Initial setup and server start
Get-SteamCmdInstalled
Update-GameServer
Start-GameServer
$timestamp = Get-Timestamp
Write-Host "$timestamp - Started PalServer.exe!"

# Continuously check if the server is running
$backupInterval = 30 * 60 # 30 minutes in seconds
$checkInterval = 10 # Check every 10 seconds
$backupTimer = 0
while ($true) {
    Start-Sleep -Seconds $checkInterval
    $backupTimer += $checkInterval

    # Check server status
    if (-not (Get-ServerRunning)) {
        $timestamp = Get-Timestamp
        Write-Host "$timestamp - PalServer.exe is not running. Starting server..."
        Start-GameServer
    }

    # Every 15 minutes, backup server data
    if ($backupTimer -ge $backupInterval) {
        Backup-ServerData
        $backupTimer = 0 # Reset timer after backup
    }
}
