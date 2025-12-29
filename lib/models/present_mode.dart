import '../ennums/presence_type.dart';

class PresentModel {
  PresentModel({
    this.presenceMode,
    this.presenceType,
    this.from,
  });

  PresenceMode? presenceMode;
  PresenceType? presenceType;
  String? from;

  factory PresentModel.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return PresentModel();
    }

    final type = json['type'];
    final mode = json['mode'];

    return PresentModel(
      presenceType: type is String ? _getPresenceType(type) : null,
      presenceMode: mode is String ? _getPresenceMode(mode) : null,
      from: json['from'] as String?,
    );
  }

  static PresenceType _getPresenceType(String presenceType) {
    switch (presenceType.toLowerCase()) {
      case 'available':
        return PresenceType.available;
      case 'unavailable':
        return PresenceType.unavailable;
      case 'subscribe':
        return PresenceType.subscribe;
      case 'subscribed':
        return PresenceType.subscribed;
      case 'unsubscribe':
        return PresenceType.unsubscribe;
      case 'unsubscribed':
        return PresenceType.unsubscribed;
      case 'probe':
        return PresenceType.probe;
      case 'error':
      default:
        return PresenceType.error;
    }
  }

  static PresenceMode _getPresenceMode(String presenceMode) {
    switch (presenceMode.toLowerCase()) {
      case 'chat':
        return PresenceMode.chat;
      case 'available':
        return PresenceMode.available;
      case 'away':
        return PresenceMode.away;
      case 'xa':
        return PresenceMode.xa;
      case 'dnd':
        return PresenceMode.dnd;
      default:
        return PresenceMode.away;
    }
  }

  Map<String, dynamic> toJson() => {
        "type": presenceType?.name.toLowerCase(),
        "mode": presenceMode?.name.toLowerCase(),
        "from": from,
      };
}
