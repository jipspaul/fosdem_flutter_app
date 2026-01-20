import 'package:equatable/equatable.dart';

abstract class EventDetailEvent extends Equatable {
  const EventDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadEventDetail extends EventDetailEvent {
  final String? eventUrl;
  final int eventId;
  final String eventTitle;

  const LoadEventDetail(this.eventUrl, this.eventId, this.eventTitle);

  @override
  List<Object?> get props => [eventUrl, eventId, eventTitle];
}
