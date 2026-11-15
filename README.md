# 被引向的真相

Godot 4.7.2 项目位于 `gotdot/`。当前主场景从第一章前台开始。

## 当前试玩路线

安卓测试包为 `chapter1-joystick-1.0.9.apk`（版本号 10，arm64，调试签名）。沿用包名 `com.cool.room102test`，可覆盖同签名的旧测试包。APK 保存在项目根目录，由 Git 忽略。

1. 打开游戏，从前台走到何青面前的柜台边。手机用左下角摇杆移动，电脑点击地面移动。
2. 点右下角“领取委托”（电脑也可按 E）。笔记同时登记“102 调查委托”和“器材交接便笺”。点“展开周闻的便笺”可读完整原文，也可关闭后从笔记回看。
3. 靠近右侧走廊入口，用交互键“前往走廊”。首次到达时故事时间从周四 18:35 推进至 18:40。先打开笔记，确认委托、便笺都仍在。
4. 走到 102 正门前查看封条。正门保持上锁。去走廊右侧选“经外廊去后院”，也可以先到后院再回来补查。
5. 在后院雨棚找推车旁的韩素，查看何青签过的后门授权。查看推车上的随车单，核对谁在什么时候领回了什么。两份证物都能从笔记回看。
6. 韩素同意后，靠近雨棚右侧门口，选“从器材门进 102”。在室内查轮痕，找韩素看第一次过槛，再查脚垫并点“装回脚垫”。找韩素“再推一次”，在笔记里回看“推车复走”。
7. 可以随时关闭笔记或证物页，从器材门原路返回补查。可在装好脚垫后走回走廊，再进 102 继续第二次过槛。笔记中的“重新开始”经确认后会清空本局并回到前台。

1.0.9 APK 可试玩到复走结果登记和证物补查。当前 Godot 工程可继续完成第一章。

8. 核对封条、后门授权、随车单和推车复走后，靠近 102 右侧的何青，选「向何青提交推理」。两题各选一项。若需要复核，可关闭推理页，打开笔记或回现场补查，再找何青提交。
9. 推理通过后，从长桌右端绕到下层抽屉前，查看报修册和散页，再装入 A01。走到箱边拍清点照片，找桌后的周闻签字。笔记可回看白色补线和签过「已阅」的清点单。
10. 从器材门经后院回走廊，靠近正门选择「回看 102 正门」，看到「第一章完」。

雨棚、角色、推车和报修册采用占位图形。复走及章节收尾用画面和文字呈现。

笔记与进度保存在本局内存中，换房保留；关闭应用后重新打开会开始新一局。本版没有磁盘存档。

## 开发与验证

将 Godot 4.7.2 的命令行程序放入 PATH 后，在项目根目录运行：

```powershell
godot --editor --path gotdot
godot --headless --path gotdot --script ../tests/chapter_one_route.gd
godot --headless --path gotdot --script ../tests/room_102_inspection.gd
godot --headless --path gotdot --script ../tests/room_102_reenactment.gd
godot --headless --path gotdot --export-debug Android ../chapter1-joystick-1.0.9.apk
```

导出使用编辑器中已配置的 JDK、Android SDK、同版本安卓模板和调试签名。不要提交签名文件或密码。

`chapter_one_route.gd` 从新游戏开始，通过地面移动、触控按钮和 E 键验证从领委托到第一章结尾的流程。测试覆盖复走后补查、错答后回看再提交、挪桌后换房与绕行、A01 清点和章末重开。加 `-- --capture` 可在图形模式下保存关键页面到 `.test-runtime/`（先创建此目录），供人工检查。

102 的共用交互与复走也可通过直接运行 `gotdot/rooms/room_102.tscn` 单独验证。

1.0.8 的后院路线和 1.0.9 的摇杆版均已通过手机试玩。

## 本次结构

- `chapters/chapter_one.gd` 管理第一章时间、目标、复走、推理和结案条件。`InvestigationLog` 保存本局证物和推理记录。
- `rooms/room_transition.gd` 统一切场与新游戏重置。器材门由后院依据授权证物决定是否允许通行。
- `rooms/investigation_room.tscn` 提供共用移动、调查与 HUD。前台、走廊和雨棚继承后配置本地场景和交互。
- `investigation/*.tres` 保存证物文本和预览。韩素的占位外观由雨棚和 102 共用。

前台委托与证物登记参考了任务状态集中维护的做法。[Quest System 的任务管理实现](https://github.com/shomykohai/quest-system/blob/d1d933c7b1822aceb637e3d6fe3a4814f973c3ee/addons/quest_system/quest_manager.gd)

后院沿用现有的延迟换房方式。换房后由章节状态还原 102 的脚垫和复走进度。[Godot 官方换房示例](https://github.com/godotengine/godot-demo-projects/blob/master/loading/autoload/global.gd)
