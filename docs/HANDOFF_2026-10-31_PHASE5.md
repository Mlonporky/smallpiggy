# 总体优化第五阶段 · 游戏音频补齐

## 当前状态

用户要求“继续第五阶段”。审核AUDIO-01中的森林环境声、部分拾取声与平台单音占位已在本轮范围内处理；交付3条环境循环、23个动作音、正式播放接入与32秒试听。技术回归完成，声音自然度、音量舒适度和整体听感仍待用户反馈；没有启动第六阶段。

现有男孩仍是正式形象。新手绘候选保留作试验，不借音频工作推进替换。剧情、对白、40%觉醒、密码和用户小猪装配均未改。开工检查Git、AGENTS、最新方向和第四阶段交接；390个代码／场景／文档快照在 `/tmp/piggy-phase5-baseline/files`，原存档／备份、原美术与已有音频共38个文件留保护指纹。保留所有既有未提交内容，无子代理、提交或推送。

## 交付入口

- [32秒试听，增益＋12dB](audio/phase5_2026-10-31/gameplay_audio_listen.wav)、[游戏原电平](audio/phase5_2026-10-31/gameplay_audio_sample.wav)。
- F6 `scenes/audio_studies/gameplay_audio_preview.tscn`，1–4选择森林、山洞、平台、纸张；空格/Esc暂停，R重播，M静音，F1设置。
- [接入清单与来源](audio/phase5_2026-10-31/README.md)、[验证证据](verification/phase5_2026-10-31/README.md)。

## 实现

`tools/music/render_gameplay_audio.py` 用Python标准库确定性合成滤波空气、树叶、洞穴水滴、泥地脚步、木材/纸张/石块瞬态与少量钟声；不是录音。新资源独立放在 `assets/audio/gameplay_v1/`，已有配乐和音效原文件不变。26个WAV以PCM导入，保留确切循环接缝。

`systems/audio/gameplay_audio.gd` 是场景内组件，不新增Autoload。环境层渐入、路由切场淡出，离场停流；复用8个音效播放器，按类别限频与优先级分配，未知事件不发兜底蜂鸣。音效/环境分别走已有Effects/Ambience总线，服从AppSettings。脚步跟随真实位移，腾空、停止和瞬移不补播。

森林入口/道路/山洞通过forest_base接入；树枝与礼物碎片只在实际拾取时发声。combat_fx的即时正弦生成改为素材库，补跳跃、落地、翻滚。黑暗小径接环境、脚步、裂地与下落，并跟随其局部暂停/结束。平台Sound脚本复用同一组件，动作与怪物保留原事件名，装备不再用治疗音；movement_room局部Esc暂停同时冻结声音。蘑菇屋纸张拾取和包装纸拼合使用纸声，完成提示保留独立钟声。

## 验证

13个不同headless脚本通过：gameplay_audio_test、gameplay_audio_routes_test、gameplay_audio_preview_test、chapter2_combat_test、chapter2_pause_menu_test、dark_path_test、action_level_test、action_monsters_test、wrapping_puzzle_test、wrapping_keyboard_test、music_test、finale_audio_test、full_story_flow_test。最后一个覆盖新游戏到Credits及续档，但仍是固定步长自动路线，不是人工盲玩。

新声音组件检查PCM循环、总线路由、8声音池上限、限频、优先级、暂停、按距离脚步、瞬移/腾空抑制及离场释放。接入检查含真实树枝/礼物拾取事件、已持有物品读档不重播、平台跳跃/装备、黑暗小径阶段声、局部Esc＋F1嵌套暂停及回菜单清理。试听页也检查四段切换、结束后暂停、重播和GameState隔离。

Apple M1 / Godot 4.7.2 OpenGL正常速度录制，9个混音片段核对分类音量、静音、两种暂停及恢复/回菜单。其中6个应无声片段PCM峰值都是0；有声对照非零。完整试听32.0435秒、25次事件顺序正确，原电平峰值−21.5129dBFS、RMS−42.4019dBFS、无削波，另生成＋12dB试听副本。录音证明引擎混音，不证明扬声器输出、自然度或主观听感。

源文件26个全部通过削波和首尾检查，环境循环无末尾静音空档。原38个保护文件哈希一致、默认声音设置仍不存在、390个快照文件无丢失；git diff --check通过。系统证书/编辑器设置沙盒警告与原有ObjectDB退出警告如实保留；未宣称解决第六阶段资源/性能问题。

## 未完成与下一步

先听32秒片段，重点判断风叶是否太弱、脚步是否重复、纸声/石声是否能辨识、完成钟声是否突兀，再调整相应素材与电平。新增声音属于原创合成首版，未经过真人听感验收；没有实地录音、人声、森林新配乐或橡子回忆新配乐，其他未接入场景仍有旧合成提示。

第六阶段按原计划单独测性能和资源；不要把本轮音频池复用当作整游戏性能已验证。第四阶段候选弃用方向、专用角色动画和第三阶段人工试玩待办继续保留。无需回滚正式男孩取帧修正，也不再推进候选手绘男孩替换。
