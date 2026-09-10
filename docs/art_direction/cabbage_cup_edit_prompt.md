# 白菜杯地图修正 · 2026-09-09

方式：内置 image_gen，edit 模式。输入：assets/chapter1/kitchen_v2.png（编辑目标）、bigidea/白菜杯.png（参考）。输出：assets/chapter1/kitchen_cabbage_cup_edit.png，1448×1086。游戏仅使用该图 Rect2(1032,310,76,66) 的局部区域，原厨房其他像素保留。用户两张高清杯子原图另存 pig_cup_hd.png / cabbage_cup_hd.png。

## 完整提示词

Edit target: image 1, the 1448x1086 hand-painted kitchen game background. Reference: image 2, the desired cabbage mug. Make ONE tiny local change: replace ONLY the green mug on the upper counter immediately right of the pink pig mug, centered around x1064 y345 in image 1. Currently it wrongly has a pig snout. Replace it with a small cabbage-shaped mug matching image 2: layered green cabbage leaves around a pale green face, two brown eyes, simple smiling mouth, pink cheeks, right-side handle. Match the same size, position, countertop contact, perspective and warm lighting as the existing green mug (roughly 60 pixels wide, 55 high). Keep the pink mug intact, coffee machines intact, all dishes intact, every door, wall, furniture and background framing unchanged. Output the complete kitchen background at the original 4:3 aspect ratio, tightly preserve original composition and object coordinates, no text or other changes.
