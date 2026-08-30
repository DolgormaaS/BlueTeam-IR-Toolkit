#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Rapid Windows triage collector. Snapshots host state to timestamped CSVs
    for first-response IR / threat hunting. Run elevated.
#>

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$out = Join-Path (Get-Location) "status-$timestamp.txt"

# --- helpers ---

# write a titled section, rendered full-width so wide columns (e.g. Path) never truncate
function Write-Section {
    param([string]$Title, $Data)
    "`n=== $Title ===" | Out-File $out -Append
    $Data | Format-Table -AutoSize | Out-String -Width 4096 | Out-File $out -Append
}

# pull EventData fields out of an event's XML BY NAME (not position) -> survives schema
# differences across event IDs. This is what makes the resume bullet literally true.
function Get-EventDataMap {
    param($Event)
    $map = @{}
    $xml = [xml]$Event.ToXml()
    foreach ($d in $xml.Event.EventData.Data) { $map[$d.Name] = $d.'#text' }
    return $map
}

# friendly logon-type names (only meaningful for 4624/4625)
function Get-LogonTypeName {
    param($Type)
    switch ($Type) {
        '2'  { 'Interactive' }
        '3'  { 'Network' }
        '4'  { 'Batch' }
        '5'  { 'Service' }
        '7'  { 'Unlock' }
        '8'  { 'NetworkCleartext' }
        '9'  { 'NewCredentials' }
        '10' { 'RemoteInteractive (RDP)' }
        '11' { 'CachedInteractive' }
        default { $Type }
    }
}

# --- report header ---
"Windows Triage Report"        | Out-File $out          # overwrite: fresh file each run
"Generated: $(Get-Date)"       | Out-File $out -Append
"Host: $env:COMPUTERNAME"      | Out-File $out -Append

# --- processes ---
Write-Host "[+] Checking for running processes..."
Write-Section "RUNNING PROCESSES" (
    Get-Process |
        Select-Object Name, Id, CPU,
            @{ N='Path'; E={ try { $_.Path } catch { 'ACCESS_DENIED' } } } |  # protected procs throw
        Sort-Object CPU -Descending
)

# --- services ---
Write-Host "[+] Checking running services..."
Write-Section "RUNNING SERVICES" (
    Get-Service | Where-Object Status -eq 'Running' |
        Select-Object Name, DisplayName, Status, StartType
)

# --- network ---
Write-Host "[+] Checking active network connections..."
Write-Section "ACTIVE NETWORK CONNECTIONS" (
    Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue |
        Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, OwningProcess,
            @{ N='Process'; E={ (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).Name } }
)

# --- local accounts ---
Write-Host "[+] Checking local accounts..."
Write-Section "LOCAL ACCOUNTS" (
    Get-LocalUser | Select-Object Name, Enabled, LastLogon, PasswordLastSet
)

# --- scheduled tasks ---
Write-Host "[+] Checking scheduled tasks..."
Write-Section "SCHEDULED TASKS" (
    Get-ScheduledTask | Where-Object State -eq 'Ready' |
        Select-Object TaskName, TaskPath
)

# --- security events (last 24h) ---
Write-Host "[+] Checking security events (last 24h)..."
$ids = 4624, 4625, 4634, 4647, 4720
$events = Get-WinEvent -FilterHashtable @{      # filter LEFT at the provider, time-bounded
    LogName   = 'Security'
    Id        = $ids
    StartTime = (Get-Date).AddDays(-1)
} -ErrorAction SilentlyContinue                 # no matches = non-terminating error; swallow

$parsed = foreach ($e in $events) {
    $d = Get-EventDataMap -Event $e
    $action = switch ($e.Id) {
        4624 { 'Logon' }
        4625 { 'Failed Logon' }
        4634 { 'Logoff' }
        4647 { 'User Logoff' }
        4720 { 'Account Created' }
    }
    $logonType = if ($d.ContainsKey('LogonType')) { Get-LogonTypeName $d['LogonType'] } else { $null }
    [PSCustomObject]@{
        Time      = $e.TimeCreated
        Id        = $e.Id
        Action    = $action
        User      = $d['TargetUserName']    # subject (e.g. the NEW account on 4720)
        Actor     = $d['SubjectUserName']   # who initiated it — the real actor on 4720
        SourceIP  = $d['IpAddress']         # null on logoff/create — correct, not a bug
        LogonType = $logonType
    }
}

Write-Section "SECURITY EVENTS (LAST 24H)" ($parsed | Sort-Object Time -Descending)

Write-Host "[+] Done. Report: $out"