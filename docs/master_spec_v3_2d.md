# 《猪猪山庄——被遗忘的快乐——》
## Godot 4.7.2 全新项目主实现规格
### Fresh Project / macOS / New Git Repository / GDScript / 2D Narrative Adventure

> **本文件是新 Godot 项目的独立工程实现起点。**
>
> 在 MacBook 上创建一个全新的 Godot 项目和一个全新的 Git repository。  
> **只以当前新 repo、本文件和之后明确导入的新素材为工程事实来源。**
>
> 这是一个 greenfield project：从 Godot 的 Scene / Node / Signal / Resource 架构出发重新设计，不假设存在任何既有实现。

---

# 0. 项目目标

制作一款以剧情、探索、情绪演出为核心的 2D 叙事冒险游戏：

**《猪猪山庄——被遗忘的快乐——》**

核心角色：

- **小呆猪 / LittlePig**：女生。
- **白白菜 / WhiteCabbage**：小男孩。
- **坏巫师 / EvilWizard**：厌恶快乐力量，认为只要抹掉记忆，人与人之间的感情就会消失。

核心主题：

> 坏巫师相信：只要抹掉记忆，感情就不存在了。  
> 故事最后证明：即使记忆被夺走，小呆猪仍会穿过最害怕的森林去找白白菜；白白菜即使不记得小呆猪，再次见到她时，仍会感觉她非常重要。  
> 真正无法被夺走的，不是“记得多少”，而是他们还会一次又一次选择彼此。

---

# 1. Greenfield 项目边界

这是一个从零开始的新项目。

Codex 必须：

- 只检查当前新 repo。
- 只使用当前 repo 中已经存在的 Godot 文件与用户之后明确加入的素材。
- 如果目录为空，就从 `project.godot` 与基础目录开始创建。
- 如果当前目录已有本次项目的新文件，先检查再修改，避免覆盖已经完成的新工作。
- 使用 Godot 原生 Scene / Node / Signal / Resource 思维设计系统。
- 将剧情、互动、镜头、VFX、UI、存档拆成可维护模块。
- 不假设存在任何需要继承的实现或存档格式。

以后如果用户主动加入图片、音乐、模型、动画或声音素材，直接按普通 Godot asset 导入并重新组织到本项目目录中。

---

# 2. MacBook 与 Git 初始化

目标 Godot 版本：

**Godot 4.7.2 stable，标准版，GDScript。**

不要使用 4.8 dev 作为本项目默认开发版本。

建议新 repo 名：

`piggy-manor-godot`

建议项目目录：

```text
piggy-manor-godot/
```

如果当前目录尚未初始化 Git：

```bash
git init
git branch -M main
```

建议 `.gitignore`：

```gitignore
.godot/
.DS_Store
build/
exports/
*.tmp
```

所有文本文件：

- UTF-8
- LF line endings
- 文件名尽量使用英文小写 `snake_case`
- 剧情文本内部可以使用中文

不要替用户猜 GitHub remote URL。  
repo 创建完成后，remote 由用户提供或在 GitHub 创建新 repo 后再添加。

首个合理 commit：

```text
chore: initialize fresh Godot project
```

---

# 3. Godot 项目技术方向

## 3.1 游戏形态

- 2D 叙事冒险
- 以俯视 / 斜俯视（three-quarter view）为主要探索视角
- 自由连续移动，不使用强制格子步进
- 角色始终可见的俯视 / 斜俯视探索
- 剧情演出优先
- 战斗不是核心系统，但小呆猪线必须包含可重复扩展的轻量实时战斗
- 最终冲突不是传统 Boss 战
- 主要玩法：
  - 探索
  - 环境互动与简单解谜
  - 白白菜的记忆共鸣
  - 小呆猪寻找礼物碎片
  - 小呆猪线的轻量战斗与森林机关
  - Cutscene

当前开发策略不是一次做完整游戏。先做一个白白菜解谜模板和一个小呆猪战斗模板，验证手感与架构后，再逐章增加新的谜题、战斗和场景。

## 3.2 2D 视觉与动作方向

本项目坚持 **2D**。不要为了“更高级”把核心角色、场景或玩法改成立体模型。

目标不是传统僵硬的格子式移动，而是：

> **2D 美术 + 更丰富的角色动作 + 更顺滑的镜头 + 分层场景 + 灯光 / shader / 粒子 / 前景遮挡。**

整体采用有纵深感的 layered 2D presentation；所有 gameplay 都基于 2D 坐标、2D 碰撞和 2D sprite。

### 角色运动最低质量要求

不要让人物像“瞬间切方向、固定速度滑动的纸片”。至少实现：

- 移动有轻微 acceleration / deceleration，而不是一按键就瞬间到满速。
- 停下时有很短的 settle / stop transition。
- 转向时切换正确朝向动画，不允许角色面朝错误方向平移。
- Idle 不完全静止：可以有呼吸、眨眼、轻微身体起伏或耳朵/衣服小动作。
- Walk / Run 的脚步节奏与移动速度匹配，避免滑步。
- 重要对白前后允许有 look / turn / step / recoil / hesitate 等短动作。
- 小呆猪害怕时应有轻微发抖或后缩；鼓起勇气时有抬头/向前一步。
- 白白菜的“空心”状态可以通过较慢 idle、停顿、目光和细微动作表现，而不是只靠文字。
- 受击必须有 hit-stop、短促位移/闪烁/受击动画中的至少两种反馈。
- 攻击必须有 anticipation → active → recovery，不允许点击后直接生成伤害框而没有动作。

优先组合：

```text
AnimatedSprite2D / Sprite2D spritesheet
+ AnimationPlayer
+ AnimationTree（需要复杂状态混合时）
+ Tween
```

如果美术暂时没有足够帧数，可以先通过 sprite scale、position、rotation、modulate、shadow、VFX 做轻量 secondary motion，但不要把这些假动作当作最终角色动画。

### 第一批角色动画最低集合

白白菜与小呆猪的探索角色至少预留：

```text
idle_down / idle_up / idle_side
walk_down / walk_up / walk_side
turn / interact
```

如果最终角色素材允许，优先补成四方向独立动画；后续再决定是否需要八方向，不要因为追求八方向阻塞第一版。

白白菜额外需要：

```text
hollow_idle      # 空心状态的轻微迟钝/停顿感
look_confused
recoil_memory
```

小呆猪额外需要：

```text
fear_shiver
resolve_step
attack_01
hurt
```

Forest Slime 至少需要：

```text
idle
telegraph
lunge
hurt
defeat
```

这些名称是逻辑语义，不要求素材文件必须完全使用同名；代码应通过动画状态映射连接实际素材。

### 场景纵深与“动画感”

2D 场景至少预留：

```text
Background
Midground / Gameplay Layer
Characters & Props
Foreground Occlusion
Lighting / Fog / VFX Overlay
```

可以使用：

