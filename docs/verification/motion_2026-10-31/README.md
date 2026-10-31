# 镜头与切场验证

范围为 2026-10-31 镜头／场景衔接首轮调校。未新增美术或声音，未修改用户原角色装配，不等于全游戏动画验收。

- `headless/results.json`：17 个不同脚本全部通过，含开场、第一幕、真实切场遮罩、最终章手部／巫师／变身／声音／路由、倍速、坠洞与营火、橡子回忆、新游戏至 Credits 连续流程与续档。
- `path-followup/results.json`：修正内部路径交接首帧遮罩、最后一步后，连续性／重逢／最终章／完整主线四项补跑通过。
- `transitions.json`：13 处相邻镜头的同场景端点，及 1×／1.5× 镜头运动、真实按键回家抵达。另断言回忆图叠化、暂停／重播一致性、内部路径第一帧全黑、同机位开场无插黑和粒子时钟连续。
- `baseline_boundaries.json`、`after_boundaries.json`：诊断扫描。跨地点切换或已离画角色的坐标变化不能直接当成故障；正式断言另检查遮罩或可见状态。修复前重逢推近／拉远的机位平移各跳 52.86977 个设计单位，修复后对应端点为零。
- `scene_covers.json`、`scene-cover-graphics.log`、`waking_dissolve.png`：普通换房、已全黑的坠洞接续、新场景初始化时仍全遮挡，起床最后一帧淡回房间。UI 透明度在结束后恢复，后续调查不透明丢失。
- `playback.json`、`playback.log`：Mac Apple M1 / OpenGL 正常时间，测试限 60 FPS；22.008446 秒、1312 次处理／绘制提交一致，覆盖有效。P95 17.889ms、最大 152.977ms；另有 78.466ms、37.927ms 间隔。最大间隔位于剪选第一次显示最终章画面，原因未定。这不是显示器扫描输出测量，不宣称无卡顿。
- `protection.json`：原男孩、两张森林猪图、用户装配、正式存档和备份六文件 SHA256 均不变。
- 成片与解码验证位于 `../../art_direction/scene_transitions_2026-10-31/`。22 秒无声，1152×648 / 30 FPS；离线导出不能代替正常时间播放检查。

首轮运动断言包含了小猪原有镜像转向的手部跳变，未通过。镜像转向缺少专用帧仍为已知限制；本轮用户澄清重点是镜头／切场，随后将移动段的指标限定为镜头与角色脚底的屏幕轨迹，静止交接仍检查手部连续性。临时尝试的森林攻击／男孩逐帧缩放改动已撤回，没有扩散为本次结果。

headless 仍有系统证书及部分既有 ObjectDB／资源退出警告；坏存档写入错误来自已有负向用例。图形版需本机窗口服务；沙盒内直接启动退出 134 后，用本机图形权限完成。没有推送、提交或上传视频。

复现：`python3 tools/run_phase12_checks.py motion_transition_test scene_transition_test opening_test chapter1_test chapter1_navigation_test finale_reunion_test finale_handhold_test finale_wizard_test finale_transformation_test finale_audio_test finale_routes_test finale_test story_speed_test dark_path_test story_cave_checkpoint_test acorn_memory_test full_story_flow_test --output /tmp/piggy-motion-recheck`。

正常时间剪选：使用独立 `PIGGY_SETTINGS_PATH`、`PIGGY_SAVE_PATH` 和 `--log-file`，运行 `--script res://tools/review_scene_transitions.gd`。导出同一脚本时加 `--fixed-fps 30 --write-movie /tmp/新的空目录/frame.png`；编码沿用 `tools/encode_png_video.swift`，以真实 PNG 和解码帧数验证，不能使用 force_draw 路径下引擎收尾的 0 帧汇总。
