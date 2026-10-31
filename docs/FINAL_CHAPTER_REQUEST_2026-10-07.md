# 猪猪山庄 · 最终章
## 小呆猪与白白菜重逢 / 遗忘魔咒终结

---

# 0. 最终章定位

这是游戏正式结局章节。

本章不是传统 Boss Battle。

最终冲突的核心是：

- 小呆猪一直记得白白菜。
- 白白菜因为坏巫师的遗忘魔咒忘记了小呆猪。
- 小呆猪一路寻找白白菜。
- 白菜一路通过各种线索逐渐意识到，自己忘记了一个很重要的人。
- 两个人最终在黑暗森林重新相遇。
- 红披风触发白菜的第一层记忆。
- “芋圆肚瓜圆”彻底唤回白菜的记忆。
- 坏巫师进行最后反扑。
- 小呆猪和白白菜牵手，共同产生快乐能量。
- 遗忘魔咒被彻底破坏。
- 猪猪山庄恢复原状。

---

# 1. 前置剧情状态

## 小呆猪线前置

小呆猪已经：

- 被坏巫师传送到黑暗森林另一端。
- 一直记得白白菜。
- 一直穿着白白菜送给他的红披风。
- 收集过礼物碎片。
- 与黑暗史莱姆战斗。
- 在战斗中解锁技能：

```text
想起白菜
```

技能效果：

```text
回复部分生命值
+
对黑暗物质造成大量伤害
```

剧情含义：

```text
小呆猪想到白菜
↓
产生快乐能量
↓
快乐能量能够破坏巫师制造的黑暗物质
```

在击败史莱姆之后，小呆猪继续寻找回到白菜身边的路。

随后意外掉进地下洞穴。

---

## 白白菜线前置

白白菜已经：

- 被坏巫师施加遗忘魔咒。
- 忘记了小呆猪。
- 但不断对曾经与小呆猪有关的物品产生熟悉感。
- 来到蘑菇屋。
- 输入密码：

```text
2129
```

进入蘑菇屋。

在蘑菇屋中调查：

- 包装纸
- 拼图
- 桌子夹层中的橡子
- 曾经属于两个人的生活痕迹
- 红披风纤维

白白菜仍然没有完全恢复记忆。

但已经明显感到：

```text
这里以前发生过很重要的事情。
```

---

# PART A
# 小呆猪 · 洞穴终点

---

# SCENE 01
# Cave_Platform_End
## 横版闯关结束

场景：

```text
Cave_Platform_Level.tscn
```

这是小呆猪掉进洞穴后的横版闯关地图。

玩家完成最后一个平台区后，到达洞穴出口。

不要加入新的敌人。

最后这一段重点是：

```text
终于找到出口
```

---

## 洞穴出口视觉

出口上方可以看到：

- 微弱的森林光线
- 少量落叶
- 风吹进洞穴
- 红披风轻微摆动

玩家走到：

```text
CaveExitTrigger
```

触发剧情。

---

## Player Input

```text
LOCKED
```

小呆猪抬头。

播放：

```text
LittlePig_LookUp
```

停顿：

```text
0.8 sec
```

然后小呆猪开始往上爬。

如果不制作完整攀爬系统，可以使用：

```text
Fade Out
↓
Scene Transition
↓
Fade In
```

---

# SCENE 02
# Return_To_Dark_Forest
## 小呆猪回到黑暗森林

加载：

```text
DarkForest_FinalPath_Pig.tscn
```

Fade In。

---

## 初始画面

小呆猪从树林边缘或者洞穴出口爬出来。

播放：

```text
LittlePig_ClimbOut
```

他站起来。

拍拍身上的灰。

红披风仍然在。

---

## 环境变化

森林仍然是黑暗森林。

但与之前相比：

- 紫色雾气更少
- 远处出现一点暖色光
- 没有敌人
- 没有战斗音乐
- 没有危险提示

BGM：

