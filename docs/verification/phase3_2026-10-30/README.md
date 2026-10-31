# 第三阶段验证证据

本机 Godot 4.7.2 / Apple M1 / OpenGL。存档与设置均使用 `/tmp` 隔离路径；日期按用户 America/Toronto 时区。

## 功能回归

[结果清单](results.json)：12 个不同脚本、13 次 headless 固定 60 步长运行，全部退出 0。

| 范围 | 脚本／证据 | 结果含义 |
| --- | --- | --- |
| 包装纸鼠标 | wrapping_puzzle_test | 不规则命中、错误摆放、拼合翻面、收集与部分存档恢复 |
| 包装纸键盘 | wrapping_keyboard_test | Tab／数字选取、连续移动、Enter／空格放下与翻面、F1 暂停、缩放／收起；继承正式房间收集与保存回归，纸片定位均改为键盘输入 |
| 平台暂停与提示 | platform_guidance_test | 独立／主线暂停 R 不重置、恢复后 R 有效、营火和收集保留、支路／出口前提示、文字画布边界；局部位置和收集状态为夹具 |
| 史莱姆 | chapter2_combat_test | 保护壳、原40%觉醒、翻滚／招架／攻击及拾取路由 |
| 密码与探索 | combination_lock_test、mushroom_guidance_test、table_slide_test | 输入、解锁、阶段目标和桌面滑块逻辑；不证明玩家知道密码 |
| 设置与存档 | settings_ui_test、story_cave_checkpoint_test | 全局设置、暂停嵌套、营火 JSON 恢复、保存失败与重试 |
| 主线 | finale_routes_test、full_story_flow_test | 既有两线和新游戏→Credits→结局续档通过；自动对白、部分调查调用正式函数 |
| 全收集 | all_fireflies_route_test 两个模式 | 独立／主线均60/60、2秘密、0死亡；物理按键路线使用R折返，主线60个ID写盘／重读及真实出口通过 |

全收集逐编号记录：[独立](fireflies-standalone-headless.json)、[主线](fireflies-story-headless.json)。本轮没有移动收集点、改拾取半径、跳跃、伤害、密码或觉醒规则。

## 图形专项

[四个最终图形进程结果](graphical_results.json)，均退出0。

- [包装纸正常速度日志](logs/wrapping-keyboard-graphical.log)：WRAPPING_KEYBOARD_INPUT_OK、WRAPPING_PUZZLE_OK，退出0。三种窗口800×600、1152×648、1440×900；输入、暂停、缩放、翻面和正式室内保存恢复通过。
- [平台正常速度日志](logs/platform-guidance-graphical.log)：PLATFORM_GUIDANCE_OK，退出0。独立／主线各检查800×600与1152×648窗口。
- [截图回调清理专项](logs/route-capture-cleanup.log)：刻意关闭绘制，两个截图均超时，回调数量保持0→0，ROUTE_CAPTURE_CLEANUP_OK、退出0。它不是视觉效果测试。
- [正常速度主线全收集最终日志](logs/all-fireflies-story-graphical.log)：工具修复后60/60、2秘密、0死亡、关内89.7秒，存档重读与出口切场通过，退出0。[逐编号记录](fireflies-story-graphical.json)。部分截图（含all-60）因窗口未绘制而跳过，本轮不提供冒充此轮的60/60截图，不声称全程绘制覆盖；ObjectDB退出警告保留。
- 保持1152×648或平台1536×864的既有逻辑布局等比缩放，800×600视口截图为800×450；外侧留黑不计入截图。可操作且无控件裁切不等于小字号最终可读性验收。

下列选取截图已打开复看，其他截图保留为补充。正常速度输入检查和静态图不证明全主线动画、声音或趣味性已验收。

最终布局截图在真实图形后端和窗口尺寸下主动渲染一次，避免窗口被遮挡时无限等 `frame_post_draw`；这是稳定界面快照，不用于测量持续绘制覆盖或帧率。正常速度物理全收集仍用有时限的截图等待，未绘制时明确记录跳过。

