class EventDomain {
  final int id;
  final String title;
  final String? subtitle;
  final String? track;
  final String type;
  final DateTime startTime;
  final DateTime endTime;
  final int duration;
  final String room;
  final String? abstract;
  final String? description;
  final String? scrapedDescription;
  final String? url;
  final int day;
  final bool isFavorite;
  final bool isNotified;

  const EventDomain({
    required this.id,
    required this.title,
    this.subtitle,
    this.track,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.room,
    this.abstract,
    this.description,
    this.scrapedDescription,
    this.url,
    required this.day,
    this.isFavorite = false,
    this.isNotified = false,
  });
}
