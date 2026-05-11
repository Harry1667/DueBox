import 'package:flutter/material.dart';

class BillGroup {
  String id; // Usually the category name
  Color color;
  bool isPinned;
  int orderIndex; // For explicit ordering

  BillGroup({
    required this.id,
    required this.color,
    this.isPinned = false,
    this.orderIndex = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'color': color.value,
        'isPinned': isPinned,
        'orderIndex': orderIndex,
      };

  factory BillGroup.fromJson(Map<String, dynamic> json) => BillGroup(
        id: json['id'],
        color: Color(json['color']),
        isPinned: json['isPinned'] ?? false,
        orderIndex: json['orderIndex'] ?? 0,
      );
}
