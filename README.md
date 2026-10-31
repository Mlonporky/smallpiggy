# 猪猪山庄——被遗忘的快乐——

Godot 4.7.2 / GDScript / 2D 叙事冒险。当前主线已接通从共同开场到重逢、回家和字幕结局；仍有角色动画与声音缺项，技术回归不代表最终观感验收。

## 已实现

当前专题为[第五阶段音频](docs/HANDOFF_2026-10-31_PHASE5.md)：森林/山洞环境、脚步、拾取与平台事件音已接入，13项回归及正常时间混音检查通过。可听[32秒试听](docs/audio/phase5_2026-10-31/gameplay_audio_listen.wav)（试听副本增益12dB）；声音为合成首版，听感待反馈。

2026-10-31 男孩造型选择：用户更喜欢现有男孩，正式形象继续沿用原素材；第四阶段新手绘候选仅保留为试验参考。后续动作完善以现有造型为基准，见[最新方向](docs/STORY_AND_ART_DIRECTION.md)。

[巫师开场与第一幕配乐](docs/MUSIC_ZH.md)已接入，开场按 Esc/P 暂停、R 重播，三房间共用探索音乐。全局 F1 打开设置与操作，M 控制全部声音；音乐、音效、环境声音量分别保存，重启后保留。

最新[橡子回忆完整效果](docs/ACORN_MEMORY_FINAL_ZH.md)：在 Godot 打开 `scenes/cabbage_act2/acorn_memory_final.tscn` 按 F6 自动播放，使用用户手调的小猪装配；已接入正式桌面回忆。

交接总入口见 [HANDOFF](docs/HANDOFF.md)，此前[总体优化第四阶段](docs/HANDOFF_2026-10-30_PHASE4.md)：五角色同高度对照、手绘男孩候选和[18秒短片](docs/art_direction/phase4_boy_v1/phase4_character_study.mp4)，另修正正式最终章男孩的方向与停步取帧。新手绘候选仅作试验，正式男孩沿用原版；可在 Godot 打开 `scenes/animation_studies/phase4_character_study.tscn` 按 F6 查看。[第三阶段](docs/HANDOFF_2026-10-30_PHASE3.md)玩法指引、[第1/2阶段](docs/HANDOFF_2026-10-30_PHASE12.md)菜单设置与存档反馈保留。保留[可编辑角色场景与操作说明](docs/EDITABLE_PIG_ZH.md)；小猪 A/B 与解剖左右仍待核对。历史章节记录见 [第二幕 handoff](docs/HANDOFF_2026-09-10_ACT2.md) 和 [第一幕 handoff](docs/HANDOFF_2026-09-10.md)，旧状态以当前交接为准。

最新设定与美术重制方向见 [方向文档](docs/STORY_AND_ART_DIRECTION.md)，协作约定见 [AGENTS.md](AGENTS.md)，进度见 [WORKLOG.md](WORKLOG.md)。序章为约 89 秒的手绘分镜版；第一幕已接入三间手绘房间，离家后切到呆呆猪的新森林入口，再进入山洞战斗。没有终极 Boss 战；最终巫师死于白菜认出呆呆猪时爆发的快乐能量。

- 可播放的手绘序章：城堡警报 → 水晶球锁定呆呆猪 → 蘑菇屋包装礼物 → 巫师降咒 → 卧室中白菜变回小男孩、BIG IDEA 画由 before 变 after → 小猪和礼物一起被卷走 → 巫师撕碎礼物、碎片散落 → 第一幕。包含镜头推近、粒子、局部溶解、提示音和字幕；尚非逐帧角色动画。
- 白白菜：卧室起床近景、调查原版 BIG IDEA after 画、厨房咖啡与猪猪杯／双人餐具、客厅抱枕、三段模糊回忆、三次心心变化、红纸入场与离家。只接附件已有句子，缺失定稿对白留空。旧复原早餐位玩法保留为历史样板，不再作为主入口。
- 人物按实际位移推进三姿势步态，脚底对齐、物理插值、脚底碰撞、家具局部遮挡；并非新增完整手绘角色动画。
- 小呆猪：林间小路与发光洞口、100 点生命、空格跳跃、40% 生命触发“想起白菜”、快乐挥击、史莱姆前摇与扑击、拾取第一块礼物碎片。
- 五个 Autoload：`GameState`、`SceneRouter`、`SaveManager`、`AppSettings`、`MusicDirector`。
- 数据化对白、统一 Interactable、可复用 HitBox/HurtBox/HealthComponent。
- 主菜单区分新游戏／继续游戏和开发预览。已有存档时，新游戏会先提示覆盖；从菜单进入的章节测试使用隔离存档，回到菜单恢复正式状态。
- 白菜蘑菇屋调查、密码锁、包装纸、桌面机关与橡子回忆，双线道路、黑暗小径、营火平台关和重逢结局已接通。平台关既有 60/60 萤火路线证据；人工难度与趣味性仍待评估。

## 运行

1. 安装 Godot 4.7.2 stable 标准版。
2. 打开 Godot Project Manager，点击 **Import**。
3. 选择本目录中的 `project.godot`。
4. 按 `F5` 运行项目（部分 Mac 需要 `fn + F5`），在主菜单选择“新游戏”。不要用章节快捷入口测试开场。

开场控制：`Esc` / `P` 暂停／继续、`R` 从头重播、`M` 全局静音／恢复、空格下一句；右上角“跳过开场”按钮进入第一幕。变身和传送不会被空格直接略过。单独打开 `scenes/prologue/prologue.tscn` 后按 `F6` 可直接预览开场。

本轮实现说明与验收范围见 [开场预览指南](docs/OPENING_PREVIEW.md)。

三房间试玩、改动清单与缺失素材见 [第一幕接入报告](docs/CHAPTER1_INTEGRATION.md)。建议通过主菜单“开发预览与章节测试 → 白菜三房间调查”隔离试玩；直接 F6 运行正式 `bedroom.tscn` 不属于菜单隔离入口。调查画、杯子等时按 E / 空格 / Esc 收起近景，再继续对白。Esc 菜单可保存返回；保存失败保留当前场景并显示提示。

按键：`WASD` / 方向键移动，`E` 调查（第一幕也支持空格），第二幕自由移动时空格跳跃、对白时空格继续，`J` / `Z` 攻击，第二幕 `Shift` 翻滚、`K` 树枝招架（减伤75%），`F5` 快速保存。

随时按 `F1` 查看当前章节操作或调节声音，`Esc` / `F1` 关闭设置。打开设置会暂停剧情和声音；从暂停菜单进入设置，关闭后仍留在暂停菜单。部分 Mac 需同时按 `fn`。设置文件 `user://piggy_manor_settings.cfg` 与剧情存档分开。

详细的新手步骤见 [`docs/MAC_FIRST_RUN_ZH.md`](docs/MAC_FIRST_RUN_ZH.md)。

## 最终章试玩

F5 后选择“开发预览与章节测试 → 最终章 · 独立预览”，或 F6 运行 `scenes/finale/final_chapter_preview.tscn`。该独立预览不改正式存档。[操作、主线路线及制作缺项](docs/FINAL_CHAPTER_ZH.md) · [当前交接](docs/HANDOFF_2026-10-30_PHASE12.md)。
