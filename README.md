# BlueTeam-IR-Toolkit

A PowerShell toolkit for rapid Windows incident-response triage and Defender hardening. Built to automate the first-response forensics workflow during a live security incident; collect host state fast, in a structured, analyst-ready form, and restore tampered defenses.

> **Status:** In active development. Currently two modules under `tools_powershell/`; more triage and hunting modules planned (see [Roadmap](#roadmap)).

---

## Contents

| Script | Purpose |
|--------|---------|
| `current_status.ps1` | **Triage collector:** snapshots host state (processes, services, network, accounts, persistence, security events). |
| `defender_checker.ps1` | **Hardening + tamper remediation:** re-enables Defender and the firewall, restores tampered policy registry keys, and logs every change to a transcript. |

---

## `current_status.ps1:` Triage Collector

Captures a point-in-time snapshot of the system and writes it to a single, sectioned report in a timestamped file (`status-<yyyyMMdd-HHmmss>/`). 

**Collected artifacts:**

- **Processes:** name, PID, CPU, and full image path (flags binaries running from unusual locations)
- **Services:** all running services with start type
- **Network:** established TCP connections, resolved to the owning process
- **Local accounts:** enabled state, last logon, password-set time, SID
- **Scheduled tasks:** non-disabled tasks and their actions (a common persistence mechanism)
- **Run-key persistence:** `Run` / `RunOnce` under both HKLM and HKCU
- **Security events (last 24h):** logon activity parsed field-by-field from the event XML

**Security event coverage:**

| Event ID | Meaning | Key fields extracted |
|:--------:|---------|----------------------|
| 4624 | Successful logon | User, Source IP, Logon Type |
| 4625 | Failed logon | User, Source IP, Logon Type |
| 4634 | Logoff | User |
| 4647 | User-initiated logoff | User |
| 4720 | Account created | New account + initiating actor |

Events are parsed out of the `EventData` XML **by field name** rather than by position, so the same collector handles logon and account-creation events without breaking on their differing schemas.

---

## `defender_checker.ps1`: Hardening & Tamper Remediation

Restores a known-good defensive baseline, useful after a compromise or in an adversarial defense scenario where a red team has degraded your protections.

**Actions:**

- Reports initial Defender status
- Enables all three firewall profiles (Domain / Private / Public)
- Installs the Defender feature on Windows Server SKUs where absent
- Starts Defender services and re-enables real-time / on-access protection
- Remediates policy registry keys commonly abused to disable Defender
- Reports final status for before/after comparison

Because the script **mutates security state**, every run is captured to a transcript (`defender-remediation-<timestamp>.log`), so there's a full audit trail of what changed.

---

## Requirements

- Windows (client or Server) with Windows PowerShell 5.1+
- **Administrator** privileges; both scripts enforce this via `#Requires -RunAsAdministrator`
- Defender/firewall cmdlets (present by default on supported Windows)

---

## Usage

Open PowerShell **as Administrator**, then run either script:

```powershell
.\tools_powershell\current_status.ps1
.\tools_powershell\defender_checker.ps1
```

If script execution is blocked, allow it for the current session only (this scope resets when you close the window, so it doesn't loosen your machine's policy permanently):

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

Confirm with `Y` when prompted.

---

## Output

- `current_status.ps1` → a `triage-<timestamp>/` folder of CSVs, one per artifact class
- `defender_checker.ps1` → console before/after status plus a `defender-remediation-<timestamp>.log` transcript

---

## Planned Features

- [ ] Persistence Sweep
- [ ] Defender Tamper Watchdog

---

## Author

Created by Dolgormaa Sansarsasikhan as part of my cybersecurity scripting practice and hands-on learning journey.
