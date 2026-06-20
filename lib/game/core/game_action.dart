import '../models/direction.dart';

sealed class GameAction {
  const GameAction();

  const factory GameAction.move(Direction direction) = MoveAction;

  const factory GameAction.look() = LookAction;

  const factory GameAction.performRoomAction(String actionId) =
      PerformRoomAction;

  const factory GameAction.talk(String npcId) = TalkAction;

  const factory GameAction.selectDialogue(String npcId, String optionId) =
      SelectDialogueAction;

  const factory GameAction.pickUp(String itemId) = PickUpAction;

  const factory GameAction.equipItem(String itemId) = EquipItemAction;

  const factory GameAction.studyItem(String itemId) = StudyItemAction;

  const factory GameAction.useItem(String itemId) = UseItemAction;

  const factory GameAction.dropItem(String itemId) = DropItemAction;

  const factory GameAction.buyItem(String npcId, String itemId) = BuyItemAction;

  const factory GameAction.sellItem(String npcId, String itemId) =
      SellItemAction;

  const factory GameAction.startCombat(String npcId) = StartCombatAction;

  const factory GameAction.attack() = AttackAction;

  const factory GameAction.fleeCombat() = FleeCombatAction;
}

class MoveAction extends GameAction {
  const MoveAction(this.direction);

  final Direction direction;
}

class LookAction extends GameAction {
  const LookAction();
}

class PerformRoomAction extends GameAction {
  const PerformRoomAction(this.actionId);

  final String actionId;
}

class TalkAction extends GameAction {
  const TalkAction(this.npcId);

  final String npcId;
}

class SelectDialogueAction extends GameAction {
  const SelectDialogueAction(this.npcId, this.optionId);

  final String npcId;
  final String optionId;
}

class PickUpAction extends GameAction {
  const PickUpAction(this.itemId);

  final String itemId;
}

class EquipItemAction extends GameAction {
  const EquipItemAction(this.itemId);

  final String itemId;
}

class StudyItemAction extends GameAction {
  const StudyItemAction(this.itemId);

  final String itemId;
}

class UseItemAction extends GameAction {
  const UseItemAction(this.itemId);

  final String itemId;
}

class DropItemAction extends GameAction {
  const DropItemAction(this.itemId);

  final String itemId;
}

class BuyItemAction extends GameAction {
  const BuyItemAction(this.npcId, this.itemId);

  final String npcId;
  final String itemId;
}

class SellItemAction extends GameAction {
  const SellItemAction(this.npcId, this.itemId);

  final String npcId;
  final String itemId;
}

class StartCombatAction extends GameAction {
  const StartCombatAction(this.npcId);

  final String npcId;
}

class AttackAction extends GameAction {
  const AttackAction();
}

class FleeCombatAction extends GameAction {
  const FleeCombatAction();
}
