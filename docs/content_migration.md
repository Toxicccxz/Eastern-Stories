# 原版内容迁移规范

## 迁移单位

不要按单个房间零散导入。每次迁移应形成一个可以独立验证的章节：

1. 一个区域或现有区域中的一段连续地图。
2. 与地图相关的 NPC、物品和商店。
3. 至少一条完整事件或任务流程。
4. 一条从现有世界进入、并能正常返回的路线。
5. 对应的数据完整性测试和玩法流程测试。

## 原版依据

迁移前记录对应的 LPC 源文件。房间名称、描述、出口、人物身份、物品和关键事件优先采用原版内容。

原版中依赖多人环境、随机等待或文字命令的内容，可以改造成适合单机按钮交互的确定性流程。此类改编应保留原事件的地点、人物和因果关系，不应冒充逐行复刻。

## ID 规则

- 使用小写英文和下划线，例如 `capital_north_gate`。
- ID 一旦进入存档，不应随意修改。
- 区域相关对象使用统一前缀，避免不同区域同名。
- 房间、NPC、物品、任务、技能和门派各自在自己的类别中必须唯一。

## 文件组织

同一区域的数据分别保存在：

```text
assets/data/rooms/<area>.json
assets/data/npcs/<area>.json
assets/data/items/<area>.json
assets/data/quests/<area>.json
assets/data/skills/<area>.json
```

新增文件后，将路径加入 `assets/data/demo_world.json` 对应类别。

## 地图规则

- 每个房间必须指定有效的 `areaId`、`mapX` 和 `mapY`。
- 同一区域内两个房间不能占用同一地图坐标。
- 普通出口必须指向真实房间。
- 跨区域出口两侧都应存在，剧情刻意设计的单向路线除外。
- `north/south/east/west` 应尽量与坐标方向一致。
- `up/down` 用于楼层，不要为了绕开平面坐标问题滥用。

## 任务规则

- 每个步骤应设置 `targetRoomId` 或 `targetNpcId`，让目标面板可以定位。
- 步骤完成条件使用任务旗标或击败 NPC 状态表达。
- 开始任务、推进旗标和完成任务必须形成可达闭环。
- 被条件出口阻挡的任务，必须在阻挡前提供取得条件的途径。
- 改动完成后至少手动走通一次任务，并补一条控制器流程测试。

## 校验

导入或修改数据后运行：

```powershell
dart run tool/validate_game_data.dart
flutter analyze
flutter test
```

也可以校验其他 manifest：

```powershell
dart run tool/validate_game_data.dart assets/data/demo_world.json
```

校验工具会检查：

- 每类对象的重复 ID。
- manifest 中的文件和初始房间。
- 房间出口、区域、NPC、物品和场景动作引用。
- 对话、任务目标、奖励、商店、掉落和技能引用。
- 门派任务、师承和条件引用。
- 同一区域内的地图坐标冲突。

工具通过不代表章节一定可玩。复杂任务仍需要端到端流程测试。
