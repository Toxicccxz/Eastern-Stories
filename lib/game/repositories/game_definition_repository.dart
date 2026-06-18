import '../models/direction.dart';
import '../models/item_definition.dart';
import '../models/npc_definition.dart';
import '../models/room_definition.dart';

class GameDefinitionRepository {
  const GameDefinitionRepository({
    required this.startingRoomId,
    required Map<String, RoomDefinition> rooms,
    required Map<String, NpcDefinition> npcs,
    required Map<String, ItemDefinition> items,
  }) : _rooms = rooms,
       _npcs = npcs,
       _items = items;

  factory GameDefinitionRepository.demo() {
    return GameDefinitionRepository(
      startingRoomId: 'willow_town_square',
      rooms: const {
        'willow_town_square': RoomDefinition(
          id: 'willow_town_square',
          name: '柳溪镇广场',
          areaName: '柳溪镇',
          description: '青石铺成的小广场被晨光照亮，茶摊旁有几名行人低声交谈。',
          mapX: 1,
          mapY: 1,
          exits: {
            Direction.north: 'north_gate',
            Direction.south: 'old_inn',
            Direction.east: 'herb_shop',
            Direction.west: 'west_lane',
          },
          npcIds: ['tea_vendor'],
          itemIds: ['notice'],
        ),
        'north_gate': RoomDefinition(
          id: 'north_gate',
          name: '北门',
          areaName: '柳溪镇',
          description: '镇门外薄雾未散，远处山路隐约通向更大的江湖。',
          mapX: 1,
          mapY: 0,
          exits: {Direction.south: 'willow_town_square'},
          npcIds: ['guard'],
        ),
        'old_inn': RoomDefinition(
          id: 'old_inn',
          name: '旧客栈',
          areaName: '柳溪镇',
          description: '客栈木门半开，柜台后传来算盘珠子的轻响。',
          mapX: 1,
          mapY: 2,
          exits: {Direction.north: 'willow_town_square'},
          npcIds: ['innkeeper'],
          itemIds: ['tea_bowl'],
        ),
        'herb_shop': RoomDefinition(
          id: 'herb_shop',
          name: '药铺',
          areaName: '柳溪镇',
          description: '药柜整齐地贴着药名，空气里有淡淡草木清香。',
          mapX: 2,
          mapY: 1,
          exits: {Direction.west: 'willow_town_square'},
          npcIds: ['doctor'],
          itemIds: ['herb_pack'],
        ),
        'west_lane': RoomDefinition(
          id: 'west_lane',
          name: '西巷',
          areaName: '柳溪镇',
          description: '小巷狭长安静，墙边堆着几只竹筐。',
          mapX: 0,
          mapY: 1,
          exits: {Direction.east: 'willow_town_square'},
        ),
      },
      npcs: const {
        'tea_vendor': NpcDefinition(
          id: 'tea_vendor',
          name: '茶摊老板',
          greeting: '少侠若要打听消息，不妨先坐下喝碗热茶。',
        ),
        'guard': NpcDefinition(
          id: 'guard',
          name: '守门兵',
          greeting: '北边山道近来不太平，出镇前最好备些药。',
        ),
        'innkeeper': NpcDefinition(
          id: 'innkeeper',
          name: '客栈掌柜',
          greeting: '住店、吃饭、问路，都可以找我。',
        ),
        'doctor': NpcDefinition(
          id: 'doctor',
          name: '药铺郎中',
          greeting: '气血不足时，药比逞强管用。',
        ),
      },
      items: const {
        'notice': ItemDefinition(
          id: 'notice',
          name: '告示',
          description: '纸上写着：镇外山路近日有野兽出没。',
        ),
        'tea_bowl': ItemDefinition(
          id: 'tea_bowl',
          name: '粗瓷茶碗',
          description: '一只普通茶碗，碗底还残留些许茶香。',
        ),
        'herb_pack': ItemDefinition(
          id: 'herb_pack',
          name: '止血草包',
          description: '用纸绳扎好的草药包，可以暂时压住伤势。',
        ),
      },
    );
  }

  final String startingRoomId;
  final Map<String, RoomDefinition> _rooms;
  final Map<String, NpcDefinition> _npcs;
  final Map<String, ItemDefinition> _items;

  Iterable<RoomDefinition> get rooms => _rooms.values;

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
}
