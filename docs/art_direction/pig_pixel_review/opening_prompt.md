# 开场小呆猪替换

工具：内置 image_gen。编辑对象为 `assets/prologue/gift_wrapping.png`，角色参考为用户确认的 `bigidea/02_pig/小呆猪披风-像素画风预览.png`。结果保存为 `assets/prologue/gift_wrapping_cape.png`，旧图保留。输出为静态插画中的姿势适配，不是把行走帧直接盖到旧角色上。

实际提示词：

> Edit image 1 locally: replace ONLY the living pig character beside the gift table with the red-CAPE pig from image 2. Image 2 is a sprite character reference, its gray checkerboard must NOT appear. Pig must have that same simple pixel-art dark stepped outlines, flat pink face and red flowing cape fastened with round pig clasp, no furry watercolor skin, no scarf. Keep standing at exactly the original location facing right and reaching to wrap the SAME gift, same total occupied character bounds. Keep the entire room, bed pillow pig, lighting, all furniture, table, presents, plant succulent, bow, wrapping paper, tools and everything else unchanged and perfectly registered to image 1. Do not add new objects. Single complete scene image 1672x941 with the same framing.

人工查看输出及实际引擎截图，原多肉、桌上礼物、工具仍在；传送终点沿用 `gift_empty_v3.png`，实机确认人物和礼物消失。生成式编辑不能承诺背景逐像素一致。
