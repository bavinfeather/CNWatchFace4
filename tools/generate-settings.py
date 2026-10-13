"""Keep phone settings and the on-watch menu in one bilingual schema."""
from pathlib import Path
import json
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
PALETTE = [(-1, '自动', 'Automatic'), (0xECF0F1, '浅白', 'Off-white'),
           (0xFFFFFF, '白色', 'White'), (0x9DAEBB, '蓝灰', 'Blue-gray'),
           (0x93DBE8, '冰蓝', 'Ice blue'), (0xFFCAA1, '暖杏', 'Warm apricot'),
           (0xFFAA55, '橙色', 'Orange'), (0x80D6B4, '薄荷', 'Mint'),
           (0xA998E8, '淡紫', 'Lavender'), (0xFF7788, '玫红', 'Rose'),
           (0xFFE377, '黄色', 'Yellow'), (0x4A90E2, '蓝色', 'Blue'),
           (0, '黑色', 'Black')]
FIELDS = [(0, '关闭', 'Off'), (1, '步数', 'Steps'), (2, '身体电量', 'Body Battery'),
          (3, '海拔', 'Elevation'), (4, '电池', 'Battery'), (5, '压力', 'Stress'),
          (6, '恢复时间', 'Recovery time')]
GROUPS = [('显示与语言', 'Display & language'), ('时间', 'Time'), ('单位', 'Units'),
          ('自定义字段', 'Custom fields'), ('亮屏颜色', 'Active colors'), ('解锁', 'Unlock')]
ROWS = []

def row(key, zh, en, group, default, options=None):
    ROWS.append(dict(key=key, zh=zh, en=en, group=group, default=default, options=options))

row('Language', '表盘语言', 'Face language', 0, 0,
    [(0, '跟随手表', 'Follow watch'), (1, '简体中文', 'Chinese'), (2, 'English', 'English')])
row('ShowDate', '显示日期', 'Show date', 0, True)
row('DateStyle', '日期格式', 'Date format', 0, 0,
    [(0, '星期与日', 'Weekday & day'), (1, '月/日', 'Month/day'), (2, '星期与月/日', 'Weekday & month/day')])
row('ShowWeatherText', '温度旁显示天气', 'Weather beside temperature', 0, True)
row('TimeFormat', '12/24 小时', '12/24 hour', 1, 0,
    [(0, '跟随手表', 'Follow watch'), (1, '12 小时', '12 hour'), (2, '24 小时', '24 hour')])
row('LeadingZero', '小时前导零', 'Leading hour zero', 1, True)
row('ShowSecondsActive', '抬腕显示秒数', 'Seconds while awake', 1, False)
row('ShowAmPm', '12 小时制显示 AM/PM', 'AM/PM in 12-hour mode', 1, True)
row('TemperatureUnit', '温度单位', 'Temperature unit', 2, 0,
    [(0, '跟随手表', 'Follow watch'), (1, '摄氏度 °C', 'Celsius °C'), (2, '华氏度 °F', 'Fahrenheit °F')])
row('ShowTemperatureUnit', '显示 C/F 单位', 'Show C/F unit', 2, True)
row('ElevationUnit', '海拔单位', 'Elevation unit', 2, 0,
    [(0, '跟随手表', 'Follow watch'), (1, '米', 'Meters'), (2, '英尺', 'Feet')])
for key, zh, en, default in [
    ('FieldUpperShort', '顶部短字段', 'Upper compact field', 5),
    ('FieldTop', '上方主字段', 'Top main field', 1),
    ('FieldMiddle', '中间主字段', 'Middle main field', 2),
    ('FieldBottom', '下方主字段', 'Bottom main field', 3),
    ('FieldLowerShort', '底部短字段', 'Lower compact field', 6)]:
    row(key, zh, en, 3, default, FIELDS)
