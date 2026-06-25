# Home Lobby Audit

本审计基于完整启动包、视觉参考图，以及当前 Godot 项目实现。范围只包含 Home/Lobby vertical slice；未审计、未实现牌桌、联机、Steam API、商店、支付或真实经济。

## 当前做对了什么

- 已经有 `collapsed_home` 和 `play_expanded` 两个核心状态。
- 使用 Godot `Control`、`PanelContainer`、`VBoxContainer`、`HBoxContainer`、`Grid/Container` 思路组织 UI，而不是把整张概念图贴成界面。
- 主要 UI 元素已组件化：TopBar、LeftNavRail、NavItem、ModeCard、DailyBonusBar、CurrencyPill、NeonButton。
- Mock 玩家和模式数据集中在 `scripts/data/mock_home_data.gd`。
- 有深色底、紫/蓝/粉霓虹、顶部玩家/货币栏、左侧导航和中央品牌 Logo。
- 已有可扩展的 `MotionManager`、背景 flow shader、soft glow shader。
- 卡片、导航、面板、前景层已经有 Tween 或 ShaderMaterial 动效基础。

## 当前偏离了什么

- 初版左侧导航偏宽，菜单项不完全符合完整规范；已改为更窄的 HOME / PLAY / CLUB / TOURNAMENTS / STORE / PROFILE。
- 初版顶部栏更像普通信息条，视觉重量偏大；已改为右上角更轻的玩家、货币和小图标结构。
- 初版 Play 展开态像一个大半透明面板，容易接近“手游弹窗”；已改成背景上浮出五张模式卡和低调 Daily Bonus。
- 初版 Logo 视觉中心不足，品牌感弱于参考图；已放大为 `TEXAS HOLD'EM` 中央品牌焦点。
- 初版 Daily Bonus 是单条 Claim 文案，偏活动页；已改成 7 日奖励条，Day 4 低调高亮。
- 初版背景霓虹线条和流动稍显直接；已降低 shader 速度、强度和粉色混合量。

## 占位素材

- 中央 Logo 仍是 Godot 文本 + 程序绘制 spade/glow，占位正式品牌字标。
- 背景是程序绘制深色氛围 + flow shader，占位正式大厅背景层。
- ModeCard 图片区是程序绘制占位图形：纸牌、筹码、奖杯、牌桌、俱乐部徽章。
- 顶部头像是圆形面板占位，没有正式头像图。
- 货币和顶部图标为文字/色点占位，没有最终 SVG 图标包。
- 前景筹码和卡牌是程序绘制占位，不是最终透明 PNG 资产。

## 已实现动效

- 背景 flow shader 慢速流动，可通过 `background_motion_enabled` 关闭。
- Logo 轻微呼吸：透明度和 1.012 倍以内的缩放循环。
- 左侧菜单 hover：文字变亮、细指示条淡入。
- 左侧 PLAY active：粉色高亮条和 Play 子菜单淡入。
- Play panel reveal：淡入 + 横向滑入。
- ModeCard stagger：每张卡延迟 0.04s 出现。
- ModeCard hover：上移 6px、scale 1.025、边框/阴影增强。
- ModeCard press：scale 0.98 后回弹。
- Daily Bonus 展开后轻微滑入。
- 前景筹码/卡牌有小幅循环漂浮。

## 只是静态参考的内容

- `docs/screenshots/static_collapsed_home.png` 和 `docs/screenshots/static_play_expanded.png` 是本环境生成的静态视觉参考图，不是真实 Godot 运行截图。
- 当前环境没有可用的 Godot 可执行文件，因此还未完成真实运行截图、真实 hover 截图或运行时无报错验证。

## 本轮二次修正

- 保留现有 Godot 4.6 / GL Compatibility / Jolt 项目配置，只补 1920x1080 桌面窗口配置。
- 重调主题色：更深的 navy/black 底、更低饱和霓虹、更克制的 panel/card 透明度。
- 左侧导航收窄为 184px，并对齐完整规范菜单。
- PLAY 选中时显示低调模式子项，复杂内容仍通过点击展开。
- 顶部栏改为更干净的右侧资源区，减少全宽面板感。
- 默认态放大 Logo 和品牌文字，让大厅第一眼更靠近参考图。
- Play 展开态改为五张横向模式卡，背景保持可见。
- ModeCard 增加程序绘制占位视觉，Quick Play 更突出。
- Daily Bonus 改成七日奖励条，避免礼包页感。
- 背景 flow shader 降低速度和强度，减少外星/过花风险。

## 后续仍建议修正

- 在 Godot 编辑器里运行并截取真实 collapsed / expanded 截图。
- 使用正式字体、正式 Logo 和统一 SVG 图标包替换文字占位。
- 使用独立透明 PNG 替换程序绘制筹码、卡牌和模式卡图。
- 给非 HOME/PLAY 导航加低调 toast 组件，而不是只 `print`。
- 用 Godot Theme 资源文件进一步集中样式，减少脚本内样式创建。
- 真实运行后微调 1920x1080 下的卡片间距、顶部栏间距和 Logo 垂直位置。
