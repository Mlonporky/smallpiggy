> 已失效：用户随后否决关节动画并要求撤回。现已恢复原动画，以下只保留历史定位记录，不作为继续修复或接入的指令。

# 圆润小猪动作修复交接 · 2026-10-02

## 当前结论

用户认可圆润小猪的**静态造型**，但明确指出最新动作样片“胳膊是错位的，头也转向一个很奇怪的方向”。这版动画没有通过美术验收。用户随后要求写 handoff，本轮停在检查与原因定位，**尚未实施新的修复**。

不要将上一轮的自动测试通过、帧率记录或视频导出成功解释为关节、朝向与动作质量通过。不要再次请用户确认已经认可的短鼻圆润造型。

## 必须先读

- 仓库 `AGENTS.md`。
- `WORKLOG.md` 最近两条圆润小猪记录，以及本次交接记录。
- `docs/STORY_AND_ART_DIRECTION.md` 最新造型与橡子回忆设定。

工作区有上一轮全部未提交改动，包括剧情接入、素材、测试、预览和文档；保留它们。没有提交、推送或启动子代理。用户本轮没有授权自动推送。

## 已确认方向与当前范围

- 已确认设计图：`docs/art_direction/pig_round_v2/design_preview.png`。短贴脸鼻、饱满脸颊、圆肚子、短四肢、粉色皮肤、红披风与猪脸扣。
- 当前只接入橡子回忆及独立动作预览。森林、平台跳跃、开场、第一幕模糊猪影尚未推广。
- 橡子回忆对白、白菜形态、粉色柔雾和剧情／存档条件不得因修复造型擅自改变。
- 先修好并查看短样片，再推广其他场景。

## 文件入口

| 文件 | 用途 |
| --- | --- |
| `scenes/cabbage_act2/round_pig_rig.gd` | 核心问题所在：八个 Sprite2D 分层、手脚目标、头／身体变换、项链 |
| `assets/characters/pig_round/parts_v2.png` | 内置 image_gen 生成的透明八部件原图；不是逐帧动画表 |
| `scenes/cabbage_act2/acorn_memory_actor.gd` | 将小猪放在512×512透明 SubViewport，合成后统一加柔雾；白菜仍用原四帧 |
| `scenes/cabbage_act2/acorn_memory.gd` | 实际剧情动作时序，手碰到橡子后转交到角色；移动距离325 |
| `scenes/cabbage_act2/pig_motion_preview.tscn` / `.gd` | F6独立样片；清晰默认，M切回忆柔雾，播完空格／按钮重播；不写存档 |
| `scenes/cabbage_act2/acorn_memory_preview.tscn` | 带背景、白菜和对白的完整回忆预览 |
| `tests/pig_round_motion_test.gd` | 脚掌目标、项链轨迹、画布边界、拾取交接、M键与状态隔离 |
| `tests/acorn_memory_test.gd` | 对白、拼图触发、返回房间、隔离存档恢复、重看 |
| `docs/PIG_ROUND_MOTION_ZH.md` | 现有使用说明及制作限制；修复后同步更新 |
| `docs/art_direction/pig_round_v2/rig_prompt.md` | 八部件生成提示词 |
| `docs/art_direction/pig_round_v2/motion_preview.mp4` | 用户指出问题的旧12秒视频，不能当作修复后结果 |
| `docs/art_direction/pig_round_v2/review/` | 旧静态审阅图，同样尚未反映修复 |

## 已定位问题

### 1. 近／远侧手臂装反

对照已确认设计图的中间三分之四朝右视角：近侧手臂应在画面左侧、身体前方；远侧手臂应在右侧。目前 `update_parts()` 将近肩放在 `(28,-28)`，远肩放在 `(-26,-28)`，近手常态也放在右侧，远手放左侧。

同时近臂强制 `z_index=2`，远臂大部分时间在身体后面，戴项链时又切层。这让左侧胳膊被遮住，右侧胳膊像从错误位置长出来。修复须同时改肩位、手目标与绘制顺序，不能只交换素材名。

### 2. 整条手臂按目标距离拉伸，缺少真实关节锚点

`limb()` 用素材包围盒中心摆整张图，以 `vector.length()+10` 改高度，再按肩到手的方向转整条手臂。原图胳膊本身是弯的，真正肩点和蹄点并不在包围盒中轴上，因此数学上的起终点不等于画面上的关节和手。

手靠近肩或越过胸前时，整条胳膊会压扁、拉长或翻转。上一轮的接触检查验证的是 `near_hand` 目标坐标，没有验证素材中的实际蹄点。

