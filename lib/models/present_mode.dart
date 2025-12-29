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
    if (json == null || json is! Map<String, dynamic>) {
      return PresentModel();
    }

    return PresentModel(
      presenceType: json['type'] != null
          ? _getPresenceType(json['type'])
          : null,
      presenceMode: json['mode'] != null
          ? _getPresenceMode(json['mode'])
          : null,
      from: json['from'],
    );
  }

  static PresenceType _getPresenceType(String presenceType) {
    switch (presenceType) {
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
      case 'error':
        return PresenceType.error;
      case 'probe':
        return PresenceType.probe;
      default:
        return PresenceType.error;
    }
  }

  static PresenceMode _getPresenceMode(String presenceMode) {
    switch (presenceMode) {
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
        "presenceMode": presenceMode?.name,
        "presenceType": presenceType?.name,
        "from": from,
      };
}
