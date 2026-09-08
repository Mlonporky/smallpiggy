# 第一阶段实现状态

## 当前入口

```text
Bootstrap / Debug Start
├── 新游戏：prologue.tscn
│   ├── 古堡水晶球警报 / 巫师登场
│   ├── 小呆猪包装礼物 / Joy Particle
│   ├── 巫师锁定“白菜”触发点 / 遗忘之咒
│   ├── 猪猪山庄熄灯 / 小呆猪呼喊
│   └── 标题卡 → 自动进入第一幕（Esc 可跳过）
├── 白白菜篇：cabbage_home.tscn
│   ├── 醒来对白
│   ├── 咖啡机
│   ├── 猪猪杯 / 粉色餐具调查
│   ├── 两个餐位候选点
│   └── 正确复原 → 模糊记忆残影 → 共鸣 1 → 自动保存
└── 小呆猪篇：forest_clearing.tscn
    ├── 害怕也可以往前走
    ├── 连续移动 / 三点生命 / 近战攻击
    ├── 史莱姆 0.8 秒前摇 / 跳扑 / 受击 / 消失
    └── 拾取 fragment_red_wrap_01 → 自动保存
```

## 架构

- `GameState`：只保存跨场景故事状态、白白菜共鸣、剧情 flags 与礼物碎片。
- `SceneRouter`：只做 fade 与换场。
- `SaveManager`：将 JSON 保存到 Godot `user://`。
- `DialogueUI`：读取章节 JSON，逐字显示，并发出行开始/结束信号。
- `Interactable`：玩家只检测并调用统一的 `interact()`；不认识具体剧情物件。
- `BreakfastPuzzleController`：只判断持有物与餐位是否匹配。
- `HealthComponent` / `HitBox2D` / `HurtBox2D`：玩家和敌人共享的战斗组件。
- `ForestSlime`：只负责自身战斗并发出 `defeated`，不知道剧情。
- `Prologue`：场景自有 CutsceneDirector，使用自动对白、镜头震动、白闪、魔法阵、雾、窗灯与标题转场。

## 使用的素材

- 已使用：`white_cabbage.png`、`little_pig.png`、`evil_wizard.png`、`crystal_ball.png`、`joy_particles.png`、蘑菇屋内外景与猪猪山庄背景。
- 已导入、等待后续章节：`cabbage_creature.png`、`big_idea_painting.png`。
- 当前程序化 placeholder：住宅和森林底图、家具、杯子/餐具、史莱姆、礼物碎片、雾和快乐粒子。
- 当前缺失：正式古堡背景、正式 tileset、史莱姆 spritesheet、完整动作帧、BGM、环境音与 SFX。

## 验证

- Godot 版本：`4.7.2.stable.official.ed1daf0bf`。
- 主菜单、完整序章、白白菜场景、小呆猪场景均能独立实例化。
- `tests/smoke_test.gd` 通过。
- `tests/gameplay_test.gd` 通过：移动、玩家攻击、敌人伤害、错误/正确餐位、自动对白、重复碎片保护、状态序列化。
- OpenGL Compatibility（Apple M1）完整序章 210 帧低帧率时间线视觉验收通过。

## 下一阶段建议

先在用户本机完整观看一次序章，记录对白速度、镜头节奏和紫色诅咒强度。确认后进入第二阶段：补 BIG IDEA、猪猪抱枕、红色包装纸和白白菜出门；同时等待正式古堡背景与音频素材。
