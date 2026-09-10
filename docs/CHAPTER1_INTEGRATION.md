# 第一幕《空掉的心》接入报告

> 这是 9 月 8 日的历史接入报告。现行门位、高清道具、点击调查、回忆及光效以 [9 月 10 日交接文档](HANDOFF_2026-09-10.md) 为准；下文旧操作描述不再作为当前验收基线。

2026-09-08。可玩接入版，不是最终动画／美术验收版。用户确认：先接附件已有句子。原资源保留；未提交或推送 Git。

## Mac 试玩步骤

1. 在 Godot 导入 `smallpiggy/project.godot`，等待素材导入结束。
2. 按 F5（部分 Mac 为 fn + F5），选第一幕快捷入口。想连开场看，选“新游戏”。旧“继续”存档若指向历史样板，仍会回旧场景，不会强制改写旧存档。
3. WASD／方向键移动；靠近物件，左侧出现提示后按 E／空格调查。近景按 E 收起；对白按 E 显示完整句子／继续下一句。
4. 卧室：床边查看床头画，结束第一段回忆后走到下方房门。厨房：沿桌子右侧走到咖啡机，做咖啡后调查粉杯，再查看餐桌；也可以先看餐桌。
5. 厨房回忆结束，下方房门菜单选“去客厅”。沿茶几左侧调查抱枕，第三段回忆后回门口看红纸；门口选择出门，切到旧呆呆猪森林样板。
6. 房门菜单可返回前一间。F5 保存；Esc 选择保存并回主菜单。对话、回忆或转场中暂不接受移动与快捷保存。

只看新房间：打开 `scenes/chapter1/bedroom.tscn`，F6 / fn + F6。房间节点由脚本在运行时建立，编辑器未运行的场景树只显示根节点；不需要先手工摆放素材。

## CREATED FILES

- `scenes/chapter1/bedroom.tscn`、`kitchen.tscn`、`living.tscn`：三个独立入口。
- `scenes/chapter1/chapter_room.gd`：房间生命周期、调查流程、回忆、剧情门槛。
- `scenes/chapter1/room_layout.gd`：原图坐标下的背景、碰撞、局部遮挡、热点、出生点。
- `scenes/chapter1/chapter_presentation.gd`：固定屏幕心心、近景、房门选择、淡入和闪白。
- `scenes/chapter1/memory_soften.gdshader`：三段递进模糊，避免完整清晰脸部。
- `actors/shared/sprite_atlas.gd`：透明边界一次性缓存、原生 AtlasTexture 切帧。
- `data/dialogue/chapter1.json`：附件中已有句子；未补写缺失剧情。
- `tests/chapter1_test.gd`、`chapter1_navigation_test.gd`、`chapter1_ui_test.gd`、`chapter1_visual_check.gd`。
- `assets/chapter1/` 原素材副本；`assets/prologue/joy_soft.png`、`joy_burst.png`。

## MODIFIED FILES

- `actors/shared/player_controller.gd`、`player.tscn`：位移步态、脚底对齐、原生剧情步行、物理相机回调。保持原战斗角色兼容。
- `project.godot`：2D 物理插值。
- `autoload/game_state.gd`：心心字段、信号、幂等推进及存档序列化。
- `scenes/prologue/story_effects.gd`：快乐粒子02／爆发接入包装礼物镜头，沿用开场时钟，暂停和重播同步。
- `scenes/prologue/opening.gd`、`scenes/bootstrap/bootstrap.gd`、`tests/opening_test.gd`：第一幕路由改为新卧室。
- README、AGENTS、WORKLOG、故事方向和开场说明。

## SCENES / AUTOLOAD

卧室、厨房、客厅路径如上。UI 由 `ChapterPresentation` 与现有 `systems/dialogue/dialogue_ui.tscn` 组合。回忆节点为每个房间运行时的 `MemoryShadow`；转场继续用 `autoload/scene_router.gd`，没有重复造新系统。Autoload 仍是 GameState、SceneRouter、SaveManager。

没有新建 ManorExterior：用户确定离家切呆呆猪，实际目标为 `scenes/chapter_02_dark_forest/forest_clearing.tscn`。这里只连接旧样板，不声称完整双线、森林、碎片任务或结局已经完成。

## GAME STATE

- 新字段 `heart_progress`（0～3），新信号 `heart_changed`；UI 只使用九格图中的前四格，无数字或含义说明。
- 新 flags：`ch1_opening_done`、`big_idea_checked`、`bedroom_memory_complete`、`bedroom_exit_intro_done`、`coffee_made`、`pig_cup_checked`、`double_tableware_checked`、`kitchen_memory_complete`、`pig_pillow_checked`、`living_room_memory_complete`、`first_clear_flashback`、`red_paper_spawned`、`red_paper_checked`、`ch1_can_leave_home`、`ch1_completed`。
- 心心每段回忆只增加一次；普通物件不增加。保存沿用原格式并增加可选字段，旧存档没有该字段时默认 0。读档回房门安全点，不保存半段演出或精确脚位。

## INTERACTABLES

运行时热点均为复用的 Interactable / Area2D，位于房间根节点下。角色是 `Depth/Player`，家具按脚底高度排序。

