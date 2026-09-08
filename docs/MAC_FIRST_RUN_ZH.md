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

1. 点击编辑器右上角三角形，或按 `F6/F5`。
2. 在 Debug Start 菜单选择白白菜或小呆猪章节。
3. 按 `WASD` / 方向键移动；`E` / 空格互动；小呆猪用 `J` / `Z` 攻击。
4. `F5` 是游戏内快速保存；编辑器的运行按钮也可能使用 F5，只有游戏窗口获得焦点时才是存档。

## 4. Git 基础

在“终端”执行：

```bash
cd /Users/missdaidai/codex/smallpiggy
git status
git log --oneline
```

远程仓库已设置为 `git@github.com:Mlonporky/smallpiggy.git`。如果第一次 push 提示 SSH 问题，需要先在 GitHub 添加这台 Mac 的 SSH key。