```text
DarkForest_AfterStorm
```

非常轻。

---

## 玩家控制

```text
UNLOCKED
```

玩家可以自由控制小呆猪继续向前走。

这里建议保留：

```text
20–40 sec
```

左右的正常探索时间。

不要直接 Cutscene。

让玩家有“终于走完了”的感觉。

---

## 地图设计

地图不需要复杂。

可以是一条相对明确的森林路径。

途中不要再设置：

- 敌人
- 解谜
- 采集任务
- 战斗

只保留：

- 风声
- 脚步声
- 树叶
- 很少量的光粒子

---

## 最终出口

玩家走到：

```text
Pig_FinalPath_Exit
```

进入：

```text
DarkForest_Reunion.tscn
```

---

# PART B
# 白白菜 · 蘑菇屋终点

---

# SCENE 03
# MushroomHouse_FinalPuzzle
## 蘑菇屋最后调查

场景：

```text
MushroomHouse_Interior.tscn
```

玩家已经完成：

```text
2129 密码
```

和：

```text
包装纸拼图
```

---

## 桌子夹层

调查桌子隐藏夹层。

发现：

- 很多橡子
- 一些小收藏
- 包装纸残片
- 很细的红色纤维

---

## 白白菜调查橡子

对白可以保持简单。

白白菜：

“怎么会有这么多橡子……”

停顿。

不要解释。

---

## 调查红色纤维

镜头稍微靠近桌面。

显示：

```text
RedCape_Fiber
```

白白菜拿起它。

---

## 白白菜

“红色的……”

停顿：

```text
1.0 sec
```

然后：

“怎么觉得心里怪怪的。”

---

## Memory Effect

不要直接出现完整回忆。

只做非常弱的视觉效果：

```text
screen_blur
+
soft heartbeat
+
brief red flash
```

时间：

```text
0.4 sec
```

不出现明确人物。

只是让玩家知道：

```text
这个东西触发了什么。
```

---

# SCENE 04
# Cabbage_Leaves_MushroomHouse
## 白白菜离开蘑菇屋

白白菜走到门口。

玩家触发：

```text
MushroomHouse_Exit_Final
```

Fade Out。

加载：

```text
DarkForest_FinalPath_Cabbage.tscn
```

---

## Fade In

白菜站在蘑菇屋外。

森林还是黑暗的。

但远处出现了一点暖色。

---

## 玩家控制

```text
UNLOCKED
```

白菜沿森林道路前进。

与小呆猪线一样：

不要增加新的谜题。

这一段是情绪过渡。

---

## 可选内心对白

如果需要：

白白菜：

“好像……”

停顿。

“还有什么东西在等我。”

如果觉得这句太直白，可以删除。

不影响剧情。

---

## 最终出口

白菜走到：

```text
Cabbage_FinalPath_Exit
```

进入：

```text
DarkForest_Reunion.tscn
```

---

# PART C
# 两条路线汇合

---

# SCENE 05
# DarkForest_Reunion
## 最终森林空地

场景：

```text
DarkForest_Reunion.tscn
```

---

## 场景构图

中央：

一块比较安静的森林空地。

可以有：

- 一棵大树
- 树冠之间透下来的月光 / 暖光
- 少量紫雾
- 风吹动的草
- 飘落的树叶

---

## Spawn Point

小呆猪：

```text
Spawn_LittlePig_Left
```

白白菜：

```text
Spawn_Cabbage_Right
```

---

## 默认顺序

小呆猪先进入场景。

玩家仍然控制小呆猪。

---

## 小呆猪进入中央

到达：

```text
ReunionTrigger
```

触发：

```text
player_input = false
```

---

## 环境

BGM 慢慢降低。

留下：

- 风声
- 树叶声
- 很轻的森林环境音

小呆猪停下来。

红披风轻轻摆动。

---

# SCENE 06
# Someone_In_The_Forest
## 森林另一边的声音

