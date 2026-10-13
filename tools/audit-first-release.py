"""Audit the local first-release artifact and its retained verification records."""
from collections import Counter
from pathlib import Path
import hashlib
import json
import re
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
release = root / 'releases/1.0.0'
evidence = release / 'evidence'
ns = {'iq': 'http://www.garmin.com/xml/connectiq'}

def read(path):
    return path.read_text(encoding='utf-8-sig', errors='replace')

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()

def save(path, obj):
    path.write_text(json.dumps(obj, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

def application(path):
    return ET.parse(path).getroot().find('iq:application', ns)

formal = json.loads(read(evidence / 'formal-inputs.json'))
changed_formal = [item['path'] for item in formal if digest(Path(item['path'])) != item['sha256']]
baseline = json.loads(read(root / 'evidence/before-first-release-inputs.json'))
siblings = [item for item in baseline if Path(item['path']).parent != root and root not in Path(item['path']).parents]
changed_siblings = [item['path'] for item in siblings if digest(Path(item['path'])) != item['sha256']]
assert len(formal) == 164 and not changed_formal, changed_formal
assert len(siblings) == 20 and not changed_siblings, changed_siblings
changed_release = [str(Path(item['path']).relative_to(root)) for item in baseline
                   if root in Path(item['path']).parents and digest(Path(item['path'])) != item['sha256']]
scope = {'formalInputs': len(formal), 'sourceChangedAfterExport': len(changed_formal),
         'siblingFiles': len(siblings), 'siblingChanged': len(changed_siblings),
         'releaseChangesFromBaseline': changed_release}
save(evidence / 'source-scope.json', scope)

app = application(root / 'manifest.xml')
third = application(root.parent / 'CNWatchFace3/manifest.xml')
products = [p.attrib['id'] for p in app.findall('iq:products/iq:product', ns)]
assert set(products) == {p.attrib['id'] for p in third.findall('iq:products/iq:product', ns)}
assert len(products) == 63
assert app.attrib['version'] == read(root / 'VERSION').strip() == '1.0.0'
for filename in ['manifest.xml', 'monkey.jungle', 'VERSION']:
    assert digest(root / filename) == digest(release / filename)
names = [ET.parse(root / path).find("string[@id='AppName']").text
         for path in ['resources/strings/strings.xml', 'resources-zhs/strings/strings.xml']]
assert names == ['Geometric Canyon cyn4', '几何峡谷cyn4'], names
key_hash = digest(root / 'keys/Canyon-release.der')
assert key_hash == '29BCE1A71901552804B4B2DC6C34C5365CA4ECDE1FC62F9182FCCFE53DBCEFDF'
assert not list(release.rglob('*.der')) and not list(release.rglob('*.pem'))

iq = release / 'GeometricCanyon-cyn4-1.0.0.iq'
iq_hash = digest(iq)
artifact_freeze = json.loads(read(evidence / 'artifact-freeze.json'))
assert iq_hash == artifact_freeze['sha256'] and iq.stat().st_size == artifact_freeze['bytes']
build = read(release / 'build.log')
assert '80 OUT OF 80 DEVICES BUILT' in build and 'BUILD SUCCESSFUL' in build
assert not re.search(r'^ERROR:', build, re.M)
warnings = [line for line in build.splitlines() if line.startswith('WARNING:')]
warning_types = Counter()
for line in warnings:
    if 'Cannot determine if container' in line:
        warning_types['dynamic_container_type_inference'] += 1
    elif 'launcher icon' in line.lower() or 'launchericon' in line.lower():
        warning_types['launcher_icon_scaling'] += 1
    else:
        warning_types['other'] += 1
test_log = read(evidence / 'core-tests.log')
assert 'PASSED (passed=37, failed=0, errors=0)' in test_log
assert 'sunClearsStackedTime' in test_log
before = read(evidence / 'sun-before-tests.log')
assert re.search(r'sunClearsStackedTime\s+ERROR', before) and 'ASSERTION FAILED' in before
settings = json.loads(read(evidence / 'settings-schema-audit.json'))
assert settings['status'] == 'pass' and settings['settingCount'] == 25
assert settings['bilingualReferencesChecked'] == 179 and len(settings['compiledDevices']) == 6
representative = json.loads(read(evidence / 'build-results.json'))
assert len(representative) == 6 and all(x['exitCode'] == 0 for x in representative)

runtime = []
for device in ['fenix9pro51mm', 'venu2', 'fr265s', 'fr255']:
    log = read(evidence / f'lifecycle-{device}-runtime.log')
    result = re.search(r'RELIABILITY PASSED frames=(\d+) sleepWake=(\d+) peak=(\d+) minFree=(\d+) total=(\d+)', log)
    assert result, device
    frames, cycles, peak, free, total = map(int, result.groups())
    blocks = [int(n) for n in re.findall(r'RELIABILITY_BLOCK frame=\d+ min=(\d+)', log)]
    assert len(blocks) == 30 and len(set(blocks)) == 1 and free >= 4096, device
    assert not re.search(r'Unhandled|RELIABILITY FAILED|app crash|Out Of Memory|Watchdog', log, re.I), device
    runtime.append({'device': device, 'frames': frames, 'injectedSleepWakeCycles': cycles,
                    'peakBytes': peak, 'minimumFreeBytes': free, 'totalBytes': total,
                    'blockMinimumBytes': blocks[0], 'stableAcross30Blocks': True,
                    'sunFixIncluded': device in ['fenix9pro51mm', 'venu2'],
                    'typographyFixIncluded': device in ['fenix9pro51mm', 'venu2'],
                    'scope': 'full current renderer' if device in ['fenix9pro51mm', 'venu2']
                             else 'pre-sun/typography-fix menu/data/cache and unchanged AOD or MIP rendering components'})

power_log = read(evidence / 'power-fenix9pro51mm-runtime.log')
power_match = re.search(r'POWER_PAIRED PASSED pairs=100 warmMs=(\d+) coldMs=(\d+) weatherPolls=(\d+)', power_log)
assert power_match
warm, cold, polls = map(int, power_match.groups())
assert polls == 1 and warm > 0 and cold > 0
power = {'device': 'fenix9pro51mm', 'pairs': 100, 'warmTotalMs': warm, 'coldTotalMs': cold,
         'weatherPolls': polls, 'scope': 'paired complete-frame CPU timing; not physical battery telemetry'}

aod = []
for device in ['fenix9pro51mm', 'venu2']:
    log = read(evidence / f'aod-{device}-native-ui.txt')
    peak = re.search(r'24-Hour simulation finished, no screen burn-in detected\. Peak Luminance Usage: ([0-9.]+)%', log)
    assert peak and 'Screen Protection: ON' in log and 'Burn-in State: NO' in log
    aod.append({'device': device, 'native24HourSimulation': 'pass', 'screenProtection': 'ON',
                'burnInState': 'NO', 'peakLuminanceUsagePercent': float(peak.group(1)),
                'scope': 'current sunless SharedAod component; simulator result'})
visual = read(evidence / 'sun-native-visual.txt')
assert 'Observed noon sun clear of stacked time' in visual
audit = {'date': '2026-10-04', 'version': '1.0.0', 'names': names,
         'appId': app.attrib['id'], 'minimumApi': app.attrib['minApiLevel'],
         'manifestProductCount': len(products), 'sameProductSetAsThird': True, 'exportTargets': 80,
         'artifact': {'file': iq.name, 'bytes': iq.stat().st_size, 'sha256': iq_hash},
         'signingKeySha256': key_hash, 'sourceScope': scope,
         'compiler': {'errors': 0, 'warningCount': len(warnings), 'warningTypes': dict(warning_types)},
         'unitTestsPassed': 37, 'unitTestFailures': 0, 'representativeBuildsPassed': 6,
         'settingCount': 25, 'bilingualReferencesChecked': 179, 'runtime': runtime,
         'power': power, 'aod': aod, 'nativeNoonVisualViewed': True, 'screenshotsExported': 0,
         'licenseValidationConnected': False, 'trialEnabled': False, 'paymentNoticeEnabled': False,
         'physicalDeviceRuntimeAndBattery': 'unverified', 'uploaded': False, 'status': 'pass'}
save(evidence / 'package-audit.json', audit)
(release / 'SHA256SUMS.txt').write_text(f'{iq_hash.lower()}  {iq.name}\n', encoding='ascii')
save(evidence / 'runtime-summary.json', {'runtime': runtime, 'power': power, 'aod': aod})
summary_path = root / 'evidence/summary.json'
summary = json.loads(read(summary_path))
summary.update({'date': '2026-10-04', 'revision': '1.0.0 first release; sun visibility corrected',
                'version': '1.0.0', 'packaged': True, 'uploaded': False,
                'currentValidation': 'releases/1.0.0/evidence/package-audit.json',
                'scope': 'releases/1.0.0/evidence/source-scope.json',
                'futureLongTests': 'Release simulator checks complete; physical watch battery/runtime remains unverified',
                'visualAcceptance': 'Current noon layout directly viewed in native F9 simulator; no screenshots exported',
                'fullValidationAppliesToCurrentRevision': False})
summary['latestChecks'].update({'simulatorTestsPassed': 37, 'simulatorTestsFailed': 0,
                               'compilerErrors': 0, 'compilerWarnings': len(warnings),
                               'nativeDisplayViewedForCurrentRevision': True,
                               'nativeAod24HourDevices': ['fenix9pro51mm', 'venu2'],
                               'currentRendererLifecycleDevices': ['fenix9pro51mm', 'venu2']})
summary['latestChecks'].pop('warningsOrErrors', None)
save(summary_path, summary)
print(f'PASS: {iq.name}, {iq.stat().st_size:,} bytes, 80/80 targets, 37 tests; {len(warnings)} compiler warnings retained.')
