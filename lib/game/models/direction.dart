enum Direction {
  north('北'),
  south('南'),
  east('东'),
  west('西'),
  northeast('东北'),
  northwest('西北'),
  southeast('东南'),
  southwest('西南'),
  up('上'),
  down('下');

  const Direction(this.label);

  final String label;
}
