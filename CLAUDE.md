# CLAUDE.md — 猪猪山庄（Piggy Manor）项目指引

本文件是 Claude Code 在本仓库工作的入口说明。`AGENTS.md` 的协作约定已完整复制在下方「项目协作约定」一节；两处内容必须保持一致，修改其中一处时同步另一处。

## 与我的沟通方式

- 主要用中文与我交流；专业术语以及我在对话中使用的英文（如 sprite、atlas、autoload、handoff、flag）保持原样，不要翻译成中文。
- 我是 Mac 开发新手：需要我操作时，给出短小、可直接照做的步骤，并说明按键或菜单位置。
- 报告结果时先说结论，明确区分「已实现」「计划中」「待我确认」，不要把测试通过说成美术验收通过。

## 项目概览

- 游戏：《猪猪山庄——被遗忘的快乐——》，Godot **4.7.2 stable 标准版**、GDScript 2.0、2D 叙事冒险，斜俯视 2.5D 观感，温暖手绘童话风。
- 主角：小呆猪（LittlePig，女生）、白白菜（WhiteCabbage，小男孩）、坏巫师（EvilWizard）。故事设定见下方协作约定与 `docs/STORY_AND_ART_DIRECTION.md`。
- 主场景：`scenes/bootstrap/main.tscn`（Debug Start 菜单）。序章入口 `scenes/prologue/prologue.tscn`；第一幕现行入口 `scenes/chapter1/bedroom.tscn`；第二幕入口 `scenes/chapter_02_dark_forest/forest_clearing.tscn`（路由地址保留，内部已换成新入口）。
- 截至 2026-09-10 的进度：序章手绘分镜可播放；第一幕卧室／厨房／客厅调查、三次回忆、离家切小呆猪已完成；第二幕森林入口、拾棍、史莱姆战斗、第一块礼物碎片已完成。尚未做：厨房冰箱探索、白白菜蘑菇屋探索与包装纸拼图（`bigidea/03_cabbage`）、后续碎片、山庄汇合、结局、全部音频。以最新 handoff 为准，不要凭本段推断。

## 目录地图

| 路径 | 内容 |
| --- | --- |
| `autoload/` | 三个 Autoload：`GameState`（story_phase、flags、gift_fragments、heart_progress）、`SceneRouter`（带淡入淡出的切场）、`SaveManager`。不要新增 Autoload。 |
| `scenes/prologue/` | 序章：`opening.gd` 是现行控制器，数据 `data/dialogue/opening_v2.json`；`prologue.gd` 是保留的旧控制器。 |
| `scenes/chapter1/` | 第一幕三房间：`room_layout.gd`（背景、碰撞、热点、出口）、`chapter_room.gd`（调查、剧情门槛、回忆）、`room_exits.gd`、`chapter_presentation.gd`（对白、近景）、`exploration_light.gd/.gdshader`（环境暗幕与物品标记）。 |
| `scenes/chapter2/` | 第二幕：`entrance.gd`（苏醒、拾树枝、红纸、巫师）、`forest_path.gd`（林间小路、发现洞口）、`cave.gd`（40%技能、战斗、碎片、重试）、`combat_fx.gd`（弧光、粒子、合成音效）、`forest_base.gd`（地图与 UI）、`pig.gd`／`slime.gd`（跳跃、挥击、扑击）。地图与角色多在运行时装配，场景树为空不代表内容丢失。 |
| `scenes/chapter_01_hollow_heart/`、`scenes/chapter_02_dark_forest/` | 历史样板。`legacy_forest_sample.tscn` 是旧森林战斗完整副本；新工作不要误改旧样板并宣称主入口生效。 |
| `actors/` | `player_controller.gd`（共享移动、三姿势步态）、`sprite_atlas.gd`（显式行边界切帧）、`forest_slime.gd`。 |
| `systems/` | `dialogue/`（DialogueUI）、`interaction/`（Interactable、PropInteractable、StoryTrigger2D）、`combat/`（HitBox2D、HurtBox2D、HealthComponent）、`vfx/`、`puzzles/`。 |
| `ui/` | `GameUI`：目标、生命、Heart 显示。 |
| `data/dialogue/` | JSON 对白。现行：`chapter1.json`、`opening_v2.json`、`assets/chapter2/dialogue.json`；`chapter_01.json`／`chapter_02.json`／`prologue.json` 属旧样板。 |
| `assets/` | 已接入的图片，按 `prologue/`、`chapter1/`、`chapter2/`、`backgrounds/`、`sprites/` 分目录；`.import` 文件随图片一起提交。 |
| `tests/` | 以 `extends SceneTree` 编写的测试脚本，见下文「验证」。 |
| `tools/` | 美术生成脚本：`monster_art/make_svgs.py`（怪物矢量源，目录带 `.gdignore`）→ `render_monster_art.gd`（转成 `assets/chapter2/monsters/*.png`）。 |
| `docs/` | 方向文档、handoff、实现说明、`art_direction/`（生成图与完整提示词）、`master_spec_v3_2d.md`（历史主规格原文）。 |

