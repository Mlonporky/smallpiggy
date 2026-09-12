# 2026-09-10 交接：第二幕小呆猪森林线

当前第二幕已实现至第一块礼物碎片，可试玩；不是整部游戏或完整森林章节完成。本文取代旧交接中“第二幕尚未实现／仍是旧样板”的描述。第一幕细节继续参考 [第一幕交接](HANDOFF_2026-09-10.md)，第二幕详细说明见 [实现说明](CHAPTER2_IMPLEMENTATION_ZH.md)。

> 2026-09-11 更新：小树枝已从山洞入口移到森林入口苏醒处，捡起时有两句台词；巫师离开且已拿树枝才开北路，山洞不再有树枝和武器门槛。下文“山洞拾棍”“未拾棍门槛”等描述是本交接当时的状态，现行做法以实现说明和 WORKLOG 为准。

## 用户确认与保护范围

- 本轮明确做「入口剧情＋木棍／史莱姆战斗」。附件中的“不做战斗”是原入口任务范围，用户已明确扩展，不要按旧范围删掉战斗。
- 小呆猪在第二幕开始前已被巫师传送到森林另一端。本幕从倒地苏醒开始，不重新播放传送。
- 新sprite由围巾换成红披风，仅第二幕更新。序章、第一幕及用户保存的回忆位置／缩放未改，继续保留。
- 小呆猪是女生，始终记得白菜，找的是礼物碎片；没有失忆恢复或共鸣收集系统。巫师仅受Joy冲击后离开，不在本幕被击败。
- 没有新增全局系统，没有重绘02_pig素材，没有制作山庄汇合／结局。

## 当前流程与试玩

F5运行项目 → 菜单「小呆猪篇 · 森林史莱姆」；也可完成第一幕，从客厅出门自然衔接。

已被传送后的苏醒 → 红纸调查 → 巫师揭示白菜失忆 → 两段残影 → 小呆猪决定回去 → Joy影响巫师 → 巫师离开、道路开放 → 向北主动迈步与章节标题 → 山洞拾棍 → 史莱姆战斗 → 拾取红色礼物碎片。

WASD／方向键移动，E／空格调查或推进对白；红纸、木棍及掉落碎片也可靠近点击。J／Z攻击。山洞未拿木棍时不能进入战斗区；史莱姆蓄力后冲撞，玩家可侧移躲开。死亡自动回山洞入口，恢复生命并保留木棍；Esc打开暂停菜单（场景停住），可保存并回主菜单（2026-09-11 起）。

章节快捷入口会重置GameState。继续已有进度应使用菜单「继续」，不要把快捷入口重置误判成存档丢失。

## 主要文件

| 文件 | 当前用途 |
| --- | --- |
| `scenes/chapter_02_dark_forest/forest_clearing.tscn` | 保留第一幕与菜单使用的路由地址，现承载新入口 |
| `scenes/chapter_02_dark_forest/legacy_forest_sample.tscn` | 原森林战斗样板的完整副本；旧forest_clearing.gd未改 |
| `scenes/chapter2/entrance.gd` | 苏醒、红纸、巫师、残影、Joy、入口阻挡、后退提示、标题与切场 |
| `scenes/chapter2/cave.tscn`、`cave.gd` | 拾棍门槛、战斗、碎片、死亡重试 |
| `scenes/chapter2/forest_base.gd` | 新场景的背景、相机、碰撞、热点、UI装配与输入锁 |
| `scenes/chapter2/pig.gd` | PiggyPlayer局部子类：披风／持棍切帧、六姿势苏醒、临时挥棍表现 |
| `scenes/chapter2/slime.gd` | ForestSlime局部子类：新版史莱姆画面，沿用原战斗逻辑 |
| `assets/chapter2/atlas.json`、`dialogue.json` | 显式切帧边界、按附件分段提取的入口对白 |

新场景的地图、角色与UI主要在运行时装配；打开空的场景根节点不代表内容丢失。调整地图布局需查看对应脚本。

复用GameState、SaveManager、SceneRouter、DialogueUI、GameUI、Interactable以及既有移动、生命、HitBox／HurtBox。不要再创建第二套这些系统。

## 资产与切帧

02_pig七张PNG已原样复制，SHA-256一致：披风→cape、苏醒→wake、拿木棍→armed、木棍→stick、变异史莱姆→slime、苏醒场景→entrance、战斗山洞→cave。巫师复用01_cabbage/巫师.png，掉落碎片复用已有高清原图。

