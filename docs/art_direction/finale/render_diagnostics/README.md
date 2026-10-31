# 最终章实际绘制频率排查

## 当前结论

已复现“游戏继续处理，但窗口不绘制”的机制：在同一山庄场景中，窗口可见时每秒约120次处理和绘制；最小化期间 `window_can_draw=false`，处理继续、绘制停止，恢复后又正常绘制。最简移动色块也约120次/秒，因此当前短测没有显示山庄复杂度导致固定低绘制频率。

这说明上次222秒、31395次处理、3217次绘制的报告**不能作为整章渲染性能证据**。旧报告没有窗口状态时间线，无法事后证明那一次究竟是最小化、遮挡、切换桌面或其他可见性变化；本轮复现支持窗口可绘制状态这一解释，不声称已确认当时的具体用户操作。

所有数字是Godot绘制调用/`frame_post_draw`回调，**不是显示器最终呈现帧率、GPU耗时或屏幕扫描测量**。本机显示接口报告60Hz，而引擎回调约120次/秒；不能向用户宣称显示器显示了120fps。

## 对照结果

| 记录 | 处理帧 | 绘制帧 | 结果 |
| --- | ---: | ---: | --- |
| restoration_foreground.json | 1440 | 1440 | 12.0004秒，P95绘制间隔13.142ms，最大14.269ms，窗口始终可绘制 |
| empty_foreground.json | 1440 | 1440 | 简单移动色块，P95 13.297ms，最大14.588ms，绘制覆盖有效 |
| restoration_cycle.json | 1389 | 894 | 4秒前台→4秒最小化→4秒恢复；495次处理时窗口不可绘制，最大绘制间隔3968.922ms，正确判为覆盖无效 |

最小化/恢复动画约各0.6秒，其窗口模式和can_draw转换并非同一瞬间，实际时间点见JSON。第一次山庄前台短测没有启用公共meter，仍独立记录了绘制信号与Engine计数，两者一致；后两个对照也验证了公共meter。第二个短探针启动时第一个仍处于退出阶段，因此这些短测不当作隔离性能基准；完整播放另行单独运行。

## 新的验证工具

`tests/finale_render_meter.gd`同时记录：

- 处理循环间隔和 `RenderingServer.frame_post_draw`绘制间隔，分别统计，不混称“帧时”。
- Engine绘制计数与回调数量是否一致（允许采样边界相差1）。
- 每秒处理/绘制数量、窗口可绘制状态、焦点/模式/渲染开关变化。
- 超过35ms的绘制间隔及是否跨过不可绘制区间。

`render_coverage_valid`仅表示本次记录有足够绘制覆盖：非headless、两计数一致、不可绘制时长<10ms、绘制/处理比≥95%。它不是流畅度验收。帧间隔是否合理仍需独立看报告。

`tests/finale_playback.gd`保留原逻辑完成与存档隔离检查，新增`rendering`报告。使用`--require-draw-coverage`时，覆盖不足返回退出码2，即使剧情已经走到Credits。旧顶层p95/max字段保留兼容，属于**process**，绘制数据只读`rendering.draw_intervals`。

## 重现

在项目根目录，使用本机Godot可执行文件（本机`/Users/missdaidai/Godot.app/Contents/MacOS/Godot`）：

```sh
Godot --path . --resolution 1152x648 --script tests/finale_render_probe.gd -- --subject=empty --variant=foreground
Godot --path . --resolution 1152x648 --script tests/finale_render_probe.gd -- --subject=restoration --variant=cycle
Godot --path . --resolution 1152x648 --script tests/finale_playback.gd -- --report=res://docs/art_direction/finale/render_diagnostics/full_playback.json --require-draw-coverage
```

逐条运行，确认上一条已退出再启动下一条。完整播放约222秒，测试窗口临时置顶；不要同步导入素材、编码或跑其他图形测试。若用户切换桌面/最小化，保留状态记录，重新在可见窗口验证，不使用force_draw伪装成正常速度渲染。

## 引擎依据

[Godot main.cpp绘制门槛](https://github.com/godotengine/godot/blob/4.7/main/main.cpp#L4706-L4722)：仅窗口可绘制（或有其他输出）且渲染循环开启时进入常规绘制；每次绘制增加Engine计数。[macOS DisplayServer实现](https://github.com/godotengine/godot/blob/4.7/platform/macos/display_server_macos.mm#L2513-L2525)由窗口可见状态提供can_draw。以上为官方4.7分支，运行二进制4.7.2 ed1daf0bf；本轮实测计数一致，未修改引擎。

正式游戏、剧情节奏、渲染器、VSync与角色源装配均未改动。这里只修正诊断与验收方式。正常速度观感和最终屏幕呈现仍不能仅凭统计宣称通过。

## 最终整章验证

单独正常速度播放到Credits通过，状态隔离通过，进程退出0。绘制采样窗口222.316118秒，26586次处理、26586次Engine绘制、26586次frame_post_draw，计数完全一致；全程can_draw=true且保持焦点，render_loop=true、low_processor=false，不可绘制时长0。绘制覆盖有效，旧“多数处理周期没绘制”在本次没有复现。

绘制间隔P50 9.390ms、P95 13.073ms、max44.550ms；只有一次超过35ms，发生在103.681224秒、remember_gift镜头。该长间隔没有跨过不可绘制区间，因此不归因于最小化，原因尚未确定；后续如再现，再针对该镜头剖析。不能称完全无卡顿，也不能把119.586次/秒引擎绘制换算成显示器120fps。

本轮完成频率排查与测量修正，没有证据需要修改正式游戏渲染设置。下一步保留长间隔观察点，按用户反馈继续动画/声音工作；旧完整报告保留用于追溯，当前以render_diagnostics/full_playback.json为准。最终git diff --check、源装配cmp通过，未提交或推送。

## 2026-10-16 后续

变身重复构建已改为初始化预备并复用，gift_repetitions_reuse.json五轮复测入镜最高2.106ms，绘制max27.955ms。润色后最终全章请读../reunion_v2/full_playback.json：27220次处理/绘制一致，P95 13.075ms/max36.049ms，一次>35ms仍位于remember_you。旧报告保留用于对照，当前阶段进度见HANDOFF_2026-10-16_FINALE_POLISH.md。
