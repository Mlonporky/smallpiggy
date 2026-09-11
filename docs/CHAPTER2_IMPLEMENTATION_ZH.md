# 第二幕 · 小呆猪森林线

本轮范围由用户确认：入口剧情＋拾取木棍＋史莱姆战斗。附件内“本次不做战斗”是原入口规格的范围说明，本轮以用户明确回复为准。

## 试玩

1. 在 Godot 打开项目，按 F5。
2. 菜单选择「小呆猪篇 · 森林史莱姆」，从第二幕开场开始；或完成第一幕客厅出门，自动接入。
3. WASD／方向键移动；E／空格阅读和调查，也可靠近后点击红纸或木棍。
4. 巫师离开后向画面上方走；山洞入口先拾取木棍，J／Z攻击，移动躲开史莱姆蓄力冲撞。失败后自动回山洞入口，保留木棍。
5. 击败史莱姆后拾取红色碎片，自动保存；Esc回菜单。此版本完成至第一块碎片，尚未制作山庄汇合与结局。

## 场景与复用

- `scenes/chapter_02_dark_forest/forest_clearing.tscn` 保留原路由地址，现承载新入口。原战斗样板完整保存在同目录 `legacy_forest_sample.tscn`，旧脚本不改。
- `scenes/chapter2/entrance.gd`：已被传送后的苏醒、红纸、巫师、两段残影、Joy、后退提示、正式迈步、标题与切场。
- `scenes/chapter2/cave.tscn` / `cave.gd`：木棍、战斗区域、史莱姆、碎片、失败重试。
- `forest_base.gd` 只为新场景装配呈现与地图，复用 PiggyPlayer、DialogueUI、GameUI、Interactable、SceneRouter、SaveManager、GameState，没有新增Autoload。
- `pig.gd` / `slime.gd` 是第二幕局部子类，保留已有移动、碰撞、生命、受击与攻击判定。没有替换序章／第一幕角色。

## 素材与边界

02_pig七张PNG原样复制到assets/chapter2；巫师复用01_cabbage/巫师.png；礼物碎片复用已有高清原图。没有重绘背景。atlas.json用显式边界排除披风表中的文字与底部表情区；方向按实际画面映射，不盲信源图文字标签。使用每套素材固定缩放与脚底对齐，不逐帧改变角色体积。

森林地形限制在中央空地及上方通路；山洞限制在入口和中央战斗区，岩石岛有碰撞，未开放全部支路。背景没有额外前景拆层，二维脚底排序和原图构图提供当前纵深。

持久状态全部存入现有flags：s2_pig_wakeup_complete、red_wrapping_paper_examined、s2_pig_wizard_scene_started、s2_pig_wizard_complete、forest_backtrack_hint_shown、s2_pig_intro_complete、heart_ui_unlocked、s2_pig_stick_collected、forest_slime_defeated。中断巫师剧情重进时从巫师段重新开始；完成的段落不重播。碎片沿用fragment_red_wrap_01，重复拾取不累加。

Heart仅写入解锁接口：现有第一幕是0–3进度，第二幕不会清空它，也不创建一套0–8收集系统。战斗显示的是3点生命，小呆猪没有记忆恢复／共鸣收集系统。

## 已知素材缺项

- 未提供森林风声、树枝声、冲击声：保留ForestAmbient节点，当前无声。
- Joy与紫雾复用现有占位粒子；小／大／爆发用不同规模分层，不再把整张效果图当作一颗粒子。
- 精确的“男孩看猪杯”和“背后藏礼物”残影素材缺失，分别复用卧室男孩图和现有回忆图，只读展示、不修改第一幕状态。对白按附件保留。
- 没有专用攻击动作表：持木棍行走使用新表，攻击暂用持棍姿势的预备、挥动与回收旋转／缩放。苏醒使用所附六姿势；不是新绘制的连续动画。
- 可选的入口停留提示未做；山庄汇合、后续碎片、结局未纳入本轮。

## 验证

Godot 4.7.2。`tests/chapter2_test.gd`覆盖入口输入锁、真实道路阻挡、完整对白推进、巫师离场、重复调查、状态序列化恢复、真实出口触发与SceneRouter切场、木棍门槛、真实HitBox三击战胜史莱姆、碎片去重、已完成状态恢复与失败重试。

`tests/chapter2_visual_check.gd`在Apple M1实际渲染，输出森林、巫师、披风四方向、山洞和持棍截图，并以正常时间推进四方向运动记录帧间隔。截图检查不等于完整人工动画验收。

测试禁用新场景自动存档；不使用用户实际存档作测试数据。测试输出在/private/tmp/pig-*.log与/private/tmp/pig-*.png。