传来脚步声。

```text
SFX:
Forest_Footsteps
```

小呆猪抬头。

播放：

```text
LittlePig_LookUp
```

镜头不要立刻给白菜。

先拍树林另一边。

---

## 白白菜出现

白白菜从画面右侧缓慢走进空地。

然后停下来。

两个人之间保持一段距离。

不要站得太近。

---

## Camera

```text
Camera2D zoom:
1.0 -> 1.1
```

让两个人同时在画面中。

---

## BGM

开始播放：

```text
Reunion_Theme_Intro
```

只使用很轻的钢琴或者音乐盒。

不要立即进入高潮。

---

# SCENE 07
# First_Reunion
## 第一次重新看见彼此

小呆猪愣住。

停顿：

```text
1.0 sec
```

---

## 小呆猪

“白菜。”

---

白白菜看着小呆猪。

没有回答。

---

## 白白菜动作

播放：

```text
Cabbage_Confused
```

他觉得小呆猪非常熟悉。

但想不起来。

---

## 小呆猪

向前走一步。

然后停下来。

对白：

“你还记得吗？”

---

白白菜轻轻摇头。

或者不回答。

---

# SCENE 08
# Red_Cape_Recognition
## 红披风

一阵风吹过。

播放：

```text
Wind_Gust
```

小呆猪身后的红披风被吹起来。

动画：

```text
RedCape_Wind
```

---

## 白白菜反应

白菜突然看向红披风。

环境音迅速降低。

加入：

```text
Soft_Heartbeat
```

屏幕周边轻微模糊。

---

## Memory Flash 01

闪白：

```text
0.15 sec
```

快速出现：

白白菜把红披风送给小呆猪。

不要播放完整回忆。

画面只包括：

- 红披风
- 白菜的手
- 小呆猪开心的表情

持续：

```text
0.5–0.8 sec
```

立即回到现实。

---

## 白白菜

下意识向前走半步。

手微微抬起。

但又停住。

---

# SCENE 09
# Secret_Phrase
## 芋圆肚瓜圆

小呆猪看着白白菜。

这一段必须慢。

---

## 小呆猪

“白菜。”

停顿。

“你还记得吗？”

---

停顿：

```text
1.0 sec
```

然后：

“芋圆肚瓜圆。”

---

# SCENE 10
# Memory_Restore
## 白白菜恢复记忆

触发：

```text
memory_restore_sequence
```

整个森林突然安静。

---

## Audio

```text
BGM STOP
Ambient LOW
```

---

## Visual

画面慢慢变亮。

不是完全白屏。

---

# MEMORY 01

蘑菇房子。

小呆猪：

“白菜！”

---

# MEMORY 02

两个人在一起。

白白菜：

“呆呆猪。”

---

# MEMORY 03

小呆猪拿着礼物。

小呆猪：

“给你的。”

---

# MEMORY 04

两个人走 Trail。

地上有很多橡子。

小呆猪弯腰捡橡子。

白菜在旁边。

---

# MEMORY 05

红披风。

白菜把它送给小呆猪。

---

# MEMORY 06

猪猪杯与白菜杯。

---

# MEMORY 07

两个人靠在一起。

声音：

“芋圆肚瓜圆。”

---

画面最后一次闪白。

---

# SCENE 11
# I_Remember
## “我想起来了。”

返回黑暗森林。

白菜站在原地。

眼睛出现非常轻的泪光。

不要夸张。

---

## 白白菜

“呆呆猪。”

---

小呆猪没有马上回答。

---

白白菜：

“我想起来了。”

---

然后依次出现非常短的回忆画面。

---

白白菜：

“蘑菇房子。”

闪过蘑菇房子。

---

白白菜：

“杯子。”

闪过杯子。

---

白白菜：

“礼物。”

闪过包装礼物。

---

停顿。

白菜看着小呆猪。

---

白白菜：

“还有你。”

---

BGM：

