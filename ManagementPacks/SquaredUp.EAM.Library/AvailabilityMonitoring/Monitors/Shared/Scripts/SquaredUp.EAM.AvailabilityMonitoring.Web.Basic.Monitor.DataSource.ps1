[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
param(
	$ConfigurationJson, 
	$Script, 
	$ResponseTimeThreshold,
	$Username,
	$Password
)
                  
#=================================================================================
# Squared Up Enterprise Application Monitoring
# Custom PowerShell availability monitor
#  
# This script wraps a simple PowerShell script and interprets the results
#
# Copyright (c) Squared Up Ltd
#=================================================================================


# Constants
#=================================================================================
$ScriptName = "SquaredUp.EAM.AvailabilityMonitoring.Web.Basic.Monitor.DataSource.ps1"
$EventID = "8001"
#=================================================================================


# Start
#=================================================================================
$whoami = whoami
$momapi = New-Object -comObject MOM.ScriptAPI
$bag = $momapi.CreatePropertyBag()
$momapi.LogScriptEvent($ScriptName,$EventID,0,"`n Script is starting. `n Running as ($whoami). `n Config: $ConfigurationJson")
#=================================================================================

# Functions
#=================================================================================

function ExecuteScript {
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "credentials")]
	param($script, $config, $credentials)
	return Invoke-Expression $script
}

#=================================================================================


# Main
#=================================================================================

# Convert the JSON to an object to be used by the script
#
$configuration = $null
if ($ConfigurationJson -ne $null) {
	$configuration = ConvertFrom-Json $ConfigurationJson
}

# Construct credentials object which can be used by the script
#
$SecureString = $null
$PSCreds = $null
if (-not [string]::IsNullOrEmpty($Password)) {
	$SecureString  = ConvertTo-SecureString -AsPlainText $Password -Force
	$PSCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username,$SecureString
	$momapi.LogScriptEvent($ScriptName,$EventID,0,"`n Credentials provided from EAM Parameter Run As profile: ($username).")
}

$credentials = [PSCustomObject]@{
	"Username" =$Username
	"Password" =$Password
	"BasicAuth" = [convert]::ToBase64String([system.text.encoding]::ASCII.Getbytes("$($username):$password"))
	"SecureString" = $SecureString
	"PSCredential" = $PSCreds
}

# Measure total time taken
#
$timeTaken = Measure-Command -Expression { 

	Try {

		# Execute the custom script
		$result = ExecuteScript $Script $configuration $credentials

	}
	Catch {
		# Treat exceptions as failures
		$result = New-Object –TypeName PSObject –Prop (@{'Success'=$false;'Description'=$_.Exception.Message})
	}

}

# $result values:
# [bool] (success)
# OR
# $result.Success = [bool]
# $result.Level = [string] "warning" | "error"
# $result.ResponseTime = [double]

# If no result, assume ok
#
if( $null -eq $result) {
	$result = New-Object -TypeName PSObject -Property (@{'Success'=$true; 'Description'=''})
}

# Is result a simple boolean?
#
if( $result.GetType().FullName -eq "System.Boolean" ) {
	$boolResult = $result
	$result = New-Object -TypeName PSObject -Property (@{'Success'=$boolResult; 'Description'=''})
}

# If no Success property, assume ok
#
if ( -not( [bool]($result.PSobject.Properties.name -match "Success") ) ) {
	$result | Add-Member –MemberType NoteProperty –Name Success –Value $true
}

# If no Description property, add one so alert paramter replacement works
#
if ( -not ([bool]($result.PSobject.Properties.name -match "Description"))) {
	$result | Add-Member -MemberType NoteProperty -Name 'Description' -Value ''
}

# If no ResponseTime, set to measured time taken
#
if ( -not( [bool]($result.PSobject.Properties.name -match "ResponseTime") ) -or (($result.ResponseTime -as [double]) -eq $null ) ) {
	$result | Add-Member –MemberType NoteProperty –Name ResponseTime –Value $timeTaken.TotalMilliseconds
}

# If ResponseTimeThreshold and success measure time
#
if ( $result.Success -and ($ResponseTimeThreshold -as [double]) -gt 0.0) {
	$underThreshold = $result.ResponseTime -lt [double]$ResponseTimeThreshold
	$result.Success = $underThreshold

	if (-not $underThreshold -and [string]::IsNullOrEmpty($result.Description)) {
		$result.Description = "Test did not complete in under $ResponseTimeThreshold ms (took $($result.ResponseTime))"
	}
}

# If no Level property, assume error
#
if ( -not( [bool]($result.PSobject.Properties.name -match "Level") ) -and -not $result.Success ) {
	$result | Add-Member –MemberType NoteProperty –Name Level –Value "error"
}

# Save result into property bag
#
$result.PSObject.Properties | ForEach-Object {
	$bag.AddValue( $_.Name, $_.Value )
}

#=================================================================================


# End
#=================================================================================
#Log an event for script ending and total execution time.
$momapi.LogScriptEvent($ScriptName,$EventID,0,"`n Script Completed. `n Script result: `n $(ConvertTo-Json $result)")
# Return property bag
$bag
#=================================================================================