- `Parallax2D` 制造森林、远山、室内窗外景深。
- 前景树叶、门框、家具边缘遮挡角色，增加空间感。
- `Camera2D` 做缓动跟随、轻微 zoom、pan、shake。
- `PointLight2D`、`CanvasModulate`、2D shader 做暖光、紫色诅咒和窗口光。
- `GPUParticles2D` 做 Joy Particle、魔法尘、雾、闪光。
- `AnimatedSprite2D` / shader 做窗光、火焰、水晶球、烟雾等循环动画。

镜头演出应该让 2D 场景“活起来”，而不是通过频繁切屏制造戏剧感。

## 3.3 建议基础节点

玩家：

```text
Player (CharacterBody2D)
├── CollisionShape2D
├── VisualRoot (Node2D)
│   ├── AnimatedSprite2D
│   ├── Shadow (Sprite2D)
│   └── CharacterVFX (Node2D)
├── AnimationPlayer
├── AnimationTree
├── Camera2D
├── InteractionDetector (Area2D or RayCast2D)
└── InteractionPromptAnchor (Marker2D)
```

可交互物：

```text
Interactable (Area2D)
├── CollisionShape2D
├── VisualRoot (Node2D)
└── InteractionMarker (Marker2D)
```

场景：

```text
StoryScene (Node2D)
├── Background
├── World
│   ├── TileMapLayers / StaticBody2D
│   ├── Props
│   └── NavigationRegion2D (only where needed)
├── Characters
├── Interactables
├── Triggers
├── Foreground
├── Lighting
├── VFX
├── Audio
├── CutsceneDirector
└── SceneMarkers
```

UI：

```text
GameUI (CanvasLayer)
├── DialogueUI
├── InteractionPrompt
├── HeartUI
├── ObjectiveUI
├── FadeLayer
└── TitleCard
```

---

# 4. 新工程目录

```text
res://
├── project.godot
├── autoload/
│   ├── game_state.gd
│   ├── scene_router.gd
│   └── save_manager.gd
├── actors/
│   ├── player/
│   ├── little_pig/
│   ├── white_cabbage/
│   ├── evil_wizard/
│   ├── slime/
│   └── shared/
├── scenes/
│   ├── bootstrap/
│   ├── prologue/
│   ├── chapter_01_hollow_heart/
│   ├── chapter_02_dark_forest/
│   ├── forest_exploration/
│   ├── finale/
│   └── piggy_manor/
├── systems/
│   ├── dialogue/
│   ├── interaction/
│   ├── cutscene/
│   ├── objectives/
│   ├── hearts/
│   ├── audio/
│   └── vfx/
├── ui/
├── data/
│   ├── dialogue/
│   ├── story/
│   └── localization/
├── assets/
│   ├── sprites/
│   ├── tilesets/
│   ├── textures/
│   ├── shaders/
│   ├── materials/
│   ├── animations/
│   ├── audio/
│   │   ├── bgm/
│   │   ├── ambience/
│   │   └── sfx/
│   └── vfx/
└── tests/
```

不要因为某个美术资源尚未存在而阻塞逻辑搭建。  
缺失的角色可先使用简单 2D placeholder sprite / shape，但必须把 placeholder 集中放在：

```text
res://assets/placeholders/
```

并在代码中标记：

```gdscript
# TODO_ASSET: replace placeholder with final asset
```

---

# 5. 全局架构

只建议三个真正需要跨场景持续存在的 Autoload：

## 5.1 `GameState`

负责：

- 当前剧情阶段
- 已完成的关键剧情 flag
- 白白菜共鸣进度
- 小呆猪礼物碎片收集状态
- 白白菜当前心理状态
- 通关状态

不要把所有临时 cutscene 状态都放进 GameState。

建议：

```gdscript
enum StoryPhase {
    PROLOGUE,
    CABBAGE_HOLLOW_HEART,
    LITTLE_PIG_DARK_FOREST,
    FOREST_EXPLORATION,
    FINALE,
    COMPLETED
}

enum CabbageEmotionalState {
    HOLLOW,
    RESONATING,
    MEMORY_RETURNED
}

var story_phase: StoryPhase = StoryPhase.PROLOGUE
var cabbage_emotional_state: CabbageEmotionalState = CabbageEmotionalState.HOLLOW

var cabbage_resonance_progress: int = 0

var flags: Dictionary = {}
var gift_fragments: Array[String] = []
```

## 5.2 `SceneRouter`

负责：

- 场景切换
- 黑屏
- fade in / fade out
- scene transition loading

复杂 cutscene 不放在这里。

## 5.3 `SaveManager`

负责：

- `user://` 存档
- 保存 GameState
- 只读写本项目自己的 Godot 存档格式
- New Game 从序章开始
- Continue 从保存的 Godot 状态恢复

---

# 6. Cutscene 实现原则

每一个剧情场景都由本场景自己的 `CutsceneDirector` 管理。

不要做一个全局 3000 行剧情脚本。

建议每段 cutscene 独立：

```text
cutscene_prologue_castle.gd
cutscene_prologue_gift.gd
cutscene_prologue_curse.gd
cutscene_ch1_wakeup.gd
cutscene_ch1_bedroom_memory.gd
cutscene_ch1_kitchen_memory.gd
cutscene_ch1_living_memory.gd
cutscene_ch2_wizard.gd
cutscene_ch2_forest_gate.gd
cutscene_final_reunion.gd
cutscene_final_memory_return.gd
cutscene_final_wizard.gd
cutscene_final_manor_restore.gd
cutscene_ending.gd
```

Cutscene 开始：

- 禁止玩家输入
- 保留必要 camera movement
- DialogueUI 接管推进
- 允许 `await` animation / timer / dialogue signals

Cutscene 结束：

- 恢复玩家输入
- 更新 GameState
- 清理临时 VFX
- 不留下重复触发的 trigger

示例形式：

```gdscript
func play() -> void:
    player.set_input_enabled(false)

    await dialogue.say("little_pig", "……白菜？")
    await get_tree().create_timer(0.5).timeout

    animation_player.play("wake_up")
    await animation_player.animation_finished

    player.set_input_enabled(true)
```

---

# 7. 对话系统

剧情对白不要硬编码散落在几十个脚本里。

建议：

```text
res://data/dialogue/prologue.json
res://data/dialogue/chapter_01.json
res://data/dialogue/chapter_02.json
res://data/dialogue/finale.json
```

数据示例：

```json
{
  "id": "ch2_pig_fear_01",
  "speaker": "little_pig",
  "text": "……我怕。",
  "pause_after": 0.7
}
```

DialogueManager 至少支持：

- speaker
- text
- optional portrait / name
- pause_before
- pause_after
- auto / confirm advance
- signal `line_started`
- signal `line_finished`
- cutscene input lock

普通对白只出现一次。

标题卡、章节标题、THE END 与普通 DialogueUI 分离。

---

# 8. 最重要的世界观设定：白白菜是“空心小男孩”

这是新版本必须贯彻到整个项目中的核心设定。

## 8.1 白白菜是谁

白白菜是一个**小男孩**。

小呆猪是女生。

