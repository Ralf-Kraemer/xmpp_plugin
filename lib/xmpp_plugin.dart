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

  static late StreamSubscription _streamGetMsg;
  static late StreamSubscription _successEventStream;
  static late StreamSubscription _connectionEventStream;
  static late StreamSubscription _errorEventStream;

  static final List<DataChangeEvents> _listeners = [];
  final Set<String> _receivedMessageIds = {};

  final dynamic auth;
  XmppConnectionState connectionState = XmppConnectionState.disconnected;

  XmppConnection(this.auth);

  /// Listener management
  static void addListener(DataChangeEvents listener) {
    if (!_listeners.contains(listener)) _listeners.add(listener);
  }

  static void removeListener(DataChangeEvents listener) {
    _listeners.remove(listener);
  }

  static void removeAllListeners() {
    _listeners.clear();
  }

  /// Core login/logout
  Future<void> login() async {
    try {
      await _channel.invokeMethod('login', auth);
      await enableMessageCarbons(); // Enable XEP-0280
    } on PlatformException catch (e) {
      log('Login failed: ${e.message}');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _channel.invokeMethod('logout');
      _updateConnectionState(XmppConnectionState.disconnected);
    } on PlatformException catch (e) {
      log('Logout failed: ${e.message}');
      rethrow;
    }
  }

  /// Message sending
  Future<String> sendMessage(String toJid, String body, String id, int time) async {
    final params = {"to_jid": toJid, "body": body, "id": id, "time": time.toString()};
    _logMethodCall('send_message', params);
    try {
      return await _channel.invokeMethod('send_message', params).timeout(const Duration(seconds: 10));
    } catch (e) {
      log('Send message failed: $e');
      return 'error';
    }
  }

  Future<String> sendGroupMessage(String toJid, String body, String id, int time) async {
    final params = {"to_jid": toJid, "body": body, "id": id, "time": time.toString()};
    _logMethodCall('send_group_message', params);
    try {
      return await _channel.invokeMethod('send_group_message', params).timeout(const Duration(seconds: 10));
    } catch (e) {
      log('Send group message failed: $e');
      return 'error';
    }
  }

  Future<String> readMessage(String toJid, String id) async {
    final params = {"to_jid": toJid, "id": id};
    _logMethodCall('read_message', params);
    try {
      return await _channel.invokeMethod('read_message', params).timeout(const Duration(seconds: 10));
    } catch (e) {
      log('Read message failed: $e');
      return 'error';
    }
  }

  /// Enable Message Carbons (XEP-0280)
  Future<void> enableMessageCarbons() async {
    try {
      await _channel.invokeMethod('enableMessageCarbons');
      log('Message Carbons enabled');
    } on PlatformException catch (e) {
      log('Failed to enable message carbons: ${e.message}');
    }
  }

  /// Presence & Typing
  Future<void> changeTypingStatus(String userJid, String typingStatus) async {
    await _channel.invokeMethod('change_typing_status', {"userJid": userJid, "typingStatus": typingStatus});
  }

  Future<void> changePresenceType(String presenceType, String presenceMode) async {
    await _channel.invokeMethod('change_presence_type', {"presenceType": presenceType, "presenceMode": presenceMode});
  }

  /// Start listening to events
  Future<void> start(Function onError) async {
    _streamGetMsg = _eventChannel.receiveBroadcastStream().listen(
      (data) => _handleIncomingEvent(data),
      onError: onError,
    );

    _connectionEventStream =
        _connectionEventChannel.receiveBroadcastStream().listen(
      (data) {
        final event = ConnectionEvent.fromJson(data);
        _handleConnectionEvent(event);
      },
      onError: onError,
    );

    _successEventStream =
        _successEventChannel.receiveBroadcastStream().listen(
      (data) {
        final event = SuccessResponseEvent.fromJson(data);
        _dispatchSuccessEvent(event);
      },
      onError: onError,
    );

    _errorEventStream =
        _errorEventChannel.receiveBroadcastStream().listen(
      (data) {
        final event = ErrorResponseEvent.fromJson(data);
        _dispatchErrorEvent(event);
      },
      onError: onError,
    );
  }

  Future<void> stop() async {
    await _streamGetMsg.cancel();
    await _successEventStream.cancel();
    await _errorEventStream.cancel();
    await _connectionEventStream.cancel();
  }

  /// Internal helpers
  void _handleIncomingEvent(dynamic data) {
    final eventModel = MessageEvent.fromJson(data);
    final messageChat = MessageChat.fromJson(data);

    if (_receivedMessageIds.contains(messageChat.id)) return;
    _receivedMessageIds.add(messageChat.id);

    for (var listener in _listeners) {
      switch (eventModel.msgtype) {
        case 'chat':
          listener.onChatMessage(messageChat);
          break;
        case 'groupchat':
          listener.onGroupMessage(messageChat);
          break;
        case 'normal':
          listener.onNormalMessage(messageChat);
          break;
      }
      switch (eventModel.type) {
        case 'presence':
          listener.onPresenceChange(PresentModel.fromJson(data));
          break;
        case 'chatstate':
          listener.onChatStateChange(ChatState.fromJson(data));
          break;
      }
    }
  }

  void _handleConnectionEvent(ConnectionEvent event) {
    XmppConnectionState newState;
    switch (event.state.toLowerCase()) {
      case 'authenticated':
        newState = XmppConnectionState.authenticated;
        break;
      case 'connected':
        newState = XmppConnectionState.connected;
        break;
      case 'connecting':
        newState = XmppConnectionState.connecting;
        break;
      case 'disconnected':
        newState = XmppConnectionState.disconnected;
        break;
      case 'failed':
        newState = XmppConnectionState.failed;
        break;
      default:
        newState = XmppConnectionState.disconnected;
    }
    _updateConnectionState(newState);
  }

  void _updateConnectionState(XmppConnectionState newState) {
    if (connectionState != newState) {
      connectionState = newState;
      for (var listener in _listeners) {
        listener.onConnectionEvents(ConnectionEvent(state: newState.name));
      }
      if (newState == XmppConnectionState.disconnected ||
          newState == XmppConnectionState.failed) {
        // Auto-reconnect after 3 seconds
        Future.delayed(const Duration(seconds: 3), () => login().catchError((e) => log('Reconnect failed: $e')));
      }
    }
  }

  void _dispatchSuccessEvent(SuccessResponseEvent event) {
    log('Success event: ${event.toSuccessResponseData()}');
    for (var listener in _listeners) listener.onSuccessEvent(event);
  }

  void _dispatchErrorEvent(ErrorResponseEvent event) {
    log('Error event: ${event.toErrorResponseData()}');
    for (var listener in _listeners) listener.onXmppError(event);
  }

  void _logMethodCall(String method, dynamic params) {
    log('Flutter → Native: $method | params: $params');
  }
}
