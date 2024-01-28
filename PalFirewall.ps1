# Check if the script is running as an administrator
function Test-IsAdmin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Exit script if not running as administrator
if (-not (Test-IsAdmin)) {
    Write-Host "This script must be run as an administrator. Exiting..."
    exit
}

# Function to create firewall rules if they do not exist
function Set-FirewallRule {
    param (
        [string]$DisplayName,
        [string]$Direction,
        [int[]]$LocalPort,
        [string]$Protocol,
        [string]$Action
    )

    $existingRule = Get-NetFirewallRule -DisplayName $DisplayName -ErrorAction SilentlyContinue
    if (-not $existingRule) {
        Write-Host "Creating firewall rule: $DisplayName"
        New-NetFirewallRule -DisplayName $DisplayName -Direction $Direction -LocalPort $LocalPort -Protocol $Protocol -Action $Action
    }
    else {
        Write-Host "Firewall rule '$DisplayName' already exists."
    }
}

# Ensure the script is running as an administrator
if (-not (Test-IsAdmin)) {
    Write-Host "This script must be run as an administrator. Exiting..."
    exit
}

# Define the firewall rules to check and create if necessary
$firewallRules = @(
    @{ DisplayName="Palworld Server TCP Inbound"; Direction="Inbound"; LocalPort=(27015, 27016, 25575); Protocol="TCP"; Action="Allow" },
    @{ DisplayName="Palworld Server TCP Outbound"; Direction="Outbound"; LocalPort=(27015, 27016, 25575); Protocol="TCP"; Action="Allow" },
    @{ DisplayName="Palworld Server UDP Outbound"; Direction="Outbound"; LocalPort=(8211, 27015, 27016, 25575); Protocol="UDP"; Action="Allow" },
    @{ DisplayName="Palworld Server UDP Inbound"; Direction="Inbound"; LocalPort=(8211, 27015, 27016, 25575); Protocol="UDP"; Action="Allow" }
)

# Check and create the firewall rules
foreach ($rule in $firewallRules) {
    Set-FirewallRule @rule
}
