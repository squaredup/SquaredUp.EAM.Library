if ($PSVersionTable.PSVersion.Major -lt 4) {
	return New-Object -TypeName PSobject -Property (@{'Success'=$false;'Description'='TCP monitoring is only available from nodes running PowerShell v4 or later.'})
} else {
	$testResult = Test-NetConnection -ComputerName $config.address -Port $config.port
	return $testResult.TcpTestSucceeded
}
