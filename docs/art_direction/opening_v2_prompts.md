# 开场 v2 · 内置 image_gen 完整提示词

日期：2026-09-08。模式：内置生成／参考编辑，未使用 CLI。原素材未覆盖。

成品存放于 `assets/prologue/`：gift_empty.png、bedroom_cabbage.png、bedroom_boy.png、castle_wizard.png、wizard_arrival.png。gift_wrapping.png、castle_exterior.png、castle_interior.png 从此前已保存方向图复制。

wizard 生成结果没有真实 alpha，棋盘格被烘焙进图，只保存为 `docs/art_direction/wizard_handpainted_reference_v1.png`，用于后续合成参考，不接入游戏。后续 refs 中曾使用的 assets/prologue/wizard.png 已移动至此参考路径。

## gift_empty

参考：/Users/missdaidai/codex/smallpiggy/docs/art_direction/gift_wrapping_handpainted_v1.png

Use case: precise-object-edit. Edit this exact 16:9 hand-painted game keyframe to create a clean background plate for a teleportation shot. Remove ONLY the living pink pig with red scarf standing beside the table, including her hands. Reconstruct the small parts of floor, rug and tabletop hidden by her. Keep camera, all furniture, gifts, ribbons, lighting, colors, composition and every other object at exactly the same position and scale. KEEP the green rosette SUCCULENT on the table and the decorative pig cushion on the bed. No new characters, no text, no visual effects. Preserve exact framing and image dimensions, match original brushwork. The same empty room after the pig has vanished.

## wizard

参考：/Users/missdaidai/codex/bigidea/wizard.png；/Users/missdaidai/codex/smallpiggy/docs/art_direction/castle_interior_handpainted_v1.png

Use case: illustration-story. Create ONE isolated full-body wizard character on a genuinely transparent alpha background for a 2.5D game, NOT a sprite sheet. Image 1 is character identity reference, Image 2 is hand-painted style reference only. Preserve the floppy purple pointed hat with muted teal band, black face in shadow, two glowing lavender eyes, tattered purple robe, small bone fasteners, wooden staff. Redraw in the soft gouache storybook brushwork of image 2, no pixels, no plastic 3D. Three-quarter view facing left, feet visible and level, staff held upright, free hand slightly raised ready to cast. Entire silhouette within frame with generous transparent margins. Restrained glow, no background, no floor, no scenery or crystal ball. Character should read as an adult wizard, not miniature.

## bedroom_cabbage

参考：/Users/missdaidai/codex/bigidea/bedroom.png；/Users/missdaidai/codex/smallpiggy/docs/art_direction/gift_wrapping_handpainted_v1.png

Use case: illustration-story. A 16:9 landscape cinematic bedroom keyframe for Piggy Manor. Image 1 is exact room design reference, image 2 is soft hand-painted gouache style reference only, do NOT include its pig or mushroom room. Reframe image 1 to a closer three-quarter elevated view of its LEFT wooden bed, pillow and blue-white checked blanket, bedside round table with lamp, window and cabbage portrait. It is NIGHT: cool blue through window, small soft amber bedside lamp. In the bed, on the pillow, rests a cute small living napa-cabbage character asleep, pale cream face nestled into light green leaves, tiny closed eyes, no human head or hair. Lower cabbage body tucked under the blue-white checked blanket. Bed and sleeping cabbage are the clear focus, a quiet moment. Keep this as mainvilla bedroom not mushroom house; preserve blue checked bedding, wall portrait and lamp, no additional bed, no pig character. No text, no UI, no special effects, no wizard. Matching painterly storybook detail and clear soft edges, not pixel art.

## bedroom_boy

参考：assets/prologue/bedroom_cabbage.png；/Users/missdaidai/codex/bigidea/白菜苏醒.png

Use case: precise-object-edit. Edit reference image 1, the nighttime bedroom, for the AFTER state of a magical transformation. Change ONLY the sleeping living cabbage in the bed into the sleeping LITTLE BOY from reference image 2: tousled light brown hair, closed eyes, fair skin, small hands resting at blanket edge. Same head center and roughly same visible silhouette size as cabbage; lower body remains under the existing blue-white checked blanket. NO cabbage leaves around the boy after transformation. Reference 2 provides boy identity ONLY; do not copy its separate bed or green blanket. Preserve image 1 exactly everywhere else: same room, wooden bed, pillow, blue checked blanket, camera angle, framing, lamp, wall picture, plants, colors and lighting. No new bed, no motion blur, no special effects, no text. Same soft hand-painted gouache style, not pixel art. Output same landscape dimensions as image 1 for an aligned before/after dissolve.

## castle_wizard

参考：/Users/missdaidai/codex/smallpiggy/assets/prologue/castle_interior.png；/Users/missdaidai/codex/smallpiggy/assets/prologue/wizard.png

Use case: compositing. Edit image 1 keeping room, table, crystal ball, camera and lighting fixed. Insert ONE wizard from image 2, identity reference ONLY, on the clear FLOOR to the RIGHT of the table, facing left looking at the crystal ball. Remove the reference checkerboard entirely: render a complete opaque room illustration. His feet stand on floor around 83 percent across and 80 percent down image, hat tip around 29 percent down image. Adult scale, visible height about HALF the image height, roughly three times ball diameter. Preserve purple hat, teal band, dark shadow face with glowing eyes, purple robe and wooden staff, but match the softly painted room and its violet side light. Tabletop about wizard waist level, realistic occlusion and contact shadow. Crystal ball stays brightest focal point, staff jewel dim. No extra wizard, no words, no checkerboard. Same landscape framing.

## wizard_arrival

参考：/Users/missdaidai/codex/smallpiggy/assets/backgrounds/mushroom_house_night.png；/Users/missdaidai/codex/smallpiggy/assets/prologue/wizard.png

Use case: compositing. Create a 16:9 landscape hand-painted storybook cinematic shot based on image 1's mushroom house exterior at night. Preserve mushroom house identity, warm windows, doorway, forest and path. Reframe as needed to landscape. ONE wizard using image 2 identity stands on the path to LEFT of mushroom house door, facing house with raised free hand casting a curse, wooden staff in other hand. His visible height about 40 percent image height, not tiny and not larger than house. Purple hat with teal band, dark face and lavender eyes, purple robe. Match soft painterly environment, no pixel edges. Subtle violet mist curls from the staff toward house, readable silhouette and contact shadow. Reference checkerboard is NOT part of the character: no checkerboard anywhere, render complete opaque scene. No pig or boy, no captions, no UI, no second wizard. Quiet sinister, not horror.