```text
Reunion_Theme_Full
```

正式进入主旋律。

---

# SCENE 12
# Reunion_Close
## 两个人终于重新站在一起

小呆猪往前跑。

但在白菜面前停下来。

不要直接夸张拥抱。

---

白白菜：

“小呆猪。”

---

小呆猪：

“我找到你了就好。”

---

白白菜：

“你找到我了。”

---

停顿：

```text
2.0 sec
```

---

# SCENE 13
# Wizard_Return
## 坏巫师再次出现

快乐的音乐突然出现杂音。

---

## Environment

森林边缘重新出现紫色雾气。

```text
PurpleFog_Spawn
```

天空变暗。

---

紫色魔法阵出现。

```text
WizardPortal_Open
```

坏巫师从魔法阵中出现。

---

## 巫师状态

这一次巫师明显慌张。

因为白菜恢复了记忆。

---

## 小呆猪

立刻挡在白菜前面。

动画：

```text
LittlePig_Protect
```

---

## 对白

小呆猪：

“你只是让他忘记了。”

停顿。

“你没有让那些事情从世界上消失。”

---

# SCENE 14
# Memory_Objects_Appear
## 被遗忘的东西重新出现

小呆猪说完以后。

场景中逐渐浮现非常淡的记忆光影。

包括：

- 礼物碎片
- 红披风
- 猪猪杯
- 白菜杯
- 橡子
- 蘑菇房子
- 玩家收集的心心
- Trail 回忆

这些不是真实物体。

像半透明的记忆。

---

# SCENE 15
# Final_Curse
## 巫师最后的遗忘魔法

坏巫师发动最后一次魔法。

大量紫色黑暗能量从森林四周出现。

---

动画：

```text
DarkCurse_Final
```

黑暗形成巨大的包围圈。

---

## Camera

轻微震动：

```text
CameraShake:
low intensity
```

不要太剧烈。

---

## Important

不要进入 Battle UI。

这是剧情战。

---

# SCENE 16
# Joy_Energy_Returns
## 小呆猪再次使用快乐能量

黑暗魔法逼近。

小呆猪身边出现之前史莱姆战斗中使用过的：

```text
JoyEnergy
```

---

## Visual

金白色光芒包围小呆猪。

但这一次：

黑暗能量太强。

快乐能量逐渐被压缩。

---

小呆猪努力坚持。

但明显挡不住。

---

# SCENE 17
# Cabbage_Steps_Forward
## 白白菜走到身边

白白菜看着小呆猪。

然后走上前。

站到小呆猪身边。

---

黑暗继续靠近。

---

白白菜慢慢伸出手。

这里：

不要对白。

---

# SCENE 18
# Holding_Hands
## 两个人牵手

小呆猪看到白菜伸出的手。

停顿：

```text
0.8 sec
```

然后握住。

---

动画：

```text
Pig_Cabbage_HoldHands
```

---

## Shared Joy Energy

两个人牵手的位置出现第一颗光粒。

然后第二颗。

然后越来越多。

---

以前的：

```text
LittlePig Joy Energy
```

升级为：

```text
Shared Joy Energy
```

---

光粒子围绕：

- 小呆猪
- 白白菜
- 两个人牵着的手

---

# SCENE 19
# Heart_Collectibles_Return
## 心心的真正意义

之前玩家收集过的 Heart Collectibles 依次出现。

它们从森林不同方向飞回来。

围绕两个人旋转。

---

如果玩家实际收集数量不同：

可以根据存档中的：

```text
heart_count
```

生成不同数量。

如果实现复杂：

可以固定使用视觉表现。

---

# SCENE 20
# Joy_Burst
## 快乐能量爆发

两个人周围形成巨大的光圈。

---

紫色魔法开始出现裂缝。

```text
DarkMagic_Crack
```

---

坏巫师后退。

魔法阵也开始破裂。

---

小呆猪看向白菜。