| 图 | 检查内容 |
| --- | --- |
| [小窗口拼图](screenshots/keyboard-800x600.png) | 选取按钮／焦点／操作行可见，文字随比例缩小 |
| [大窗口拼图](screenshots/keyboard-1440x900.png) | 图案与按钮没有重叠、裁切 |
| [键盘搬动](screenshots/carried-1152x648.png) | 移动中的碎片、状态和焦点对应 |
| [键盘翻面](screenshots/keyboard-message.png) | 完成后焦点到翻面按钮；破损右缘文字裁切为原设计 |
| [主线出口小窗口](screenshots/story-exit-800x600.png)、[标准窗口](screenshots/story-exit-1152x648.png) | 越过洞口将继续剧情、无需全收集及提前R折返的提示可见 |
| [独立关出口](screenshots/standalone-exit-800x600.png) | 使用独立关的提示，保留出口后探索行为 |

## 复现与诊断

以下在仓库目录运行，独立脚本不要同时启动两份；Godot安装位置不同时替换路径。

```bash
python3 tools/run_phase12_checks.py wrapping_puzzle_test wrapping_keyboard_test platform_guidance_test chapter2_combat_test combination_lock_test mushroom_guidance_test table_slide_test story_cave_checkpoint_test settings_ui_test finale_routes_test full_story_flow_test --output /tmp/piggy-phase3-repeat
python3 tools/run_phase12_checks.py all_fireflies_route_test --output /tmp/piggy-phase3-flies-independent
STORY_FIREFLIES=1 python3 tools/run_phase12_checks.py all_fireflies_route_test --output /tmp/piggy-phase3-flies-mainline
PIGGY_SETTINGS_PATH=/tmp/piggy-phase3-settings.cfg PIGGY_SAVE_PATH=/tmp/piggy-phase3-save.json /Users/missdaidai/Godot.app/Contents/MacOS/Godot --path . --rendering-driver opengl3 --audio-driver Dummy --log-file /tmp/piggy-phase3-keyboard.log --script res://tests/wrapping_keyboard_test.gd
```

将最后一行脚本替换为 `platform_guidance_test.gd` 可复跑平台图形专项。正常速度全收集另用 `STORY_FIREFLIES=1` 和 `all_fireflies_route_test.gd`。

诊断单列，不作为最终通过日志：

- [修复前暂停R复现](diagnostics/paused-r-before-fix.log)：正式问题，暂停后角色位置被重置。
- [收集计数测试纠正](diagnostics/collection-count-test-correction.log)：夹具移动途中又捡到一颗，原断言错误要求总数不增加；改为已有ID和秘密不丢失。不是游戏丢收集。
- [图形换场等待纠正](diagnostics/graphical-scene-wait.log)：测试只等物理帧导致当前场景尚未赋值；改等正式场景到位。不是正式路线切场失败。
- [全收集退出崩溃复跑](diagnostics/graphical-all60-repeat-crash.log)：玩法标记、60个ID重读及出口都通过，但退出134，不能算通过的进程。截图未绘制被跳过。
- [短复现修复前](diagnostics/capture-timeout-before.log)：关闭绘制、两个截图超时，回调0→2，退出时同样崩溃。单独加载最终章而不超时截图的对照退出0。修复只改测试截图函数，超时后断开残留回调；[修复后](logs/route-capture-cleanup.log)0→0、退出0。

故意保存失败的ERROR是负向用例；系统证书、ObjectDB退出警告保留，不宣称零警告。原存档／备份、原设置缺省状态及用户装配的保护核对见 [保护结果](workspace_protection.json)。

## 仍待真实试玩

无伤玩家对40%觉醒的理解、首次密码信息、支路发现性与整体趣味性。已提供[简短试玩记录](../../PHASE3_PLAYTEST_ZH.md)，目前没有人类参与者结果。没有新素材、动作表或音频；自动检查不是美术／听感验收。
