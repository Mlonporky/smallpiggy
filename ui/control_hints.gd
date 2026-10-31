extends RefCounted
## Shared interface wording; no story dialogue or puzzle solutions.
const PAUSE_OPTIONS := {"stay":"继续游戏", "settings":"设置与操作", "save":"保存并回主菜单"}
const DIALOGUE := "E / 空格 / Enter 继续"
const CLOSEUP := "点击 / E / 空格 / Esc 收起"
const COMMON := "F1  设置与操作　 ·　 M  全部声音静音 / 恢复\nTab 切换按钮，Enter / 空格确认；Mac 功能键可能需要同时按 fn。"

static func for_scene(path: String) -> String:
	if "audio_studies/" in path:
		return "声音试听\n1–4 切换森林、山洞、平台、包装纸片段。\n空格 / Esc 暂停或继续；R 从头重播。\nM 全部静音；本预览不改变剧情或存档。"
	if "prologue/" in path:
		return "开场\n空格 下一句；变身与传送会完整播放。\nEsc / P 暂停或继续；R 从头重播。\n需要略过开场时，点击右上角「跳过开场」。"
	if "story_cave" in path or "action_test/" in path:
		return "苔根小径\nA / D 或左右方向键移动；空格短跳 / 长跳。\nJ 攻击，Shift 翻滚，E 拾取武器，S + 空格穿下树枝。\nEsc 暂停；R 返回最近点亮的营火，萤火与秘密保留。\n萤火是可选收集；主线越过出口就继续剧情，补收集请先折返。\n主线营火自动保存，F5 手动保存；独立测试关不写正式剧情存档。"
	if "dark_path/" in path:
		return "黑暗小径\nA / D 或左右方向键移动；Esc 暂停或继续。\n这一段是连续剧情过渡，进入苔根小径后会自动保存。"
	if "finale/" in path:
		return "最终章\n道路上用 A / D 或左右方向键移动。\nE / 空格 / Enter 继续对白，Esc 打开暂停菜单。\n暂停菜单可切换自动 / 手动对白，正式主线可保存并回主菜单。\n独立预览可以重播，不修改正式剧情存档。"
	if "chapter2/" in path or "chapter_02_dark_forest/" in path:
		return "森林探索与战斗\nWASD / 方向键移动，靠近后按 E 调查。\n空格跳跃；对白期间用 E / 空格 / Enter 继续。\nJ / Z 挥击，Shift 翻滚，K 正面招架（减伤）。\nEsc 暂停，F5 保存；生命降至 40% 时触发快乐力量。"
	if "chapter1/" in path or "cabbage_act2/" in path:
		return "白菜探索\nWASD / 方向键移动；靠近物品后点击或按 E / 空格调查。\n近景用点击 / E / 空格 / Esc 收起；对白用 E / 空格 / Enter 继续。\nEsc 关闭当前界面，探索时打开暂停菜单；F5 保存。\n包装纸：拖拽，或 1–4 选取、方向键移动、Shift 慢移、Enter / 空格放下。\n桌面滑块支持点击或方向键，并可撤回。"
	return "开始游玩\n「新游戏」从共同开场开始；「继续游戏」读取最近一次保存。\n探索：WASD / 方向键移动，E 调查。\n对白：E / 空格 / Enter 继续。\nEsc 关闭当前界面或暂停；F5 在可操作的探索阶段保存。\n各章节的具体操作可随时按 F1 查看。"
