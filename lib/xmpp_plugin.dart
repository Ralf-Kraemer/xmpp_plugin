import 'dart:async';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:xmpp_plugin/ennums/xmpp_connection_state.dart';
import 'package:xmpp_plugin/error_response_event.dart';
import 'package:xmpp_plugin/message_event.dart';
import 'package:xmpp_plugin/models/message_model.dart';
import 'package:xmpp_plugin/success_response_event.dart';

import 'models/chat_state_model.dart';
import 'models/connection_event.dart';
import 'models/present_mode.dart';

abstract class DataChangeEvents {
  void onChatMessage(MessageChat messageChat);
  void onGroupMessage(MessageChat messageChat);
  void onNormalMessage(MessageChat messageChat);
  void onPresenceChange(PresentModel message);
  void onChatStateChange(ChatState chatState);
  void onConnectionEvents(ConnectionEvent connectionEvent);
  void onSuccessEvent(SuccessResponseEvent successResponseEvent);
  void onXmppError(ErrorResponseEvent errorResponseEvent);
}

class XmppConnection {
  static const MethodChannel _channel = MethodChannel('flutter_xmpp/method');
  static const EventChannel _eventChannel = EventChannel('flutter_xmpp/stream');
  static const EventChannel _successEventChannel =
      EventChannel('flutter_xmpp/success_event_stream');
  static const EventChannel _connectionEventChannel =
      EventChannel('flutter_xmpp/connection_event_stream');
  static const EventChannel _errorEventChannel =
      EventChannel('flutter_xmpp/error_event_stream');

  static late StreamSubscription streamGetMsg;
  static late StreamSubscription successEventStream;
  static late StreamSubscription connectionEventStream;
  static late StreamSubscription errorEventStream;

  static List<DataChangeEvents> dataChangelist = <DataChangeEvents>[];

  dynamic auth;

  XmppConnection(this.auth);

  static void addListener(DataChangeEvents dataChangeA) {
    if (!dataChangelist.contains(dataChangeA)) dataChangelist.add(dataChangeA);
  }

  static void removeListener(DataChangeEvents dataChangeA) {
    dataChangelist.remove(dataChangeA);
  }

  static void removeAllListener() {
    dataChangelist.clear();
  }

  Future<void> login() async => await _channel.invokeMethod('login', auth);
  Future<void> logout() async => await _channel.invokeMethod('logout');

  Future<String> sendMessage(
      String toJid, String body, String id, int time) async {
    final params = {"to_jid": toJid, "body": body, "id": id, "time": time.toString()};
    printLogForMethodCall('send_message', params);
    return await _channel.invokeMethod('send_message', params);
  }

  Future<String> sendGroupMessage(String toJid, String body, String id, int time) async {
    final params = {"to_jid": toJid, "body": body, "id": id, "time": time.toString()};
    printLogForMethodCall('send_group_message', params);
    return await _channel.invokeMethod('send_group_message', params);
  }

  Future<String> readMessage(String toJid, String id) async {
    final params = {"to_jid": toJid, "id": id};
    printLogForMethodCall('read_message', params);
    return await _channel.invokeMethod('read_message', params);
  }

  Future<void> start(Function _onError) async {
    streamGetMsg = _eventChannel.receiveBroadcastStream().listen(
      (dataEvent) {
        final eventModel = MessageEvent.fromJson(dataEvent);
        final messageChat = MessageChat.fromJson(dataEvent);
        for (var element in dataChangelist) {
          if (eventModel.msgtype == 'chat') {
            element.onChatMessage(messageChat);
          } else if (eventModel.msgtype == 'groupchat') {
            element.onGroupMessage(messageChat);
          } else if (eventModel.msgtype == 'normal') {
            element.onNormalMessage(messageChat);
          } else if (eventModel.type == 'presence') {
            element.onPresenceChange(PresentModel.fromJson(dataEvent));
          } else if (eventModel.type == 'chatstate') {
            element.onChatStateChange(ChatState.fromJson(dataEvent));
          }
        }
      },
    );

    connectionEventStream = _connectionEventChannel
        .receiveBroadcastStream()
        .listen((connectionData) {
      final connectionEvent = ConnectionEvent.fromJson(connectionData);
      for (var element in dataChangelist) element.onConnectionEvents(connectionEvent);
    }, onError: _onError);

    successEventStream =
        _successEventChannel.receiveBroadcastStream().listen((successData) {
      final eventModel = SuccessResponseEvent.fromJson(successData);
      print("success event ${eventModel.toSuccessResponseData()}");
      for (var element in dataChangelist) element.onSuccessEvent(eventModel);
    }, onError: _onError);

    errorEventStream =
        _errorEventChannel.receiveBroadcastStream().listen((errorData) {
      final eventModel = ErrorResponseEvent.fromJson(errorData);
      print("Error event ${eventModel.toErrorResponseData()}");
      for (var element in dataChangelist) element.onXmppError(eventModel);
    }, onError: _onError);
  }

  Future<void> stop() async {
    streamGetMsg.cancel();
    successEventStream.cancel();
    errorEventStream.cancel();
    connectionEventStream.cancel();
  }

  Future<void> changeTypingStatus(String userJid, String typingStatus) async {
    await _channel.invokeMethod('change_typing_status', {"userJid": userJid, "typingStatus": typingStatus});
  }

  Future<void> changePresenceType(String presenceType, String presenceMode) async {
    await _channel.invokeMethod('change_presence_type', {"presenceType": presenceType, "presenceMode": presenceMode});
  }

  void printLogForMethodCall(String methodName, dynamic params) {
    log('call method to app from flutter methodName: $methodName: params: $params');
  }
}