## 素材仓 bigidea

素材仓在同一父目录下的另一个文件夹：`/Users/missdaidai/codex/bigidea`（与本仓库 `smallpiggy` 并列）。它不是 Git 仓库的一部分，也不在本项目 `res://` 内。

- `01_cabbage/`：第一幕素材（三房间 BG／FG、碰撞与热点参考图、男孩／小呆猪／巫师／白菜角色表、Heart UI、回忆影子、猪杯、餐具等）以及 `Godot_实现规格_第一幕_空掉的心.md`。
- `02_pig/`：第二幕素材（披风、苏醒、拿木棍、木棍、变异史莱姆、苏醒场景、战斗山洞七张 PNG）以及第二幕小呆猪线的 Codex 实现文本。
- `03_cabbage/`：白白菜线「蘑菇屋探索／包装纸拼图／橡子暗格」实现文本，尚未实施。
- 根目录：`bigidea_before.png`／`bigidea_after.png`（BIG IDEA 画原稿，直接使用不重生成）、蘑菇屋、mainvilla、kitchen／livingroom 及其 collisionplan／hotspot 图、水晶球、心脏动画、快乐粒子、模糊猪影等原图；`CODEX_START_HERE_PiggyManor_Godot_v3_2D.md` 与 `PiggyManor_Godot_Fresh_Project_Master_Spec_v3_2D.md` 内容相同，且与本仓库 `docs/master_spec_v3_2d.md` 相同。

使用规则：

- 只读取，不修改、移动或删除 bigidea 内任何文件。用户可能随时往里追加新素材，开工时先看有没有新文件。
- 需要用的素材原样复制到本仓库 `assets/` 对应章节目录，用英文小写 `snake_case` 重命名；复制后核对 SHA-256，并在 WORKLOG 或 handoff 里记录来源文件名与映射。
- 不重绘、不裁切原稿代替用户给的图；确需局部改图时保留原图，把参考图与完整提示词放到 `docs/art_direction/`。
- bigidea 里的文件名含中文、空格和 `%20`，在 shell 中一律加引号。
- 素材附带的实现文本是历史规格；与用户最新指示冲突时以用户为准，并在方向文档中记录。

## 运行与验证

本机 Godot：`/Users/missdaidai/Godot.app/Contents/MacOS/Godot`（已核对为 4.7.2.stable.official）。旧文档提到的 `/private/tmp/godot-4.7.2-check/...` 是临时路径，不是项目依赖。

在项目根目录运行逻辑测试（headless）：

```bash
/Users/missdaidai/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/smoke_test.gd
```

