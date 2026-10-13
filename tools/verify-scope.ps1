param([switch]$AllowAodReliabilityFix)
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$siblings = Get-Content "$project/evidence/siblings-before.json" -Raw | ConvertFrom-Json
$changed = @($siblings | Where-Object { (Get-FileHash -LiteralPath $_.path).Hash -ne $_.sha256 })
if ($changed.Count) { throw 'A sibling source or project file changed.' }
$before = Get-Content "$project/evidence/FourthView-before-amoled.txt" -Raw
$after = Get-Content "$project/source/FourthView.mc" -Raw
$aodPattern = '(?s)function drawAod\(.*?\n    \}'
$aodBefore = [regex]::Match($before.Replace("`r`n","`n"),$aodPattern).Value
$aodAfter = [regex]::Match($after.Replace("`r`n","`n"),$aodPattern).Value
$aodUnchanged=$aodBefore -and $aodBefore -ceq $aodAfter
if (!$aodBefore -or (!$aodUnchanged -and !$AllowAodReliabilityFix)) { throw 'AOD renderer differs from baseline; use the explicitly authorized reliability-fix scope.' }
$third = Join-Path (Split-Path $project -Parent) 'CNWatchFace3'
[xml]$fourthManifest = Get-Content "$project/manifest.xml"
[xml]$thirdManifest = Get-Content "$third/manifest.xml"
$fourthIds = @($fourthManifest.manifest.application.products.product | ForEach-Object { $_.id })
$thirdIds = @($thirdManifest.manifest.application.products.product | ForEach-Object { $_.id })
if (Compare-Object $fourthIds $thirdIds) { throw 'Device IDs differ from the third face.' }
$fontCount = 0
foreach ($size in 240,260,280,360,390,416,454,466) {
    foreach ($name in 'Aod.fnt','Aod.png','Small.fnt','Small.png') {
        $fourthFont = "$project/resources-$size/fonts/$name"
        $thirdFont = "$third/resources-$size/fonts/$name"
        if ((Get-FileHash -LiteralPath $fourthFont).Hash -ne (Get-FileHash -LiteralPath $thirdFont).Hash) {
            throw "AOD font differs: $size/$name"
        }
        $fontCount += 1
    }
}
[pscustomobject]@{
    siblingFilesChecked=$siblings.Count; siblingChanged=0
    aodFunctionUnchanged=$aodUnchanged; aodReliabilityFixAuthorized=[bool]$AllowAodReliabilityFix; aodFontFilesMatchThird=$fontCount
    deviceIdsMatchThird=$true; deviceCount=$fourthIds.Count
} | ConvertTo-Json | Set-Content "$project/evidence/scope-check.json" -Encoding utf8
Get-Content "$project/evidence/scope-check.json"
