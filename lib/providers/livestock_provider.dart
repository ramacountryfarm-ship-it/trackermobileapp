import 'package:flutter/material.dart';

/// For now: Poultry only. Goat/Sheep can be added later.
class LivestockProvider extends ChangeNotifier {
  String get type => 'poultry';
  String get label => 'Poultry';
  String get emoji => '🐔';
  bool get isPoultry => true;
}
