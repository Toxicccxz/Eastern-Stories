import '../models/direction.dart';
import '../models/item_definition.dart';
import '../models/npc_definition.dart';
import '../models/quest_definition.dart';
import '../models/room_definition.dart';

class GameDefinitionRepository {
  const GameDefinitionRepository({
    required this.startingRoomId,
    required Map<String, RoomDefinition> rooms,
    required Map<String, NpcDefinition> npcs,
    required Map<String, ItemDefinition> items,
    required Map<String, QuestDefinition> quests,
  }) : _rooms = rooms,
       _npcs = npcs,
       _items = items,
       _quests = quests;

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
            Direction.west: 'liu_home',
            Direction.south: 'little_garden',
            Direction.east: 'jade_snail_lake',
          },
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
        'hengbing_sword': ItemDefinition(
          id: 'hengbing_sword',
          name: '横冰剑',
          description: '刘老农赠予的短剑，剑身寒光很淡，却颇为坚韧。',
        ),
        'parry_book': ItemDefinition(
          id: 'parry_book',
          name: '招架入门',
          description: '薄薄一本手抄书，讲的是最基础的拆招与格挡。',
        ),
      },
      quests: const {
        'find_flower_girl': QuestDefinition(
          id: 'find_flower_girl',
          title: '老刘寻女',
          description: '刘老农正在寻找在屋后花园玩耍的小女娃。',
          steps: ['向刘老农询问小女娃的去向。', '到屋后花园找到采花女。', '回到刘家小房告诉刘老农。'],
          requiredFlags: {'found_flower_girl'},
          rewardSilver: 30,
          rewardItemIds: ['hengbing_sword', 'parry_book'],
        ),
      },
    );
  }

  final String startingRoomId;
  final Map<String, RoomDefinition> _rooms;
  final Map<String, NpcDefinition> _npcs;
  final Map<String, ItemDefinition> _items;
  final Map<String, QuestDefinition> _quests;

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
}
