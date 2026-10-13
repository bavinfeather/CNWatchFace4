# 几何峡谷cyn4 / Geometric Canyon cyn4 — 1.0.0

独立第四表盘，采用现代设备架构，最低 API 4.2.2。正式名称为「几何峡谷cyn4 / Geometric Canyon cyn4」，AMOLED 亮屏基于选定的 07 低噪切面。
设备 ID 完整取自 CNWatchFace3 当前 0.5.8 manifest，共 63 个；不会混入旧设备架构。
现代 AMOLED / MIP 设备路由独立；当前只制作 AMOLED 亮屏，MIP 保留原简化骨架。

## 文件结构

- `source/FourthApp.mc`：独立应用入口。
- `source/FourthView.mc`：07 的两行时间、日期、温度、电池弧、三个主字段、上下两个短字段及 AOD。
- `source/Landscape.mc`：固定山体坐标、昼夜光照、云雨雪雾。
- `source/FourthData.mc`：天气、被动定位、日出日落与默认字段数据。
- `source/MoonPhase.mc`：固定版本 SunCalc 日月坐标和相位计算；月相图仍为 Weather Icons 原素材。
- `source/licensing/`：Key 读取和授权校验接入点。
- `source/FourthOptions.mc`、`source/FourthSettings.mc`：设置缓存与系统入口的分组手表菜单；`FourthSettingsData.mc` 为共用定义生成结果。
- `resources/`、`resources-zhs/`：启动图标、25 项英文与中文手机设置。
- `resources-{240,260,280,360,390,416,454,466}/`：与第三表盘相同的 AOD/Small 字体资源。
- `assets/licenses/`：字体许可。
- `docs/`：设备清单、收费调研与后续实施范围。
- `tests/`：模拟器单元测试及免费 / Key 解锁待执行场景。
- `tools/`：本地构建工具。
- `evidence/`：构建日志、源码指纹与验证结论。
- `bin/`：开发构建与临时测试签名；`releases/`：以后明确要求打包时使用。

## 当前行为

没有试用期或到期逻辑，免费功能可持续使用，不显示收费横幅或红色收费文字。
新的收费规则仅为：有效 Key 解锁更多自定义字段设置；无 Key 或无效 Key 保持免费设置。
中间三个字段默认步数、身体电量、海拔，名称在上、数据在下。上下两项采用左图标、右数据，默认压力和恢复时间，可关闭或改选。设计阶段先开放预览；正式免费/Key 选项分界尚未定义。

AMOLED AOD 保持第三表盘的黑底、灰色 HH:mm、MM/DD、电量和字体；可靠性修正后，上下两个不重叠区域每分钟交替，避免连续点亮同一像素。MIP 保留原 5×5 分钟位移。
AMOLED 亮屏现为几何山体，日出日落调整光照，天气叠加云、雨、雪、雾。
当前先完成背景，字体评审暂停；昼夜与天气的实现及历史运行截图见 `docs/BACKGROUND.md`、`evidence/BACKGROUND-VALIDATION.md`。位置/时区、月相、AOD、内存、恢复和省电相关验证见 `evidence/RELIABILITY-VALIDATION.md`。
最新五字段布局、19 项测试、63 设备构建和 F9 新版本循环运行结果见 `evidence/FIVE-FIELDS-VALIDATION.md`。
2026-10-04 最新完整菜单与温度旁天气文字见 `docs/SETTINGS.md`；当前设置功能验证、六款代表设备构建及原生菜单操作见 `evidence/SETTINGS-VALIDATION.md`。历史循环运行与全设备构建不代表本轮完整验证；长时间内存、黑屏与省电检查按用户要求留到打包前。
详细坐标、参考图、天气缺项与位置不可用规则见 `docs/DESIGN-07.md`。
GitHub 方法、许可及未采用的资源见 `docs/GITHUB-REFERENCES.md`。

手机与手表设置均提供 `LicenseKey` 输入，设置变化后重新读取。`LicenseProvider.isLicensed()`
仍固定返回 false：真实 Key 校验与更多字段设置尚未接入，不会把任意非空文本当作有效 Key。
实际支付渠道继续暂缓；无付款 URL、价格、商户账户或 Key 签发服务。
当前是 A 屏设计实现首版，真实授权、MIP 亮屏和视觉验收未完成，不可作为完整收费产品发布。

## 本地验证

`tools/build.ps1` 默认覆盖 8 个分辨率代表设备，`-Device all` 验证 manifest 的全部 63 个设备。
`-Key <开发签名 DER 路径>` 可传入测试密钥，默认使用 `bin/development.der`。
第四表盘首次发布的长期签名已固定为 `keys/Canyon-release.der`，与开发阶段签名保持同一身份。该文件不进入公开发布目录，后续更新继续使用它，需单独妥善备份。
原试用实现与测试已退役，历史资料保留在 `evidence/retired-trial/`，不参与构建。
1.0.0 是首次本地上传准备版，IQ 包和中英文首次上架文案在 `releases/1.0.0/`，只准备本地文件，不代为上传。完整记录以同目录的 `RELEASE.md` 与 `evidence/package-audit.json` 为准。当前产品不宣传收费解锁；MIP 的简洁路径与 AMOLED 山景在商店文案中明确区分。历史背景验证见 `evidence/BACKGROUND-VALIDATION.md`，初版记录见 `evidence/VALIDATION.md`。
