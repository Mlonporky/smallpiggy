# 橡子回忆 · 完整效果

## 直接看

- 视频：[acorn_memory_final.mp4](art_direction/acorn_memory_final/acorn_memory_final.mp4)，约35秒，1152×648、30fps，无音轨。
- 自动播放场景：[`acorn_memory_final.tscn`](../scenes/cabbage_act2/acorn_memory_final.tscn)。在 Godot 打开后按 **F6**（部分 Mac 用 **fn+F6**），结尾可点“再看一次橡子回忆”。
- 手动对白场景：[`acorn_memory_preview.tscn`](../scenes/cabbage_act2/acorn_memory_preview.tscn)。用 **E / 空格**继续。

两个预览都不改玩家存档。正式剧情仍在蘑菇屋桌面拼图完成后触发。

## 本轮效果

桌面打开、28颗橡子落下 → 林间同行、放慢脚步 → 小猪整体前倾触碰地面橡子 → 拿起并说原对白 → 穿绳、在领口佩戴、放开吊坠 → 白菜回应 → 回到现实的小男孩与原独白。

小猪读取用户保存的 [`editable_pig.tscn`](../scenes/animation_studies/editable_pig.tscn)。头、身体、领口保持一个完整部件；运行时校准旋转中心，固定四肢长度和走路髋点。用户编辑源文件保持原样。A/B为节点编号，不推断角色自身左右。

本轮按已说明的动作口径执行：站立、行走按可见指尖轮廓同高；拾取、穿绳及佩戴允许两只手处于不同高度。拾取使用32°整体前倾、A腿原地内收，并检查脚底与腹部不穿地；同一颗橡子在蹄尖接触后才跟手，最后转为胸前吊坠。肩部、比例和层级来自用户装配。

画面增加脚下软阴影、少量林间浮尘、柔和暗角与缓慢推近。小猪先合成为一张图再加粉色柔雾，避免半透明四肢互相透出。对白保留三句原文，文字框缩小并随实际高度贴底，现实长独白的自动阅读时间更长。

## 当前制作范围

小猪为五部件程序动画；白菜仍为既有四帧步态。穿绳和佩戴以双手、绳线与同一吊坠连续运动表达，没有细致手指打结、独立表情／眨眼或新音频。本次仅接入橡子回忆，其他章节不推广。正常速度图形播放与自动检查通过，不代替用户对动作观感的验收。

## 重新导出

创建临时目录后，用本机 Godot 的 Movie Maker 渲染：

```sh
mkdir -p /tmp/acorn-final
/Users/missdaidai/Godot.app/Contents/MacOS/Godot --path . --resolution 1152x648 --fixed-fps 30 --write-movie /tmp/acorn-final/frame.png --script tools/render_acorn_memory.gd
swift tools/encode_png_video.swift /tmp/acorn-final /tmp/acorn-memory-final.mp4
```

在仓库目录运行，输出文件需使用尚未存在的路径。编码使用 macOS AVFoundation；固定30fps导出不作为运行时性能证据。
