# Run as Administrator
$timestamp = Get-Date -Format "yyyyMMdd-HHmm"
$out = "status-$timestamp.txt"

Write-Host "[+] Checking for running processes..."
"=== RUNNING PROCESSES ===" | Out-File $out
Get-Process | Select-Object Name, Id, CPU, Path | Sort-Object CPU -Descending | Out-File $out -Append

Write-Host "[+] Checking current services and states..."
"=== CURRENT SERVICES ===" | Out-File $out -Append
Get-Service | Where-Object Status -eq "Running"| Out-File $out -Append

Write-Host "[+] Checking current active network connections..."
"=== ACTIVE NETWORK CONNECTIONS ===" | Out-File $out -Append
Get-NetTCPConnection -State Established | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort | Out-File $out -Append

Write-Host "[+] Checking for local accounts..."
"=== LOCAL ACCOUNTS ===" | Out-File $out -Append
Get-LocalUser | Out-File $out -Append

Write-Host "[+] Checking for current scheduled tasks..."
"=== SCHEDULED TASKS ===" | Out-File $out -Append
Get-ScheduledTask | Where-Object State -eq "Ready" | Select-Object TaskName, TaskPath | Out-File $out -Append

Write-Host "[+] Checking event logs..."
"=== EVENT LOGS ===" | Out-File $out -Append
#Log ins 
Get-WinEvent -LogName Security | Where-Object Id -eq 4624 | Out-File $out -Append
#System log offs
Get-WinEvent -LogName Security | Where-Object Id -eq 4634 | Out-File $out -Append
#Log offs
Get-WinEvent -LogName Security | Where-Object Id -eq 4647 | Out-File $out -Append
#Account creation
Get-WinEvent -LogName Security | Where-Object Id -eq 4720 | Out-File $out -Append

#Write-Host "[+] Checking system information and installed software..."
#Get-WmiObject

#Write-Host "[+] Checking for connections..."
#Test-NetConnection