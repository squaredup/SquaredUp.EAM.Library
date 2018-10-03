$testResult = Invoke-WebRequest -Uri $config.url -UseBasicParsing -UseDefaultCredentials

# test response
$statusCodePassed = $testResult.StatusCode -eq 200
$matchPassed = $config.match.length -eq 0 -or $testResult.RawContent -match $config.match
$notMatchPassed = $config.notmatch.length -eq 0 -or $testResult.RawContent -notmatch $config.notmatch
$passed = $statusCodePassed -and $matchPassed -and $notMatchPassed

# return result
$result = New-Object -TypeName PSobject -Property (@{'Success'=$passed;'Description'=''})

if (-not $statusCodePassed) {
	$result.description = "HTTP status code $($testResult.StatusCode) returned."
}
else {
	if (-not $matchPassed) {
		$result.description += "Content did not match expression $($config.match)"
	}

	if (-not $notMatchPassed) {
		$result.description += "Content matched expression $($config.notmatch)"
	}

	if (-not ($matchPassed -and $notMatchPassed)) {
		$result | Add-Member -MemberType NoteProperty -Name "ResponseContent" -Value $testResult.RawContent
	}
}

return $result
