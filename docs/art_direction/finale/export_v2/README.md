# 山庄恢复 · 视频导出复验（2026-10-15）

`restoration_with_sound.mp4`：18秒、540帧、1152×648、30fps，含引擎声音。
正常游戏的18秒F6预览此前已正确恢复；本轮修复的是离线录制。

## 修复与证据

旧工具等待自动绘制，发生过背景不更新、重复帧及结束等待追加帧。当前工具禁用自动渲染循环，每个固定30fps处理周期更新场景、刷新CanvasItem绘制队列后明确调用 `RenderingServer.force_draw(false, 1/30)`，第540帧当次退出，不等待另一个绘制信号。窗口不可绘制/遮挡可能导致自动绘制跳过；这是结合探针和引擎流程的解释，未证明所有旧问题都来自同一窗口状态。

原始PNG恰好540张；WAV为48kHz立体声32位PCM、864000个采样帧，即18秒。编码后完整解码540帧，所有时间戳等于索引/30，最后17.966667秒；音轨覆盖0–18秒、连续且无削波，峰值-14.343dBFS、RMS-30.042dBFS。

`decoded/movie_validation.json`记录全片解码结果，`decoded/frame-*.png`为六个精确时间点。复查了紫雾、局部庭院和完整日光三阶段；天空亮度在原始帧0/234/300分别为0.344/0.403/0.913。静态图不替代正常速度观感验收。

Godot内置结束统计仍报告0帧：显式 `force_draw` 不更新自动绘制帧计数。因此使用磁盘计数、PCM采样数和编码后逐帧解码交叉验证，不引用该结束统计。快速退出会留下8个ObjectDB警告。固定帧率导出不作实时性能证据。

## 重现

使用一个新的空输出目录，避免旧帧混入。项目根目录运行（Mac的Godot可执行文件路径按安装位置）：

```sh
Godot --path . --resolution 1152x648 --fixed-fps 30 \
  --write-movie /tmp/new-restoration/frame.png \
  --script tools/render_finale_restoration.gd --quit-after 541
swift tools/encode_png_video.swift /tmp/new-restoration /tmp/new-restoration-silent.mp4
swift tools/mux_video_audio.swift /tmp/new-restoration-silent.mp4 /tmp/new-restoration/frame.wav /tmp/new-restoration.mp4
swift tools/verify_finale_movie.swift /tmp/new-restoration.mp4 /tmp/new-restoration-decoded 540
```

编码器只接受新的目标文件；混流工具现在拒绝音视频时长不一致，不再静默截短。首次/二次失败记录仍保留在10月13日交接，不是现行交付。其他旧巫师/牵手导出工具尚未统一迁移到本轮时钟，不能据此声明它们都已修复。

API依据：[Godot RenderingServer](https://docs.godotengine.org/en/stable/classes/class_renderingserver.html)、[Movie Maker](https://docs.godotengine.org/en/stable/tutorials/animation/creating_movies.html)。
