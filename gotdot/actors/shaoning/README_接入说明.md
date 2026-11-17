# 《被引向的真相》邵宁 C4 第一批：四方向站姿 v1

这是可直接导入 Godot 4 项目的 1× 游戏 PNG，不是高清概念图。没有包含预览图、对比图或未通过的中间稿。

## 本包内容

- `gotdot/actors/shaoning/idle/shaoning_idle_front.png`
- `gotdot/actors/shaoning/idle/shaoning_idle_right.png`
- `gotdot/actors/shaoning/idle/shaoning_idle_left.png`
- `gotdot/actors/shaoning/idle/shaoning_idle_back.png`
- `gotdot/actors/shao_ning.tscn`：可单独实例化的角色场景，默认正面
- `source/shaoning_4directions_editable.ora`：四个方向分别作为独立图层的可编辑原稿（288×108）
- `meta/qa_report.json` 与 `meta/来源与授权.md`：交付记录

## 导入步骤

1. 解压后，将包内 `gotdot/` 的内容复制到项目 `gotdot/` 对应位置。
2. 在 Godot 4 中重新扫描项目文件。可打开 `res://actors/shao_ning.tscn`；`Sprite` 默认显示正面。
3. 当前项目的 `front_desk.tscn` 里 `Scenery/ShaoNing` 是一个已有的 Node2D 色块占位人物。接入时须保留该节点名称及原位置 (570,317)、调查点的 NodePath，并用一张 Sprite2D 替换原来的 Body/Head/Hair Polygon2D。不要同时显示色块和 PNG；原有 Name Label 可以保留。
4. Sprite2D：`texture_filter = 1`（Nearest），`scale=(1,1)`，`centered=false`，`position=Vector2(-36,-104)`。Texture 指向当前方向的 PNG。若实例化 `shao_ning.tscn` 替换旧节点，同样保留 `ShaoNing` 根节点名称与原位置，按项目需要恢复/保留 Name Label。
5. 人物切换朝向时，分别加载 `shaoning_idle_front/right/left/back.png`。不要临时水平镜像左右帧。

## 对齐和视觉规范

- 单帧 72×108 像素，人物高 98px，脚底 Y=104，参考锚点 (36,104)
- 四方向共用一套 32 色有限色板，RGBA 真透明（仅 alpha 0/255）；1× 直接使用，不要再次缩小
- 外观：深棕短发、灰绿针织开衫、浅色内衬、胸牌、深灰长裤与深鞋，与何青/周闻区分
- 后续看手机、露出纸角等动作尚未包含在本包；C4 第一批仅交四方向站姿

## 验收范围

- 已做静态格式/尺寸/透明通道/色板/连续像素区域/脚底基线检查，并检查四方向 1×/5× 效果。
- `.tscn` 使用项目 Godot 4 的标准 TextScene 和 `res://` 路径结构，文件引用已按压缩包验证。
- **未在 Godot 编辑器或安卓机实际运行**。替换前台占位人物、桌前遮挡和 NPC 对话仍需实际接入后回归验证。
