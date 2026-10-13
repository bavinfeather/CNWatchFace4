"""Check the shared phone/watch schema and representative compiled resources."""
import json
import xml.etree.ElementTree as ET
from pathlib import Path
import runpy

ROOT=Path(__file__).resolve().parents[1]
schema=runpy.run_path(str(ROOT/'tools/generate-settings.py'))
rows=schema['ROWS']
expected={row['key'] for row in rows}
properties=ET.parse(ROOT/'resources/settings/properties.xml').getroot()
settings=ET.parse(ROOT/'resources/settings/settings.xml').getroot()
assert {p.attrib['id'] for p in properties}==expected
assert {s.attrib['propertyKey'].removeprefix('@Properties.') for s in settings}==expected
strings={lang:{s.attrib['id']:s.text or '' for s in ET.parse(ROOT/path).getroot()}
         for lang,path in [('eng','resources/strings/strings.xml'),('zhs','resources-zhs/strings/strings.xml')]}
refs={s.attrib['title'].removeprefix('@Strings.') for s in settings}
refs.update(e.text.removeprefix('@Strings.') for s in settings for e in s.findall('./settingConfig/listEntry'))
for lang,texts in strings.items():
    assert all(ref in texts and texts[ref] for ref in refs), lang
for row in rows:
    assert strings['zhs'][row['key']+'Title']==row['zh']
    assert strings['eng'][row['key']+'Title']==row['en']
builds=json.loads((ROOT/'evidence/build-results.json').read_text(encoding='utf-8-sig'))
compiled=[]
for build in builds:
    assert build['exitCode']==0, build['device']
    payload=json.loads((ROOT/f"bin/{build['device']}-settings.json").read_text(encoding='utf-8'))
    assert {s['key'] for s in payload['settings']}==expected
    assert 'zhs' in payload['languages'], build['device']
    assert payload['languages']['zhs']['LanguageTitle']==strings['zhs']['LanguageTitle']
    for texts in payload['languages'].values():
        assert refs.issubset(texts)
    compiled.append(build['device'])
result=dict(settingCount=len(rows),groups=schema['GROUPS'],colorChoices=len(schema['PALETTE']),
            sourceLanguages=list(strings),bilingualReferencesChecked=len(refs),compiledDevices=compiled,
            compiledSettingsCount=len(expected),status='pass')
(ROOT/'evidence/settings-schema-audit.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(result,ensure_ascii=False))
