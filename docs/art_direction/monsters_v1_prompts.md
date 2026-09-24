# 苔根小径怪物 · 第一版（2026-09-23）

## 这批图是怎么做的

本轮没有使用 AI 生图工具（当前会话没有生图能力）。7 种怪物全部由矢量图形逐个绘制：`tools/monster_art/make_svgs.py` 用 SVG 描述每个部件（渐变明暗、细描边、高光、腮红），`tools/render_monster_art.gd` 用 Godot 自带的 SVG 渲染把它们转成 PNG。没有参考或复制任何现成作品。

- 源文件：`tools/monster_art/svg/*.svg`（目录带 `.gdignore`，不会被 Godot 导入）
- 游戏用图：`assets/chapter2/monsters/*.png`，导入开启 mipmap，与小猪帧同为 `CharacterSpriteStyle.FILTER`
- 重新出图：

```bash
python3 tools/monster_art/make_svgs.py
/Users/missdaidai/Godot.app/Contents/MacOS/Godot --headless --path . --script tools/render_monster_art.gd
```

风格对齐已认可的 `assets/chapter2/pig_unified/frames/cape_right_00.png`：Q 版圆润造型、左上方柔光、渐变明暗、深色同色系细描边、带双高光的亮眼睛和腮红。游戏内统一按 0.42 缩放（夜蛾 0.36、蜗牛 0.5），描边粗细与小猪接近。

每只怪物身上都有一处紫色"诅咒印记"（眼底紫光、刺尖、发光斑点、紫水晶），表示它们是被巫师诅咒影响的森林小动物；被打倒时诅咒化作紫色光团飘起、散成暖金色火花（"净化"），没有血腥或死亡画面。这是本轮提出的设定，**待用户确认**。

## 部件与锚点

| 怪物 | 部件 | 锚点（纹理像素） |
|---|---|---|
| 苔团史莱姆（含大苔团／小苔团） | `slime_body` 170×150、`slime_eye` 26×32 | 脚底 (85,142)；眼睛中心 (13,16)，在身体上的位置 (66,86)/(104,86) |
| 栗刺球 | `burr_body` 210×170（朝右）、`burr_ball` 170×170 | 脚底 (100,158)；球心 (85,85) |
| 噗噗菇 | `puff_stem` 120×114、`puff_cap` 180×112、`spore` 42×42 | 茎脚底 (60,104)；伞底 (90,100) 坐在茎的 (60,36) |
| 灰翅夜蛾 | `moth_body` 100×120、`moth_wing` 130×152（左翅，右翅镜像） | 身体中心 (50,64)；翅根 (124,72) |
| 橡果蛛 | `spider_body` 120×116（腿和蛛丝由代码画） | 身体中心 (60,70) |
| 苔壳蜗牛 | `snail_body` 184×94（朝右）、`snail_shell` 130×124 | 脚底 (82,86)；壳心 (65,70) 坐在身体的 (74,34) |

动作全部由 Godot 程序叠加（挤压拉伸、眨眼、看向小猪、振翅、腿部摆动、滚动旋转等），**不是逐帧手绘动画**。

## 可选：用 AI 生图换成手绘质感

如果希望换成更有笔触的手绘版本，可以在 ChatGPT 等生图工具里使用下面的提示词，每次附上小猪参考图 `assets/chapter2/pig_unified/frames/cape_right_00.png`。生成后放进 `bigidea/02_pig/`，告诉我文件名，我会检查透明度、切部件、对齐锚点后替换，保留现有行为代码不变。

通用前缀（每条都加在最前面）：

> Game sprite on a genuinely transparent background, no checkerboard, no text, no floor, no shadow. Match the attached reference character's style exactly: cute chibi proportions, soft hand-painted shading lit from the top left, thin dark outline tinted with the local colour, glossy dark eyes with two white highlights, soft pink blush. Side-scrolling fairy-tale forest game. Each creature carries one small glowing violet mark of a wizard's curse. Cute and a little mischievous, never scary or gory. Each part separate with generous transparent gutters.

1. 苔团史莱姆：`A round translucent mint-green jelly slime with a little moss beret and a two-leaf sprout on top, tiny bubbles inside and a small violet four-point spark floating in its jelly. Parts: body without eyes (front view); one separate eye.`
2. 栗刺球：`A chubby chestnut-brown hedgehog whose back is a spiky chestnut burr, pale olive spines with a few violet-glowing tips, tan face, pink snout, mischievous brow, facing right. Parts: standing body without feet; the same creature curled into a round spiky ball.`
3. 噗噗菇：`A small grumpy sleepy mushroom creature: cream stem body with half-closed eyes and little root feet, a teal-blue cap covered in glowing violet spots. Parts: stem with face; cap alone; one fuzzy glowing violet spore ball.`
4. 灰翅夜蛾：`A fluffy moth seen from the front: lavender-cream fuzzy body, white scalloped collar, big dark eyes, feathery antennae; dusky violet wings with pale edges and a glowing eye-spot. Parts: body without wings; one left wing (upper and lower wing joined at the shoulder).`
5. 橡果蛛：`A round fuzzy cocoa-brown spider wearing an acorn cap with a tiny violet diamond on it, two big shiny eyes and two small ones, two tiny cream fangs, seen from the front. Body only, no legs.`
6. 苔壳蜗牛：`A soft pale-olive slug body with two eye stalks and a small smile, facing right; separately, its round stone spiral shell with a moss patch, a tiny sprout and a small cluster of violet crystals.`

## 审阅图

`monsters_v1_review/`：`parts.png`（全部部件）、`lineup.png`（游戏内七种同框）、`states_a.png`／`states_b.png`（蓄力、跳扑、「!」预警、滚动、晕眩、鼓胀、孢子、展翅锁定、俯冲、垂丝拦路、正面挡刀、壳被敲碎、净化光团与火花）、`level.png`（苔根小径实机路线截图）。截图来自 Apple M1 OpenGL 实际渲染，是静态帧；动作是否顺眼需要实际试玩判断。
