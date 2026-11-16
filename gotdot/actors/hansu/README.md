# 《被引向的真相》韩素 NPC 素材包

## 包含文件

- `gotdot/actors/hansu/idle/hansu_idle_front.png` — 韩素正面自然站姿，72×108，真实透明 RGBA，脚底 y=104，锚点 (36,104)。
- `gotdot/actors/hansu/actions/hansu_pushcart_right.png` — 韩素向右侧伸双臂握推车的修正版静态姿势，72×108，真实透明 RGBA，脚底 y=104。
- `gotdot/props/pushcart_loaded_right.png` — 向右移动的平板车，载六把折叠凳，128×86，真实透明 RGBA。
- `previews/hansu_cart_aligned_1x_rgba.png` — 人物和推车同框的透明对齐测试；只作检验。
- `previews/hansu_cart_aligned_1x_grey.png` — 同框 1× 中性灰底查看图。
- `previews/hansu_cart_comparison_1x_4x.png` — 1× / 4× 最近邻检查图，便于复核手与把手的位置。
- `previews/hansu_linhe_comparison.png` — 前面已制作的林禾与韩素正面站姿对照。
- `alignment.json` — 实际像素位置与 Godot 放置建议。

## Godot 接入说明

把 `gotdot/` 文件夹内资源按相同路径复制到仓库的 `gotdot/`。只上传 PNG 素材不会自动替换现有的 `Polygon2D` 占位角色或复走动画，需要在对应场景中替换贴图并接入动画。

对齐预览的坐标（左上为原点，1× 像素）：画布 212×125；人物左上 `(10,0)`，推车左上 `(46,22)`。人物与轮胎接地在同一条 y=104 基线。贴图分层时先画推车，再画人物，以便双手压在把手上。

如果以韩素脚底中心为父 Node2D 原点，并使用默认 `Sprite2D.centered=true`：

- 韩素 Sprite2D 位置 `(0,-50)`。
- 推车 Sprite2D 位置 `(64,-39)`。

其中推车相对于人物帧左上的偏移是 `(36,22)`，相对于人物脚底中心锚点的推车左上偏移是 `(0,-82)`。此偏移仅针对当前两张 PNG。图片使用 `Nearest` 纹理过滤、`scale = 1`。

## 范围与自检

当前包交付的是正面站姿、右侧**静态推车握姿**、独立推车以及检查图；不含右侧推车行走逐帧动画，不含脚垫状态变体、音效或自动接入 Godot 的代码。1× 合成预览已按实际贴图坐标复核双手与握把接触位置，原始 PNG 无背景、人物无投影。

素材制作：AI 辅助生成与像素级处理；具体商业使用需按项目素材授权记录归档。游戏内已有林禾 PNG 仅用于风格对照，不参与韩素人物图复制。
