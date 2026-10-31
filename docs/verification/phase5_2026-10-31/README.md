# 第五阶段验证

本目录保留最终代码回归、正常时间引擎混音与原文件保护证据。音色审美和人类完整游玩听感未验收。

## 结果

- `headless/results.json`：13个不同脚本的最终结果，全部退出0并有对应成功标记。最终音频组件测试补查PCM导入；路线测试等待拾取对白结束后才卸载，避免夹具留下未结束等待。
- `mix_playback.log`：正常时间运行 `gameplay_audio_mix_test.gd`，9个混音片段、32.0435秒完整试听、25个事件、剧情状态不变，退出0。
- [validation.json](../../audio/phase5_2026-10-31/validation.json)：26个源文件无削波、接缝/端点差0；三条循环末尾有非零环境信号。6个预期静音片段峰值0，有声对照/恢复片段非零。完整混音无削波，试听副本仅增益＋12dB。
- [playback_events.json](../../audio/phase5_2026-10-31/playback_events.json)：实际录制事件顺序与时间；[试听界面截图](../../audio/phase5_2026-10-31/preview.png)仅用于布局检查。
- `protection.json`、`baseline_changes.json`：正式存档/备份、原男孩/小猪素材与用户装配、旧音频38个文件未变；默认设置仍不存在，390个开工快照文件无丢失。

音效/环境均通过正式GameplayAudio组件播放。混音来自Godot Master总线录音；AppSettings同时静音相关分类总线，单测不只检查静音布尔值。正常时间录制未使用fixed-fps加速；headless自动路线则明确是固定步长逻辑测试。

首次独立预加载发现组件直接引用Autoload名称在SceneTree脚本启动期不可解析，已改为运行时根节点查找；暂停测试也修正为只要求正在播放的声音具有stream_paused状态，停止中的播放器不能作此断言。两次早期失败被中断后重跑通过，不列入最终通过数。导入默认QOA后已显式改PCM并重新验证。原有证书/资源退出警告保留，不声称性能或资源警告已解决。

## 复现

```sh
python3 tools/run_phase12_checks.py gameplay_audio_test gameplay_audio_routes_test gameplay_audio_preview_test chapter2_combat_test chapter2_pause_menu_test dark_path_test action_level_test action_monsters_test wrapping_puzzle_test wrapping_keyboard_test music_test finale_audio_test full_story_flow_test --output /tmp/piggy-phase5-checks
```

录音使用临时存档/设置路径，图形模式运行 `res://tests/gameplay_audio_mix_test.gd`，不要加 `--fixed-fps`；随后执行 `python3 tools/music/validate_gameplay_audio.py`。目录中的WAV包含应当完全无声的测试片段，不将它们误作试听资产失败。试听使用 [gameplay_audio_listen.wav](../../audio/phase5_2026-10-31/gameplay_audio_listen.wav)。
