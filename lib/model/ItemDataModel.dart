import 'dart:ui';

class ItemData {
  final String name;
  final String id;
  final Color color;
  final Color? textColor;
  final String imagePath;

  ItemData(this.name, this.id, this.color, {this.textColor, required this.imagePath});
}