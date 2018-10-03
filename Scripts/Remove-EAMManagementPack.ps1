<#
.SYNOPSIS
    Exports all MPs that depend on the SquaredUp.EAM.Library mp and then remove them, along with the EAM mp itself.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    $BackupDir = '.\exported\',
    [Switch]
    $Force
)

$eamLibrary = 'SquaredUp.EAM.Library'

$managementPacks = Get-SCOMManagementPack -Name $eamLibrary -Recurse | Where-Object {$_.name -ne $eamLibrary}

if(-not (Test-Path -Path $backupDir -PathType Container)) {
    New-Item -Path $backupDir -ItemType Directory -ErrorAction Stop -Force:$Force | Out-Null
}

$managementPacks | ForEach-Object {
    if ($PSCmdlet.ShouldProcess($_, "Backup and remove MP")) {
        Export-SCOMManagementPack -Path $backupDir -ErrorAction Stop -Confirm:$false

        Remove-SCOMManagementPack -Confirm:$false
    }
}

Get-SCOMManagementPack -Name $eamLibrary | Remove-SCOMManagementPack -ErrorAction Stop
