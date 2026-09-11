# 猪猪山庄——被遗忘的快乐——

Godot 4.7.2 / GDScript / 2D 叙事冒险。当前版本实现规格中定义的首批“双角色玩法样板”。

## 已实现

最新交接见 [第二幕 handoff](docs/HANDOFF_2026-09-10_ACT2.md)：已接入森林入口剧情、拾棍、史莱姆战斗与第一块礼物碎片。第一幕细节见 [第一幕 handoff](docs/HANDOFF_2026-09-10.md)。

最新设定与美术重制方向见 [方向文档](docs/STORY_AND_ART_DIRECTION.md)，协作约定见 [AGENTS.md](AGENTS.md)，进度见 [WORKLOG.md](WORKLOG.md)。序章为约 89 秒的手绘分镜版；第一幕已接入三间手绘房间，离家后切到呆呆猪的新森林入口，再进入山洞战斗。没有终极 Boss 战；最终巫师死于白菜认出呆呆猪时爆发的快乐能量。

- 可播放的手绘序章：城堡警报 → 水晶球锁定呆呆猪 → 蘑菇屋包装礼物 → 巫师降咒 → 卧室中白菜变回小男孩、BIG IDEA 画由 before 变 after → 小猪和礼物一起被卷走 → 巫师撕碎礼物、碎片散落 → 第一幕。包含镜头推近、粒子、局部溶解、提示音和字幕；尚非逐帧角色动画。
- 白白菜：卧室起床近景、调查原版 BIG IDEA after 画、厨房咖啡与猪猪杯／双人餐具、客厅抱枕、三段模糊回忆、三次心心变化、红纸入场与离家。只接附件已有句子，缺失定稿对白留空。旧复原早餐位玩法保留为历史样板，不再作为主入口。
- 人物按实际位移推进三姿势步态，脚底对齐、物理插值、脚底碰撞、家具局部遮挡；并非新增完整手绘角色动画。
- 小呆猪：森林探索、3 点生命、近战攻击、史莱姆前摇与跳扑、拾取第一块礼物碎片。
- 三个 Autoload：`GameState`、`SceneRouter`、`SaveManager`。
- 数据化对白、统一 Interactable、可复用 HitBox/HurtBox/HealthComponent。
- Debug Start 主菜单，方便直接测试两个 slice。

## 运行

1. 安装 Godot 4.7.2 stable 标准版。
2. 打开 Godot Project Manager，点击 **Import**。
3. 选择本目录中的 `project.godot`。
4. 按 `F5` 运行项目（部分 Mac 需要 `fn + F5`），在主菜单选择“新游戏”。不要用章节快捷入口测试开场。

开场控制：`P` 暂停／继续、`R` 从头重播、`M` 静音／恢复、空格下一句、`Esc` 跳到第一幕。变身和传送不会被空格直接略过。单独打开 `scenes/prologue/prologue.tscn` 后按 `F6` 可直接预览开场。

本轮实现说明与验收范围见 [开场预览指南](docs/OPENING_PREVIEW.md)。

三房间试玩、改动清单与缺失素材见 [第一幕接入报告](docs/CHAPTER1_INTEGRATION.md)。可在主菜单选择第一幕快捷入口，或打开 `scenes/chapter1/bedroom.tscn` 按 F6（部分 Mac 用 fn + F6）。调查画、杯子等时按 E 收起近景，再继续对白。房门菜单可返回前一间；Esc 可选择保存并返回主菜单。

按键：`WASD` / 方向键移动，`E` / 空格调查，`J` / `Z` 攻击，`F5` 快速保存。

详细的新手步骤见 [`docs/MAC_FIRST_RUN_ZH.md`](docs/MAC_FIRST_RUN_ZH.md)。