不要根据角色外形、模型或 placeholder 改变性别。

## 8.2 “遗忘之咒”真正造成的结果

巫师不是只删除了一个联系人名字。

他把白白菜脑海中**所有关于小呆猪的记忆连接**夺走：

- 小呆猪的名字
- 两个人一起吃饭
- 一起说过的话
- 一起生活的习惯
- 猪猪杯
- 双人餐具
- 抱枕
- 礼物
- 快乐
- 期待
- 思念
- “芋圆肚瓜圆”

因此，白白菜醒来后不是一个普通的失忆者。

他成为了一个：

> **空心小男孩。**

他依然认识自己的家。  
他依然知道咖啡机怎么用。  
他依然知道什么是杯子、餐具、窗户。  
他甚至可能保留与小呆猪无关的日常记忆。

但这个家中最重要的一层情绪联系被挖空了。

所以他的主观体验是：

- “这里明明是家，为什么不像家？”
- “这些东西明明很熟悉，为什么想不起为什么重要？”
- “我应该觉得安心，但是什么都感觉不到。”
- “胸口……怎么空空的。”

## 8.3 第一幕的演出方向

猪猪山庄和家本身不需要变成恐怖场景。

真正可怕的是：

> **一个本来装满两个人共同生活痕迹的地方，对白白菜来说突然没有情绪了。**

因此第一幕的视觉应：

- 仍然能看出这里曾经温暖
- 但色温 / 饱和度略微降低
- 环境声比正常生活场景更空
- 不要塞满悲伤音乐
- 可以保留钟声、风声、咖啡机等现实声音
- 玩家通过“过于正常的物件”感受到不正常

## 8.4 心心 / 共鸣

第一幕出现的心形 UI：

- 不显示数字
- 不写“记忆值”
- 不写“快乐值”
- 不解释含义

它是视觉上的“共鸣”表现。

BIG IDEA、猪猪杯、双人餐具、猪猪抱枕并不是在给白白菜“加经验”。

它们证明：

> 他的身体和情绪仍然会对两个人曾经的生活产生反应，即使大脑想不起小呆猪。

三段记忆结束后：

白白菜仍没有真正恢复记忆。

只是从完全 HOLLOW 进入 RESONATING。

真正恢复必须留到最终章的“芋圆肚瓜圆”。

---

# 9. 白白菜共鸣与小呆猪礼物碎片

## 9.1 白白菜共鸣

白白菜被遗忘之咒影响，因此他的探索可以使用“共鸣”作为内部剧情进度。

内部变量：

```gdscript
cabbage_resonance_progress: int # 当前首批内容只使用 0..1，未来可扩展
```

UI：

- `CabbageHeartUI`
- 只显示图形
- 不显示 `1/3`、Memory、快乐值等解释文本

共鸣不是传统收集任务，而是白白菜在环境解谜中触碰到被抹除生活痕迹后的情绪反应。

## 9.2 小呆猪没有“空心”或失忆进度

小呆猪**没有忘记白白菜，也没有被挖空情绪连接**。

不要为小呆猪创建：

- 空心状态
- Heart 恢复进度
- 0/8 心心收集
- 用心心代表她恢复对白白菜的感情

她从开场到结尾始终记得白白菜，也始终想回到他身边。

但在**玩家任务系统**里，小呆猪当前只有一个明确任务：

> **寻找散落的礼物碎片。**

“回到白白菜身边”是她的剧情动机和章节方向，不另做第二条 Quest，不与礼物碎片形成两个并列任务。

她的主要可保存收集状态为：

```gdscript
gift_fragments: Array[String]
```

每个碎片使用稳定字符串 ID，例如：

```text
fragment_red_wrap_01
fragment_ribbon_01
fragment_gift_box_01
```

具体总数量暂不锁死。后续新增森林场景时继续扩展。

---

# 10. VFX 实现映射

所有特效按 Godot 原生系统重新实现。

## 快乐粒子

```text
GPUParticles2D
```

三级：

- JoyParticleSmall
- JoyParticleLarge
- JoyBurst

颜色：

- 淡金
- 金白
- 不做火焰攻击感

小呆猪本人在前期不知道这些粒子的意义。

## 紫色遗忘魔法

组合：

- GPUParticles2D
- CanvasModulate / full-screen CanvasLayer overlay
- Parallax2D fog layers / animated fog Sprite2D / shader overlay
- PointLight2D / DirectionalLight2D / LightOccluder2D
- AnimationPlayer
- Camera shake

## 魔法阵

优先：

- `Sprite2D` / `AnimatedSprite2D`
- `GPUParticles2D`
- 或 CanvasItem shader 做扩散、旋转与发光

## 记忆残影

优先：

- 半透明 Sprite2D / AnimatedSprite2D memory silhouette
- Shader 降低细节 / blur impression
- 配合短暂 full-screen white flash

第一幕前两段：

**绝不能完整显示小呆猪。**

第三段：

可以更清晰，但仍不是正式重逢。

## 猪猪山庄灯光

每栋房子使用独立的 `WindowGlow` Sprite2D / AnimatedSprite2D，并可搭配 `PointLight2D`。

诅咒时依次熄灭。  
恢复时依次点亮。

---

# 11. 序章 PROLOGUE

建议场景：

```text
scenes/prologue/castle_crystal_hall.tscn
scenes/prologue/mushroom_house_night.tscn
scenes/prologue/piggy_manor_night.tscn
scenes/prologue/title_sequence.tscn
```

## 11.1 黑暗古堡

开场：

- 黑屏
- 风声
- 水晶球：“滴……”
- 再次：“滴……”
- 警报突然加速
- fade in

环境：

- 阴暗古堡
- 紫色火焰
- 中央水晶球
- 坏巫师

对白：

坏巫师：
“……”

“又来了。”

“这股令人作呕的力量……”

显示仅用于水晶球系统的视觉信息：

“欢乐能量异常。”

“能量等级：■■■■■■■■□”

坏巫师：

“八级？”

“昨天还只有六级。”

“到底是谁……”

“每天都在散发这种烦人的力量？”

水晶球显示猪猪山庄的小蘑菇屋。

坏巫师：

“……猪猪山庄。”

“又是那里。”

白闪切换。

## 11.2 小呆猪包装礼物

房间：

- 暖黄色灯光
- 茶杯
- 白菜形状小摆件
- 包装纸
- 彩带
- 礼物盒

对白：

小呆猪：

“唔……”

“好像还是有一点歪。”

调整蝴蝶结。

“这样呢？”

停顿。

“……”

“更歪了。”

短暂尴尬动作。

“没关系！”

“白菜才不会嫌弃我包得丑呢。”

这里第一次出现**极弱**金色粒子。

不要解释。

继续：

“而且……”

“他拆开的时候，一定会很开心吧。”

金色粒子增强。

“嘿嘿。”

“不知道白菜会是什么表情。”

画面轻微变暖。

突然 hard cut。

## 11.3 巫师发现快乐来源

水晶球警报：

