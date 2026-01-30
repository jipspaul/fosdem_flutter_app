import '../../domain/models/journey_models.dart';

abstract class JourneyEvent {
  const JourneyEvent();
}

class LoadJourney extends JourneyEvent {
  const LoadJourney();
}

class AddToWishlist extends JourneyEvent {
  final int eventId;
  final int priority;

  const AddToWishlist({
    required this.eventId,
    this.priority = 3,
  });
}

class AddToJourney extends JourneyEvent {
  final int eventId;
  final int priority;

  const AddToJourney({
    required this.eventId,
    this.priority = 3,
  });
}

class RemoveFromJourney extends JourneyEvent {
  final String journeyItemId;

  const RemoveFromJourney(this.journeyItemId);
}

class MoveToJourney extends JourneyEvent {
  final String journeyItemId;

  const MoveToJourney(this.journeyItemId);
}

class MoveToWishlist extends JourneyEvent {
  final String journeyItemId;

  const MoveToWishlist(this.journeyItemId);
}

class UpdatePriority extends JourneyEvent {
  final String journeyItemId;
  final int priority;

  const UpdatePriority({
    required this.journeyItemId,
    required this.priority,
  });
}

class UpdateNotes extends JourneyEvent {
  final String journeyItemId;
  final String? notes;

  const UpdateNotes({
    required this.journeyItemId,
    this.notes,
  });
}

class UpdateStatus extends JourneyEvent {
  final String journeyItemId;
  final JourneyStatus status;

  const UpdateStatus({
    required this.journeyItemId,
    required this.status,
  });
}

class DetectConflicts extends JourneyEvent {
  const DetectConflicts();
}

class UpdatePreferences extends JourneyEvent {
  final JourneyPreferences preferences;

  const UpdatePreferences(this.preferences);
}

class ImportJourneyFromUrl extends JourneyEvent {
  final String url;

  const ImportJourneyFromUrl(this.url);
}

class RemoveImportedJourney extends JourneyEvent {
  final String key;

  const RemoveImportedJourney(this.key);
}

class SetShowImportedJourney extends JourneyEvent {
  final bool show;

  const SetShowImportedJourney(this.show);
}

class ClearImportError extends JourneyEvent {
  const ClearImportError();
}