### 3. 头、领口、躯干分开移动

蹲下时躯干旋转约0.60弧度，头约0.20弧度，还额外平移 `(13*crouch,24*crouch)`；领口只旋转约0.04弧度。头绕图片中心转，而不是绕颈部连接点转。结果是头和领口脱节、头身方向不协调。不要用更大的整头旋转冒充低头看橡子。

## 建议修复路径（尚未实施）

1. **先校准静止装配。** 使用已确认三分之四朝右视角，校正近／远肩、手臂前后关系；对照设计图看完整身体轮廓，而非只看脸。
2. **使用实际关节锚点。** 实测原图肩、肘、蹄中心；保持合理固定臂长，限制可达范围。考虑将现有手臂做两段网格变形／两关节控制，或生成专用手臂姿势。具体实现尚未决定，不要把这一建议当作已完成代码。
3. **将头绑定到颈部／领口。** 用同一父变换或明确颈部锚点连接，减小头的独立旋转。头、胸腹、肩位必须使用同一朝向与透视。
4. **重做可达的拾取动作。** 校正近侧手臂后，不应继续强迫短手跨越整个身体伸到原 `(68,-10)`。必要时调整停步位置、蹲下重心和橡子落点，保持先碰到再拿起，避免橡子在地上跳位。
5. **逐姿势复查。** 站立、两脚交换、接近停步、蹲下中途、触碰、起身中途、持橡子、举圈、过头、放手。特别看胳膊是否脱肩、头是否脱颈、蹄子是否真的接触道具、层级切换是否突然。
6. 更新短视频与回忆接入后再报告，不沿用旧视频。

如果更换为网格部件，`tests/pig_round_motion_test.gd` 当前直接读取 Sprite2D 的 `texture/offset/transform` 做边界检查，需要按实际节点类型更新。新测试应覆盖实际锚点变换，而不是仅验证代码里的手目标。

## 现有验证及其局限

上一轮通过：`PIG_ROUND_MOTION_OK` headless和Mac图形、`ACORN_MEMORY_OK` headless和Mac图形、`SMOKE_TEST_OK`、`BOY_ATLAS_TEST_OK`。无截图完整播放约26.01秒，p95 13.13ms，最长20ms。这些只能证明当时流程和性能，无力反驳用户指出的美术问题。

当前素材仍是手绘分层＋程序动画。脸部表情固定，没有独立眨眼、细致穿绳打结、专用战斗动作、新配音／音效。不要宣称已成为完整逐帧手绘动画。

## 运行与导出

Godot：`/Users/missdaidai/Godot.app/Contents/MacOS/Godot`。在仓库根目录：

```sh
/Users/missdaidai/Godot.app/Contents/MacOS/Godot --headless --path . --log-file /tmp/pig-round-motion-fix.log --script tests/pig_round_motion_test.gd
/Users/missdaidai/Godot.app/Contents/MacOS/Godot --headless --path . --log-file /tmp/pig-round-memory-fix.log --script tests/acorn_memory_test.gd
```

图形测试去掉 `--headless`，可加 `--always-on-top`。本机沙箱图形启动此前退出134，授权执行后成功；headless有既有证书提示。不是用户操作错误。

本机临时导出辅助仍存在，但交接后应先检查是否可用：

- `/tmp/pig_round_gallery.gd`：四个旧姿势并排截图，路径为 `/tmp/pig-round-gallery.png`。
- `/tmp/pig_round_encode.swift` 与 `/tmp/pig_round_encode`：将同目录PNG序列按30fps编码为MP4；目标文件须不存在。
- `/tmp/pig_round_verify_video.swift` 与对应可执行文件：解码视频10.8秒处，检查时长、画面方向。
- `/tmp/pig_round_timing_no_capture.gd`：不保存截图的正常速度回忆帧时测量。

Godot可用 `--fixed-fps 30 --write-movie /tmp/新的目录/frame.png --quit-after 360 res://scenes/cabbage_act2/pig_motion_preview.tscn` 导出12秒画面，再编码。macOS编解码器此前需要授权执行才能访问。固定帧率导出不能代替正常速度播放检查，也不能作为运行时性能证据。

## 下一步最小交付

校准后的站立／拾取／戴项链姿势对照 + 正常速度短样片 + 对应回忆回归。报告具体改了哪些连接、实际看过哪些姿势，以及仍未完成的动画，不用“测试通过”代替美术结论。
