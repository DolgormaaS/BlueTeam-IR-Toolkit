#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Checks for tampered folders that are being excluded from the sight of Defender. 
    For example: "Add-MpPreference -ExclusionPath 'C:\Users\Public'" would exclude the path from the 
    Defender and the defender would miss it, saying everything is fine. This is where this scipt comes in.
#>

