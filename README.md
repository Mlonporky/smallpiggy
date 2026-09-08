# 猪猪山庄——被遗忘的快乐——

Godot 4.7.2 / GDScript / 2D 叙事冒险。当前版本实现规格中定义的首批“双角色玩法样板”。

## 已实现

- 完整序章动画：古堡水晶球、礼物包装、巫师发现快乐来源、遗忘之咒、山庄熄灯与标题卡。
- 白白菜：醒来、咖啡交互、调查粉色猪猪杯与双人餐具、复原早餐位、Kitchen Memory Echo。
- 小呆猪：森林探索、3 点生命、近战攻击、史莱姆前摇与跳扑、拾取第一块礼物碎片。
- 三个 Autoload：`GameState`、`SceneRouter`、`SaveManager`。
- 数据化对白、统一 Interactable、可复用 HitBox/HurtBox/HealthComponent。
- Debug Start 主菜单，方便直接测试两个 slice。

## 运行

1. 安装 Godot 4.7.2 stable 标准版。
2. 打开 Godot Project Manager，点击 **Import**。
3. 选择本目录中的 `project.godot`。
4. 点击右上角运行按钮，或按 `F6/F5`。

按键：`WASD` / 方向键移动，`E` / 空格调查，`J` / `Z` 攻击，`F5` 快速保存。

详细的新手步骤见 [`docs/MAC_FIRST_RUN_ZH.md`](docs/MAC_FIRST_RUN_ZH.md)。
