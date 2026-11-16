# 韩素｜向右推车四帧素材包（含最新确认的预览）

## 请先区分两类内容

1. `previews/latest_approved_visual_preview.png` 是你刚确认的那张 **1448×1086 不透明概念/组合预览**，如实保留。它没有独立透明人物/推车图层，不能直接作为 1× 游戏帧导入。
2. `gotdot/` 下是当前已经完成、可单独导入的 **透明 RGBA 像素素材**。这些来自前一次经像素接触点校准的四帧和独立推车，不是从最新概念预览中逐帧原样提取；两套图的细节和比例可能不同。请通过 `previews/actual_1x_4x_from_game_png.png` 检查真实游戏资产的组合效果。

## 正式游戏资产

- `gotdot/actors/hansu/idle/hansu_idle_front.png`：韩素正面站姿，72×108。
- `gotdot/actors/hansu/actions/hansu_pushcart_right.png`：向右静态握把，72×108。
- `gotdot/actors/hansu/actions/hansu_pushcart_walk_right_01.png` ～ `_04.png`：向右推车四帧，逐帧 72×108。
- `gotdot/props/pushcart_loaded_right.png`：包含六把折叠凳、已降低顶部握把的推车，128×86。
- 所有正式 PNG 是硬边透明 RGBA。人物脚底基线 y=104。Godot 使用最近邻过滤、scale=1。

## 合成参数

以组合画布左上角为 (0,0)：角色 PNG 放 (10,0)；推车 PNG 放 (46,22)，即相对人物左上角 `(+36,+22)`。**先画推车，再画人物**，使手遮住握把的接触点。静止和四帧推车时不要再额外移动车把。如果在游戏里统一移动角色与车，应移动共同父节点。

组合图片 `previews/actual_combined_1x_01.png` ～ `_04.png` 是直接由上述两套 PNG 生成的 212×125 透明画面。`previews/actual_loop_from_game_png.gif` 是实际素材循环，供核对而非游戏资源。

## 当前限制

- 最新确认预览图只有合成平面图，**尚未做成与它逐像素相同的四张透明人物帧和独立推车图**。
- 这份 ZIP 不包含 Godot 场景变更、轮子越槛动画或实机验证。
- 如以最新概念预览为最终像素造型，仍需先按原角色规格精修并重新输出正式素材，不能只靠打包来完成。
