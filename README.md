# 被引向的真相

Godot 4.7.2 项目位于 `gotdot/`。当前主场景从第一章前台开始。

## 当前试玩：前台领委托 → 走廊查封条

安卓测试包：`chapter1-frontdesk-seal-1.0.7.apk`（版本号 8，arm64，调试签名）。沿用包名 `com.cool.room102test`，可覆盖同签名的旧测试包。APK 保存在项目根目录，不提交到 Git。

1. 打开游戏，从前台走到何青面前的柜台边。手机拖动左下摇杆或点地面移动；电脑点地面。
2. 点右下角“领取委托”（电脑也可按 E）。笔记同时登记“102 调查委托”和“器材交接便笺”。点“展开周闻的便笺”可读完整原文，也可关闭后从笔记回看。
3. 靠近右侧走廊入口，用交互键“前往走廊”。首次到达时故事时间从周四 18:35 推进至 18:40。先打开笔记，确认委托、便笺都仍在。
4. 走到 102 正门前，使用右下角交互键查看封条。近景显示完整编号纸条跨贴门扇和门框；查看后自动登记“102 正门封条”。重复查看不重复登记。
5. 从左侧入口返回前台，再从笔记回看三条记录。往返不会倒退故事时间或重复领取委托。
6. 笔记中的“重新开始”经确认后清空本局笔记与章节进度，回到前台起点。

本版只接通前台与走廊。正门保持上锁，不能穿过完整封条进屋；下一段再接后院授权与随车单、从器材门进入 102 复走、结案与 A01 登记。场景与封条图使用自制占位形状，便于后续替换美术。走廊的灯光和声响目前以画面和文字交代。

笔记与进度保存在本局内存中，换房保留；关闭应用后重新打开会开始新一局。本版没有磁盘存档。

## 开发与验证

将 Godot 4.7.2 的命令行程序放入 PATH 后，在项目根目录运行：

```powershell
godot --editor --path gotdot
godot --headless --path gotdot --script ../tests/chapter_one_route.gd
godot --headless --path gotdot --script ../tests/room_102_inspection.gd
godot --headless --path gotdot --script ../tests/room_102_reenactment.gd
godot --headless --path gotdot --export-debug Android ../chapter1-frontdesk-seal-1.0.7.apk
```

导出使用编辑器中已配置的 JDK、Android SDK、同版本安卓模板和调试签名。不要提交签名文件或密码。

`chapter_one_route.gd` 从新游戏开始，通过真实地面移动、触控按钮和 E 键验证领取、笔记回看、房间往返、封条登记、重复操作及重开清理。加 `-- --capture` 可在图形模式下保存关键页面到 `.test-runtime/`（先创建此目录）；截图须人工检查。

102 的共用交互与复走仍可通过直接运行 `gotdot/rooms/room_102.tscn` 单独验证。本次没有将其接到未完成的后院路线。

2026-11-15：三套自动流程均通过，并检查了前台、委托、便笺、走廊和封条的桌面渲染。APK 已导出并校验；本次未连接安卓设备，新流程仍需在手机上按上述步骤验收。原有 102 复走与共用交互键的真机验证沿用此前用户确认。

## 本次结构

- `chapters/chapter_one.gd` 集中管理第一章进度、时间和目标；`InvestigationLog` 保存本局证物。
- `rooms/room_transition.gd` 统一切换与新游戏重置；出口仅配置目标场景和入口标记。
- `rooms/investigation_room.tscn` 组装共用移动、调查、HUD；前台与走廊继承后配置场景和本地事件。
- `investigation/*.tres` 保存委托、便笺、封条原文；`props/front_door_seal.tscn` 同时用于门上的纸条和笔记近景。

开发前检索并阅读了 [Quest System 的任务管理实现](https://github.com/shomykohai/quest-system/blob/d1d933c7b1822aceb637e3d6fe3a4814f973c3ee/addons/quest_system/quest_manager.gd)，借鉴集中维护状态、重复开始不重复登记的思路；未引入该插件或复制其代码。
