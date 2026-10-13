# GitHub 与官方接口依据

## 可采用的方法

### 上下短字段图标（2026-10-03）

[Lucide](https://github.com/lucide-icons/lucide/tree/500620a2e8123f8d1db191538886dc0c223f69a9) 固定 commit `500620a2e8123f8d1db191538886dc0c223f69a9`。复用 footprints、battery-plus、mountain、battery、activity、timer 的原始 SVG，不自行构造图标轮廓。完整 ISC/Feather 许可、源 SVG 和版本清单保存在 `assets/lucide-short-fields`。仅替换描边颜色，转成透明 32px PNG；每次只缓存当前两项，睡眠时释放，构建工具为 `tools/build-short-field-icons.cjs`。

[Garmin Complications](https://developer.garmin.com/connect-iq/api-docs/Toybox/Complications.html) 定义压力为 0–100 或空值，恢复时间为分钟；沿用十秒指标读取节流。恢复时间在短字段中显示分钟或向上取整的小时，异常/空值显示 --。

### 月相素材（2026-10-03 接入）

[erikflowers/weather-icons](https://github.com/erikflowers/weather-icons)，本地资料库原始 Git commit `bb80982bf1f43f2d57f9dd753e7413bf88beb9ed`。上游图标许可 SIL OFL 1.1，署名 Lukas Bischoff、Erik Flowers。源字体、28 阶段映射、来源与完整许可保存在 `assets/moon`。

直接复用原始字体的非 alt 月相图标，不自行构造月相轮廓。`tools/build-moon-assets.py` 保持统一圆盘边界，将原字形缩小为 28 张透明 32px 图片。`automaticPalette="false"` 允许 F9 的缩放和着色；每次只加载当前阶段，避免加载整张大图集。构建产物指纹见 `evidence/moon-asset-source.json`。

阶段选择现采用 [SunCalc](https://github.com/mourner/suncalc/tree/ecb6bb0b0f3a5003298cfb536e46176117caf4e5) 的日月坐标与照明相位算法，精简移植到 `source/MoonPhase.mc`，每 UTC 小时缓存一次。当前固定版本许可为 BSD 2-Clause，Copyright (c) 2026 Volodymyr Agafonkin；原源码、完整许可和移植说明保存在 `assets/suncalc`。28 张原图不变，阶段仍就近映射；2026 年 USNO 官方 50 个主要月相时刻全部选中预期阶段。未计算月出月落、真实月亮方位或南北半球方向，不作为完整天文历表。新月隐藏；上弦右亮，下弦左亮。历史四格见 `evidence/screenshots/f9-background-github-moon-phases.png`。

[chrisdfennell/Spring-Watchface — Bloom](https://github.com/chrisdfennell/Spring-Watchface)
代码 SHA：`501b20918906ab9924e891309566f2f6a7c80535`（GitHub 文件 blob SHA）。
[MIT 许可](https://github.com/chrisdfennell/Spring-Watchface/blob/main/LICENSE)，Copyright (c) 2026 Christopher Fennell。

源码 `source/BloomView.mc`：
- `updateSunTimes` 约第 1604 行：按日期缓存事件，缺定位时保持回退时段并重试。
- `getLocationDeg` 约第 1638 行：优先活动位置，再天气观测位置，不开启 GPS。
- `getSkyColors` 约第 1765 行：以真实日出日落为天空配色锚点。

这里参考的是缓存、被动定位和时间配色的方法。第四代改用 Garmin 原生日出日落接口；未复制 Bloom 的 NOAA 算法、字体、插画或完整 View。
Bloom 的整屏位图缓存没有采用，第四代用逐行渐变，避免引入整屏缓存内存压力。
设计及山体坐标来自用户选定的 07，不能声称 Bloom 提供同款山景。

## 不采用的视觉资源

- [flyingfisch/garmin-instinct-mountain-watchface](https://github.com/flyingfisch/garmin-instinct-mountain-watchface)：可作山景表盘比较，但目标是 Instinct，未确认适用于本项目的资源许可；不复制代码或插画。
- [MatthiasBenaets/Garmin-WatchFace](https://github.com/MatthiasBenaets/Garmin-WatchFace)：公开说明限制发布到 Connect IQ，不作为本项目复用来源。

未找到许可明确且与获批 07 完全相同的现成表盘实现，因此不能拿另一款开源画面替代设计图。

## 官方接口

### Bug 复核（2026-10-04）

本次成功读取 [SnowfallView 源码](https://github.com/chrisdfennell/WinterTime-Watchface/blob/main/source/SnowfallView.mc)，核对休眠与唤醒时请求更新、被动位置及天气处理；同时核对 [EasyDisplayApp](https://github.com/Holger-L/EasyDisplay/blob/main/source/EasyDisplayApp.mc) 的设置入口。没有替换 07 背景、山体、月相素材或字体。

[Garmin SensorHistory](https://developer.garmin.com/connect-iq/api-docs/Toybox/SensorHistory.html) 用于身体电量当前值缺失时读取一个新鲜样本，增加对应权限并检查 API；[Graphics.getVectorFont](https://developer.garmin.com/connect-iq/api-docs/Toybox/Graphics.html#getVectorFont-instance_function) 的可空返回用于修正温度符号回退。[Complications](https://developer.garmin.com/connect-iq/api-docs/Toybox/Complications.html) 确认海拔为米、恢复为分钟及 Float / Number 兼容。修复与最终测试范围见 [BUG-AUDIT-2026-10-04.md](../evidence/BUG-AUDIT-2026-10-04.md)。

### 完整菜单与文字（2026-10-04）

[Garmin AppBase.getSettingsView](https://developer.garmin.com/connect-iq/api-docs/Toybox/Application/AppBase.html#getSettingsView-instance_function) 与 SDK 9.2 官方 Properties and Settings 章节明确：表盘通过系统 Watch Face 菜单进入自定义设置，正常模式不允许推入页面。本项目仅从此入口返回 Menu2 与输入委托；保存到 Application.Properties 后刷新表盘。参考 [Holger-L/EasyDisplay 的应用入口](https://github.com/Holger-L/EasyDisplay/blob/main/source/EasyDisplayApp.mc) 的官方入口用法，没有复制第三方菜单实现。

[Garmin 每秒刷新说明](https://developer.garmin.com/connect-iq/connect-iq-faq/how-do-i-get-my-watch-face-to-update-every-second/) 用于亮屏秒数：系统唤醒时每秒 onUpdate，休眠后隐藏；没有加入定时器或低功耗秒级重绘。[DeviceSettings](https://developer.garmin.com/connect-iq/api-docs/Toybox/System/DeviceSettings.html) 用于跟随设备语言、小时制、温度及海拔单位；[Graphics.Dc.drawBitmap2](https://developer.garmin.com/connect-iq/api-docs/Toybox/Graphics/Dc.html#drawBitmap2-instance_function) 的 tintColor 用于上下短字段图标与标题独立配色。

中文文字回退复用第三代表盘已有 [Google Fonts Noto Sans SC](https://github.com/google/fonts/tree/main/ofl/notosanssc) 字体及完整 SIL OFL 许可，拷贝后在第四代独立生成有限字形子集，不建立跨项目运行路径。日期、字段、天气与紧凑数字均纳入子集；原 Time07 / Small / Aod 文件未改动。

2026-10-02 样式复核另读 [Snowfall / WinterTime-Watchface](https://github.com/chrisdfennell/WinterTime-Watchface) 的公开说明：天空与日月按日出日落变化、冬季前后景分层及渐变缓存。其常态飘雪属于冬季主题，不能当作实时天气响应示例。部分原始图片与源码请求未成功加载，本轮只借鉴公开描述的方法，没有复制资源或代码。当前 07 对照结论见 `evidence/DESIGN-WEATHER-REVIEW.md`。

- [Weather](https://developer.garmin.com/connect-iq/api-docs/Toybox/Weather.html)：当前天气、条件枚举、日出日落。
- [CurrentConditions](https://developer.garmin.com/connect-iq/api-docs/Toybox/Weather/CurrentConditions.html)：温度为摄氏，字段及观测时间可能为空；位置需要 Positioning 权限。
- [Complications](https://developer.garmin.com/connect-iq/api-docs/Toybox/Complications.html)：身体电量、海拔读取；异常或未知值显示 `--`。
- [Activity.Info](https://developer.garmin.com/connect-iq/api-docs/Toybox/Activity/Info.html)：海拔及已有位置回退。
- [Graphics.Dc](https://developer.garmin.com/connect-iq/api-docs/Toybox/Graphics/Dc.html)：多边形、文字、弧线。弧首尾相同会成为整圆，因此守卫零电量。

已查看本地 `D:\Watch Face\Notes\bugs\regression-checklist.md`，针对字体边界、定位权限、天气缺项、完整帧、图形内存和 466px 路由安排验证。
