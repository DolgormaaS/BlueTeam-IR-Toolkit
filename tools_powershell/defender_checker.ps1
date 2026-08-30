#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Defender / firewall hardening + policy-tamper remediation.
    Mutates security state, so every run is captured to a transcript.
#>

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$log = Join-Path (Get-Location) "defender-remediation-$timestamp.log"
Start-Transcript -Path $log | Out-Null

Write-Host "[+] Initial Defender status..."
Get-MpComputerStatus | Select-Object AntivirusEnabled, RealTimeProtectionEnabled,
    IsTamperProtected, AMRunningMode, AntivirusSignatureLastUpdated

Write-Host "`n[+] Enabling firewall profiles..."
Set-NetFirewallProfile -Profile Domain, Private, Public -Enabled True

Write-Host "`n[+] Checking for Windows Server (Install-WindowsFeature)..."
if (Get-Command Install-WindowsFeature -ErrorAction SilentlyContinue) {
    foreach ($feature in 'Windows-Defender','Windows-Defender-GUI') {
        $f = Get-WindowsFeature -Name $feature -ErrorAction SilentlyContinue
        if ($f -and -not $f.Installed) {
            Write-Host "[+] Installing $feature..."
            Install-WindowsFeature -Name $feature
        }
    }
} else {
    Write-Host "[*] Not a Server SKU (or feature cmdlets unavailable). Skipping feature install."
}

Write-Host "`n[+] Starting Defender services..."
Start-Service WinDefend -ErrorAction SilentlyContinue
Start-Service WdNisSvc  -ErrorAction SilentlyContinue

Write-Host "`n[+] Enabling real-time protection..."
try {
    Set-MpPreference -DisableRealtimeMonitoring $false
    Set-MpPreference -DisableIOAVProtection $false
} catch {
    Write-Host "[!] Could not set Defender preferences — Tamper Protection or policy may be blocking."
    Write-Host "    $($_.Exception.Message)"
}

Write-Host "`n[+] Remediating Defender policy registry keys..."
try {
    $policy = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender'
    $rt = "$policy\Real-Time Protection"
    New-Item -Path $policy -Force | Out-Null
    New-Item -Path $rt     -Force | Out-Null
    New-ItemProperty -Path $rt     -Name DisableBehaviorMonitoring   -Value 0 -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $rt     -Name DisableOnAccessProtection   -Value 0 -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $rt     -Name DisableScanOnRealtimeEnable -Value 0 -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $policy -Name DisableAntiSpyware          -Value 0 -PropertyType DWORD -Force | Out-Null
    Write-Host "[+] Policy remediation complete."
} catch {
    Write-Host "[!] Could not modify policy keys (Tamper Protection / GPO may block this even as admin)."
    Write-Host "    $($_.Exception.Message)"
}

Write-Host "`n[+] Restarting Defender services..."
Restart-Service WinDefend -ErrorAction SilentlyContinue
Start-Service   WdNisSvc  -ErrorAction SilentlyContinue

Write-Host "`n[+] Final Defender status:"
Get-MpComputerStatus | Select-Object AntivirusEnabled, RealTimeProtectionEnabled,
    IsTamperProtected, AMRunningMode, AntivirusSignatureLastUpdated

Write-Host "`n[+] Final firewall status:"
Get-NetFirewallProfile | Select-Object Name, Enabled

Stop-Transcript | Out-Null
Write-Host "`n[+] Audit log: $log"