“滴滴滴滴滴滴滴滴——！！！”

坏巫师：

“……”

“又是这只猪。”

回放：

小呆猪：
“白菜看到一定会很开心吧。”

能量暴涨。

坏巫师：

“等等。”

“刚刚它说了什么？”

倒带。

小呆猪：
“白菜……”

明显 Joy Burst。

坏巫师：

“……”

“白菜。”

“原来如此。”

“不是猪猪山庄。”

“也不是那间可笑的蘑菇屋。”

“真正制造这些欢乐的……”

“是你想到他的那一瞬间。”

紫色火焰升高。

“真讨厌。”

“快乐。”

停顿。

“期待。”

停顿。

“思念。”

停顿。

“还有那些自以为永远不会消失的回忆。”

## 11.4 遗忘之咒

坏巫师：

“既然如此……”

“只要把它们拿走就好了。”

雷声。

“以黑夜为幕——”

“以遗忘为名——”

“让所有关于那只猪的痕迹……”

“从这个世界消失！”

大型紫色魔法阵展开。

“遗忘之咒！”

爆发。

## 11.5 猪猪山庄被诅咒

- 紫雾进入山庄
- 前后两层空间深度
- 窗灯一盏一盏熄灭
- 小蘑菇屋最后仍亮着

切回小呆猪。

小呆猪：

“好了！”

“明天就可以送给白菜啦。”

窗外紫光。

“……？”

魔法爆发。

小呆猪：

“白菜——！”

**立即切黑。**

不要慢 fade。

黑屏停留。

## 11.6 Title

黑屏：

《猪猪山庄》

——被遗忘的快乐——

第一次播放温柔主题旋律。

之后进入：

**第一幕《空掉的心》**

GameState：

```gdscript
story_phase = StoryPhase.CABBAGE_HOLLOW_HEART
cabbage_emotional_state = CabbageEmotionalState.HOLLOW
```

---

# 12. 第一幕《空掉的心》

建议使用一个连续的 2D 住宅场景，让卧室、厨房、客厅在空间上自然连接；不要为了沿用传统地图切换而把住宅切成互不连续的小房间。

```text
scenes/chapter_01_hollow_heart/cabbage_home.tscn
```

住宅内部至少包含：

- Bedroom
- Kitchen
- LivingRoom
- FrontDoor

玩家：白白菜。

## 12.1 醒来

黑屏。

Morning Birds。

慢慢淡入。

白白菜醒来。

必须保留：

“好安静。”

“胸口……怎么空空的。”

Heart UI 以 0 共鸣状态出现。

白白菜注意到它，但不要解释。

这里第一次给玩家自由控制。

**演出目标：**
玩家要感觉“这个男孩回到了自己的家，可是情绪没有一起醒过来”。

## 12.2 BIG IDEA 画

交互：

`big_idea_painting`

第一次调查完成后：

```gdscript
cabbage_resonance_progress = 1
```

播放第一段 memory echo。

第一段残影：

- BIG IDEA 附近
- 很模糊的小型粉色影子
- 不显示完整小呆猪
- 环境极轻微变暖
- Memory shimmer
- 影子出现 → 消失

白白菜：

“刚才……”

“那里是不是有个人？”

……

“好像也不是。”

> 注意：提供的资料只保留了这一段的关键对白，不包含 BIG IDEA 调查全过程的全部逐字定稿。不要擅自把未提供的对白声称为已定稿原文；若需要可先把未提供部分放在 `TODO_DIALOGUE` 中。

完成后白白菜可以自然离开卧室。

必须保留：

“算了。”

“先去弄点咖啡吧。”

“可能只是没睡醒。”

## 12.3 Coffee Machine

互动咖啡机。

保留：

“咖啡……”

“希望有用。”

玩家角色走向杯柜，而不是瞬移。

叙事描述：

“你习惯性地伸手去拿自己的杯子。”

随后解锁猪猪杯调查。

## 12.4 猪猪杯

关键对白必须保留：

“这是谁的？”

“不是新的。”

“以前真的有人用过。”

以及：

“不知道为什么……”

“我不太想把它扔掉。”

重复调查：

“粉色的猪猪杯。”

“总觉得放在这里才对。”

## 12.5 双人餐具

关键视觉：

- 绿色餐具
- 粉色餐具
- 猪鼻子勺柄

猪猪杯 + 双人餐具都调查后：

```gdscript
cabbage_resonance_progress = 2
```

触发第二段 memory echo。

## 12.6 第二段记忆

桌子对面：

一个模糊的小型粉色影子，两只手抱着猪猪杯。

？？？：

“烫——！”

另一个声音：

“都叫你慢一点喝了。”

白闪。

影子消失。

不要让白白菜在此恢复小呆猪身份。

## 12.7 客厅：猪猪抱枕

关键对白：

“又来了。”

“到底有多喜欢猪啊。”

“中间已经被压得有一点扁了。”

“经常有人抱着它吗？”

“它放在这里特别正常。”

调查后：

```gdscript
cabbage_resonance_progress = 3
cabbage_emotional_state = CabbageEmotionalState.RESONATING
```

触发第三段 memory echo。

## 12.8 第三段记忆

门口。

模糊粉色影子正在穿鞋。

？？？：
“我走啦！”

另一个声音：
“等等。”

？？？：
“嗯？”

声音：
“……早点回来。”

粉色影子：
“知道啦！”

？？？：
“白白菜拜拜！”

白闪。

这是白白菜第一次清楚听见：

**“白白菜”**

随后：

“这个家里……”

“一定少了什么。”

“不。”

“是少了谁。”

## 12.9 红色包装纸

门外：

“沙……”

一小片红色包装纸被风吹进门内。

它必须是 2D 世界坐标中的 Sprite2D / AnimatedSprite2D 物体，而不是屏幕固定 UI。

白白菜调查。

保留：

“这是……”

“一小片红色的包装纸。”

“上面印着小小的猪鼻子。”

提供的资料在这里省略了中段逐字对白，因此中段保持 `TODO_DIALOGUE`，不要假装是原稿。

结尾保留：

“我真的得出去看看了。”

前门解锁。

离开前：

“这个东西是从外面来的。”

“也许……”

“外面会有答案。”

之后进入猪猪山庄。

---

# 13. 第二幕·小呆猪线：穿过黑暗森林

建议场景：

```text
scenes/chapter_02_dark_forest/dark_forest_entrance.tscn
```

玩家切换为小呆猪。

## 13.1 醒来

黑屏。

森林风声。

fade in。

小呆猪倒在地上。

手边有一小片红色包装纸。

对白：

“……白菜？”

停顿。

“白菜？”

站起来。

“这里是……”

“我的礼物呢？”

看向包装纸。

“这是礼物的包装纸……”

“我明明已经快包好了。”

“白菜还没有看到呢。”

“……礼物呢？”

给玩家一个很小的自由探索区域。

## 13.2 包装纸调查

第一次：

“这是礼物的包装纸……”

“礼物应该是在被传送的时候散开了。”

