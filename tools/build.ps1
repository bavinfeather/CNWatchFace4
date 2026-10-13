param(
    [string[]]$Device = @('fenix7s','fenix7','enduro3','fr265s','epix2pro42mm','venu2','fr965','fenix9pro51mm'),
    [string]$Key
)
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$sdk = (Get-Content "$env:APPDATA/Garmin/ConnectIQ/current-sdk.cfg").Trim()
if (!$Key) { $Key = Join-Path $project 'bin/development.der' }
if (!(Test-Path -LiteralPath $Key)) { throw 'Provide a development signing key with -Key. See README.md.' }
[xml]$manifest = Get-Content (Join-Path $project 'manifest.xml')
$products = @($manifest.manifest.application.products.product | ForEach-Object { $_.id })
if ($Device.Count -eq 1 -and $Device[0] -eq 'all') { $Device = $products }
foreach ($id in $Device) { if ($id -notin $products) { throw "Unsupported device: $id" } }
$results = @()
foreach ($id in $Device) {
    $log = Join-Path $project "evidence/build-$id.log"
    $program = Join-Path $project "bin/$id.prg"
    & "$sdk/bin/monkeyc.bat" -f "$project/monkey.jungle" -d $id -o $program -y $Key *> $log
    $exitCode = $LASTEXITCODE
    $results += [pscustomobject]@{
        device=$id; exitCode=$exitCode
        sha256=if ($exitCode -eq 0) { (Get-FileHash -LiteralPath $program -Algorithm SHA256).Hash } else { $null }
    }
    $results | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $project 'evidence/build-results.json') -Encoding utf8
    Write-Output "$id : exit $exitCode"
}
if (@($results | Where-Object { $_.exitCode -ne 0 }).Count) { throw 'Build failures; inspect evidence/build-*.log.' }
