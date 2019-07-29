param($sourceId, $managedEntityId, $DiscoveriesJson)

#=================================================================================
# Squared Up Enterprise Application Monitoring
# PowerShell discovery for additional objects and relationships for Enterprise
# Applications
#
# Copyright (c) Squared Up Ltd
#=================================================================================

# Load required SCOM PowerShell functionality
#=================================================================================

# Import using absolute path (non-default path SCOM installs don't update $env:PSModulePath
# to allow an import by name to work reliably).
$setupKey = Get-Item -Path "HKLM:\Software\Microsoft\Microsoft Operations Manager\3.0\Setup" -ErrorAction SilentlyContinue
$installDirectory = $setupKey.GetValue("InstallDirectory") | Split-Path -ErrorAction SilentlyContinue
$psmPath = "$installdirectory\Powershell\OperationsManager\OperationsManager.psm1"
Import-Module $psmPath -ErrorAction SilentlyContinue

# Belt and braces - do it the old-fashioned way also (liberal use of -ErrorAction SilentlyContinue
# means that this should not cause any problems.)
Add-PSSnapin Microsoft.EnterpriseManagement.OperationsManager.Client -ErrorAction SilentlyContinue

# Constants
#=================================================================================
$ScriptName = "SquaredUp.EAM.Discovery.ps1"
$EventID = "8011"
$ErrorEventID = "8012"
#=================================================================================

# Start
#=================================================================================
$start = [DateTime]::UtcNow
$whoami = whoami
$SCRIPT:momapi = New-Object -ComObject 'MOM.ScriptAPI'
$SCRIPT:momapi.LogScriptEvent($ScriptName,$EventID,0,"`n Script is starting. `n Running as ($whoami).")
$discoveryData = $SCRIPT:momapi.CreateDiscoveryData(0, $sourceId, $managedEntityId)
$discoveries = $DiscoveriesJson | ConvertFrom-Json
$objInstancesByInstanceId = @{}

