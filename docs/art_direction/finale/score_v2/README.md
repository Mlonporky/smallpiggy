# 最终章配乐第二版（2026-10-15）

六段音乐盒草稿已在最终章中替换为完整编曲循环。音符为本项目原创，沿用开场暖主题；由macOS General MIDI乐器离线演奏，无配音、无实录乐团。旧WAV保留供追溯，山庄48秒主题保持原版。编曲和混音仍待试听验收。

| 段落 | 音频 | 时长 | 处理 |
| --- | --- | --- | --- |
| 两条森林路 | `path_v2.wav` | 48秒 | 钢琴、稀疏竖琴、低弦，留脚步空间 |
| 重逢与认出彼此 | `reunion_v2.wav` | 48秒 | 暖主题、钢琴与长笛回应 |
| 记忆画面 | `memory_v2.wav` | 32秒 | 稀疏钢琴、钟琴，无稳定鼓点 |
| 巫师最后反扑 | `curse_v2.wav` | 24秒 | 低弦与拨弦，不加战斗鼓点 |
| 牵手与共同快乐 | `joy_v2.wav` | 32秒 | 展开的弦乐、竖琴与长笛 |
| 魔咒解除与光飞向山庄 | `afterglow_v2.wav` | 32秒 | 较轻的余韵，接回家主题 |

音频均在 `assets/audio/finale/`。仍使用原剧情mood切换点、0.85秒交叉淡入淡出、暂停/静音和跨回家对白连续播放。六段源PCM为44.1kHz立体声，RMS约-20dBFS，无削波，峰值-6.566至-3.098dBFS；运行时分别再降11–21dB。回家主题继续降10dB。听感强弱需要结合实际引擎混音判断，不能只看源文件峰值。

每段多渲染2秒混响尾音，折回循环开头，避免末音突然截断；循环边界单采样差不超过0.002904。这个数值只证明没有大幅采样跳变，不证明旋律接缝已经获得听感验收。源文件报告见 `source_validation.json`。

`engine_mix_excerpt.wav`（已验证46.045秒）按森林/重逢/回忆/巫师/快乐/余韵/回家各约6秒剪选，再接4秒森林循环边界；这是正常速度引擎混音，不是连续全片。`engine_mix_cuts.json`记录切镜与情绪，供定位试听。

## 重现

1. Python运行 `tools/music/compose_finale_score.py` 写六份音符JSON，不改其他章节音乐。
2. 每份使用 `swift tools/music/render_score.swift SCORE.json RAW.caf` 离线演奏，再 `afconvert -f WAVE -d LEI16 RAW.caf NAME_v2.wav` 转换至临时目录。
3. 使用带numpy的Python运行 `tools/music/master_finale_score.py 临时目录`，制作循环WAV及校验报告。
4. Godot重新导入，运行 `tests/finale_audio_test.gd` 和 `tests/finale_score_playback.gd`。

音色采用系统音源，因此不同macOS版本可能略有差异；游戏使用已导出的WAV，不要求玩家安装音源。

最终引擎混音峰值-15.085dBFS、RMS-32.270dBFS，无削波，状态隔离通过；详见`engine_mix_validation.json`。循环边界片段已录入供试听，尚未获用户听感验收。
