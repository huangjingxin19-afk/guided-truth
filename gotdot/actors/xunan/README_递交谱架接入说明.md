# 《被引向的真相》许南 C5 · 递交谱架 v9（保留原版右侧站姿）

## 本次唯一人物变更
- `gotdot/actors/xunan/actions/xunan_hand_over_stand_right.png`：72×108 真透明单帧动作，只修改原站姿局部手臂（x32–54, y44–63）；正脸、肩背、衣襟、胸腰、裤子、鞋子沿用原版。
- **没有包含、没有修改 `gotdot/actors/xunan/idle/xunan_idle_right.png`**。无需改动原仓库的四方向待机帧；废弃此前 v8 的加宽侧面。
- 改成近身弯肘、一只手从下方托住折叠谱架。旧的垂下手掌已清理。
- `gotdot/props/xunan_music_stand_12_handover.png` 沿用 v7 同一独立道具，未重画。

## Godot 4 导入
1. 将 ZIP 内 `gotdot/` 文件合并进工程根目录的 `gotdot/` 中（工程 `res://` 指向此目录）。**不要导入任何 v8 的 xunan_idle_right.png。**
2. 在测试场景中打开 `res://actors/xu_nan_hand_over_stand.tscn`，此场景复合独立谱架与人物动作帧，已使用 Nearest 且 `centered=false`。
3. 人物 Sprite 坐标 `(-36,-104)`，谱架 Sprite 坐标 `(5,-57)`，对应人物画布上的 `(41,47)`；人物在前、谱架在后。角色 Node2D 原点为脚下，保持 `scale=(1,1)`。
4. 只替换第三章「许南递交谱架」动作引用；不要修改已有 `xu_nan.tscn`、`xunan_idle_right.png` 或「抽出谱架」动作。
5. 场景角色是否真的跟韩素手部衔接，需要在 Godot 现场检查。此包完成静态尺寸/资源/合成检查，**没有运行 Godot 引擎/安卓测试**。

## 原版及检查
- 脚底固定 y=104，角色实际边界和头部沿用原版。
- 服装、皮肤仅使用角色定版色板；无半透明像素。
- `qa_report.json` 有旧手清理、握点重叠、原版 SHA 和资源路径验证。
- `source/*.ora` 是可编辑像素源文件，可用支持 OpenRaster 的工具打开；预览比对图不放进正式 ZIP。
- GitHub 原仓库未修改。本 ZIP 请人工复核动作自然度，后续再定版。
