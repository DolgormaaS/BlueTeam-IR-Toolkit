# Run as Administrator

Write-Host "[+] Checking initial Defender status..."
Get-MpComputerStatus | Select-Object AntivirusEnabled, RealTimeProtectionEnabled, IsTamperProtected, AMRunningMode, AntivirusSignatureLastUpdated

Write-Host "`n[+] Enabling Windows Firewall profiles..."
Set-NetFirewallProfile -Profile Domain, Private, Public -Enabled True

Write-Host "`n[+] Checking whether this is Windows Server with Install-WindowsFeature..."
if (Get-Command Install-WindowsFeature -ErrorAction SilentlyContinue) {
    $defenderFeature = Get-WindowsFeature -Name Windows-Defender -ErrorAction SilentlyContinue

    if ($defenderFeature -and -not $defenderFeature.Installed) {
        Write-Host "[+] Installing Windows Defender feature..."
        Install-WindowsFeature -Name Windows-Defender
    } else {
        Write-Host "[+] Windows Defender feature appears installed or unavailable."
    }

    $defenderGui = Get-WindowsFeature -Name Windows-Defender-GUI -ErrorAction SilentlyContinue
    if ($defenderGui -and -not $defenderGui.Installed) {
        Write-Host "[+] Installing Windows Defender GUI..."
        Install-WindowsFeature -Name Windows-Defender-GUI
    }
} else {
    Write-Host "[*] Install-WindowsFeature not available. Skipping Defender feature install."
}

Write-Host "`n[+] Starting Defender services..."
Start-Service WinDefend -ErrorAction SilentlyContinue
Start-Service WdNisSvc -ErrorAction SilentlyContinue

Write-Host "`n[+] Enabling Defender real-time protections..."
try {
    Set-MpPreference -DisableRealtimeMonitoring $false
    Set-MpPreference -DisableIOAVProtection $false
} catch {
    Write-Host "[!] Failed to set Defender preferences. Tamper Protection or policy may be blocking this."
    Write-Host $_
}

Write-Host "`n[+] Attempting Defender policy registry remediation..."

try {
    $defenderPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
    $rtPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"

    New-Item -Path $defenderPolicyPath -Force | Out-Null
    New-Item -Path $rtPolicyPath -Force | Out-Null

    New-ItemProperty -Path $rtPolicyPath -Name "DisableBehaviorMonitoring" -Value 0 -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $rtPolicyPath -Name "DisableOnAccessProtection" -Value 0 -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $rtPolicyPath -Name "DisableScanOnRealtimeEnable" -Value 0 -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $defenderPolicyPath -Name "DisableAntiSpyware" -Value 0 -PropertyType DWORD -Force | Out-Null

    Write-Host "[+] Defender policy registry remediation completed."
}
catch {
    Write-Host "[!] Could not modify Defender policy registry keys."
    Write-Host "[!] This can happen even as Administrator if Tamper Protection, Group Policy, or security policy blocks changes."
}

Write-Host "`n[+] Restarting Defender services..."
Start-Service WinDefend -ErrorAction SilentlyContinue
Start-Service WdNisSvc -ErrorAction SilentlyContinue

Write-Host "`n[+] Final Defender Status"
Get-MpComputerStatus | Select-Object AntivirusEnabled, RealTimeProtectionEnabled, IsTamperProtected, AMRunningMode, AntivirusSignatureLastUpdated

Write-Host "`n[+] Final Firewall Status"
Get-NetFirewallProfile | Select-Object Name, Enabled