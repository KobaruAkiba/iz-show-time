/// Tag model for organizing content in the catalogue
class Tag {
  final String name;
  final String color;

  const Tag({
    required this.name,
    required this.color,
  });

  @override
  String toString() => 'Tag(name: $name, color: $color)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tag && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode ^ color.hashCode;

  @override
  String debugDescribe() => 'Tag($this)';
}
