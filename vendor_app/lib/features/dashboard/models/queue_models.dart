import 'package:flutter/material.dart';

enum QueueSort { readyFirst, newest, highestValue }

class QueueRailItem {
  final String id;
  final String label;
  final int count;
  final Color color;

  const QueueRailItem({
    required this.id,
    required this.label,
    required this.count,
    required this.color,
  });
}
