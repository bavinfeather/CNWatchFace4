"""Assemble the final evidence from completed native runs; fail on missing checks."""
from pathlib import Path
import json, re, hashlib

root = Path(__file__).resolve().parents[1]
evidence = root / 'evidence'
def read(name):
    return (evidence / name).read_text(encoding='utf-8-sig')
def load(name):
    return json.loads(read(name))
def save(name, value):
    (evidence / name).write_text(json.dumps(value, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')

inputs = load('reliability-inputs-before-build.json')
for item in inputs:
    assert hashlib.sha256(Path(item['path']).read_bytes()).hexdigest().upper() == item['sha256']
builds = load('build-results.json')
assert len(builds) == 63 and all(x['exitCode'] == 0 for x in builds)
assert 'PASSED (passed=17, failed=0, errors=0)' in read('core-tests.log')
scope = load('scope-check.json')
assert scope['siblingChanged'] == 0 and scope['aodFontFilesMatchThird'] == 32
devices = []
for device, resolution in [('fenix9pro51mm',466),('fr265s',360),('venu2',416),('fr255',260)]:
    log = read(f'lifecycle-{device}-runtime.log')
    assert not re.search(r'UNHANDLED|RELIABILITY FAILED|out of memory|watchdog', log, re.I)
    m = re.search(r'RELIABILITY PASSED frames=(\d+) sleepWake=(\d+) peak=(\d+) minFree=(\d+) total=(\d+)',log)
    assert m and m.groups()[:2] == ('3000','30')
    lows = [int(x) for x in re.findall(r'RELIABILITY_BLOCK frame=\d+ min=(\d+)', log)]
    assert len(lows)==30 and len(set(lows))==1
    devices.append(dict(device=device,resolution=resolution,frames=int(m[1]),sleepWakeCycles=int(m[2]),
        peakHeapBytes=int(m[3]),minimumFreeHeapBytes=int(m[4]),totalHeapBytes=int(m[5]),
        stableBlockMinimumBytes=lows[0],fixtureData=True,productionOnUpdate=True))
power = re.search(r'POWER_PAIRED PASSED pairs=(\d+) warmMs=(\d+) coldMs=(\d+) weatherPolls=(\d+)',read('power-fenix9pro51mm-runtime.log'))
assert power and int(power[1])==100
power = dict(pairs=int(power[1]),warmTotalMs=int(power[2]),coldTotalMs=int(power[3]),weatherPolls=int(power[4]),
    comparison='identical complete daylight frames; alternating order; forced sky-color recomputation versus cached colors',
    batteryMeasurement=False)
power['warmMeanMs']=power['warmTotalMs']/power['pairs']
power['coldMeanMs']=power['coldTotalMs']/power['pairs']
power['cpuTimeReductionPercent']=100*(1-power['warmTotalMs']/power['coldTotalMs'])
aod = load('aod-pixel-check.json')
assert len(aod)==10 and all(x['maxAdjacentOverlap']==0 and x['clippedPixels']==0 and x['peakLitPercent']<10 for x in aod)
heat = load('aod-native-heatmap.json')
assert len(heat)==2 and all(x['simulationSeconds']==86400 and x['burnInState']=='NO' and x['screenProtection']=='ON' for x in heat)
assert 'BACKGROUND_STRESS PASSED frames=63' in read('reliability-background-stress-runtime.log')
result = dict(date='2026-10-03',formalInputs=len(inputs),formalInputsChangedDuringBuild=0,
    buildsPassed=len(builds),unitTestsPassed=17,officialMoonPhaseSamplesPassed=50,
    scope=scope,nativeLifecycle=devices,nativeColdBackgroundFramesPassed=63,
    aodBitmapFallback=aod,aodNativeHeatMap=heat,pairedCpu=power,
    metricsPolling=dict(fullCallbacks=61,activityPolls=7,weatherPolls=1,metricsIntervalSeconds=10),
    realDevicePower='unverified',realDeviceGestureWake='unverified',
    recoveryScope='30 injected sleep/wake hooks and 12 explicit graphics releases per native run; null-resource fallback unit test; no deliberate OS graphics-memory exhaustion')
save('reliability-results.json',result)
for key, path in [('currentNativeLightPreview','screenshots/f9-reliability-light.png'),
                  ('currentNativeAodPreview','screenshots/f9-aod-reliability.png')]:
    if (evidence/path).exists(): result[key]=path
save('reliability-results.json',result)
summary = load('summary.json')
summary.update(revision='07 landscape reliability: location/time zone, SunCalc phase, WINDY, AOD and resource recovery',
    sourceFilesFingerprinted=len(inputs),sourceChangedDuringBuild=0,simulatorTestsPassed=17,scope=scope,
    aodRenderer='same fonts/colors; AMOLED alternates disjoint upper/lower bands; MIP original drift',
    raiseToWake='native injected hooks passed on 4 devices; physical gesture unverified',
    moonPhase='pinned BSD-2-Clause SunCalc coordinate/illumination port; hourly cache; no moonrise/moonset',
    reliabilityEvidence='evidence/RELIABILITY-VALIDATION.md',nativeLifecycleDevices=[x['device'] for x in devices],
    nativeLifecycleFrames=sum(x['frames'] for x in devices),nativeSleepWakeCycles=sum(x['sleepWakeCycles'] for x in devices),
    aodNativeHeatMapDevices=[x['device'] for x in heat],realDevicePower='unverified')
save('summary.json',summary)
save('amoled-source.json',inputs)
table = '\n'.join(f"| {x['device']} | {x['resolution']} | {x['frames']} | {x['sleepWakeCycles']} | {x['peakHeapBytes']} | {x['minimumFreeHeapBytes']} | {x['stableBlockMinimumBytes']} |" for x in devices)
report = f'''# 第四代表盘可靠性验证 — 2026-10-03

本轮完成前次审查的四项修正，并补内存、恢复、AOD 与省电相关验证。07 构图和现有字体资源保留；只改变三个既有正式源码文件并新增 MoonPhase.mc。92 个正式输入在最终构建和验证期间无变化。前三代 20 个冻结文件无变化，32 个 AOD/Small 字体资源仍与第三代相同。

## 已修正

- 位置与时区：接受有效的新天气位置；四小时过期后回退活动位置。日期、时区或相对已计算位置漂移达到 0.1 度时失效太阳缓存；空太阳事件每 60 秒重试。系统时间倒退清理未来缓存。
- AOD：同一字体、黑底和灰色文本，AMOLED 每分钟在上下不重叠区域交替，MIP 保留原位移。前次微移连续亮点问题已修复。
- 普通大风：独立条件，不再强制阴云与湿山面；风暴保留自己的表现。
- 月相：固定 SunCalc commit ecb6bb0b0f3a5003298cfb536e46176117caf4e5 的坐标/照明算法，BSD 2-Clause 原许可保留。阶段计算每 UTC 小时一次。28 张 Weather Icons 原月相素材及 OFL 许可不变，2026 年 USNO 全部 50 个主要相位时刻选中预期阶段。

## 构建与功能

63/63 产品构建成功，17/17 模拟器测试成功。测试涵盖位置、时区、定位过期、太阳重试、时间回拨、天气缺项/过期、字段边界、风天气、月相参考、AOD 区域和空图形资源回退。日志见 build-results.json、core-tests.log；来源和指纹见 reliability-scope.json、reliability-inputs-before-build.json。

## 内存与恢复

| 模拟设备 | 像素 | 完整帧 | 完整休眠唤醒 | 峰值堆内存 B | 最低空闲 B | 每百帧堆内存低点 B |
|---|---:|---:|---:|---:|---:|---:|
{table}

同一个 View 和 Landscape 实例持续运行，共 12000 帧、120 次注入的休眠唤醒。每百帧低点在各设备所有 30 个区间相同，没有检测到持续堆内存增长。每次休眠释放天空纹理和月相图片，另每 250 帧主动释放一次（每设备 12 次），随后完整重画。AMOLED 变化覆盖九种天气、四个时段和全部 28 张月相资源；FR255 验证现有 MIP 骨架。

资源为空的专项测试确认天空仍绘制 233 个色带、山体继续绘制；月相资源缺失只省略月亮。天空纹理异常有回退，不会中断时间与字段。最终原生冷启动也通过 35 个昼夜/天气场景和 28 个月相场景，共 63 帧。

以上验证系统刷新中的完整绘制、受控资源释放和注入的休眠钩子，不代表真机手势测试或实际 OS 图形内存耗尽测试。堆内存统计不能等同全部图形内存。未发现异常、内存不足或超时；没有对全部 12000 帧逐帧截图，因此不作全程像素级无黑屏保证。

## AOD

离线位图回退模型覆盖 360/390/416/454/466，12/24 小时格式，逐分钟 1441 帧（含跨午夜）。相邻分钟亮点重叠全部为零，最高点亮面积 {max(x['peakLitPercent'] for x in aod):.2f}%，圆屏裁切零像素。模型不是原生字体热图，结果见 aod-pixel-check.json。

F9 Pro 51 与 Venu 2 另在原生 Screen Burn-In Simulation 运行 86400 秒的全天模拟，Always-On、Screen Protection ON，结束显示 Burn-in State NO。F9 完成弹窗明确说明未检测到烧屏，峰值亮度占用 0.68%；Venu 2 的记录是完成后 Start 重新可用和 Burn-in State NO。实际 UI 文字记录见 aod-native-heatmap.json；原生亮度百分比与离线亮点面积是不同指标。F9 原生 AOD 导出截图见 screenshots/f9-aod-reliability.png。

## 省电相关验证

生产数据每 10 秒取一次活动/身体电量/海拔，天气正常每 300 秒、空结果每 60 秒。61 次按秒更新只调用活动数据 7 次、天气一次。没有新增 GPS、网络请求、秒针或动画定时器；每个系统要求的帧仍完整绘制。

天空只缓存两行纹理和颜色列表，不缓存整屏。F9 同一完整白天画面做 100 组成对计时，交替先后顺序，每次原生回调只绘制一帧：复用颜色平均 {power['warmMeanMs']:.2f} ms，强制重新计算平均 {power['coldMeanMs']:.2f} ms，模拟器 CPU 时间减少 {power['cpuTimeReductionPercent']:.1f}%。这是该缓存步骤的耗时对比，不是整体耗电降幅或续航承诺。日志见 power-fenix9pro51mm-runtime.log。

初次计时工具把预热和两次绘制合并在一个回调，触发执行预算超时；失败日志保存在 power-rejected-batch-runtime.log。修正测试工具为单帧回调后完成复测。正式表盘始终每回调一帧，此项未修改正式源码。

## 保留的边界

真实手表 24 小时耗电、真机抬腕恢复、OS 强制图形内存回收未验证；没有连接可控制的真机或电流测量装置。极昼极夜和跨午夜太阳事件仍使用视觉回退；未加入月出月落、真实月亮方位或南半球镜像。MIP 景色和 Key 的额外收费设置继续按原决定暂缓。较旧 Venu 2 的现有温度度数字形显示为缺字方框，字体评审按用户要求暂停，未在本轮改字体。没有打包或上传。
'''
if 'currentNativeLightPreview' in result:
    report += '\n## 当前代码导出截图\n\n![清晨、白天、黄昏、夜晚](screenshots/f9-reliability-light.png)\n\n四格为样本时段，日出 06:00、日落 18:00，每格 233px，不是四个全尺寸截图。\n\n![原生 AOD 上方区域](screenshots/f9-aod-reliability.png)\n'
(evidence/'RELIABILITY-VALIDATION.md').write_text(report,encoding='utf-8')
print(json.dumps(result,ensure_ascii=False,indent=2))