- 测试脚本以 `extends SceneTree` 编写，成功时打印 `XXX_OK` 并 `quit(0)`，失败时 `push_error` 并 `quit(1)`。改动后至少跑对应章节测试与 `smoke_test.gd`、`gameplay_test.gd`。
- 常用逻辑测试：`smoke_test`、`gameplay_test`、`opening_test`、`chapter1_test`、`chapter1_navigation_test`、`chapter1_ui_test`、`chapter1_exit_routing_test`、`chapter1_bottom_exit_test`、`chapter1_prop_click_test`、`chapter1_polish_test`、`memory_anchor_test`、`boy_atlas_test`、`chapter2_test`、`chapter2_combat_test`、`chapter2_pause_menu_test`、`save_manager_test`。
- `*_visual_check.gd` 是实机渲染检查，必须去掉 `--headless`，截图与日志写到 `/private/tmp/pig-*.png`、`/private/tmp/pig-*.log` 等临时位置；macOS 沙箱可能需要图形权限。
- 提交前跑 `git diff --check`。
- 用编辑器试玩：Project Manager → Import 选 `project.godot` → F5（部分 Mac 用 fn + F5）。主菜单可直接进序章、第一幕、第二幕；章节快捷入口会重置 GameState，继续进度用「继续」。
- 按键：`WASD`／方向键移动，`E` 调查；第一幕空格也可调查，第二幕自由移动时空格跳跃、对白时空格继续；`J`／`Z` 攻击，第二幕 `Shift` 翻滚、`K` 树枝招架（减伤75%），`F5` 快速保存，`Esc` 暂停（可保存并回主菜单）；序章 `P` 暂停、`R` 重播、`M` 静音。

## 代码约定

- GDScript 2.0，Tab 缩进，尽量使用类型标注（`var x: int`、`-> void`），信号与节点用 `@onready`／`%UniqueName`。
- 文件名英文小写 `snake_case`；UTF-8、LF；剧情文本内部可用中文。`.uid`、`.import` 文件一并提交，`.godot/` 忽略。
- 复用现有系统：GameState.flags 存状态、SaveManager 存档、SceneRouter 切场、DialogueUI 对白、Interactable 交互、HitBox／HurtBox／HealthComponent 战斗。不要为新章节再建第二套。
- 缺失素材时可以占位，但代码里写明 `# TODO: Missing asset`，报告中列出。
- 角色表切帧用显式边界（见 `sprite_atlas.gd`、`assets/chapter2/atlas.json`），不按整图均分；每套素材固定缩放并对齐脚底。
- 场景里由用户手动保存的位置（如三房间 `MemoryAnchor` 的 position／scale／modulate）是权威来源，脚本不得写死覆盖。
- 通过 Godot 编辑器 UI 修改 `project.godot`，避免手写 Input Map。

## 文档阅读顺序

1. 本文件与 `AGENTS.md`。
2. `WORKLOG.md` 最近几条记录。
3. `docs/STORY_AND_ART_DIRECTION.md`（最新设定，优先于历史主规格）。
4. 最新 handoff：`docs/HANDOFF_2026-09-10_ACT2.md`、`docs/HANDOFF_2026-09-10.md`。
5. 按任务再读 `docs/CHAPTER1_INTEGRATION.md`、`docs/CHAPTER2_IMPLEMENTATION_ZH.md`、`docs/OPENING_PREVIEW.md`，以及 bigidea 内对应章节的实现文本。

## Git

- 远端 `origin` 为 `git@github.com:Mlonporky/smallpiggy.git`，主分支 `main`。
- 只在用户明确要求时 commit／push；一次授权不延续到下一轮。不改全局 Git 配置，不自动创建子代理。
- 开工先 `git status`，保留用户现有改动。工作区可能长期有未提交内容，这是正常状态。

---

# 项目协作约定

以下内容与 `AGENTS.md` 完全一致。

## 开工与交接

- 工作范围为本仓库。修改前检查 Git 状态，保留用户现有改动。
- 开工阅读本文件、`WORKLOG.md` 的最近记录及 `docs/STORY_AND_ART_DIRECTION.md`。
- 每次完成有实质改动的工作后更新 `WORKLOG.md`：用户要求、已改内容、验证证据、未解决问题、下一步。区分已实现、计划与待确认。
- 用户最新明确设定优先于历史规格。历史主规格保留原文，冲突以方向文档中记录的最新设定为准。
- 第一幕现行入口为 `scenes/chapter1/bedroom.tscn`，厨房／客厅同目录；旧 `chapter_01_hollow_heart` 是保留的历史样板。新工作不要误改旧样板并宣称主入口生效。
- 第一幕只使用附件已有对白；用户已确认缺失的“完整定稿对白”暂不补写。离家切呆呆猪，仍优先于附件的山庄外景建议。
- 不自动创建子代理，不自动推送远端或修改全局 Git 配置。

