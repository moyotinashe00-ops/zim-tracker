enum SlotType { on, off }

class ScheduleSlot {
  final String startTime; // e.g., "06:00"
  final String endTime;   // e.g., "10:00"
  final SlotType type;
  final String? title;
  final String? subtitle;

  ScheduleSlot({
    required this.startTime,
    required this.endTime,
    required this.type,
    this.title,
    this.subtitle,
  });

  factory ScheduleSlot.fromMap(Map<String, dynamic> data) {
    return ScheduleSlot(
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      type: data['type'] == 'OFF' ? SlotType.off : SlotType.on,
      title: data['title'],
      subtitle: data['subtitle'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'type': type == SlotType.off ? 'OFF' : 'ON',
      'title': title,
      'subtitle': subtitle,
    };
  }
}