白菜也看着小呆猪。

两个人仍然牵着手。

---

不要攻击动作。

---

## Final Trigger

```text
JoyBurst_Final
```

---

金白色光芒从两个人所在的位置向外扩散。

不是爆炸。

表现为：

```text
soft expanding light wave
```

像晨光一样扫过森林。

---

# SCENE 21
# Wizard_Defeat
## 巫师消失

金色光芒覆盖紫色魔法。

---

依次消失：

- 紫雾
- 黑暗粒子
- 黑暗魔法阵
- 天空中的紫色阴影

---

坏巫师被光覆盖。

不要制作死亡。

不要尸体。

他的身体逐渐变成黑色粒子。

被风吹散。

---

最后：

魔法阵彻底破碎。

---

# SCENE 22
# Curse_Broken
## 遗忘魔咒解除

整个森林安静下来。

停顿：

```text
1.0 sec
```

然后：

鸟叫出现。

---

树木恢复颜色。

草地恢复。

紫色雾气彻底消失。

阳光从树冠照下来。

---

两个人身边的快乐粒子慢慢升上天空。

---

# SCENE 23
# Light_Travels_To_Manor
## 快乐能量飞向猪猪山庄

Camera 慢慢向上移动。

看到快乐能量离开森林。

向远方飞去。

---

Fade / Transition。

---

# SCENE 24
# PiggyManor_Restoration
## 猪猪山庄恢复

场景：

```text
PiggyManor_Dark.tscn
```

---

山庄仍然处于诅咒状态：

- 紫雾
- 暗色
- 灯熄灭
- 植物失去颜色

---

快乐能量进入山庄。

---

## Restoration Sequence

### Step 1

紫色雾气逐渐消散。

### Step 2

房屋窗户重新亮起。

### Step 3

花草恢复颜色。

### Step 4

水面恢复反光。

### Step 5

居民恢复正常。

### Step 6

天空变亮。

### Step 7

猪猪山庄原本的 BGM 重新响起。

---

最后：

```text
PiggyManor_Normal
```

完全恢复。

---

# SCENE 25
# Return_To_Manor
## 两个人回家

Fade Out。

---

Fade In：

```text
PiggyManor_ReturnPath.tscn
```

---

小呆猪和白白菜一起走回猪猪山庄。

---

## Gameplay

重新开放非常有限的玩家控制。

玩家控制小呆猪。

白菜作为：

```text
Follower
```

跟在旁边或者身后。

---

不要再安排：

- 战斗
- 解谜
- 收集

就是安静地走回家。

---

# SCENE 26
# Ending_Home
## 猪猪山庄结尾

玩家进入：

```text
Ending_Home_Trigger
```

锁定控制。

---

两个人站在已经恢复的猪猪山庄里。

---

## 小呆猪

“因为你在这里呀。”

---

白白菜看向小呆猪。

---

## 小呆猪

“只要一直往白菜那里走……”

停顿。

“最后一定会找到你的。”

---

## 白白菜

“以后不用一个人走那么远了。”

停顿。

“我会去找你的。”

---

两个人继续往前走。

Camera 不跟随。

让两个人慢慢走远。

---

# SCENE 27
# Final_Secret
## 最后的暗号

两个人快走出画面时。

白白菜停下来。

---

白白菜：

“芋圆肚瓜圆。”

停顿。

“到底是什么意思？”

---

小呆猪：

“不告诉你。”

---

白白菜追过去。

两个人一起离开画面。

---

# SCENE 28
# Final_Shot

Camera 留在猪猪山庄。

不要立刻黑屏。

---

环境音：

- 风
- 鸟叫
- 山庄 BGM

持续：

```text
3 sec
```

---

然后：

```text
Fade Out
duration = 2.5 sec
```

---

# SCENE 29
# Ending_Title

黑屏。

停顿：

```text
1 sec
```

显示：

```text
猪猪山庄
```

停顿。

然后显示：