“白菜还没有看到呢……”

重复：

“我要把礼物找回来。”

调查后触发巫师登场。

## 13.3 巫师出现

Purple Fog。

坏巫师：

“呆呆猪。”

“你醒了。”

小呆猪：

“你是谁？”

“你对白菜做了什么？”

“还有——”

“我的礼物去哪里了？！”

坏巫师：

“礼物？”

“你现在还有心情担心那个东西？”

“你应该先担心一下……”

“白白菜还记不记得你。”

小呆猪：

“……什么意思？”

坏巫师：

“我已经把关于你的记忆，从他那里全部拿走了。”

“你的名字。”

“你们一起吃过的饭。”

“你们一起说过的话。”

“那些无聊的礼物。”

“那些更加无聊的快乐。”

“全部——”

“消失了。”

## 13.4 “空心白白菜”残影

这里的闪回必须使用第一幕建立的设定。

短暂看到白白菜一个人站在家里，看着猪猪杯。

他不是单纯疑惑。

他是：

- 明明知道这是自己家
- 却无法从这些东西上感到幸福
- 变成“空心小男孩”

坏巫师：

“现在的他，就算站在你面前——”

“也不会知道你是谁。”

小呆猪：

“……他真的……”

“忘记我了吗？”

坏巫师：

“当然。”

“所以你还有什么理由回去？”

## 13.5 小呆猪决定重新认识他

短回忆：

白白菜：
“你藏什么啦？”

小呆猪：
“没有！”

回到森林。

小呆猪：

“……那我要去找他。”

坏巫师：

“什么？”

小呆猪：

“如果白菜忘记我了——”

“那我就重新认识他。”

“如果他忘记了我们做过的事情……”

“我就陪他再做一次。”

“如果他连我的名字都忘记了……”

“那我就再告诉他一次。”

第一次 JoyParticleSmall。

坏巫师后退。

“……又是这个东西。”

## 13.6 黑暗森林

坏巫师：

“你以为你回得去？”

“看看你周围。”

镜头展示森林。

“这里是黑暗森林的最深处。”

“而猪猪山庄——”

“在森林的另一端。”

树枝断裂。

小呆猪：

“……”

“黑、黑暗森林？”

坏巫师：

“怎么？”

“害怕了？”

“你不是最怕这里吗？”

“那些没有灯的地方。”

“那些奇怪的声音。”

“那些藏在树后面的东西……”

“你连晚上一个人走出蘑菇房子都不敢。”

“你真的觉得——”

“你能穿过整片黑暗森林？”

## 13.7 核心台词

节奏必须慢。

小呆猪：

“……我怕。”

停顿。

“我真的很怕。”

“这里这么黑。”

“我也不知道里面有什么。”

停顿。

“可是白菜一个人在那边。”

JoyParticleSmall。

“他醒过来的时候……”

“如果发现所有事情都变得奇奇怪怪的……”

“他一定也会害怕。”

第二个 JoyParticleSmall。

小呆猪抬头。

“所以我要回去。”

## 13.8 连续质问

坏巫师：

“就算他已经忘记你？”

小呆猪：

“嗯。”

坏巫师：

“就算他不认识你？”

小呆猪：

“嗯。”

坏巫师：

“就算他根本不相信你？”

小呆猪：

“那我就想办法让他相信。”

坏巫师：

“就算你要穿过你最害怕的地方？”

小呆猪仍然发抖。

“……嗯。”

停顿。

“因为我要去找白菜。”

JoyParticleSmall → Large → JoyBurst。

坏巫师：

“你——！”

小呆猪：

“诶？”

“刚才是什么？”

巫师不解释。

## 13.9 巫师离开

坏巫师：

“那就去吧。”

“让我看看……”

“你的勇气究竟能坚持多久。”

Purple Fog。

巫师消失。

短暂只有森林环境声。

## 13.10 森林入口

玩家重新获得控制。

如果往错误方向走，一次性提示：

“……”

“这边不是白菜的方向。”

当玩家真正走到森林入口：

小呆猪：

“……”

“我还是很害怕。”

停顿。

主动向前一步。

“但是——”

“害怕也可以往前走。”

这里不要把“回到猪猪山庄 / 找到白白菜”做成 Quest UI。它们是小呆猪的剧情动机。

此处**不要**启用任何小呆猪 Heart UI。

小呆猪当前唯一任务 UI：

**寻找散落的礼物碎片**

可以显示当前场景需要的路线/战斗提示。碎片总数量尚未定稿时，不要显示强制性的 `0 / N`。

章节标题：

**第二幕 · 小呆猪篇**

**「为了你，我会走过最害怕的地方。」**

进入正式森林探索。

---

# 14. 中段玩法边界与扩展策略

当前不一次性设计完整中段。采用“小模块验证 → 后续追加场景”的方式。

长期方向已经确定：

- 白白菜线：环境探索 + 简单解谜 + 记忆共鸣
- 小呆猪线：寻找礼物碎片 + 轻量实时战斗 + 森林机关/简单解谜
- 小呆猪没有失忆，也没有 Heart 恢复任务
- 最终章依旧以两人重新找到彼此为高潮，而不是数值型 Boss 战

首批只固定两个玩法样板：

1. **白白菜：一次“复原双人早餐位”环境解谜**
2. **小呆猪：一次“森林史莱姆守护礼物碎片”轻量战斗**

之后再以相同接口新增新的住宅/山庄谜题、森林机关、敌人和礼物碎片场景。

建议模块：

```text
scenes/puzzles/
scenes/forest_exploration/
systems/puzzles/
systems/combat/
systems/gift_fragments/
```

礼物碎片数量不能阻止结局，除非后续设计文档明确修改。

## 14.1 白白菜首个解谜：复原双人早餐位

场景位于白白菜家中的 Kitchen / Dining Area。

叙事目的：

> 白白菜并不知道另一个人是谁，但他会发现家里的物品留下了“两个人长期一起生活”的结构。玩家不是靠密码开锁，而是通过观察生活痕迹把早餐位恢复成“本来就应该是这样”的状态。

可交互物：

- 白白菜自己的绿色杯 / 餐具
- 粉色猪猪杯
- 粉色餐具
- 猪鼻子勺柄
- 桌面上两个有轻微使用痕迹的位置 / 杯垫

谜题流程：

1. 白白菜先制作咖啡。
2. 玩家调查粉色猪猪杯和双人餐具，获得环境提示，不出现解释性系统文本。
3. 玩家可以拿起/选择粉色杯与粉色餐具，并放到桌面的两个候选位置。
4. 正确状态必须是：白白菜的绿色餐具在一侧，粉色猪猪杯与粉色餐具在对面长期使用痕迹的位置。
5. 错误摆放只给非常轻的角色反应，例如“……好像不对。”，不扣血、不重置章节。
6. 正确摆放后，白白菜下意识说出类似“……这样才对。”的已有语气；若没有定稿逐字对白，用 `TODO_DIALOGUE`，不要替用户编成正式台词。
7. `cabbage_resonance_progress` 从 0 → 1。
8. 播放 Kitchen Memory Echo：桌子对面出现模糊粉色影子，两只手抱着猪猪杯，保留原稿中的“烫——！”等记忆碎片。