披风源表含右侧方向文字与底部表情，不能整图均分。atlas.json已排除这些区域，方向按角色实际朝向映射。保持每套素材固定缩放与脚底对齐，不按每帧高度重新缩放。序章角色与第一幕男孩的切帧方案不受本轮影响。

当前地图只开放森林中央空地／上方通路和山洞入口／中央战斗区；岩石有碰撞，未开放所有支路，也没有新拆前景遮挡层。

## 状态与存档

沿用GameState.flags：

- `s2_pig_wakeup_complete`：苏醒结束。
- `red_wrapping_paper_examined`、`s2_pig_wizard_scene_started`：红纸首次调查与巫师段开始。
- `s2_pig_wizard_complete`：巫师离开，道路开放。
- `forest_backtrack_hint_shown`：后退提示只出现一次。
- `s2_pig_intro_complete`、`heart_ui_unlocked`：入口结尾完成及Heart接口解锁。
- `s2_pig_stick_collected`：持棍状态，死亡保留。
- `forest_slime_defeated`：拾取胜利碎片后写入完成标记。

碎片沿用`fragment_red_wrap_01`，重复拾取不累加。巫师段中途退出后会从该段开头恢复，已完成段落不重播。击败史莱姆但未拾取碎片不是持久完成点。

Heart仅写解锁flag，不能清空第一幕0–3进度；尚无新的0–8收集UI。战斗显示的3点生命不是Heart收集进度。

## 验证结果与复现

已通过：

- `chapter2_test.gd`：完整入口、输入锁、真实道路阻挡、重复调查、序列化恢复、真实出口与SceneRouter切场、未拾棍门槛、真实攻击、碎片去重、完成状态恢复、死亡后恢复生命并保留木棍／剧情。
- `chapter2_combat_test.gd`：真实HitBox每击扣一点生命，死亡淡出结束后开放碎片。
- `smoke_test.gd`、`chapter1_exit_routing_test.gd`、`gameplay_test.gd`：场景加载、第一幕真实出门衔接及既有玩法回归。
- `chapter2_visual_check.gd`：Apple M1真实渲染，检查森林、巫师、披风四方向、山洞和持棍；正常时间运动采样p50约5.44ms、p95约13.74ms。这不等于完整人工动态动画验收。
- Git diff --check通过；未使用用户实际存档作测试数据。

本机Godot 4.7.2临时路径：`/private/tmp/godot-4.7.2-check/Godot.app/Contents/MacOS/Godot`。示例（项目根目录运行）：

```sh
/private/tmp/godot-4.7.2-check/Godot.app/Contents/MacOS/Godot --headless --path . --log-file /tmp/pig-flow-engine.log --script tests/chapter2_test.gd
```

图形验证去掉`--headless`并改用`tests/chapter2_visual_check.gd`；macOS沙箱可能需要图形运行权限。测试日志／截图在`/private/tmp/pig-*.log`和`/private/tmp/pig-*.png`，均为临时文件。headless沙箱曾有macOS系统证书读取提示；实机图形运行无此提示，最终没有新场景脚本错误。

测试注意：史莱姆生命归零后还有死亡淡出，`defeated`信号在淡出结束才发出。不要用过短固定延迟断言掉落已开放。固定命中测试锁住区域触发避免意外启动AI，但仍使用真实HitBox。

## 未完成与后续建议

已知缺项，不能误报为已制作：

- 音频未提供，当前第二幕无声，只有ForestAmbient接口。
- Joy／紫雾沿用现有占位粒子。曾发现把整张Joy效果图当单颗粒子会形成方块，现已改为单颗星光；不要恢复整图方案。
- 精确的“男孩看猪杯”“藏礼物”残影图缺失，暂用卧室男孩图和既有回忆图只读展示，对白按附件保留。
- 无专用挥棍攻击表，暂用持棍姿势旋转／缩放；苏醒为提供的六姿势，非新绘制连续动画。
- 可选入口停留提示未做；后续碎片、山庄汇合与结局未做。
- 冰箱探索仍未做，但用户本轮已选择先推进第二幕，不应自行回头插入冰箱工作。

建议下一轮先让用户试玩，按反馈调整比例、碰撞、战斗节奏与镜头；再根据素材补音频、精确残影和攻击动作。后续剧情范围需以用户新指令为准。不要顺带改动第一幕或推倒现有系统。

## Git与交接状态

第二幕代码、素材和本轮文档目前都在工作区，尚未提交／推送。此前第一幕提交授权不等于本轮自动推送授权。开始下一轮先检查git status，保留所有现有改动。
