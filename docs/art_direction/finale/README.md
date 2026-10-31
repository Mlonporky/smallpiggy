# 最终章美术与验证

2026-10-07 使用 imagegen 内置工具生成：

- reunion_forest_v1：16:9 手绘森林空地，两侧古树、低位横向道路、蓝绿暗部和远方暖晨光；无角色／文字／发光道具。用于最终道路及重逢。
- holding_hands_v1：参考 cabbage_walk_v1.png 与已认可 pig_round_v2/design_preview.png；圆润短鼻红披风小猪在左，白菜在右，短臂在腰间真实牵手，同一地面，透明底，无粒子文字。生成图带少量边缘柔色，按实际脚底定位。静态关键姿势，不当作完整动画。
- cape_memory_v1：同两张角色参考，近景白菜把折好的红披风交给小猪。初稿额外画了一件已穿的披风。
- cape_memory_v2：对初稿明确“只移除小猪肩背和颈部已穿的披风，保留双手之间的唯一赠礼披风，其他不变”；检查后接入，v1 保留但不引用。

所有最终运行时素材复制进 assets/finale，不依赖 .codex 目录。原有 BIG IDEA 原图和用户可编辑装配未改。角色动画及专门声音缺项见 docs/FINAL_CHAPTER_ZH.md。

finale-*.png 为实际 Godot OpenGL 渲染截图。playback.json 来自正常速度完整播放，非固定帧导出；测试期间存在其它 headless 验证进程，不能将帧时当作严格单进程性能基准。