实现建议：

```text
BreakfastPuzzleController (Node)
├── PlacementSlot_Green
├── PlacementSlot_Pink
├── PigCupInteractable
├── PinkTablewareInteractable
└── PuzzleFeedback
```

PuzzleController 只判断物件 ID 与 slot 是否匹配；Dialogue/Cutscene 由场景自己的 director 响应 `puzzle_solved` signal。

## 14.2 小呆猪首个战斗：森林史莱姆与第一块礼物碎片

这是用来验证战斗系统的最小可玩样板，不代表游戏以后要变成动作 RPG。

场景：一个小型森林空地。

剧情目的：

> 小呆猪在寻找礼物碎片时发现第一块明显的礼物残片就在前方，但一只受黑暗魔法影响的史莱姆占据了空地。她必须鼓起勇气通过一次简单战斗，拿回碎片。

第一版战斗只需要：

**小呆猪**
- `3` 点生命
- 一个近距离普通攻击
- 攻击使用短时 `Area2D` HitBox
- 受伤后短暂无敌，避免连续碰撞瞬间死亡
- 可以移动躲开攻击
- 暂时不要求技能树、装备、复杂 combo 或锁定系统

**Forest Slime**
- `3` 点生命
- 一个清晰前摇的跳扑/冲撞攻击
- 攻击前约 `0.7–1.0s` 给动画或身体压缩提示
- 接触命中造成 `1` 点伤害
- 被击败后 dissolve / 缩小消失

胜利：

- 战斗结束
- 环境音乐恢复
- 前方的第一块礼物碎片可拾取
- 添加例如 `fragment_red_wrap_01` 到 `GameState.gift_fragments`
- 不增加 Heart
- 小呆猪的动机仍然是“把给白菜的礼物找回来”

建议接口：

```text
CombatActor
HealthComponent
HitBox2D
HurtBox2D
ForestSlime
GiftFragmentPickup
```

战斗系统必须与剧情导演解耦。`ForestSlime` 不应该知道最终章或白白菜是谁；它只发出 `defeated`。场景 controller 再决定解锁礼物碎片。

## 14.3 小呆猪未来的解谜

小呆猪章节以后也需要简单森林机关/解谜，例如路径、光源、环境物件或礼物痕迹追踪，但**第一批不需要再实现第二个谜题**。只建立可扩展的 `PuzzleController` / `Interactable` 接口，等后续新场景再增加具体设计。

---

# 15. 最终章：重逢

场景：

```text
scenes/finale/forest_exit_reunion.tscn
```

最终史莱姆结束后：

- 战斗音乐淡出
- 森林恢复安静
- 小呆猪站在原地

小呆猪：

“呼……”

“终于……”

“白菜。”

“我来了。”

远处出现暖色光。

Soft Chime。

小呆猪：

“……？”

白白菜从猪猪山庄方向出现。

**白白菜是男生。**

两人保持距离。

白白菜：

“……”

“是你？”

小呆猪：

“白菜！”

她向前一步。

白白菜必须后退一步。

“等等。”

“你认识我？”

小呆猪：

“……”

“我是呆呆猪啊。”

白白菜：

“呆呆猪……”

“对不起。”

“我好像……”

“应该认识你。”

“可是我想不起来。”

---

# 16. 空心设定在重逢时的回收

这是“空心小男孩”设定真正发挥作用的地方。

小呆猪：

“坏巫师说的是真的……”

“他真的把我从你的记忆里删掉了。”

白白菜：

“……”

“可是……”

“为什么我看到你的时候……”

“会觉得很难过？”

“好像我忘记了一件……”

“特别特别重要的事情。”

这里意味着：

> 记忆还没有回来，但“空心”第一次明确感知到了自己缺失部分的形状。

小呆猪：

“没关系。”

“你想不起来也没关系。”

“我可以重新告诉你。”

“我是小呆猪。”

“我最喜欢的人……”

停顿。

“是白白菜。”

---

# 17. 遗忘魔法干扰

紫雾重新出现。

白白菜头痛。

坏巫师声音：

“没有用的。”

“他的记忆已经属于遗忘。”

“你们之间的一切……”

“都已经不存在了。”

小呆猪：

“不对。”

坏巫师：

“什么？”

小呆猪：

“你只是让他忘记了。”

“你没有让那些事情从世界上消失。”

---

# 18. “芋圆肚瓜圆”

音乐停止约 1 秒。

紫雾减慢。

小呆猪面向白白菜。

“白菜。”

“你还记得吗？”

停顿。

**“芋圆肚瓜圆。”**

这句话必须独立显示。

说完后长停顿。

不要立刻给答案。

---

# 19. 白白菜记忆恢复

Memory Chime。

柔和白闪。

依次出现三段记忆残影：

1. 两个人快乐相处
2. 猪猪山庄 / 杯子 / 日常生活
3. 小呆猪准备礼物 / 想到白白菜

碎片对白：

“白菜！”

“呆呆猪。”

“给你的。”

“你怎么又这样……”

“芋圆肚瓜圆。”

回到森林。

白白菜向前一步。

“……”

“呆呆猪。”

小呆猪：

“……！”

白白菜：

**“小呆猪。”**

此刻才设置：

```gdscript
cabbage_emotional_state = CabbageEmotionalState.MEMORY_RETURNED
flags["cabbage_memory_returned"] = true
```

随后：

白白菜：

“我想起来了。”

“蘑菇房子。”

“杯子。”

“礼物。”

“还有你。”

小呆猪：

“白菜……”

白白菜：

“对不起。”

“我忘记你了。”

小呆猪：

“不是你的错。”

“我找到你了就好。”

白白菜：

“嗯。”

“你找到我啦！”

---

# 20. 最终对抗

坏巫师正式出现。

坏巫师：

“不可能！”

“我明明已经消除了你的记忆！”

白白菜：

“你消掉的是记忆。”

“不是我们经历过的事情。”

坏巫师：

“闭嘴！”

紫色魔法冲击。

“快乐是最没有意义的东西！”

“只要失去记忆——”

“所谓的感情根本什么都不是！”

小呆猪站起来。

“才不是。”

“就算白菜忘记我。”

“我还是会去找他。”

“森林很黑。”

“我也真的很害怕。”

“可是只要想到白菜……”

JoyParticleSmall。

“我就没有那么害怕了。”

JoyParticleLarge。

“因为真正让我快乐的……”

停顿。

“从来都不是记住了什么。”

“是他就在这里。”

---

# 21. 牵手

白白菜向小呆猪伸手。

白白菜：

“呆呆猪。”

小呆猪：

“嗯？”

白白菜：

“这次一起。”

小呆猪：

“嗯！”

两人牵手。

如果尚无牵手 animation：

