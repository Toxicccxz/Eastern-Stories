import '../models/direction.dart';
import '../models/item_definition.dart';
import '../models/npc_definition.dart';
import '../models/quest_definition.dart';
import '../models/room_definition.dart';
import '../models/skill_definition.dart';

class GameDefinitionRepository {
  const GameDefinitionRepository({
    required this.startingRoomId,
    required Map<String, RoomDefinition> rooms,
    required Map<String, NpcDefinition> npcs,
    required Map<String, ItemDefinition> items,
    required Map<String, QuestDefinition> quests,
    required Map<String, SkillDefinition> skills,
  }) : _rooms = rooms,
       _npcs = npcs,
       _items = items,
       _quests = quests,
       _skills = skills;

  factory GameDefinitionRepository.demo() {
    return GameDefinitionRepository(
      startingRoomId: 'liu_home',
      rooms: const {
        'liu_home': RoomDefinition(
          id: 'liu_home',
          name: '刘家小房',
          areaName: '小村',
          description: '这是一所破旧的木屋。山风吹来时，屋梁会发出轻响。屋后有一座小花园，西北通向一间小仓房。',
          mapX: 1,
          mapY: 1,
          exits: {
            Direction.north: 'small_storage',
            Direction.south: 'little_garden',
            Direction.east: 'village_road',
          },
          npcIds: ['old_liu'],
        ),
        'small_storage': RoomDefinition(
          id: 'small_storage',
          name: '小仓房',
          areaName: '小村',
          description: '仓房里堆着旧农具和几捆干草，角落里有一本薄薄的旧书。',
          mapX: 1,
          mapY: 0,
          exits: {Direction.south: 'liu_home'},
          itemIds: ['old_book'],
        ),
        'little_garden': RoomDefinition(
          id: 'little_garden',
          name: '花园',
          areaName: '小村',
          description: '屋后的花园里有许多盛开的花。这里是春夏时节，常有小姑娘在花丛间玩耍。',
          mapX: 1,
          mapY: 2,
          exits: {Direction.north: 'liu_home', Direction.east: 'village_road'},
          npcIds: ['flower_girl'],
          itemIds: ['wild_flower'],
        ),
        'village_road': RoomDefinition(
          id: 'village_road',
          name: '村中小路',
          areaName: '小村',
          description: '一条弯弯曲曲的小路穿过村子，向西可回刘家小房，向东能走到玉螺湖畔。',
          mapX: 2,
          mapY: 1,
          exits: {
            Direction.north: 'melon_farm',
            Direction.west: 'liu_home',
            Direction.south: 'little_garden',
            Direction.east: 'jade_snail_lake',
          },
        ),
        'melon_farm': RoomDefinition(
          id: 'melon_farm',
          name: '瓜地',
          areaName: '小村',
          description: '这是一片很大的西瓜地，沙质土壤里长出的瓜想来又甜又脆。几个熟透的西瓜已经离开瓜蔓，静静躺在田垄边。',
          mapX: 2,
          mapY: 0,
          exits: {Direction.south: 'village_road'},
          npcIds: ['meloner'],
          itemIds: ['water_melon'],
        ),
        'jade_snail_lake': RoomDefinition(
          id: 'jade_snail_lake',
          name: '玉螺湖畔',
          areaName: '小村',
          description: '玉螺湖因湖中螺贝洁白如玉而得名。几名渔夫站在岸边，神色不安，湖边还散落着几只木船。',
          mapX: 3,
          mapY: 1,
          exits: {Direction.west: 'village_road'},
          npcIds: ['fisher'],
          actions: [
            RoomActionDefinition(
              id: 'paddle_to_lake',
              label: '登上木船',
              description: '划船前往湖心。',
              resultRoomId: 'jade_snail_lake_center',
              log: '你跳上木船，奋力向湖心划去。',
            ),
          ],
        ),
        'jade_snail_lake_center': RoomDefinition(
          id: 'jade_snail_lake_center',
          name: '玉螺湖',
          areaName: '小村',
          description: '这里是玉螺湖的湖心，湖面雾气蒸腾，四周静得出奇。你俯身望向湖底，仿佛看见一闪而过的白光。',
          mapX: 4,
          mapY: 1,
          exits: {},
          actions: [
            RoomActionDefinition(
              id: 'paddle_to_lakeside',
              label: '划回岸边',
              description: '把木船划回玉螺湖畔。',
              resultRoomId: 'jade_snail_lake',
              log: '你划动双桨，小船慢慢漂回岸边。',
            ),
            RoomActionDefinition(
              id: 'dive_into_lake',
              label: '潜入湖底',
              description: '屏住呼吸，潜向湖底那道白光。',
              resultRoomId: 'underwater_cave',
              log: '你深吸一口气潜入水中。湖底白光骤亮，冰层碎裂，水流将你卷进一处岩洞。',
            ),
          ],
        ),
        'underwater_cave': RoomDefinition(
          id: 'underwater_cave',
          name: '水下岩洞',
          areaName: '小村',
          description: '岩洞中全是洁白的冰，寒意从四周袭来。入口很快结上一层薄冰，发光的藻类让洞内显得异常明亮。',
          mapX: 4,
          mapY: 2,
          exits: {Direction.west: 'ice_cave'},
        ),
        'ice_cave': RoomDefinition(
          id: 'ice_cave',
          name: '冰洞深处',
          areaName: '小村',
          description: '洞窟忽然变得宽阔，半透明的穹顶外有小鱼游过。几道巨大的白影盘在冰面与水流之间。',
          mapX: 3,
          mapY: 2,
          exits: {Direction.east: 'underwater_cave'},
          npcIds: ['white_ice_dragon'],
        ),
      },
      npcs: const {
        'old_liu': NpcDefinition(
          id: 'old_liu',
          name: '刘老农',
          description: '刘老农年近六十，手脚却还算灵活，眉间藏着焦急。',
          greeting: '这位少侠，可曾见到小女娃儿？',
          dialogueOptions: [
            DialogueOption(
              id: 'ask_daughter',
              label: '询问小女娃',
              response: '她常在屋后的花园玩耍，若少侠见着她，还请告诉老汉一声。',
              startsQuestId: 'find_flower_girl',
            ),
            DialogueOption(
              id: 'report_daughter',
              label: '告知小姑娘平安',
              response: '多谢少侠搭救小女娃儿。这口剑和这本薄书，便赠予少侠防身。',
              requiredQuestId: 'find_flower_girl',
              requiredQuestStatus: QuestStatus.active,
              completesQuestId: 'find_flower_girl',
            ),
          ],
        ),
        'flower_girl': NpcDefinition(
          id: 'flower_girl',
          name: '采花女',
          description: '天真的小女孩正在花丛间玩耍，手里拿着一枝新摘的小花。',
          greeting: '你是来找我的吗？爷爷是不是又担心我啦？',
          dialogueOptions: [
            DialogueOption(
              id: 'found_girl',
              label: '告诉她刘老农在找她',
              response: '我就在花园里，没有乱跑。你替我告诉爷爷，我马上回去。',
              requiredQuestId: 'find_flower_girl',
              requiredQuestStatus: QuestStatus.active,
              setsQuestFlag: 'found_flower_girl',
            ),
          ],
        ),
        'fisher': NpcDefinition(
          id: 'fisher',
          name: '渔夫',
          description: '一个精壮汉子，头戴斗笠，身披蓑衣，望向湖面时眼神格外锐利。',
          greeting: '不知这水怪又吃了几个人。',
        ),
        'meloner': NpcDefinition(
          id: 'meloner',
          name: '瓜农',
          description: '一个中年瓜农，脸被阳光晒得黝黑，身形结实，看着很是警觉。',
          greeting: '这位少侠，要不要买个西瓜解解渴？',
        ),
        'white_ice_dragon': NpcDefinition(
          id: 'white_ice_dragon',
          name: '白鳞冰龙',
          description: '一只浑身长满白鳞的巨龙，盘踞在寒冰之间。',
          greeting: '冰龙缓缓睁眼，寒气沿着冰面蔓延开来。',
          combat: CombatDefinition(
            maxHp: 36,
            attack: 7,
            defense: 4,
            rewardSilver: 80,
            rewardExperience: 70,
          ),
        ),
      },
      items: const {
        'old_book': ItemDefinition(
          id: 'old_book',
          name: '旧书',
          description: '一本旧旧的薄书，封皮上写着“招架入门”。',
        ),
        'wild_flower': ItemDefinition(
          id: 'wild_flower',
          name: '野花',
          description: '花园里随处可见的小花，带着清新的草木气味。',
        ),
        'water_melon': ItemDefinition(
          id: 'water_melon',
          name: '西瓜',
          description: '一个绿皮墨纹的大西瓜，不但解渴，还能填肚子。',
          restoreHp: 16,
          restoreInnerPower: 6,
        ),
        'hengbing_sword': ItemDefinition(
          id: 'hengbing_sword',
          name: '横冰剑',
          description: '刘老农赠予的短剑，剑身寒光很淡，却颇为坚韧。',
          attackPower: 10,
        ),
        'parry_book': ItemDefinition(
          id: 'parry_book',
          name: '过招要门',
          description: '一本介绍拆招卸力之法的入门书。',
          studySkillId: 'parry',
        ),
      },
      quests: const {
        'find_flower_girl': QuestDefinition(
          id: 'find_flower_girl',
          title: '老刘寻女',
          description: '刘老农正在寻找在屋后花园玩耍的小女娃。',
          steps: [
            QuestStepDefinition(description: '向刘老农询问小女娃的去向。'),
            QuestStepDefinition(
              description: '到屋后花园找到采花女。',
              requiredFlag: 'found_flower_girl',
            ),
            QuestStepDefinition(
              description: '回到刘家小房告诉刘老农。',
              requiredFlag: 'found_flower_girl',
            ),
          ],
          requiredFlags: {'found_flower_girl'},
          rewardSilver: 30,
          rewardExperience: 60,
          rewardItemIds: ['hengbing_sword', 'parry_book'],
        ),
      },
      skills: const {
        'parry': SkillDefinition(
          id: 'parry',
          name: '基础招架',
          description: '从过招要门中领会的拆招卸力之法，可略微降低受到的伤害。',
          damageReduction: 2,
        ),
      },
    );
  }

  final String startingRoomId;
  final Map<String, RoomDefinition> _rooms;
  final Map<String, NpcDefinition> _npcs;
  final Map<String, ItemDefinition> _items;
  final Map<String, QuestDefinition> _quests;
  final Map<String, SkillDefinition> _skills;

  Iterable<RoomDefinition> get rooms => _rooms.values;

  Iterable<QuestDefinition> get quests => _quests.values;

  RoomDefinition room(String id) {
    final room = _rooms[id];
    if (room == null) {
      throw StateError('Unknown room id: $id');
    }
    return room;
  }

  NpcDefinition npc(String id) {
    final npc = _npcs[id];
    if (npc == null) {
      throw StateError('Unknown npc id: $id');
    }
    return npc;
  }

  ItemDefinition item(String id) {
    final item = _items[id];
    if (item == null) {
      throw StateError('Unknown item id: $id');
    }
    return item;
  }

  QuestDefinition quest(String id) {
    final quest = _quests[id];
    if (quest == null) {
      throw StateError('Unknown quest id: $id');
    }
    return quest;
  }

  SkillDefinition skill(String id) {
    final skill = _skills[id];
    if (skill == null) {
      throw StateError('Unknown skill id: $id');
    }
    return skill;
  }
}
