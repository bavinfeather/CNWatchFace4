# 收费规则与 Key 接入 — 2026-10-01

用户最新决定：没有试用期；有效 Key 仅解锁更多自定义字段设置；不显示红色收费文字或收费横幅。
无 Key 或无效 Key 可持续使用免费功能。支付渠道继续暂不选择，先完成表盘设计。

## 当前工程

- 已移除 TrialPolicy、TrialManager、首次启动计时、到期判断及收费横幅和中英文提示资源。
- 手机设置提供 LicenseKey 文本输入，Application.Properties 保存该值；设置变化时重新读取。
- LicenseProvider.isLicensed() 是待接入的真实校验边界，当前仍返回 false，不把任意非空输入当作授权。
- 更多字段设置还没有定义或接入，免费与付费字段名单／数量待界面设计确定。
- AMOLED 07 首版已提供三个基础字段选择：步数、身体电量、海拔、电池；它们不依赖 Key。额外付费设置仍待确定。
- 正常显示与 AOD 不因 Key 而改变。

## 后续接入范围

1. 界面确定后划分基本字段设置与 Key 解锁的额外选项，保持差异只在自定义字段设置。
2. 确定有效 Key 的签发、验证和设备／应用绑定方式，然后接入校验。
3. 手机设置与手表设置的呈现方式随最终界面确定；字段读取和生效也必须校验授权，不能仅隐藏菜单。
4. 无 Key、无效 Key 或清空 Key 均回到免费设置；已有付费字段如何回退随字段规则定义。

## 已检查的依据

- Garmin Application.Properties：读取的键必须先在 properties XML 声明；本工程已经声明 LicenseKey。
  https://developer.garmin.com/connect-iq/api-docs/Toybox/Application/Properties.html
- Garmin DeviceSettings.uniqueIdentifier：可作为设备与应用绑定的授权标识，可能为 null。
  https://developer.garmin.com/connect-iq/api-docs/Toybox/System/DeviceSettings.html#uniqueIdentifier-var
- 本地资料：D:/Watch Face/Components/license-manual/README.md 与 Components/licensing/README.md。
  人工激活码和离线校验是候选，未引入共享秘密、付款账户或 Key 签发服务。
- GitHub：james-o-johnstone/garmin-stripe 是旧在线支付后端，未识别到开源许可证。
  不符合直接接入本工程的条件；只保留前期流程研究，没有复制其代码。
  https://github.com/james-o-johnstone/garmin-stripe

## 旧方案退役

前期 24 小时试用、到期提醒与测试结果只作为历史记录保存在 evidence/retired-trial/。
这些结果不代表当前 Key 解锁方案已经实现或通过验证；正式源码和资源中不再包含试用与到期提醒。