使用位置、朝向和手部 IK / 简易靠近动作占位。

不要因为没有最终动画阻塞剧情。

---

# 22. 快乐力量爆发

顺序：

1. JoyParticleSmall
2. JoyParticleLarge
3. 金白色 Magic Circle
4. Warm Glow
5. JoyBurst
6. White Flash
7. 紫雾向外退散

这不是“攻击技能”。

它应表现为：

> 两个人重新建立连接后，快乐力量自然从他们之间扩散。

坏巫师：

“这是什么？！”

小呆猪：

“白菜。”

白白菜：

“嗯。”

两个人一起：

**“咱们回猪猪山庄吧！”**

JoyBurst。

---

# 23. 巫师败退

光芒击碎遗忘魔法。

坏巫师：

“不——！”

“这种东西……”

“怎么可能——”

最终白闪。

巫师闪烁 / dissolve / 被光卷走。

**不要明确表现死亡。**

设置：

```gdscript
flags["wizard_final_defeated"] = true
```

---

# 24. 森林恢复

- 暗紫 / 蓝黑环境逐渐恢复正常
- Purple Fog 消失
- 恐怖眼睛 / 影子关闭
- 鸟叫回归
- 温暖主题音乐回来

小呆猪：

“结束了吗？”

白白菜：

“好像是。”

小呆猪：

“那……”

“我的礼物怎么办？”

白白菜：

“……”

“你刚刚才打败一个坏巫师。”

“第一件事居然是礼物？”

小呆猪：

“当然！”

白白菜：

“……”

“呆呆猪。”

小呆猪：

“嗯？”

白白菜：

“你回来就是最好的礼物。”

小呆猪：

“……”

“但是我还是想把礼物拼好。”

白白菜：

“……”

“我就知道。”

---

# 25. 猪猪山庄恢复

进入：

```text
scenes/piggy_manor/piggy_manor_restored.tscn
```

或者使用同一 PiggyManor 场景根据 GameState 切换环境状态。

推荐同一场景多状态，而不是复制“黑暗版 / 正常版”两套逻辑。

恢复演出：

- 天空恢复
- 窗户逐栋点亮
- 紫雾消失
- 植物恢复颜色
- NPC 恢复
- 音乐恢复
- 心形 / 音符 / 笑脸等极短环境反馈

设置：

```gdscript
flags["manor_restored"] = true
```

---

# 26. 蘑菇房子最终对白

两个人回到序章同一个家。

白白菜：

“呆呆猪。”

小呆猪：

“怎么啦？”

白白菜：

“森林里那么黑。”

“你真的一个人走过来了？”

小呆猪：

“嗯。”

白白菜：

“你不是最怕黑了吗？”

小呆猪：

“是啊。”

“超级怕。”

白白菜：

“那你怎么还敢来？”

停顿。

小呆猪：

“因为你在这里呀。”

白白菜：

“……”

小呆猪：

“而且我知道。”

“不管有多远。”

“只要一直往白菜那里走……”

“最后一定会找到你的。”

白白菜：

“笨蛋。”

小呆猪：

“？”

白白菜：

“以后不用一个人走那么远了。”

“我会去找你的。”

小呆猪：

“真的吗？”

白白菜：

“真的。”

小呆猪：

“那说好了。”

白白菜：

“说好了。”

---

# 27. “芋圆肚瓜圆”最后回收

准备进屋。

白白菜：

“对了。”

小呆猪：

“嗯？”

白白菜：

“刚才那句话……”

小呆猪：

“什么？”

白白菜：

“芋圆肚瓜圆。”

小呆猪：

“！！！”

白白菜：

“到底是什么意思？”

小呆猪：

“……”

“不告诉你。”

白白菜：

“？”

小呆猪跑进屋：

“芋圆肚瓜圆——！”

白白菜：

“小呆猪！”

恢复轻松主题音乐。

---

# 28. 最后一个镜头

镜头留在恢复后的蘑菇房子外。

- 窗户暖黄灯
- 很轻的烟囱烟
- 山庄正常环境声

然后慢慢淡出。

Ending Card：

**有些记忆会消失。**

停顿。

**有些东西不会。**

停顿。

**猪猪山庄**

**THE END**

设置：

```gdscript
story_phase = StoryPhase.COMPLETED
flags["game_completed"] = true
```

默认回到 Title / Main Menu。

不要自动覆盖玩家最后一个手动存档。

---

# 29. 可选彩蛋

THE END 后：

小呆猪：

“白菜？”

白白菜：

“嗯？”

小呆猪：

“芋圆肚瓜圆。”

白白菜：

“……”

“你到底要说多少遍？”

小呆猪：

“一辈子！”

跑走。

白白菜：

“小呆猪！！”

---

# 30. Godot 交互系统最低接口

所有可交互物实现统一接口：

```gdscript
class_name Interactable
extends Area2D

@export var interaction_id: String
@export var prompt_text: String = "调查"

signal interacted(actor)

func interact(actor: Node) -> void:
    interacted.emit(actor)
```

玩家只负责检测与发起交互。

探索时可以使用角色前方短距离 `Area2D` 或 `RayCast2D` 判断当前面对的可交互物；不要依赖屏幕坐标。

具体剧情逻辑由对应 scene controller / story trigger 处理。

不要让 Player script 知道“猪猪杯”“BIG IDEA”“礼物纸”是什么。

---

# 31. Trigger 最低接口

```gdscript
class_name StoryTrigger2D
extends Area2D

@export var trigger_id: String
@export var one_shot := true

signal triggered(trigger_id: String)

var consumed := false
```

永久剧情是否已完成由 GameState 判断。

本场景临时触发由 trigger 自己管理。

---

# 32. 摄像机演出

探索 camera 与 cinematic camera 逻辑分离，但不强制堆很多 Camera2D。

建议优先：

```text
CameraRig (Node2D)
└── Camera2D
```

Gameplay 时使用平滑跟随；Cutscene 时由 CutsceneDirector 暂时接管同一台 Camera2D 的 `position`、`offset`、`zoom` 与 shake。只有确实更清晰时才额外放置 cinematic Camera2D。

需要：

- 巫师靠近水晶球
- 环视黑暗森林
- 白白菜从远处出现
- “芋圆肚瓜圆”近景
- 两人牵手
- 山庄恢复
- 最终蘑菇屋外景

不要把所有 camera path 写死在全局脚本。

每个场景用 AnimationPlayer / Tween / Path2D 控制自己的 Camera2D 演出。

---

# 33. 音频

建议 Bus：

```text
Master
├── Music
├── Ambience
├── SFX
├── Dialogue
└── UI
```

需要支持：

- BGM crossfade
- ambience 保持
- cutscene 中降低 Music
- “芋圆肚瓜圆”前 1 秒近乎静音
- 魔法爆发时 SFX 峰值不能压爆对白

---

# 34. 第一批应该真正实现的内容

不要一口气做完整游戏。

第一阶段目标是建立一个真正可玩的“双角色玩法样板”，而不是把所有已写剧情一次全部实现。

