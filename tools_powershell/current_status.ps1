# Run as Administrator

Write-Host "[+] Checking for running processes..."
Get-Process 

Write-Host "[+] Checking current services and states..."
Get-Service 

Write-Host "[+] Checking current active network connections..."
Get-NetTCPConnection

Write-Host "[+] Checking for local accounts..."
Get-LocalUser

Write-Host "[+] Checking for current scheduled tasks..."
Get-ScheduledTask

#Write-Host "[+] Checking event logs..."
#Get-WinEvent

#Write-Host "[+] Checking system information and installed software..."
#Get-WmiObject

#Write-Host "[+] Checking for connections..."
#Test-NetConnection