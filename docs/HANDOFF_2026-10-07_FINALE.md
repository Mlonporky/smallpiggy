# 最终章交接 · 2026-10-07

## 用户要求与停工条件

用户提供 ChatGPT 最终章稿件，要求实施，并在五小时额度剩余 10% 时停止、写 handoff。开工额度剩 82%；按阶段通过 usage 工具读取，收尾读数会追加到本文。没有子代理、提交或推送。仓库开工已有大量未提交角色／橡子回忆／配乐改动，全部保留。

先读 AGENTS.md、WORKLOG 最近记录、STORY_AND_ART_DIRECTION 最新段落。本专题取代旧 handoff 的配乐待办作为当前入口。用户最新原稿在 FINAL_CHAPTER_REQUEST_2026-10-07.md；前一轮“出蘑菇屋直接切小猪”的路线现在按新稿加入白菜森林过渡，但仍会顺序切到小猪去完成洞穴。

## 已实施

- `scenes/finale/final_chapter.gd`：步行入口、29 场原稿对应的 61 个对白／演出节拍，真实前置门槛、暂停、手动／自动对白、回家跟随、结尾／字幕、分段保存与恢复。剧情台词以原稿为准，无巫师 HP 或战斗 UI。
- `finale_story.gd`：集中保存节拍与原对白；`finale_actor.gd`：复用图集、脚底对齐、按位移换步态；`restoration.gdshader`：森林／山庄恢复。
- `final_chapter.tscn` 正式入口、`final_chapter_preview.tscn` 隔离预览，主菜单左下角新增预览按钮。预览 GameState 与存档完全隔离。
- `interior.gd`：看完橡子回忆后桌前 E 调查红纤维，完成后出屋 → 白菜小路。没调查就出门仍先走小猪，之后门槛会送回蘑菇屋补全。
- `dark_path.gd` 的坠洞改接 `story_cave.tscn`。故事关继承动作测试关，最后爬升区两敌删除，到出口等待 0.8 秒后上地面；原动作测试关不改。
- `assets/finale/` 新森林、牵手姿势、披风送礼 v2；v1 保留追溯。`assets/audio/finale/` 为原创合成音符／风声 WAV。

状态沿用 `GameState.flags`，无需破坏旧存档：`mushroom_red_fiber_seen`、`mushroom_house_completed`、`cave_level_completed`、`finale_cabbage_path_done`、`finale_pig_path_done`、`cabbage_memory_restored`、`wizard_defeated`、`curse_broken`、`ending_completed`；`finale_checkpoint` 是字符串，读取用 flags.get，不用 has_flag。心心取现有 heart_progress。首次暗号之后开始完整回忆才写记忆恢复；光波／巫师消散之后写解除魔咒；字幕页写完成。重载每个镜头从头，步行段从起点。

## 验证与已修问题

- 第一次流程测试发现 `bounds.assign()` 改写 SpriteAtlas 缓存，导致再次载入男孩越界；现每次配置先创建自己的数组，后续图形流程无该错误。
- 修正背景 fragment 中重复乘纹理颜色造成的过暗画面。
- 简易配乐改为离线 WAV，避免切镜头时实时合成阻塞。
- 修正长路“腿按长距离换帧、角色只挪一屏”的不匹配；长路现在使用镜像衔接背景滚动，角色实际位移 170 单位/秒。
- `FINALE_TEST_OK`：预览隔离、真实按键逐句、暂停、记忆／诅咒／完成时机、隔离存档重载、存档失败不退出。测试故意写无效 /tmp 路径会有一条预期的保存错误。
- `FINALE_ROUTES_OK`：红纤维门槛与原句、蘑菇屋出口→白菜路→坠洞→故事关→小猪路→重逢，及独立动作关不污染状态。洞穴终点由测试定位，不代表本轮从头徒手打穿平台关。
- 图形运行 Apple M1 OpenGL；首轮沙箱退出 134，授权后运行正常。图形截图在 /tmp/finale-*.png，最终选图复制到 docs/art_direction/finale/。后续最终回归／帧时结果见本文追加记录。

## 未完成，勿称已验收

详见 FINAL_CHAPTER_ZH.md 的美术与声音范围。当前是完整流程的可玩首版，专用角色动画、按七步骤分层修复山庄、最终配乐与完整音效仍欠缺。巫师仍像素，牵手为静态关键姿势，男孩→白菜为姿势切换而非完整变身。回忆图和静态截图不能冒充连续动作。赠披风 v2 尚需用户审阅角色一致性。新对白只来自最终章原稿；未改第一幕定稿对白。

## 下一轮优先顺序

1. 请用户 F5 点“最终章 · 独立预览”，复看对白节奏、两人位置、形态恢复点、回家路径；按具体反馈改。
2. 修好连续动作：两人靠近→白菜伸手→0.8 秒停顿→实际接触→牵手；保持关节固定，不在既有未确认 A/B 左右映射上继续推断。
3. 新绘巫师、抬头／拍灰／保护、披风风动、变身／消散；补 Trail 回忆实际拾取片段。
4. 山庄窗灯、植被、水面、居民、天空分别恢复；补鸟叫和脚步，配乐由草稿升级。
5. 正常速度全片再验，补真实从平台起点打穿至结局的人工试玩。勿在不清楚哪些文件属先前工作时全量撤回或 reset。

Mac 运行方法见 FINAL_CHAPTER_ZH.md。Godot 路径：`/Users/missdaidai/Godot.app/Contents/MacOS/Godot`。测试存档都在 /tmp；用户原存档未被预览／测试改写。

## 最终验证与停工

最终 `FINALE_TEST_OK` 再次通过 Apple M1 OpenGL，全套截图已复制至 `docs/art_direction/finale/`，复查牵手、山庄恢复、THE END 画面。除故意触发的保存失败分支外，无本轮脚本错误。`SMOKE_TEST_OK`、`BOY_ATLAS_TEST_OK`、`MUSHROOM_EXPLORATION_OK`、`DARK_PATH_OK` 均通过。`git diff --check` 通过。

`FINALE_PLAYBACK_OK`：正常速度完整独立预览，219.50377 秒，P95 13.002 ms，最大 26.925 ms，走完两条路、全部对白／演出、有限控制回家、字幕；验证 GameState 前后完全相同。详情 `docs/art_direction/finale/playback.json`。同期运行过其它 headless 测试，非严格性能基准，不能代替用户动画验收。

五小时额度读数从剩 82% → 71% → 56% → 45% → 30% → 18% → 13%。在剩 13% 时已停止功能开发，只进行证据归档和交接收尾，为用户指定的 10% 保留余量；未使用额度重置或额外额度。没有提交或推送。下一轮直接从“未完成”清单继续，不将第一版称为已完成全部最终章制作。

交接完成时最新读数：五小时已用89%，剩11%。已停止工作，未继续消耗到阈值以下。
