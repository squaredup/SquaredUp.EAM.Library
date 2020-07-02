$scomApi = New-Object -comObject MOM.ScriptAPI

$results = @( 
	(New-Object –TypeName PSObject –Prop (@{'Name'='PU-WEB-01.partsunlimited.com'; 'CPU'=(Get-Random -Minimum 30 -Maximum 75); 'Memory'=(Get-Random -Minimum 45 -Maximum 60); 'Connections'=(Get-Random -Minimum 20 -Maximum 60); 'Status'='Healthy'})),
	(New-Object –TypeName PSObject –Prop (@{'Name'='PU-WEB-02.partsunlimited.com'; 'CPU'=(Get-Random -Minimum 30 -Maximum 75); 'Memory'=(Get-Random -Minimum 60 -Maximum 90); 'Connections'=(Get-Random -Minimum 70 -Maximum 93); 'Status'='Unhealthy'})),
	(New-Object –TypeName PSObject –Prop (@{'Name'='AW-WEB-01.AdventureWorks.com'; 'CPU'=(Get-Random -Minimum 30 -Maximum 75); 'Memory'=(Get-Random -Minimum 40 -Maximum 60); 'Connections'=(Get-Random -Minimum 20 -Maximum 84); 'Status'='Healthy'})),
	(New-Object –TypeName PSObject –Prop (@{'Name'='AW-SQL-01.AdventureWorks.com'; 'CPU'=(Get-Random -Minimum 95 -Maximum 100); 'Memory'=(Get-Random -Minimum 40 -Maximum 60); 'Connections'=(Get-Random -Minimum 20 -Maximum 87); 'Status'='Unhealthy'})),
	(New-Object –TypeName PSObject –Prop (@{'Name'='Sales-WEB-01.contoso.com'; 'CPU'=(Get-Random -Minimum 30 -Maximum 75); 'Memory'=(Get-Random -Minimum 40 -Maximum 60); 'Connections'=(Get-Random -Minimum 20 -Maximum 84); 'Status'='Healthy'})),
	(New-Object –TypeName PSObject –Prop (@{'Name'='Sales-WEB-02.contoso.com'; 'CPU'=(Get-Random -Minimum 30 -Maximum 100); 'Memory'=(Get-Random -Minimum 40 -Maximum 60); 'Connections'=(Get-Random -Minimum 20 -Maximum 87); 'Status'='Unhealthy'})),
	(New-Object –TypeName PSObject –Prop (@{'Name'='Sales-WEB-03.contoso.com'; 'CPU'=(Get-Random -Minimum 10 -Maximum 40); 'Memory'=(Get-Random -Minimum 20 -Maximum 40); 'Connections'=(Get-Random -Minimum 0 -Maximum 10); 'Status'='Healthy'})),
	(New-Object –TypeName PSObject –Prop (@{'Name'='Sales-APP-01.contoso.com'; 'CPU'=(Get-Random -Minimum 30 -Maximum 80); 'Memory'=(Get-Random -Minimum 40 -Maximum 60); 'Connections'=(Get-Random -Minimum 20 -Maximum 87); 'Status'='Healthy'})),
	(New-Object –TypeName PSObject –Prop (@{'Name'='Sales-APP-02.contoso.com'; 'CPU'=(Get-Random -Minimum 30 -Maximum 75); 'Memory'=(Get-Random -Minimum 40 -Maximum 60); 'Connections'=(Get-Random -Minimum 20 -Maximum 84); 'Status'='Unhealthy'})),
	(New-Object –TypeName PSObject –Prop (@{'Name'='Sales-SQL-01.contoso.com'; 'CPU'=(Get-Random -Minimum 55 -Maximum 75); 'Memory'=(Get-Random -Minimum 40 -Maximum 60); 'Connections'=(Get-Random -Minimum 20 -Maximum 50); 'Status'='Health'})),
	(New-Object –TypeName PSObject –Prop (@{'Name'='Sales-SQL-02.contoso.com'; 'CPU'=(Get-Random -Minimum 95 -Maximum 100); 'Memory'=(Get-Random -Minimum 90 -Maximum 100); 'Connections'=(Get-Random -Minimum 50 -Maximum 99); 'Status'='Unhealthy'})),
	(New-Object –TypeName PSObject –Prop (@{'Name'='Azure Active Directory (SmartHotel 360)'; 'Status'='Health'})),
	(New-Object –TypeName PSObject –Prop (@{'Name'='SmartHotel Azure Cloud Service'; 'Status'='Unhealthy'})),
	(New-Object –TypeName PSObject –Prop (@{'Name'='Azure Active Directory (Contoso)'; 'Status'='Health'})),
	(New-Object –TypeName PSObject –Prop (@{'Name'='Sales App SAN Luns (Contoso)'; 'Status'='Unhealthy'}))
)

# Create bags for each object
Foreach ($result in $results) {

	$bag = $scomApi.CreatePropertyBag()

	Foreach ($prop in $result.PSObject.Properties) {
		$bag.AddValue( $prop.Name, $prop.Value )
	}
	# Return property bag
	$bag

}
