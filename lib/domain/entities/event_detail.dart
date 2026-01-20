class EventDetail {
  final String title;
  final String subtitle;
  final String abstract;
  final String description;
  final List<EventSpeaker> speakers;
  final String track;
  final String room;
  final String day;
  final String startTime;
  final String duration;
  final String eventType;
  final String language;
  final List<EventLink> links;
  final List<EventAttachment> attachments;

  EventDetail({
    required this.title,
    required this.subtitle,
    required this.abstract,
    required this.description,
    required this.speakers,
    required this.track,
    required this.room,
    required this.day,
    required this.startTime,
    required this.duration,
    required this.eventType,
    required this.language,
    required this.links,
    required this.attachments,
  });
}

class EventSpeaker {
  final String name;
  final String profileUrl;

  EventSpeaker({
    required this.name,
    required this.profileUrl,
  });
}

class EventLink {
  final String title;
  final String url;

  EventLink({
    required this.title,
    required this.url,
  });
}

class EventAttachment {
  final String title;
  final String url;

  EventAttachment({
    required this.title,
    required this.url,
  });
}
