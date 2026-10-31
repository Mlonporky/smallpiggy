# 最终章连续牵手与 Trail 闪回 · 2026-10-08

## 运行

Godot 打开 `scenes/finale/handhold_preview.tscn`，按 F6。约 12 秒，结尾空格／E 重看，Esc 菜单、M 静音。这个样片读取正式最终章的角色和动作；不改 GameState 或玩家存档。

完整最终章仍为 F5 →「最终章 · 独立预览」。Trail 动态闪回在听到暗号后的完整回忆中。

## 实现范围

- 小猪读取用户的 editable_pig.tscn，只改运行副本；A/B 是部件编号，未重新推断自身左右。
- 最终章小猪从道路到回家使用同一套装配；白菜在恢复形态后使用新分层部件。其它章节原角色未替换。
- 白菜走近 2 秒、伸手 1.2 秒、小猪停顿 0.8 秒、回应 1 秒、接触后停留；保持各自肩髋位置和部件大小，用实际手部接触位置产生共享光粒。静态 holding_hands_v1.png 只保留为回忆插图，不再顶替现实角色。
- 牵手后保持两只独立角色，直到镜头转向山庄。任意相关镜头重载会重建相同姿势。
- Trail 闪回从 3 秒静态背景改为 5.2 秒动作，复用橡子回忆的真实地面拾取，接触后才归手，无新增对白或剧情标记。
- 白菜素材存在不规则排布，按 alpha 内容边界裁切；躯干右下用透明间隙多边形排除相邻脚片。没有把图按等格切开。
- 修正分层角色穿到回忆卡片／对白上方的 Z 层级；修正巫师消散时 X 坐标逐帧累加，现按镜头时间确定位置。

## 新素材

`assets/finale/cabbage_parts_v1.png`，1536×1024 RGBA，mipmap 已开启。内置 image_gen 生成，参考原牵手插图和白菜行走表。源文件不覆盖旧资源。工具原始输出与该文件一致。

### 原始提示词

Use case: illustration-story. Create a production 2D cutout animation PARTS SHEET of ONLY the little cabbage character, matching the cabbage identity and watercolor storybook paint in the two references. Reference 1 shows its face and round body beside the pig; reference 2 its leaf hair and pale cream green limbs. Do not include the pig. Real transparent background, NO glow, NO shadows, NO text, NO checkerboard. One large complete HEAD + TORSO connected as a SINGLE piece in the LEFT HALF, facing three-quarter LEFT as in reference 1: leaf hair framing head, friendly black oval eyes, pink cheeks, smiling, small round pale cream cabbage torso below. The body piece has NO ARMS and NO LEGS and no stumps; paint complete smooth torso outline so detached limb sprites can overlap it cleanly. Keep neck/head/body connected. Four isolated separate small limb pieces in the RIGHT HALF with generous transparent gutters: upper row TWO simple rounded pale cream green arms, shoulder at top and rounded mitten hand at bottom, one single segment each, no elbow; lower row TWO short rounded legs with feet at bottom pointing LEFT. All four pieces at natural consistent proportions relative to the large body, not magnified diagrams. Each limb must be visibly separate from all other parts. Fine olive watercolor edges and warm cream light, same storybook materials and proportions as reference, no clothes, no human fingers, no objects. Layout is an atlas for fixed shoulder/hip rotation, NOT animation poses and NOT multiple complete characters. Landscape 1536x1024 composition.

## 限制

这是固定关节的手绘部件程序动画，不是逐帧手绘；头身仍为完整一片，没有新表情、眨眼或精细指尖握紧。白菜与小猪的新组合待用户观感验收，几何通过不等于动画自然。白菜回忆步态仍为旧四帧。巫师还是旧像素图；变身、山庄分层恢复、完整配乐与脚步鸟鸣仍待做。

短视频采用固定 30 fps 渲染，为无音轨预览；不能当作运行时性能证据。播放性能由独立的正常速度测试记录。
