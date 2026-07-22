enum Direction {
  north('北', '向北走去', 0, -1),
  south('南', '向南走去', 0, 1),
  east('东', '向东走去', 1, 0),
  west('西', '向西走去', -1, 0),
  northeast('东北', '向东北走去', 1, -1),
  northwest('西北', '向西北走去', -1, -1),
  southeast('东南', '向东南走去', 1, 1),
  southwest('西南', '向西南走去', -1, 1),
  up('上', '向上走去', 0, -1),
  down('下', '向下走去', 0, 1),
  northup('北上', '向北上山', 0, -1),
  southup('南上', '向南上山', 0, 1),
  eastup('东上', '向东上山', 1, -1),
  westup('西上', '向西上山', -1, -1),
  northdown('北下', '向北下山', 0, -1),
  southdown('南下', '向南下山', 0, 1),
  eastdown('东下', '向东下山', 1, 1),
  westdown('西下', '向西下山', -1, 1),
  enter('进入', '走了进去', 0, 0),
  out('出去', '走了出去', 0, 0);

  const Direction(this.label, this.actionLabel, this.mapDx, this.mapDy);

  final String label;
  final String actionLabel;
  final int mapDx;
  final int mapDy;

  bool get isPrimaryMovement {
    return switch (this) {
      Direction.north ||
      Direction.south ||
      Direction.east ||
      Direction.west ||
      Direction.northeast ||
      Direction.northwest ||
      Direction.southeast ||
      Direction.southwest ||
      Direction.up ||
      Direction.down => true,
      _ => false,
    };
  }
}
