# 包装纸正反面素材（2026-09-19）

内置 image_gen。正面参考现行 assets/chapter1/gift_fragment_hd.png 的配色及猪脸图案；背面独立生成。输出保存于 assets/cabbage_act2/wrapping/front.png 与 back_blank.png。

正面提示词：

Use case: illustration-story. Asset: single flat intact wrapping-paper front texture for a four-piece torn paper jigsaw in a cozy handpainted storybook game. Reference image only for colors and pig-face motif, NOT its torn silhouette. Make an entire unbroken rectangular sheet viewed perfectly straight overhead, filling the entire image edge to edge without margins, transparency, shadows or background. Landscape 3:2. Warm coral-red paper with soft watercolor grain, repeating pale blush pink round friendly pig faces and small cream hearts matching reference. Arrange around 8 varied pig faces in a staggered pattern with generous breathing room and hearts between; recognizable asymmetry helps players align the pieces. Subtle broad paper fold creases, mostly flat and evenly lit. No letters, no writing, no border, no puzzle seams, no perforations, no separated pieces, no ribbon or gift box. We will use exact polygon UV cuts in the game to create matching irregular fragments from this one full sheet.

背面提示词：

Use case: illustration-story. Asset: reverse side texture of a flattened sheet of gift wrapping paper for a storybook game, 3:2 landscape. Warm ivory uncoated paper, delicate fibers, a few soft diagonal and horizontal fold creases and barely visible coral-pink bleedthrough near outer edges. Entire rectangle of paper fills whole image exactly, edge to edge. Perfectly flat overhead, even gentle lighting. Central area very clean and light so a Chinese handwritten message can be added in game. NO text, no letters, no symbols, no doodles, no objects, no shadows, no border, no torn holes, no pieces. Soft handpainted watercolor-gouache texture, high resolution, restrained contrast.

四块碎片由Godot共边多边形裁切同一正面，UV严格连续，不分别生成无法匹配的碎片。back_message.png由Godot渲染精确中文及空行。导出脚本tests/export_wrapping_art.gd，图形运行后生成piece_1.png至piece_4.png及back_message.png；完整源图始终保留。

## 2026-09-21 轮廓修订

沿用既有正反面生成纹理，以 Godot 共边多边形裁出斜四边形残纸和四块碎片。完成后保留接缝；背面中文作为纸张多边形的裁切子节点，实际截断于撕裂边缘。重新导出四片 PNG 与 back_message.png，无新增生成图片。
