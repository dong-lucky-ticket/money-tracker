import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class CategoryIconGroup {
  final String groupName;
  final List<String> icons;

  CategoryIconGroup(this.groupName, this.icons);
}

final List<CategoryIconGroup> categoryIconGroups = [
  CategoryIconGroup('娱乐', ['gamepad-variant-outline', 'music-note-outline', 'movie-open-outline', 'microphone-variant', 'cards-playing-outline', 'ticket-outline', 'tent']),
  CategoryIconGroup('饮食', ['silverware-fork-knife', 'noodles', 'hamburger', 'coffee-outline', 'cup-water', 'cupcake', 'ice-cream', 'fruit-cherries', 'carrot']),
  CategoryIconGroup('医疗', ['medical-bag', 'pill', 'hospital-building', 'tooth-outline', 'needle', 'wheelchair-accessibility']),
  CategoryIconGroup('学习', ['book-outline', 'school-outline', 'pencil-outline', 'notebook-outline', 'calculator-variant-outline', 'ruler']),
  CategoryIconGroup('交通', ['bus', 'car-outline', 'bike', 'train', 'airplane', 'taxi', 'ferry', 'subway-variant', 'gas-station-outline']),
  CategoryIconGroup('购物', ['shopping-outline', 'cart-outline', 'tshirt-crew-outline', 'shoe-sneaker', 'glasses', 'watch-variant', 'lipstick', 'hanger']),
  CategoryIconGroup('生活', ['water-outline', 'lightning-bolt-outline', 'fire', 'cellphone', 'home-outline', 'umbrella-outline', 'camera-outline']),
  CategoryIconGroup('个人', ['face-man-profile', 'hair-dryer-outline', 'spa-outline', 'ring', 'necklace']),
  CategoryIconGroup('家庭', ['bed-outline', 'sofa-outline', 'television', 'washing-machine', 'toilet-outline', 'lamp-outline']),
  CategoryIconGroup('宝宝', ['baby-face-outline', 'baby-bottle-outline', 'baby-carriage-outline', 'teddy-bear', 'duck']),
  CategoryIconGroup('健身', ['dumbbell', 'run', 'swim', 'yoga', 'basketball', 'soccer', 'table-tennis']),
  CategoryIconGroup('办公', ['briefcase-outline', 'laptop', 'printer-outline', 'paperclip', 'folder-outline']),
  CategoryIconGroup('收入', ['cash-multiple', 'cash-plus', 'chart-line', 'sack-outline', 'bank-outline', 'wallet-outline']),
  CategoryIconGroup('其它', ['gift-outline', 'heart-outline', 'paw', 'help-circle-outline']),
];

IconData getIconData(String name) {
  // Use MdiIcons.fromString if possible, but since we use specific names, we can just use a switch or try to match.
  // Actually, MdiIcons.fromString exists in some versions, but to be safe, we map them directly.
  return MdiIcons.fromString(name) ?? MdiIcons.helpCircleOutline;
}
