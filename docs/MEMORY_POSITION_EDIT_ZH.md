# 手动调整回忆影子

1. 在 Godot 文件系统面板打开 `scenes/chapter1/kitchen.tscn`（第二次）或 `living.tscn`（第三次）。第一次是 `bedroom.tscn`。
2. 切到上方「2D」，在左侧场景树选中 `MemoryAnchor`。
3. 在画布拖动影子，或在右侧 Inspector 的 Transform → Position 修改坐标；Scale 可调整大小。背景节点已锁定，避免误拖。
4. 按 Command+S 保存，再运行游戏触发对应回忆。

请选择「本地 / Local」场景树来编辑，不要在运行时的「远程 / Remote」节点中改位置。已完成的回忆不会因重新进房自动重播，可从新游戏验证。

预览显示影子淡入完成时的位置和颜色；游戏中固定位置，只淡入淡出，不再上浮、缩放镜头或闪白。三次峰值不透明度依次为0.42、0.55、0.68，颜色也逐次加深。MemoryAnchor的Position、Scale、Modulate直接用于运行时，调整后保存即可生效。
