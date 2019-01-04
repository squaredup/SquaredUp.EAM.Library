param(
	$ManagedEntityId, 
	$State, 
	$Description, 
	$DisplayName, 
	$ManagementServer, 
	$SetByUser
)

$scriptName = "SquaredUp.EAM.Library.WriteAction.ManualAvailability.StartEventTask.ps1"

$momapi = New-Object -comObject MOM.ScriptAPI
$momapi.LogScriptEvent($scriptName,8998,0,"`n Script is starting. `n Attempting to trigger health state change to '$State' with description '$Description' for '$DisplayName' on $ManagementServer")

Import-Module OperationsManager

$ms = Get-SCOMClassInstance -Id $ManagementServer

$task = Get-SCOMTask -Id "$MPElement[Name='SquaredUp.EAM.Library.AgentTask.ManualAvailability.MS.Unhealthy']$"

$overrides = @{
	"State"=$State
	"Description"=$Description
	"ManagedEntityId"=$ManagedEntityId
	"TargetDisplayName"=$DisplayName
	"SetByUser"=$SetByUser
}

$momapi.LogScriptEvent($scriptName,8998,0,"Triggering task to set health for '$DisplayName'")
$taskOut = Start-SCOMTask -task $task -instance $ms -Override $overrides

if ($taskOut.BatchId -ne $null){

	$results = $null
	$momapi.LogScriptEvent($scriptName,8998,0,"Polling for results...")

	while ($results -eq $null){
		
		$currentState = Get-SCOMTaskResult -BatchID $taskOut.BatchId

		if ($currentState.TimeFinished -ne $null){
			$results = $currentState
		}
		else{
			Start-Sleep -Milliseconds 300
		}
	}
}

if ($results.status -eq 'Succeeded'){
	Write-Host $results.Status
}
else {
	Throw "Task failed with state '$($results.Status)', error: $($results.ErrorCode) $($results.ErrorMessage)"
}


$momapi.LogScriptEvent($scriptName,8998,0,"`n Script is Complete.")