```text
THE END
```

---

随后进入：

```text
Credits.tscn
```

---

# GODOT 场景结构建议

```text
FinalChapter
│
├── Cave_Platform_Level
│
├── DarkForest_FinalPath_Pig
│
├── MushroomHouse_Interior
│
├── DarkForest_FinalPath_Cabbage
│
├── DarkForest_Reunion
│
├── PiggyManor_Restoration
│
├── PiggyManor_ReturnPath
│
└── Credits
```

---

# DarkForest_Reunion.tscn 建议结构

```text
DarkForest_Reunion
│
├── World
│   ├── Background
│   ├── Trees_Back
│   ├── Ground
│   ├── Trees_Front
│   │
│   ├── Characters
│   │   ├── LittlePig
│   │   ├── Cabbage
│   │   └── EvilWizard
│   │
│   └── VFX
│       ├── ForestMist
│       ├── PurpleFog
│       ├── MemoryGhosts
│       ├── JoyParticles
│       ├── HeartParticles
│       ├── DarkCurse
│       └── FinalJoyBurst
│
├── Camera2D
│
├── CutsceneController
│
├── AnimationPlayer
│
├── DialogueManager
│
├── Audio
│   ├── BGM
│   ├── Ambient
│   └── SFX
│
├── MemoryOverlay
│
└── FadeLayer
```

---

# 最终章状态机

建议使用：

```text
CAVE_COMPLETE
PIG_RETURN_FOREST
CABBAGE_PUZZLE_COMPLETE
CABBAGE_LEAVE_HOUSE
REUNION_START
FIRST_REUNION
RED_CAPE_TRIGGER
SECRET_PHRASE
MEMORY_RESTORE
CABBAGE_REMEMBERS
WIZARD_RETURN
FINAL_CURSE
JOY_ENERGY_FAILING
HOLD_HANDS
SHARED_JOY
JOY_BURST
WIZARD_DEFEATED
CURSE_BROKEN
MANOR_RESTORE
RETURN_HOME
FINAL_DIALOGUE
FINAL_SECRET
CREDITS
```

---

# 关键剧情变量

建议 GameState 中保留：

```text
slime_defeated = true
cave_level_completed = true
mushroom_house_completed = true
cabbage_memory_restored = false
wizard_defeated = false
curse_broken = false
ending_completed = false
```

---

# 相遇触发条件

只有：

```text
cave_level_completed == true
AND
mushroom_house_completed == true
```

才允许正式执行：

```text
start_reunion_sequence()
```

---

# 白菜恢复记忆

听到：

```text
芋圆肚瓜圆
```

后：

```text
cabbage_memory_restored = true
```

---

# 最终魔法解除

Joy Burst 完成：

```text
wizard_defeated = true
curse_broken = true
```

---

# Credits 之前

设置：

```text
ending_completed = true
```

并 Save Game。

---

# 角色动画需求

## Little Pig

需要：

```text
Idle
Walk
Run
LookUp
BattleIdle
ClimbOut
CapeWind
Protect
HoldHands
Happy
```

所有版本必须穿：

```text
Red Cape
```

不要再出现红围巾。

---

## Cabbage

需要：

```text
Idle
Walk
Confused
MemoryReaction
Emotional
ReachHand
HoldHands
Happy
Run
```

---

## Wizard

需要：

```text
Appear
Idle
Angry
CastFinalCurse
HitByJoy
Dissolve
```

---

# 必要 VFX

```text
Forest Mist
Purple Fog
Red Cape Fiber Glow
Memory Flash
Memory Blur
Soft Heartbeat Screen Pulse
LittlePig Joy Energy
Shared Joy Energy
Heart Collectibles
Dark Curse
Dark Magic Crack
Joy Burst
Wizard Dissolve
Forest Restoration
Piggy Manor Restoration
```

---

# Audio 需求

## Ambient