## 不可混淆的故事设定

- 白白菜本来是小男孩。感受到呆呆猪、幸福快乐时，他才会变成白菜形态。
- 诅咒使白白菜忘记呆呆猪、失去这份情绪连接，因此从白菜形态恢复小男孩形态；不是诅咒把人变成白菜。
- 呆呆猪是女生，始终记得白白菜。她被传送离开，不拥有失忆恢复或共鸣收集系统。
- 最新开场顺序：城堡 → 水晶球警报 → 巫师查看并锁定呆呆猪 → 蘑菇屋包装礼物 → 巫师前来降咒 → 白白菜从白菜变成小男孩 → 呆呆猪和礼物一起被卷走 → 巫师撕碎礼物、碎片散落。此条取代早先“包装礼物先开场”的要求。
- BIG IDEA 画直接使用用户提供的 bigidea_before.png / bigidea_after.png：白菜形态时用 before，诅咒生效后用 after，不用重新生成的图替代原稿。
- 小呆猪后续寻找的是被巫师撕碎的礼物碎片；礼物不能留在蘑菇屋桌上。多肉、工具和未使用的包装纸不是礼物。
- 白白菜在 mainvilla，开场不先给他镜头；后续可在 bedroom 的床上呈现他睡着的状态。具体镜头节奏尚待设计。
- 蘑菇屋包装礼物方向图桌上的绿色植物是多肉，用户明确要求保留；不是白白菜。
- 主线结构：共同开场 → 白菜以空心小男孩调查家里 → 调查结束、决定出门时切换到呆呆猪 → 她进入森林冒险、击败史莱姆 → 返回猪猪山庄与白菜汇合 → 结束剧情。
- 不制作终极 Boss 战。巫师死于白菜认出呆呆猪时爆发的巨大快乐能量，而不是玩家战斗击杀。先做开场，再实施双线任务。

## 美术与动画基线

- 用户已接受温暖手绘童话风，高清呈现、2.5D 观感；此决定取代之前的像素方向。
- 2.5D 暂按 2D 角色与物理、斜俯视、分层纵深、遮挡和光影实现；用户未要求迁移到 3D。
- 保留适配的手绘背景，统一角色、道具、特效的笔触、光色和透视；不把绘本背景与像素角色混搭当作最终美术。手绘同样需要控制源图分辨率和缩放。
- 用角色实际可见高度校准比例，不按整张素材尺寸盲目设置缩放。
- 切帧前检查内容边界，对齐脚底、尺寸和重心。避免把排版展示图直接均分当作合格动画表。
- 男孩 `assets/chapter1/boy.png` 的四行不是等高网格，使用显式行边界 `[0,368,694,1028,1448]`；不能恢复为高度四等分，否则侧／背面头发被截掉并混入邻行。切帧回归需跑 `tests/boy_atlas_test.gd`，不能只检查用了三个帧编号。
- `assets/chapter1/*_fg.png` 与背景未完全配准，不直接全图叠加；当前家具局部遮挡使用背景同坐标纹理。起床表自带床，当前为近景替代，并非完整下床动画。
- 步态使用连续相位，与位移匹配；场景中的整理礼物、转身、靠近、变身等需要实际动作设计。
- 先做短样片验证比例、画风和运动，再推广到整段序章。

## 验收与沟通

- 引擎加载、逻辑测试通过不等于美术或动画验收通过。
- 静态截图检查构图；正常速度动态播放检查步态、闪烁、插值和动作节奏。低帧率采样不能证明流畅。
- 报告必须明确仍在使用的占位素材、缺失动画、音频和实际测试范围。
- 使用中文提供适合 Mac 开发新手的短步骤。不要把制作质量问题归咎于用户需求写作。