## 34.1 白白菜 Vertical Slice

```text
Boot / Debug Start
→ Chapter 1 Wake Up
→ 家中基础探索
→ Coffee Interaction
→ 调查 Pig Cup / Double Tableware
→ 解谜：复原双人早餐位
→ Kitchen Memory Echo
→ cabbage_resonance_progress = 1
→ Slice End
```

BIG IDEA、Pig Pillow、红色包装纸以及后续白白菜场景继续保留在总剧情中，但**不要求第一批同时完成**。等第一个解谜的交互、镜头、对白与存档模式稳定后再逐个追加。

## 34.2 小呆猪 Vertical Slice

```text
Debug Start / Dark Forest Entry
→ 小呆猪确认要寻找散落的礼物碎片
→ 进入第一片森林空地
→ Forest Slime Encounter
→ 简单实时战斗
→ Slime Defeated
→ 拾取第一块 Gift Fragment
→ 写入 GameState.gift_fragments
→ Slice End
```

小呆猪不使用 Heart 恢复系统。第一批只验证“移动 + 攻击 + 受伤 + 敌人前摇 + 胜利 + 礼物碎片拾取”。

## 34.3 序章的处理

完整序章剧情仍然属于正式游戏：

```text
Castle
→ Gift Wrapping
→ Wizard Discovers Cabbage
→ Curse
→ Piggy Manor Darkens
→ Title
```

但为了开发效率，第一批必须提供 Debug Start，可直接启动白白菜解谜 slice 或小呆猪战斗 slice，不需要每次 playtest 都重放完整序章。正式 New Game 之后再接回完整顺序。

第一批可以全部使用 placeholder 2D sprite、简单几何图形或临时 spritesheet。目标不是最终画质，而是验证：

- 项目架构干净
- 两个角色的 gameplay loop 都能独立运行
- Dialogue System 可维护
- Interaction / PuzzleController 可扩展
- Combat components 可复用
- Cutscene 不会重复
- GameState 能保存礼物碎片与白白菜共鸣状态
- Camera / VFX / Audio 接口合理

完成这两个样板后，再逐次加入一个新场景或一个新玩法模块，不一次性铺完整地图。

---

# 35. 首批验收标准

## 工程

- [ ] 项目在 macOS Godot 4.7.2 可打开。
- [ ] 当前目录是新 Git repo。
- [ ] 工程没有无关的历史兼容代码。
- [ ] `.godot/` 不进入版本控制。
- [ ] project run 无 script error。
- [ ] 所有新增资源路径使用 Godot `res://`。

## 2D 表现与动作

- [ ] 项目核心 gameplay 全部使用 2D node / physics / sprite。
- [ ] 玩家移动为连续移动，不强制锁格。
- [ ] Player 有起步与停步缓动，不是瞬间满速 / 瞬间停。
- [ ] Idle 至少有一种轻微循环动作。
- [ ] Walk 动画方向与速度正确，不明显滑步。
- [ ] 剧情中的转身、犹豫、后退、靠近不是用瞬移替代。
- [ ] 小呆猪第一次攻击具有明显前摇、命中、收招。
- [ ] Slime 攻击前有可读的预警动作。
- [ ] 受击有明确视觉反馈。
- [ ] Camera2D 跟随与剧情移动使用缓动。
- [ ] Joy Particle / Purple Fog / Memory Echo 使用 2D VFX。
- [ ] 场景至少有背景、Gameplay、前景/VFX 的视觉分层。

## 架构

- [ ] Player 不负责剧情逻辑。
- [ ] Dialogue 文本独立数据化。
- [ ] Cutscene 按场景拆分。
- [ ] GameState 仅保存跨场景状态。
- [ ] SceneRouter 仅处理场景切换。
- [ ] Interactable 接口统一。

## 剧情

- [ ] 小呆猪是女生。
- [ ] 白白菜是小男孩。
- [ ] 白白菜醒来表现为“空心小男孩”，而不仅仅是“忘了一个人”。
- [ ] 小呆猪没有空心或失忆设定；她始终记得白白菜。
- [ ] 小呆猪没有 Heart 恢复/0–8 心心任务。
- [ ] 小呆猪当前主任务是寻找礼物碎片。
- [ ] 第一批白白菜玩法只实现一次“复原双人早餐位”解谜。
- [ ] 第一批小呆猪玩法只实现一次 Forest Slime 轻量战斗并获得第一块礼物碎片。
- [ ] 序章明确表现“小呆猪想到白白菜 → 快乐能量上升”。
- [ ] 巫师发现“白菜”是触发点。
- [ ] 第一幕不提前揭示完整小呆猪。
- [ ] 三次共鸣逐渐清晰。
- [ ] 第三段才第一次听清“白白菜”。
- [ ] 红色包装纸把白白菜引向门外。
- [ ] 小呆猪承认自己怕黑。
- [ ] “害怕也可以往前走”必须保留。
- [ ] 最终重逢时白白菜仍不认识小呆猪。
- [ ] 即使不认识，他仍觉得她非常重要。
- [ ] “芋圆肚瓜圆”触发真正记忆恢复。
- [ ] 最终胜利不是传统战斗。
- [ ] 两人牵手后的快乐力量击碎遗忘魔法。
- [ ] 山庄恢复。
- [ ] Ending 主题完整。

---

# 36. Codex 开工指令

把下面这一段视为实施命令：

> 在当前目录中创建/继续一个**全新的 Godot 4.7.2 GDScript 项目**《猪猪山庄——被遗忘的快乐——》。这是一个新的 macOS 项目和新的 Git repo。只以当前 repo、本文件和用户之后明确导入的新素材为工程事实来源。按照本文件定义的目录、GameState、SceneRouter、SaveManager、Dialogue、Interaction、Cutscene 与 2D 场景架构实现。
>
> 第一阶段只实现第 34 节定义的两个 gameplay slice：一次白白菜环境解谜、一次小呆猪 Forest Slime 轻量战斗。小呆猪没有空心/失忆/Heart 恢复系统，她始终记得白白菜；她的当前任务是寻找礼物碎片。美术资源缺失时用集中管理的 placeholder，不要阻塞逻辑。不要自行改写已经提供的核心对白。对于资料中明确缺失的逐字对白，用 `TODO_DIALOGUE` 标记，不要冒充原稿。每完成一个可运行阶段后做 playtest，并保证控制台没有新增错误。
>
> 开始前先检查**当前新 repo 自身**的文件结构和 Git 状态，只用于避免覆盖本次项目中已经创建的内容。若当前目录没有 Godot 项目，则创建 `project.godot` 和基础目录。如果当前目录没有 `.git`，初始化新的 Git repo。
>
> 首批完成后输出：
> 1. 新增/修改的文件；
> 2. 当前 scene tree 与关键脚本；
> 3. 已实现的剧情段落；
> 4. placeholder / missing assets；
> 5. playtest 结果；
> 6. 下一阶段建议；
> 7. `git status --short --branch` 结果。
