# Mac 第一次运行（一步一步）

## 1. 安装 Godot

1. 前往 Godot 官方下载页，下载 **Godot 4.7.2 stable 标准版**（不要下载 .NET 版或 dev 版）。
2. 打开下载的压缩包，把 `Godot.app` 拖进“应用程序”。
3. 如果 macOS 第一次拦截：进入“系统设置 → 隐私与安全性”，确认打开 Godot。

## 2. 导入项目

1. 打开 Godot。
2. 在 Project Manager 点击 **Import**。
3. 选择 `smallpiggy/project.godot`。
4. 点击 **Import & Edit**，等待右下角素材导入完成。

## 3. 第一次试玩

1. 点击编辑器右上角三角形，或按 `F5`（部分 Mac 用 `fn + F5`）。`F6` 只运行当前场景，不是完整项目入口。
2. 选择“新游戏 · 从故事开场开始”；已有存档会先提示覆盖。章节试玩请进入“开发预览与章节测试”，其中的测试不会覆盖正式存档。
3. 按 `WASD` / 方向键移动；`E` / 空格互动；小呆猪用 `J` / `Z` 攻击。
4. `F5` 是游戏内快速保存；编辑器的运行按钮也可能使用 F5，只有游戏窗口获得焦点时才是存档。
5. `F1` 打开设置与操作，按 `Esc` / `F1` 返回；音乐、音效、环境声分别调节，重启后保留。`M` 一键静音全部声音。
6. 开场 `Esc` / `P` 暂停，右上按钮跳过；调查近景 `Esc` 收起；探索时 `Esc` 打开暂停菜单。保存失败会显示提示，保留当前游戏后重试。

## 4. Git 基础

在“终端”执行：

```bash
cd /Users/missdaidai/codex/smallpiggy
git status
git log --oneline
```

远程仓库已设置为 `git@github.com:Mlonporky/smallpiggy.git`。如果第一次 push 提示 SSH 问题，需要先在 GitHub 添加这台 Mac 的 SSH key。
