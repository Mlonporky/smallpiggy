# 2026-10-31 剧情倍速验证

实现与操作见[剧情播放速度](../../STORY_PLAYBACK_ZH.md)。测试全部使用独立设置/存档，没有更改玩家存档或用户小猪装配。

## 最终通过

- `results.json`：10个不同headless脚本退出0，覆盖倍速持久化/切换、已有Tween即时变速、暂停/离场取消、开场59秒完成及原速、声音时间映射、关键停顿、手动对白/自动阅读、第一幕导航、森林战斗、橡子回忆、最终章路由及新游戏至Credits和续档。主线使用固定步长自动路线，不是人工试玩。
- `restart-results.json`：两个独立进程写入/读取，确认切换到1×后下次启动仍为1×；声音设置和GameState隔离正常。
- `graphical-final.log`、`playback.json`：Apple M1 OpenGL正常时间运行，测试限60FPS，没有改项目配置。800×600、1152×648、1440×900窗口的剧情页边界通过；真实键盘切换、暂停中切换、嵌套F1恢复和R重播通过。
- 四段播放测量：1.5×时7.000177秒推进10.499630剧情秒；1×时5.016470秒推进5.016488剧情秒；恢复/重播后的两段1.5×也匹配。音频读取位置最大偏差0.033044秒，四段稳态播放均0次纠偏seek。此为播放器位置数据，不是声卡输出延迟或真人听感验收。
- 加速重逢剪选样片实际播放并到末尾，含截图等待计时约21.68秒；保留认出/变身停顿。没有本轮完整视频导出或整章正常时间帧率验收。
- `audio-validation.json`：新配乐59秒、44.1kHz、峰值0.596039、0个削波采样；6秒440/880Hz测试音加速后4秒，四个测量窗仍为440/440/880/880Hz。原曲哈希保持一致。
- `protected-files.json`：5个保护文件哈希一致，含原男孩、用户装配、原开场配乐和正式存档/备份。正式设置文件开工时不存在，验证后仍不存在。

设置页、开场和重逢末帧PNG已复看；截图仅证明静态布局。原手绘/atlas与程序动作继续使用，未补专用动画、配音或橡子回忆配乐。

## 初期发现与修复

`initial-*.txt`仅记录初期诊断，不算通过证据：测试路径需兼容macOS的`/private/tmp`；暂停音乐的真实音频位置与剧情位置分开记录；预加载的回忆/对白脚本运行时获取AppSettings，避免SceneTree测试早于Autoload初始化时报错；设置页需在自动换行的最小尺寸稳定后重新布局。首次图形测量包含窗口/资源初始化，后续测量显式预热，最终四段结果见上。

系统音频组件在沙盒内无法初始化，随后用本机AVFoundation离线渲染。初次Swift输出未结束文件作用域，导致WAV头未完成，修正后重新生成并核对全部采样。沙盒内图形进程启动失败后，改用本机图形运行并保留隔离存档。系统证书、ObjectDB/资源退出警告仍保留在日志；不声称本轮解决了资源清理或全游戏性能问题。

## 复现

```sh
python3 tools/run_phase12_checks.py story_speed_test opening_test music_test acorn_memory_test settings_ui_test chapter1_navigation_test chapter2_combat_test finale_audio_test finale_test full_story_flow_test --output /tmp/piggy-story-speed-recheck
PIGGY_SETTINGS_PATH=/tmp/piggy-speed-visual.cfg PIGGY_SAVE_PATH=/tmp/piggy-speed-visual-save.json /Users/missdaidai/Godot.app/Contents/MacOS/Godot --path . --log-file /tmp/piggy-speed-visual-engine.log --script res://tests/story_speed_playback.gd
```

图形脚本需本机图形权限，不能加`--fixed-fps`。配乐重新生成：`swift tools/music/retime_story.swift assets/audio/music/opening_story.wav assets/audio/music/opening_story_1_5x.wav 1.5`，需要macOS系统音频组件访问权限。
