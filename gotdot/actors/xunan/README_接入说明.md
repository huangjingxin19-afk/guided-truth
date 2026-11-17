# 许南 C5 · 第一批游戏素材 v1

## 游戏素材
- `gotdot/actors/xunan/idle/xunan_idle_front.png` 正面站姿
- `gotdot/actors/xunan/idle/xunan_idle_right.png` 朝右站姿
- `gotdot/actors/xunan/idle/xunan_idle_left.png` 朝左站姿
- `gotdot/actors/xunan/idle/xunan_idle_back.png` 背面站姿
- `gotdot/actors/xunan/actions/xunan_carry_narrow_bag_front.png` 手握窄袋人物动作帧（袋子单独存放）
- `gotdot/props/xunan_narrow_music_stand_bag.png` 独立细长谱架袋（12×41）

## Godot 场景
- `gotdot/actors/xu_nan.tscn`: 许南正面普通待机示例
- `gotdot/actors/xu_nan_carry_bag.tscn`: 叠放人物动作帧 + 独立窄袋，人物在前，窄袋在后
- Godot 工程的 `res://` 根目录对应压缩包中 `gotdot/`。将整个 `gotdot` 子目录合入工程。
- 所有角色贴图 `72×108`，RGBA 真透明无半透明边缘，脚底像素 y=104。`Sprite2D.centered=false`，`position=(-36,-104)`，`texture_filter=NEAREST`、`scale=(1,1)`，角色父节点原点为脚下。
- **独立窄袋像素坐标**：相对 72×108 角色帧左上角 `(45,58)`，在 Godot 角色节点下的局部位置 `(9,-46)`；袋子先画，人物后画。不要在已有合成场景中再重复叠袋。
- 对应 `front_desk` / 后院角色 NPC 需要替换占位 Node2D 里的 Polygon2D。角色场景本身不自动覆盖游戏中的现有占位。

## 剧情限制和状态
- 本包是 C5 第一批：站姿四方向、提窄袋（肩上的小包是人物服饰的一部分，谱架窄袋为单独道具）。
- 第三章实际 12 号白脚折叠谱架、从袋里抽出谱架和递交谱架动作 **没有制作**，后续另批交付。
- 人物右手腕旧伤通过自然姿势表现，不绘制夸张伤痕。
- `.ora` 为独立帧及窄袋图层的可编辑源；`qa_report.json` 为静态技术检查。
- 本批素材为 AI 辅助角色参考图，经脚底校准、背景分离、统一限色和小范围像素修正制作。应登记为 AI 辅助生成与编辑，不是纯人工原创。
- 已检查：尺寸、透明度、限色、图像路径和 ZIP。**未在本机实际运行 Godot 或安卓设备**，需完成游戏内遮挡、持袋动作和手部握点的实机验收。