# Check SDK connectivity by logging the names of management servers
#=================================================================================
$msClsId = "9189a49e-b2de-cab0-2e4f-4925b68e335d"
$msInsts = Get-SCOMClassInstance -Class (Get-SCOMClass -Id $msClsId)
$SCRIPT:momapi.LogScriptEvent($ScriptName,$EventID,0,"`n Management Server pool: [`"$([string]::Join('", "', @($msInsts | %{ $_.DisplayName })))`"]")

#=================================================================================

# Functions
#=================================================================================

function Write-ErrorLog {
    param (
        $message
    )

	$SCRIPT:momapi.LogScriptEvent($ScriptName,$ErrorEventID,1,$message)
	'Write-ErrorLog called: $ScriptName={0}, $ErrorEventID]{1}, $message="{2}"' -f $ScriptName,$ErrorEventID,$message
}

#
# Get one level of SCOM hosting information for a SCOM object
#
function Get-ScomHostingParentInfo {
    param (
        $obj
    )

    $result = $null

	$relInsts = @()
	try {
		$relInsts = @(Get-SCRelationshipInstance -TargetInstance $obj | Where-Object { -not $_.IsDeleted } )
	} catch {
		Write-ErrorLog "Get-SCRelationshipInstance -TargetInstance '$($obj.Id)' threw '$_'"
	}

    foreach ($relInst in $relInsts) {
		# Check if it's a hosting relationship
		$isHosting = $false
		try {
			$relCls = Get-SCRelationship -Id $relInst.RelationshipId
		} catch {
			Write-ErrorLog "1st Get-SCRelationship -Id '$($relInst.RelationshipId)' threw '$_'"
			return $null
		}
		do {
			if ($relCls.Name -eq "System.Hosting") { $isHosting = $true; }
			try {
				$relCls = Get-SCRelationship -Id $relCls.Base.Id
			} catch {
				Write-ErrorLog "2nd Get-SCRelationship -Id '$($relCls.Base.Id)' threw '$_'"
				return $null
			}
				
		} while ($relCls.Base -and -not $isHosting)

		# If so, we can return information about our host to the caller
        if ($isHosting) {
            $parent = Get-ScomClassInstance -Id $relInst.SourceObject.Id
            $result = @{ ParentObj = $parent; RelInst = $relInst }
            break
        }
    }

    return $result
}

#
# Create a discovery class instance from an already extant SCOM object given its ID
#
function CreateClassInstanceFromId {
	param(
        $discoveryObject,
        $discoveryData
    )

	# Get the object and create a class instance discovery object using its type
	$obj = $null
	try {
		$obj = Get-SCOMClassInstance -Id $discoveryObject.ObjId
	} catch {
		Write-ErrorLog "Get-SCOMClassInstance -Id '$($discoveryObject.ObjId)' threw '$_'"
	}
	if ($obj) {
		if ($obj.LeastDerivedNonAbstractMonitoringClassId -or $obj.LeastDerivedNonAbstractMonitoringClassId -eq [Guid]::Empty) {
			$class = $obj.LeastDerivedNonAbstractMonitoringClassId
		} else {
			Write-ErrorLog "CreateClassInstanceFromId $($discoveryObject.ObjId) - Got object with ID $($discoveryObject.ObjId) but no sensible value in LeastDerivedNonAbstractMonitoringClassId"
			return $null
		}
	} else {
		Write-ErrorLog "CreateClassInstanceFromId $($discoveryObject.ObjId) - Failed to get object with ID $($discoveryObject.ObjId)"
		return $null
	}

	# Create the class instance in the discovery data
	$objDiscoveryInstance = $discoveryData.CreateClassInstance($class)

	# Loop through the object's hosting stack adding key properties at each level
    $nextInst = $obj
    while($nextInst) {
		$inst = $nextInst
		$instCl = $null
		try {
			$instCl = Get-ScomClass -Id $inst.LeastDerivedNonAbstractManagementPackClassId
		} catch {
			Write-ErrorLog "Get-ScomClass -Id '$($inst.LeastDerivedNonAbstractManagementPackClassId)' threw '$_'"
		}
        while ($instCl) {
            $keyProps = $instCl.GetKeyProperties()
            foreach ($keyProp in $keyProps) {
                $propName = "[$($instCl.Name)].$($keyProp.Name)"
                $propRawValue = $inst."$propName".Value
                if ($keyProp.SystemType.FullName -eq "System.Guid") {
                    # SCOM requires specific string syntax for GUIDs
                    $propValue = $propRawValue.ToString("b")
                } elseif ($keyProp.SystemType.FullName -eq "System.Enum") {
                    # For enums, we use the ID GUID in SCOM's preferred notation
                    $propValue = $propRawValue.Id.ToString("b")
                } else {
                    $propValue = [System.Management.Automation.LanguagePrimitives]::ConvertTo($propRawValue, $keyProp.SystemType)
                }
                try {
                    $objDiscoveryInstance.AddProperty($keyProp.Id, $propValue)
                } catch {
                    Write-ErrorLog "AddProperty($($keyProp.Id), $propValue) threw '$_'"
                }
            }
            $instCl = $instCl.GetBaseType()
        }
        $hostInfo = Get-ScomHostingParentInfo $inst
        $nextInst = $hostInfo.ParentObj
    }

	# Return the result
	return $objDiscoveryInstance
}

#
# Create a discovery class instance from the type ID and property information supplied
#
function CreateClassInstanceFromTypeId {
	param(
        $discoveryObject,
        $discoveryData
    )

	$objDiscoveryInstance = $discoveryData.CreateClassInstance($discoveryObject.TypeId)
	foreach ($discoveryProperty in $discoveryObject.Properties) {
		$objDiscoveryInstance.AddProperty($discoveryProperty.PropertyId, $discoveryProperty.Value)
	}
	return $objDiscoveryInstance
}

#=================================================================================


# Main
#=================================================================================

try {
	foreach ($discoveryObject in $discoveries.ExistingObjects) {
		# Create a discovery data instance object from the ID of an existing object
		$objDiscoveryInstance = CreateClassInstanceFromId $discoveryObject $discoveryData

		# Record instance if required for relationship(s)
		if ($objDiscoveryInstance -and $discoveryObject.InstanceId) {
			$objInstancesByInstanceId[$discoveryObject.InstanceId] = $objDiscoveryInstance
		}
	}

	foreach ($discoveryObject in $discoveries.NewObjects) {
		# Create a discovery data instance object from the TypeID and properties for a new object
		$objDiscoveryInstance = CreateClassInstanceFromTypeId $discoveryObject $discoveryData

		# Add it to the discovery data
		$discoveryData.AddInstance($objDiscoveryInstance)

		# Record instance if required for relationship(s)
		if ($objDiscoveryInstance -and $discoveryObject.InstanceId) {
			$objInstancesByInstanceId[$discoveryObject.InstanceId] = $objDiscoveryInstance
		}
	}

	foreach ($discoveryRelationship in $discoveries.Relationships) {
		# Check if both objects exist
		if ($objInstancesByInstanceId.ContainsKey($discoveryRelationship.SourceInstanceId) -and
			$objInstancesByInstanceId.ContainsKey($discoveryRelationship.TargetInstanceId)) {

			# Create a discovered relationship instance
			$relInstance = $discoveryData.CreateRelationshipInstance($discoveryRelationship.TypeId)
			$relInstance.Source = $objInstancesByInstanceId[$discoveryRelationship.SourceInstanceId]
			$relInstance.Target = $objInstancesByInstanceId[$discoveryRelationship.TargetInstanceId]

			# Add any properties
			foreach ($discoveryProperty in $discoveryRelationship.Properties) {
				$relInstance.AddProperty($discoveryProperty.PropertyId, $discoveryProperty.Value)
			}

			$discoveryData.AddInstance($relInstance)
		} else {
			if (-not $objInstancesByInstanceId.ContainsKey($discoveryRelationship.SourceInstanceId)) {
				$SCRIPT:momapi.LogScriptEvent($ScriptName,$ErrorEventID,1,"Relationship missing source '$($discoveryRelationship.SourceInstanceId)'")
			}
			if (-not $objInstancesByInstanceId.ContainsKey($discoveryRelationship.TargetInstanceId)) {
				$SCRIPT:momapi.LogScriptEvent($ScriptName,$ErrorEventID,1,"Relationship missing target '$($discoveryRelationship.TargetInstanceId)'")
			}
		}
	}
} catch {
	Write-ErrorLog "Unhandled exception '$_'"
}

# End
#=================================================================================
# Log an event for script ending and total execution time.
$end = [DateTime]::UtcNow
$SCRIPT:momapi.LogScriptEvent($ScriptName,$EventID,0,"`n Script Completed after $($end - $start)")

# Return discovery data
$discoveryData
#=================================================================================