for key, zh, en in [('HourColor', '小时颜色', 'Hour color'),
                    ('MinuteColor', '分钟颜色', 'Minute color'),
                    ('FieldLabelColor', '字段标题与单位颜色', 'Field label & unit color'),
                    ('FieldValueColor', '字段数据颜色', 'Field value color'),
                    ('DateColor', '日期颜色', 'Date color'),
                    ('WeatherColor', '温度与天气颜色', 'Temperature & weather color'),
                    ('BatteryColor', '电池弧颜色', 'Battery arc color'),
                    ('SecondaryColor', '秒数与 AM/PM 颜色', 'Seconds & AM/PM color')]:
    row(key, zh, en, 4, -1, PALETTE)
row('LicenseKey', '解锁 Key', 'Unlock key', 5, '')

def literal(value):
    return json.dumps(value, ensure_ascii=False, separators=(',', ':'))

def generate():
    properties = ET.Element('properties')
    settings = ET.Element('settings')
    strings = [ET.Element('strings'), ET.Element('strings')]
    for root, name in zip(strings, ['Geometric Canyon cyn4', '几何峡谷cyn4']):
        ET.SubElement(root, 'string', id='AppName').text = name
    menu_rows = []
    defaults = []
    choices = []
    for spec in ROWS:
        key, default = spec['key'], spec['default']
        typ = 'boolean' if isinstance(default, bool) else 'string' if isinstance(default, str) else 'number'
        ET.SubElement(properties, 'property', id=key, type=typ).text = str(default).lower() if isinstance(default, bool) else str(default)
        title = key + 'Title'
        for idx, lang in enumerate(('zh', 'en')):
            ET.SubElement(strings[idx], 'string', id=title, scope='settings').text = spec[lang]
        setting = ET.SubElement(settings, 'setting', propertyKey='@Properties.' + key, title='@Strings.' + title)
        options = spec['options']
        if isinstance(default, bool):
            ET.SubElement(setting, 'settingConfig', type='boolean')
            options = [(False, '关闭', 'Off'), (True, '开启', 'On')]
        elif isinstance(default, str):
            ET.SubElement(setting, 'settingConfig', type='alphaNumeric')
        else:
            config = ET.SubElement(setting, 'settingConfig', type='list')
            for index, (value, zh, en) in enumerate(options):
                option_id = key + 'Opt' + str(index)
                ET.SubElement(config, 'listEntry', value=str(value)).text = '@Strings.' + option_id
                for root, label in zip(strings, (zh, en)):
                    ET.SubElement(root, 'string', id=option_id, scope='settings').text = label
        menu_rows.append([key, spec['zh'], spec['en'], spec['group']])
        defaults.append('"%s"=>%s' % (key, literal(default)))
        if options:
            choices.append('        if(key.equals(%s)) { return %s; }' % (literal(key), literal(options)))
    for path, root in [(ROOT/'resources/settings/properties.xml', properties),
                       (ROOT/'resources/settings/settings.xml', settings),
                       (ROOT/'resources-zhs/strings/strings.xml', strings[0]),
                       (ROOT/'resources/strings/strings.xml', strings[1])]:
        ET.indent(root, space='    ')
        path.write_text(ET.tostring(root, encoding='unicode') + '\n', encoding='utf-8')
    source = '// Generated by tools/generate-settings.py; one schema for phone and watch.\nmodule FourthSettingsData {\n'
    source += '    function defaults() { return {' + ','.join(defaults) + '}; }\n'
    source += '    function groups() { return ' + literal(GROUPS) + '; }\n'
    source += '    function rows() { return ' + literal(menu_rows) + '; }\n'
    source += '    function choices(key) {\n' + '\n'.join(choices) + '\n        return null;\n    }\n}\n'
    (ROOT/'source/FourthSettingsData.mc').write_text(source, encoding='utf-8')
    print(f'Generated {len(ROWS)} matching phone/watch settings, English and Chinese.')

if __name__ == '__main__':
    generate()
