# 游戏中文字体

全局 UI 使用 `game_font.tres`：Noto Sans SC，字重 400。项目设置 `gui/theme/custom_font` 让菜单、对白及动态创建的 Label/Button 都继承这份字体；直接绘制文字的 PropInteractable 也使用同一资源。字体随项目分发，不依赖电脑安装中文字体。

原始可变字体未修改，2026-09-14 下载自 Google Fonts 官方仓库：
- https://github.com/google/fonts/tree/main/ofl/notosanssc
- 字体文件：`NotoSansSC[wght].ttf`，本地命名为 `NotoSansSC.ttf`
- SIL Open Font License 1.1，完整版权及许可见 `OFL.txt`，发布游戏时保留该文件。

字体约 17 MiB，保留完整字库以支持后续新增中文对白，不做仅包含现有文本的裁剪。
