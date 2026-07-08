import 'package:flutter/material.dart';

class MockDataStore {
  static final MockDataStore _instance = MockDataStore._internal();
  factory MockDataStore() => _instance;
  MockDataStore._internal();

  final ValueNotifier<List<Map<String, dynamic>>> tasks = ValueNotifier([
    {
      "id": "t1",
      "title": "Track Inspection - Section A",
      "location": "Northern Sector B",
      "time": "Today • 14:00 PM",
      "priority": "High",
      "status": "Assigned",
      "icon": Icons.build,
      "color": Colors.red,
    },
    {
      "id": "t2",
      "title": "Replace Track Sensor",
      "location": "Junction 4",
      "time": "Tomorrow • 10:00 AM",
      "priority": "Medium",
      "status": "In Progress",
      "icon": Icons.settings,
      "color": Colors.orange,
    },
    {
      "id": "t3",
      "title": "Rail Alignment Check",
      "location": "Eastern Sector C",
      "time": "22 June • 09:00 AM",
      "priority": "Low",
      "status": "Assigned",
      "icon": Icons.engineering,
      "color": Colors.green,
    },
  ]);

  final ValueNotifier<List<Map<String, dynamic>>> history = ValueNotifier([
    {
      "id": "h1",
      "title": "Patrol Run - Section A",
      "date": "18 June 2026",
      "duration": "45 mins",
      "distance": "12.4 km",
      "status": "Completed",
    },
    {
      "id": "h2",
      "title": "Inspection Run - Junction 4",
      "date": "16 June 2026",
      "duration": "1 hr 10 mins",
      "distance": "18.2 km",
      "status": "Completed",
    },
    {
      "id": "h3",
      "title": "Maintenance Run - Sector C",
      "date": "14 June 2026",
      "duration": "30 mins",
      "distance": "8.5 km",
      "status": "Completed",
    },
  ]);

  void updateTaskStatus(String id, String status) {
    final newList = List<Map<String, dynamic>>.from(tasks.value);
    final index = newList.indexWhere((t) => t['id'] == id);
    if (index != -1) {
      newList[index] = {...newList[index], 'status': status};
      tasks.value = newList;
    }
  }
}
