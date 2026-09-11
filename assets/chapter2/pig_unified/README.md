# 小呆猪细化版（当前使用）

用户指出小猪像素颗粒比白菜、巫师、史莱姆重，要求统一。根因是旧小猪素材的大像素阶梯／粗描边，加上它单独使用Nearest而其他角色使用Linear或Linear with mipmaps。

当前使用内置image_gen以白菜男孩、巫师为渲染参考，细化披风和持棍小猪：保留角色、姿势及排列，改为细轮廓和柔和明暗，去掉粗方块。原粗像素版本保留在 `../pig_pixel/`。

结构保持不变：cape四行四列16帧；armed四行三列12帧；expressions六表情；wake复用既有姿势构成六段时序；frames为独立透明PNG。画布320×320、脚底(160,300)，方向行序下／左／上／右。持棍源图使用固定0.72倍高质量缩小，披风／持棍在游戏内统一0.53倍。wake取自源图中画得较小的表情行（站立头宽175px，披风正面195px），倒地／睡／坐五帧在游戏内固定0.59倍（≈0.53×1.11），倍率见 `scenes/chapter2/pig.gd` 的 `SHEET_SCALE`。wake第6帧（表情行的站姿）披风和手臂轮廓比行走图窄，头宽对齐后仍显得小一圈，所以游戏内不再使用：起身最后一步直接显示披风正面行走帧 `cape_down_00`（见 `pig.gd` 的 `wake_up()`）。wake.png本身未改。

`actors/shared/character_sprite_style.gd` 是角色纹理过滤的唯一配置点。男孩、白菜形态、小猪、巫师、史莱姆纹理统一开启mipmap，活动角色代码引用同一个FILTER。背景、调查图片、回忆图等不属于此配置范围。场景中的角色自然身高保持原设计，并不强行拉成相同大小。

可通过 `scripts/art/prepare_pig_pixel.py --style unified` 重建；依赖Pillow和numpy，读取仓库旁 `bigidea/02_pig/小呆猪披风-统一画风.png`、`小呆猪拿木棍-统一画风.png`。首次导入需保留本目录已有的mipmap导入配置。

验证：`character_sprite_style_test.gd`、`pig_pixel_test.gd`（历史命名）、`boy_atlas_test.gd`、`opening_test.gd`、`gameplay_test.gd`通过。真实Godot渲染四方向、持棍及开场截图；同尺寸前后比较在 `docs/art_direction/character_style_review/comparison.png`。同尺寸对照按alpha>0.1的可见边界排除源图透明杂点，只用于比较描边和颗粒，不是游戏内相对身高。

渲染参数已严格统一；轮廓、明暗已向参考靠拢，角色颜色和材质仍保持各自特征。没有将生成式风格匹配宣称为逐像素相同。攻击仍复用持棍旋转，苏醒仍是已有表情组合，没有新增独立攻击或起身动画。
