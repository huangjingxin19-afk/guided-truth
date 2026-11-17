# 邵宁 C4 展示登记页纸角 · Godot 像素素材 v1

项目：《被引向的真相》，第二章《少掉的一页》。这批是**实际游戏尺寸的透明像素 PNG**，不是高清概念图压缩。GitHub 原仓库尚未修改。

## 直接使用
将 `gotdot/` 下的文件合并至 Godot 工程的 `gotdot/` 同名目录（使场景内路径以 `res://actors/…` 和 `res://props/…` 开头）。

- `actors/shaoning/actions/shaoning_show_page_front.png`：**72×108**，脚底 `(36,104)`，人物和小夹本体已经画在同一动作帧上。动作时切换 Sprite 贴图；完毕切回 `idle/shaoning_idle_front.png`。**不要**将下列独立登记夹再次叠加到她手上。
- `actors/shaoning/shaoning_show_page_pose.tscn`：可单独实例化的 Godot 4 静态场景，已设置 `texture_filter=1`（Nearest），Sprite 偏移 `(-36,-104)` 让节点原点位于脚底。注意：这个独立场景不会自动替换 `front_desk.tscn` 现有 NPC，也不包含剧情交互。
- `props/visitor_register_folder_world.png`：30×36 独立登记夹小道具，适合柜台摆放，**不用于动作帧叠加**。
- `props/visitor_register_folder_detail.png`：240×280 证物放大图，**上页周三，下页周五，中间两只空夹扣**。
- `props/visitor_page_{wednesday,thursday,friday}.png`：144×168 候选原页，其他个人信息全部遮盖，露出日期和纸角。只有周四页带月牙形咖啡渍。
- `props/visitor_register_storage_rule.png`：328×184，登记夹背面收存规则的可读放大图。文字已直接烘焙至 PNG；也可在 Godot UI 中从 JSON 文字重新排版。

## 证据一致性（重要）
- 周四候选页的污渍从 `source/canonical_thursday_coffee_stain.png` 盖入，坐标 `(103,20)`；将来制作群聊原图／局部裁剪图时，请重用这一张污渍源图，**不要另画形状**。
- 未提供剧情里不存在的具体年份和月份，也没有绘制访客联系方式。
- 背面收存规则原文：**含联系方式的原页用完请收入前台内袋，日常查阅只看来访日期与事项**。

## 质量与来源
- 角色头部（y=0–34）和裤腿鞋子（y=72–107）逐像素保留邵宁已定版母版；修改上半身手臂及展示动作。
- 角色仍为 72×108，脚底 y=104；所有 PNG 为 RGBA 真透明、仅 0/255 alpha、硬边；近邻缩放，Godot `scale=1`。
- `source/shaoning_show_page_editable.ora` 为分层可编辑图；另附四张动作分层 PNG、可复用的污渍源图和 `meta/alignment_and_story.json`、QA 报告。
- 美术来源：以仓库邵宁 C4 站姿定版帧为母版，程序辅助逐像素编辑和重绘道具；AI 辅助参考概念图，但正式素材非概念图直接缩小。授权记录需按项目 AI 辅助素材登记。

**验收边界**：静态文件尺寸、alpha、脚底、场景贴图路径与 ZIP 已检查；没有实际启动 Godot / 在安卓设备上验证遮挡或点击区域，不能视为实机验收。