| 房间 | 实际节点 / interaction_id |
| --- | --- |
| Bedroom | Painting / painting；Door / door |
| Kitchen | Coffee / coffee；Cup / cup；Tableware / tableware；Door / door |
| LivingRoom | Pillow / pillow；Blanket / blanket；Basket / basket；Window / window；Paper / paper；Door / door |

红纸图像为 `LivingRoom/Depth/RedWrappingPaper`，调查区为同房间的 `Paper`。图像从世界坐标门外滑入，停稳后调查区开启；不是屏幕 UI 假纸片。

## ANIMATIONS

- 开场：快乐粒子持续轻浮，最后一句快乐台词时爆发；原故事和礼物传送顺序不改。
- Walk：每方向原三姿势按 `0 → 1 → 2 → 1` 使用；连续位移相位取代“累计时间 × 当前速度”；不再整个人上下漂浮，脚底固定，空闲轻呼吸。
- Wake：原三格起床近景、黑场淡入、回到床边；不是连续下床／穿鞋动画，见缺口。
- Heart：小幅 1.07 倍脉冲与变亮，三次幂等变化。
- Memory 01/02/03：原素材模糊、透明淡入、漂移、轻微镜头推进和闪白；第三段对白放屏幕上方，避免挡住门口影子。
- Coffee：原三帧蒸汽；角色沿柜前通道走向杯子、转向，不用瞬移。
- Paper：世界坐标 1.6 秒减速滑入、轻旋转。
- Scene Fade：复用 SceneRouter。房间互返不重复起床或增加心心。

## USED ASSETS

`bigidea/01_cabbage/` 的卧室／厨房／客厅 BG、男孩表、起床表、Heart UI 0～8、Memory Pig Shadow 01～03、Coffee steam animation、RedWrappingPaper sprite、PigCup、DoubleTableware、PigPillow；`bigidea_after.png` 使用已有原稿副本。快乐粒子源为 `bigidea/快乐粒子02.png` 和 `bigidea/快乐粒子爆发.png`。

三张 FG 也复制保留，但没有直接全图叠入：与 BG 家具位置不完全一致。当前遮挡采用背景原坐标局部纹理，避免双重家具。带文字的热点／碰撞指导图仅作布局参考，不作游戏贴图。

## MISSING ASSETS / 尚未完成

- 完整 BIG IDEA 初次／重复对白、完整餐具对白、部分回忆后续对白、窗边／毯子／篮子环境对白没有提供。按用户回复不补写：有图先看图，已有句子照用。
- Morning_Birds、Heart_Weak、Memory_Shimmer、Coffee_Machine、Soft_Magic_Wind、Paper_Slide、Door_Open 等音频未找到，尚未接入。现有开场合成警报音保留，不能视为第一幕音频完成。
- 男孩和心心原图仍含像素轮廓。缩小、线性采样、暖色调和投影只改善融合，不等于最终手绘重画；角色每方向仅三姿势，仍缺更细的步态、自然转身、伸手、连续下床动画。
- 起床图自带绿色床铺，与蓝色卧室床不一致。暂用独立近景避免第二张床叠在背景上；后续应补匹配床铺／独立角色的起床素材。
- Memory 03 原图是挥手离开，不是穿鞋逐帧动画；当前只做模糊离开意象。
- 前景最终分层仍需逐物件配准；当前只对主要床尾／餐桌／茶几提供局部遮挡，不是所有植物家具的精细遮罩。
- 普通场景环境声音、窗影、薄雾等未全面制作；不把现状称为最终精修。

## MANUAL ADJUSTMENTS

试玩前无需用户手工配置。已校准出生点、脚底碰撞、主要家具和关键热点路线。若后续换素材，位置与碰撞在 `room_layout.gd` 的 DATA 调整；角色高度／速度在 `chapter_room.gd`，粒子透明度在 `story_effects.gd`。最终 FG 对齐、角色补帧、音量和平衡仍是后续制作工作，不要求新手自行修好才能运行。

## 验证

- `CHAPTER1_TEST_OK`：首次起床、三次心心、调查前置、重复调查幂等、纸片／离家条件、状态序列化、行走三姿势／脚底、桌子碰撞与离家切猪。
- `CHAPTER1_NAVIGATION_OK`：真实物理走路绕家具，关键线索与房门均能到达并出现正确提示。
- `CHAPTER1_UI_OK`：实际 E 键事件收起近景、推进对白，完成后恢复移动，不靠测试模式跳过交互。
- `OPENING_TEST_OK`、`SMOKE_TEST_OK`、`GAMEPLAY_TEST_OK`：开场路由与旧移动／战斗／早餐样板回归。
- Apple M1 实际渲染截图：三房间、画近景、门口回忆、开场快乐粒子。最终一次正常速度行走 8 秒采样：963 帧，中位 8.03 ms，P95 13.26 ms，最大 14.31 ms；是该机器该段采样，不代表所有场景或主观动画质量。
- 截图目录：Godot `user://chapter1_review`。视觉检查不能证明源图已成为完整手绘动画。

复跑（Godot 命令行）：`godot --headless --path . --script tests/chapter1_test.gd`；其余 headless 测试替换脚本名。视觉测试必须去掉 `--headless` 并用 `tests/chapter1_visual_check.gd`。
