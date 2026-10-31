# 男孩手绘部件候选 v1

工具：内置 image_gen；用途：第四阶段独立角色与动作样片，未经用户观感验收，不替换正式 atlas。

输入1（编辑目标／身份）：assets/chapter1/boy.png。
输入2（画风参考）：assets/characters/pig_single_joint/parts_v1.png。

Use case: style-transfer / identity-preserve.
Redraw the little human boy from reference 1 as a production-friendly cutout puppet asset sheet in the soft hand-painted gouache children's-book style of reference 2. The pig is a paint-style reference only; do not include any pig anatomy or pig clothing. Preserve the boy's ash-brown tousled hair with the small top tuft, round young face, small dark eyes, cream long-sleeved tunic with a restrained moss-green hem pattern, olive-green short shoulder cape/scarf tied at the neck, brown trousers and short dark-brown boots. Neutral, quiet expression appropriate to the boy who has lost his emotional connection. No new accessories or emblems.

A single right-facing three-quarter orthographic view, the same slightly elevated 2.5D camera as the right-facing third row of reference 1. Compact chibi proportions, no pixel grid; soft broad gouache shading, thin warm dark contours, subtle paper texture, no plastic or glossy toy rendering. One coherent character design across all pieces.

Make a genuinely transparent 1536x1024 production sheet with five well-separated parts and generous transparent gutters. Left half: one large continuous HEAD + NECK + TORSO + TUNIC + CAPE piece; head and body are permanently connected, no detached neck. End the tunic naturally above the thighs; no arms or legs baked into this body. Upper right: two complete short sleeve-and-mitten arm pieces, each a single rigid segment from rounded shoulder root to small human hand. Lower right: two complete short trouser-leg-and-boot pieces, each a single rigid segment from rounded hip root to sole. Paint overlapping upper roots in the same material so the tunic can cover the joints. All parts at exactly the same source scale and same light direction; both arms same physical length, both legs same physical length and boot size, anatomically plausible for this boy. The cape stays part of the body, visible behind him on the screen-left. Only these five assets, no assembled duplicate, no extra heads, no text, numbers, arrows, borders, ground plane, cast shadow or checkerboard. Keep every edge fully inside its own region; no crop, no cross-part overlap. True alpha transparency between and around pieces.

## 定向修正

初稿在头身部件内残留了一段袖子，不能直接叠加独立手臂。再次使用内置 image_gen，编辑同一张图，要求：只移除大部件左侧披风下烘焙的袖子，补为连续无臂的奶油色衣身；保持脸、头发、安静表情、披风、衣纹、四肢素材、尺度和排版。保留透明背景，不增加第三条袖子或额外附件。

初稿：`exec-cf6f41bc-588c-4b7a-81f3-0677e28be3c3.png`，未接入。
选用修正版：`exec-5fca4a51-8c00-4c43-8c3d-0469e1b38755.png`，复制至 `assets/characters/boy_handpainted_v1/parts_v1.png`。
源图均保留于本会话的 Codex generated_images 目录；实际预览只引用仓库内版本。
