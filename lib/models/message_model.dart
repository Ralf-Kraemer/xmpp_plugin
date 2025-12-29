class MessageChat {
  String? customText;
  String? from;
  String? senderJid;
  String? time;
  String? id;
  String? type;
  String? body;
  String? msgtype;
  String? bubbleType;
  String? mediaURL;
  int? isReadSent;
  String? delayTime;
  String? chatStateType;

  MessageChat({
    this.customText,
    this.from,
    this.senderJid,
    this.time,
    this.id,
    this.type,
    this.body,
    this.msgtype,
    this.bubbleType,
    this.mediaURL,
    this.isReadSent,
    this.delayTime,
    this.chatStateType,
  });

  Map<String, dynamic> toEventData() {
    return {
      'customText': customText,
      'from': from,
      'senderJid': senderJid,
      'time': time,
      'id': id,
      'type': type,
      'body': body,
      'msgtype': msgtype,
      'bubbleType': bubbleType,
      'mediaURL': mediaURL,
      'isReadSent': isReadSent,
      'delayTime': delayTime,
      'chatStateType': chatStateType,
    };
  }

  factory MessageChat.fromJson(dynamic eventData) {
      if (eventData == null || eventData is! Map<String, dynamic>) {
        return MessageChat();
      }

      return MessageChat(
        customText: eventData['customText']?.toString() ?? '',
        from: eventData['from']?.toString() ?? '',
        senderJid: eventData['senderJid']?.toString() ?? '',
        time: eventData['time']?.toString() ?? '0',
        isReadSent: eventData['isReadSent'] is int ? eventData['isReadSent'] : 0,
        id: eventData['id']?.toString() ?? '',
        type: eventData['type']?.toString() ?? '',
        body: eventData['body']?.toString() ?? '',
        msgtype: eventData['msgtype']?.toString() ?? '',
        bubbleType: eventData['bubbleType']?.toString() ?? '',
        mediaURL: eventData['mediaURL']?.toString() ?? '',
        delayTime: eventData['delayTime']?.toString() ?? '',
        chatStateType: eventData['chatStateType']?.toString() ?? '',
      );
}

}
