# 橡子回忆 · 内置 image_gen 原创素材

2026-10-01。全部原稿非破坏保存到 `assets/cabbage_act2/acorn_memory/`。猪与白菜参考为当前角色，未重画 BIG IDEA。生成图片只是动作姿势与背景，动画由 Godot 设计与驱动，不称为自动生成完整视频。

## pig_pickup_empty_v1.png

原动作表的蹲下姿势已拿着橡子；新增空手拾取姿势，使用独立透明图，不覆盖原图。

```text
Use case: illustration-story
Asset type: one transparent crouching animation pose for Piggy Manor.
Reference image: the eight-pose pink girl-pig atlas. Recreate ONLY the bottom-left crouched pig, as a single isolated character, SAME proportions, head, red cape and hooves.
Primary request: she kneels low and reaches an EMPTY front hoof down toward a small object on the ground to her right. Remove the acorn: absolutely no acorn or necklace in this image. Her empty reaching hoof must be complete, anatomically consistent and clearly reaching downward. Both feet are on the same baseline. Gentle happy curiosity.
Style: same delicate warm shaded watercolor/gouache as reference, not pixel art.
Composition: square transparent RGBA, full-body side/three-quarter right view, generous 12 percent transparent margins. Entire ears, cape, empty reaching hoof and feet within frame. The body's visible height when crouching is about 85 percent of standing pose height, not a flattened character.
Constraints: exactly one character, no acorn, no props, no necklace, no shadows, no floor, no text, no watermark, genuine alpha transparency. Preserve reference identity.
```

## trail_v1.png

```text
Use case: illustration-story
Asset type: original 16:9 background plate for an animated memory in Piggy Manor.
Primary request: a warm hand-painted woodland hiking trail under old oak trees, soft late-afternoon sunlight. Empty scene, no characters.
Scene: gently winding sandy footpath crossing horizontally through the lower half, from x=0 at about 70 percent height to x=100 percent at 68 percent height. Oak leaves and small ferns at edges, distant trunks receding in layers. A few natural fallen acorns on the path, subtle and small. Comfortable clear space for two small characters walking together in the lower middle.
Style: high-definition gouache/watercolor fairytale game illustration, fine warm outlines and softly shaded forms, consistent with the cozy mushroom-house scene. Muted sage, amber, cream and warm dusty pink sunlight. Gentle depth, never pixel art.
Composition: wide cinematic 16:9 (1536x864), eye-level three-quarter side view appropriate for small storybook sprites on the path. The lower right is open for a crouching character. No strong perspective distortion. No extra house, no table, no characters, no lettering, no title, no border, no watermark. Not dark or threatening.
```

## pig_actions_v1.png

```text
Use case: illustration-story
Asset type: transparent animation pose atlas for the girl pig character in Piggy Manor.
Input images: provided existing pink pig in a red cape is the identity/style reference.
Primary request: draw exactly eight distinct full-body poses of the SAME small pale pink girl pig with floppy triangular ears, round pink snout, tiny dark eyes, small pink hooves, red cape fastened with a tiny pig-face clasp. Soft warm gouache shading, delicate outlines, no pixel blocks. Match reference proportions and clothing. No trousers or other new clothing.
Composition: transparent RGBA canvas 2048x1024 with exactly 2 rows and 4 columns, ample empty gutters, one isolated character per cell. Each cell 512x512. Feet on baseline y=455 within each cell, same head size and same scale in all poses, each character safely inside its cell with at least 40 px transparent margins. Do not draw cell borders, labels, grids, shadow rectangles or backgrounds.
Row 1 left to right: four consecutive walking-right gait poses, slight three-quarter angle so the face is visible, alternating foot contact and passing poses, arms and cape swinging naturally. No acorn and no necklace in these four walking poses.
Row 2 left to right: (1) crouched low facing right, extending front hoof toward the ground to pick up an acorn, both feet still visible; (2) standing happily facing three-quarter right, front hoof lifted presenting one small brown acorn near the chest; (3) standing with both hooves raised beside the neck, pulling a thin brown loop necklace over the head, one brown acorn pendant clearly visible on the loop; (4) standing proudly and smiling with hooves gently outward, wearing the thin brown cord with a single small brown acorn pendant below the cape clasp at the upper chest.
Constraints: actual alpha transparency, no shadows beyond character silhouette, no text, no numbers, no extra characters, no cropped ears or feet, no sheet title, no checkerboard painted into image. The acorn cap must look like a natural small oak acorn, not a mushroom or bell.
```

## cabbage_walk_v1.png

```text
Use case: illustration-story
Asset type: transparent four-frame cabbage-form walking atlas for Piggy Manor.
Input images: existing cabbage creature sprite atlas is the identity reference. Preserve this exact cute leafy cabbage creature design.
Primary request: four successive walking-right poses of a small anthropomorphic cabbage, NOT a human boy and NOT a boy wearing a cabbage costume. Cream-pale green round face and body, tiny dark eyes, happy mouth, pink cheeks, whole head/back composed of overlapping soft sage cabbage leaves with pale veins, two tiny rounded arms and two tiny feet. No clothing, no hair, no hat. Hand-painted fairytale gouache with fine outlines and smooth shaded leaf edges; soften the reference's chunky pixels without changing the identity.
Composition: transparent 2048x512 horizontal strip of four poses, 512x512 cells, every character isolated with at least 40 pixels clear margins. Feet baseline at y=455, consistent visible height around 340 pixels. Safe leaf boundaries, no overlap across cells, no grid or labels.
Four frames left to right: right-foot contact, passing, left-foot contact, passing. Three-quarter right view with face readable, continuous gait and gentle leaf motion.
Constraints: genuine transparent alpha background, no ground shadows, no acorns, no pig, no text, no numbers, no watermark, no extra body parts or characters.
```

## acorn_v1.png

```text
Use case: illustration-story
Asset type: a single isolated acorn sprite, transparent RGBA, for a cozy hand-painted game.
Primary request: one cute but natural oak acorn, upright at a slight 12-degree angle, complete silhouette. Smooth chestnut brown teardrop nut, warm amber highlight, textured dark brown cup with fine overlapping scales and short curved stem. Delicate watercolor/gouache brushwork, fine warm outline, gentle shaded volume, matching a fairytale game.
Composition: square 512x512, object occupies central 65 percent with generous transparent margins all around. One acorn only, no face, no leaves, no cord, no hands, no ground, no cast shadow, no text, no watermark. Genuine alpha transparency.
```
