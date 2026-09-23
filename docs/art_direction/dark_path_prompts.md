# 黑暗小径素材 · 2026-09-21

工具：内置 image_gen。原始生成文件已复制进项目，未覆盖既有角色或背景。参考图为 `assets/chapter2/pig_unified/frames/cape_right_00.png`，生成前已查看。

## 森林背景

输出：`assets/chapter2/dark_path/forest_v1.png`，1536×1024。

Use case: illustration-story. Game background, wide 3:2 composition. A dark enchanted forest path immediately outside a cave, hand painted gouache storybook art, muted navy teal and charcoal, mossy rocks and twisted roots. Camera slightly elevated, path runs horizontally left to right across lower third at 72 percent image height, broad flat uninterrupted walkable dirt strip. Cave opening at far left (10 percent image width), rock arch extends off left edge. Deep dense forest behind. Right half path continues through roots. No visible hole yet, no characters, no lights, no glowing mushrooms, no moon, no text or UI. Detailed natural textures locally visible in neutral dim lighting; game engine will add almost black darkness and moving character light. Foreground sparse dark ferns at bottom edge. This is a production environment plate for a side scrolling fairytale game. Output landscape 1536x1024.

## 小猪动作

输出：`assets/chapter2/dark_path/pig_actions_source_v1.png`，1536×1024 RGBA。已检查透明角落与帧间空隙alpha=0；图像工具预览的深色区域不代表游戏内黑底。保留原图alpha，使用AtlasTexture显式区域，不做色键抠图。

Use case: identity-preserve. Create a game sprite animation sheet on genuinely transparent background. Reference is exact character identity: small pink girl pig, simple black oval eyes, dark hooves, red cape and round pink clasp, no clothing additions. Match hand painted fine shaded outline style exactly. 1536x1024 sheet, six separate full-body poses in 3 columns by 2 rows, generous transparent gutters, all same visible body size, no floor shadows. Top row: right-facing walking contact left foot forward; right-facing passing pose legs under body; right-facing walking opposite contact right foot forward. Bottom row: right-facing opposite passing pose; startled losing balance leaning backward arms raised with cape flaring; falling down a hole arms reaching up, feet dangling, cape lifted above shoulders by air. Side view, whole body visible including ears cape feet. No text no labels no decorations no borders no checkerboard. Each cell contains exactly one complete character centered, no overlap. These are production sprite frames, same proportions and consistent silhouette, drawn as movement poses not merely translated duplicate images.

## 接入与边界检查

行走alpha主要内容实测约387×356、380×358、385×355、381×361像素；所有帧按0.46统一缩放，可见身高约164–166世界像素，剧情姿势保留伸展差异。脚底与躯干中心按各姿势显式锚定；`dark_path.gd` 中 REGIONS／ANCHORS 是消费源。向左通过镜像实现。背景同坐标UV用于前沿遮挡与落石，避免再次生成不匹配的前景。

不是最终完整动画表：仅四帧步行、一个失衡姿势、一个坠落姿势；连续相位、重心起伏、旋转、重力下落与遮挡由Godot实现。没有生成音频。独立样片入口与限制见 `../DARK_PATH_PREVIEW_ZH.md`。
