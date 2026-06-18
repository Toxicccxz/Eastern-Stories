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
