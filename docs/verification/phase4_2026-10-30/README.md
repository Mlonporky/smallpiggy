# 第四阶段验证证据

范围：独立角色比较／侧向动作样片，以及正式最终章原男孩方向、站立与对应泪光修正。不是新的全主线、全收集或人类观感验收。

## 最终通过记录

- `headless/results.json`：7个脚本全部退出0，各日志保留对应 `_OK` 标记。脚本名单：phase4_character_study_test、finale_boy_direction_test、boy_atlas_test、finale_reunion_test、finale_transformation_test、finale_routes_test、finale_test。
- `study_graphics.log`：图形样片的显式裁切、1,681姿势、脚底、关节、暂停／重播／F1嵌套暂停与状态隔离。
- `reunion_graphics.log`：正式重逢站立泪光，变身端点通道差0／1。
- `playback.log` 与[完整提交计量](../../art_direction/phase4_boy_v1/playback_rendering.json)：正常时间约14秒，测试上限60 FPS；839次处理／绘制提交，P95 18.398ms、最大54.886ms。没有在计量期间截图、强制绘制、文件写入或更换焦点。没有声称无卡顿。
- `export.log`：540帧离线PNG导出。显式force_draw导出路径的引擎收尾汇总仍打印0帧；使用实际序列数与解码数验证。
- `movie_verify.log` 与[解码JSON](../../art_direction/phase4_boy_v1/movie_validation.json)：MP4全540帧解码，18秒，30 FPS，1152×648，时间戳误差0，无音轨。`decoded_*.png`来自成片本身。
- `protection.json`：正式存档／备份、原男孩图、小猪图、用户装配未变，默认设置仍不存在；快照文件无丢失。`baseline_changes.json`列出本轮实际改变的开工文件。

图形环境为 Godot 4.7.2 stable、Apple M1、OpenGL Compatibility。静态截图使用 `force_draw`以保证视口可读，这些截图不是正常帧率证据。动态图形数值只反映引擎提交，未测显示器呈现和真人主观流畅。

初次脚本加载发现候选场景函数名与内置ease冲突，已改名；第一版背景最小尺寸溢出已修正后重拍。初次受限沙盒不能访问系统H.264编码器，改为本地系统编码服务成功；没有上传。Swift工具仍有SDK弃用警告，headless日志有系统证书警告；最终通过日志无脚本错误。原有退出资源警告按原样保留，不作为新性能修复结论。

## 复现

```sh
python3 tools/run_phase12_checks.py phase4_character_study_test finale_boy_direction_test boy_atlas_test finale_reunion_test finale_transformation_test finale_routes_test finale_test --output /tmp/piggy-phase4-checks
```

图形专项使用同一Godot可执行文件，分别运行 `res://tests/phase4_character_study_test.gd`、`res://tests/phase4_character_playback.gd`、`res://tests/phase4_reunion_visual_test.gd`。每次指定独立的 `PIGGY_SAVE_PATH`、`PIGGY_SETTINGS_PATH` 和 `--log-file` 临时路径，勿并行跑两份同一测试。

视频用 `tools/render_phase4_character_study.gd`、`--fixed-fps 30 --write-movie /tmp/新的空目录/frame.png` 导出，再用 `tools/encode_png_video.swift` 编码至新的MP4路径，最后 `tools/verify_phase4_movie.swift MOVIE.mp4 检查输出目录`。必须使用空帧目录和新成片文件，避免把旧帧混入。
