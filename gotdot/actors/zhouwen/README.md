# 周闻 NPC 像素统一修正版 v2 · 《被引向的真相》

此包替代此前 `zhouwen_npc_assets.zip` 中的周闻站姿与整理交接卡素材。

## 正式素材

- `gotdot/actors/zhouwen/idle/zhouwen_idle_front.png`：延续已确认的原正面稿。
- `gotdot/actors/zhouwen/idle/zhouwen_idle_right.png`：重新导出、按原正面调色的朝右站姿。
- `gotdot/actors/zhouwen/idle/zhouwen_idle_left.png`：重新导出、按原正面调色的朝左站姿（非临时镜像）。
- `gotdot/actors/zhouwen/idle/zhouwen_idle_back.png`：重新导出、按原正面调色的背面站姿。
- `gotdot/actors/zhouwen/actions/zhouwen_sort_cards.png`：修正动作姿势，完整保留两条腿、裤脚和鞋子。**当前纸张与人物绘制在同一张动作帧上**。
- `gotdot/props/zhouwen_handover_note_folded.png`：之前制作的可单独放置的折叠便笺小道具。若使用上述人物动作帧，**不要把这张小道具叠在人物手上两次**；用于独立证物/交接演出时单独加载。

## 一致性检查

- 所有五张人物帧均为 **72×108 像素**、RGBA **真实透明** PNG。
- 透明度只取 0/255，无柔边或半透明残留。
- 人物鞋底最后一行在 **y=104**；画布脚底中心参考点为 **(36,104)**，顶部保留透明留边。
- 所有新帧匹配先前周闻**灰褐开衫、浅色衬衫、深色直筒裤、短发侧分**造型。
- 人物可见颜色均被映射到原正面稿的 **26 色有限色板**（包含描边、头发、肤色、衣服和鞋色），使用最近邻缩放与硬边轮廓。
- `previews/zhouwen_identity_1x.png` 是真正原尺寸对照，`previews/zhouwen_identity_4x.png` 是最近邻放大，林禾和韩素均来自已有定版文件。
- `previews/zhouwen_sort_cards_leg_check_8x.png` 用于核对双腿是否完整。
- `qa_report.json` 含尺寸、透明通道、配色及包内 PNG 哈希。

## Godot 接入

将 `gotdot` 文件夹内容复制到同名项目目录，Sprite2D 设定 `texture_filter=NEAREST`、`scale=(1,1)`。人物原点/摆放请按脚底参考点 `(36,104)` 统一；如果角色父节点的原点就是脚底，且 `Sprite2D.centered=true`，将 Sprite2D 的本地 `position` 设为 `Vector2(0,-50)`，使贴图内的 `(36,104)` 对齐父节点原点；**不要误把贴图左上角当成脚底锚点**。

本包是静态 PNG，可导入 Godot，但**没有修改仓库的 `zhou_wen.tscn`，也没有做 Godot 运行验证**。角色可读性经过 1× / 4× 视觉复核。仍建议在真正的 102 场景里再查遮挡及站位。

## 来源与授权记录

AI 辅助创建和修正人物美术，并根据 `guided-truth` 主分支的林禾成品帧、韩素成品帧和周闻原正面稿统一规格。上传项目素材授权表时应登记 AI 辅助创作及修订情况，不应将其写为纯手绘成品。