```text
Dark Forest Wind
Forest Leaves
Footsteps on Leaves
Cave Wind
Birds Return
Piggy Manor Ambient
```

---

## BGM

```text
Cave Platform Theme
Dark Forest Final Path
Reunion Theme Intro
Reunion Theme Full
Final Curse Theme
Joy Burst Theme
Piggy Manor Restored Theme
Credits Theme
```

---

# 剧情实现原则

## 1. 小呆猪没有失忆

绝对不要出现：

```text
LittlePig memory restore
```

他的故事一直是：

```text
白菜忘了他
但他没有忘记白菜
```

---

# 2. 红披风不是装饰

红披风有三层意义。

第一层：

```text
白白菜送给小呆猪的礼物
```

第二层：

白菜在蘑菇屋发现：

```text
红色纤维
```

产生熟悉感。

第三层：

真正见到小呆猪时：

```text
看到完整红披风
↓
Memory Flash
```

---

# 3. 白菜恢复记忆必须分阶段

不要突然恢复。

正确顺序：

```text
蘑菇屋线索
↓
红披风纤维
↓
心里觉得奇怪
↓
真正看到小呆猪
↓
看到红披风
↓
第一次 Memory Flash
↓
听到“芋圆肚瓜圆”
↓
完整恢复记忆
```

---

# 4. 横版洞穴不是独立小游戏

它的剧情意义是：

```text
小呆猪为了回到白菜身边
继续穿越最后的障碍
```

所以洞穴结束以后：

不要再设置 Boss。

不要再加复杂剧情。

出来以后就是：

```text
最后一段回家的路
```

---

# 5. 最终战不是战斗系统

不要使用：

```text
HP
MP
Turn Battle
Attack Button
Skill Menu
```

最终冲突是剧情演出。

---

# 6. “想起白菜”技能必须得到最终回收

前面史莱姆战：

```text
想起白菜
↓
快乐能量
↓
击败黑暗物质
```

最终：

```text
小呆猪已经找到白菜
↓
白菜也恢复记忆
↓
两个人牵手
↓
快乐能量共鸣
↓
遗忘魔咒彻底失效
```

这就是整个游戏机制与剧情的最终闭环。

---

# 7. 最后一幕不要过度煽情

结尾重点不是长篇表白。

最重要的是：

两个人终于重新回到猪猪山庄。

所以最后仍然使用：

白白菜：

“芋圆肚瓜圆。”

“到底是什么意思？”

小呆猪：

“不告诉你。”

然后两个人离开画面。

这样故事最终落回：

```text
他们两个人原本的相处方式
```

而不是停在打败巫师这件事上。

---

# FINAL FLOW

```text
小呆猪击败史莱姆
↓
掉进洞穴
↓
横版闯关
↓
离开洞穴
↓
黑暗森林最后道路
↓
────────────────

白菜进入蘑菇屋
↓
2129
↓
包装纸拼图
↓
橡子
↓
红披风纤维
↓
离开蘑菇屋
↓
黑暗森林最后道路
↓
────────────────

两条路线汇合
↓
小呆猪：“白菜。”
↓
“你还记得吗？”
↓
红披风
↓
Memory Flash
↓
“芋圆肚瓜圆。”
↓
白菜恢复记忆
↓
“我想起来了。”
↓
坏巫师出现
↓
“你只是让他忘记了。”
↓
“你没有让那些事情从世界上消失。”
↓
Final Curse
↓
小呆猪快乐能量无法抵挡
↓
白菜伸手
↓
两个人牵手
↓
Shared Joy Energy
↓
Heart Collectibles Return
↓
Joy Burst
↓
坏巫师消失
↓
遗忘魔咒解除
↓
猪猪山庄恢复
↓
两个人回家
↓
“以后不用一个人走那么远了。”
↓
“我会去找你的。”
↓
“芋圆肚瓜圆。”
↓
“到底是什么意思？”
↓
“不告诉你。”
↓
THE END
```