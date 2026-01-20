import '../models/event_model.dart';
import '../models/person_model.dart';
import '../models/link_model.dart';
import '../models/attachment_model.dart' as model;
import '../models/track_model.dart';
import '../models/building_model.dart';
import '../models/blueprint_model.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/link.dart';
import '../../domain/entities/attachment.dart' as entity;
import '../../domain/entities/track.dart';
import '../../domain/entities/building.dart';

// Person Mappers
extension PersonModelX on PersonModel {
  Person toEntity() {
    return Person(
      id: id,
      name: name,
      bio: bio,
      avatar: avatar,
    );
  }
}

extension PersonEntityX on Person {
  PersonModel toModel() {
    return PersonModel(
      id: id,
      name: name,
      bio: bio,
      avatar: avatar,
    );
  }
}

// Link Mappers
extension LinkModelX on LinkModel {
  Link toEntity() {
    return Link(
      title: title,
      url: url,
      isVideo: isVideo,
      isMP4Video: isMP4Video,
    );
  }
}

extension LinkEntityX on Link {
  LinkModel toModel() {
    return LinkModel(
      title: title,
      url: url,
      isVideo: isVideo,
      isMP4Video: isMP4Video,
    );
  }
}

// Attachment Mappers
extension AttachmentModelX on model.AttachmentModel {
  entity.Attachment toEntity() {
    return entity.Attachment(
      title: title,
      url: url,
      type: _mapAttachmentType(type),
    );
  }

  entity.AttachmentType _mapAttachmentType(model.AttachmentType type) {
    switch (type) {
      case model.AttachmentType.slides:
        return entity.AttachmentType.slides;
      case model.AttachmentType.video:
        return entity.AttachmentType.video;
      case model.AttachmentType.audio:
        return entity.AttachmentType.audio;
      case model.AttachmentType.document:
        return entity.AttachmentType.document;
      case model.AttachmentType.other:
        return entity.AttachmentType.other;
    }
  }
}

extension AttachmentEntityX on entity.Attachment {
  model.AttachmentModel toModel() {
    return model.AttachmentModel(
      title: title,
      url: url,
      type: _mapAttachmentType(type),
    );
  }

  model.AttachmentType _mapAttachmentType(entity.AttachmentType type) {
    switch (type) {
      case entity.AttachmentType.slides:
        return model.AttachmentType.slides;
      case entity.AttachmentType.video:
        return model.AttachmentType.video;
      case entity.AttachmentType.audio:
        return model.AttachmentType.audio;
      case entity.AttachmentType.document:
        return model.AttachmentType.document;
      case entity.AttachmentType.other:
        return model.AttachmentType.other;
    }
  }
}

// Event Mappers
extension EventModelX on EventModel {
  Event toEntity() {
    return Event(
      id: id,
      title: title,
      subtitle: subtitle,
      abstract: abstract,
      description: description,
      room: room,
      track: track,
      date: date,
      start: start,
      duration: duration,
      url: url,
      people: people.map((p) => p.toEntity()).toList(),
      links: links.map((l) => l.toEntity()).toList(),
      attachments: attachments.map((a) => a.toEntity()).toList(),
    );
  }
}

extension EventEntityX on Event {
  EventModel toModel() {
    return EventModel(
      id: id,
      title: title,
      subtitle: subtitle,
      abstract: abstract,
      description: description,
      room: room,
      track: track,
      date: date,
      start: start,
      duration: duration,
      url: url,
      people: people.map((p) => p.toModel()).toList(),
      links: links.map((l) => l.toModel()).toList(),
      attachments: attachments.map((a) => a.toModel()).toList(),
    );
  }
}

// Track Mappers
extension TrackModelX on TrackModel {
  Track toEntity() {
    return Track(
      name: name,
      day: day,
      date: date,
      color: color,
    );
  }
}

extension TrackEntityX on Track {
  TrackModel toModel() {
    // Convert Color to hex string using component extraction
    final int r = ((color.r * 255.0).round() & 0xff);
    final int g = ((color.g * 255.0).round() & 0xff);
    final int b = ((color.b * 255.0).round() & 0xff);
    final colorHex = '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
    
    return TrackModel(
      name: name,
      day: day,
      date: date,
      colorHex: colorHex,
    );
  }
}

// Blueprint Mappers
extension BlueprintModelX on BlueprintModel {
  Blueprint toEntity() {
    return Blueprint(
      title: title,
      imageName: imageName,
      imageUrl: imageUrl,
    );
  }
}

extension BlueprintEntityX on Blueprint {
  BlueprintModel toModel() {
    return BlueprintModel(
      title: title,
      imageName: imageName,
      imageUrl: imageUrl,
    );
  }
}

// Building Mappers
extension BuildingModelX on BuildingModel {
  Building toEntity() {
    return Building(
      id: id,
      title: title,
      glyph: glyph,
      coordinate: coordinate,
      polygon: polygon,
      blueprints: blueprints.map((b) => b.toEntity()).toList(),
    );
  }
}

extension BuildingEntityX on Building {
  BuildingModel toModel() {
    return BuildingModel(
      id: id,
      title: title,
      glyph: glyph,
      coordinate: coordinate,
      polygon: polygon,
      blueprints: blueprints.map((b) => b.toModel()).toList(),
    );
  }
}

// List Extensions
extension EventModelListX on List<EventModel> {
  List<Event> toEntities() => map((e) => e.toEntity()).toList();
}

extension EventEntityListX on List<Event> {
  List<EventModel> toModels() => map((e) => e.toModel()).toList();
}

extension PersonModelListX on List<PersonModel> {
  List<Person> toEntities() => map((p) => p.toEntity()).toList();
}

extension PersonEntityListX on List<Person> {
  List<PersonModel> toModels() => map((p) => p.toModel()).toList();
}

extension TrackModelListX on List<TrackModel> {
  List<Track> toEntities() => map((t) => t.toEntity()).toList();
}

extension TrackEntityListX on List<Track> {
  List<TrackModel> toModels() => map((t) => t.toModel()).toList();
}

extension BuildingModelListX on List<BuildingModel> {
  List<Building> toEntities() => map((b) => b.toEntity()).toList();
}

extension BuildingEntityListX on List<Building> {
  List<BuildingModel> toModels() => map((b) => b.toModel()).toList();
}
