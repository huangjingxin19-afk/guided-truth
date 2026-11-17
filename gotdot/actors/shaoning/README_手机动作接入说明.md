# 《被引向的真相》邵宁 C4 · 看手机动作 v4

这版针对 v2/v3 头、手、手机拥挤导致的模糊感，不缩小大图，而是在 72×108 定版像素母版上改一侧手臂与手持小手机，并保留另一只手自然下垂。

## 游戏里真正需要的资源
- `gotdot/actors/shaoning/actions/shaoning_check_phone.png`：72×108、RGBA 真透明，手机**已画在动作帧中**。
- `gotdot/props/shaoning_phone.png`：12×18 独立手机，用于桌面/道具展示/证物图，**不要再叠加到人物动作上**。
- `gotdot/actors/shaoning/shaoning_phone_pose.tscn`：可以单独加载的 Godot 4 静态场景，脚底锚点在节点原点，已设置 Nearest。

## 正式接入
1. 将 ZIP 内 `gotdot/` 目录合并至现有工程 `gotdot/` 同名目录。
2. 第二章前台邵宁查看群聊/私信时，将她的 Sprite2D 贴图切换为 `res://actors/shaoning/actions/shaoning_check_phone.png`；结束时恢复 `shaoning_idle_front.png`。
3. 保持角色站位不变：72×108 原图脚底参考 `(36,104)`；若 Sprite2D.centered=false，位置设 `(-36,-104)`；texture_filter=Nearest、scale=1。
4. 手机界面与聊天证据请继续由专门 UI 展示，不在 72×108 人物帧中绘制文字。
5. 若选择独立场景 `shaoning_phone_pose.tscn`，它已经使用同一个动作帧。避免重复覆盖场景中的邵宁调查节点。

## 编辑文件与质量记录
- `source/shaoning_phone_v4_editable.ora`：两层可编辑源文件。
- `source/shaoning_idle_front_v1_source.png`：第一批正面来源帧。
- `source/base_idle_without_right_forearm.png` 和 `source/arm_hand_phone_overlay.png`：可分别调整人物母版与动作。
- `meta/qa_report.json`：色板、透明、尺寸、脚底等程序检查。

**状态**：逐像素静态检查通过；尚未运行 Godot / Android，且没有修改 GitHub 仓库，需在前台镜头对照遮挡、比例和动作可读性。
