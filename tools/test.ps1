$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$sdk = (Get-Content "$env:APPDATA/Garmin/ConnectIQ/current-sdk.cfg").Trim()
$log = "$project/evidence/core-tests.log"
& "$sdk/bin/monkeyc.bat" -f "$project/tests/tests.jungle" -d fenix9pro51mm -o "$project/bin/core-tests.prg" -y "$project/bin/development.der" -t *> "$project/evidence/test-build.log"
if ($LASTEXITCODE -ne 0) { throw 'Test compilation failed.' }
& "$sdk/bin/monkeydo.bat" "$project/bin/core-tests.prg" fenix9pro51mm /t *> $log
$result = Get-Content -LiteralPath $log -Raw
if ($LASTEXITCODE -ne 0 -or $result -notmatch 'PASSED \(passed=37, failed=0, errors=0\)') {
    throw 'Simulator tests failed; inspect evidence/core-tests.log.'
}
Write-Output '37/37 simulator tests passed.'
