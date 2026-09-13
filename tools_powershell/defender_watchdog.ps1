#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Checks for things that are excluded (Exclusions) from the sight of Defender. 
    For example: "Add-MpPreference -ExclusionPath 'C:\Users\Public'" would exclude the path from the 
    Defender and the defender would miss it, saying everything is fine. This is where this scipt comes in.
#>

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$out = Join-Path (Get-Location) "watchdog-$timestamp.txt"

Write-Host "[+] Checking for excluded paths..."
"`n=== Excluded Paths ===" | Out-File $out -Append
(Get-MpPreference).ExclusionPath      | Out-File $out -Append

Write-Host "[+] Checking for excluded processes..."
"`n=== Excluded Processes ===" | Out-File $out -Append
(Get-MpPreference).ExclusionProcess   | Out-File $out -Append

Write-Host "[+] Checking for excluded extensions..."
"`n=== Excluded Extensions ===" | Out-File $out -Append
(Get-MpPreference).ExclusionExtension | Out-File $out -Append

