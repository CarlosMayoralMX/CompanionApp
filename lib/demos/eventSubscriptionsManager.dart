import 'package:flutter/services.dart';
import 'dart:core';

/*
 * un/subscribes to Native -> Flutter events 
 * (as presumably they should not be handled all the time)
 * use in location?
 */
class EventSubscriptionsManager {
  Map<String, Function> _eventSubscriptions = new Map();

  static const _platform = MethodChannel('com.kumulos.companion.push');

  EventSubscriptionsManager() {
    _platform.setMethodCallHandler((MethodCall call) async {
      if (!this._eventSubscriptions.containsKey(call.method)) {
        return;
      }

      this._eventSubscriptions[call.method](call.arguments);
    });
  }

  void subscribeToEvent(String eventType, Function successHandler) {
    if (this._eventSubscriptions.containsKey(eventType)) {
      return;
    }

    this._eventSubscriptions[eventType] = successHandler;
  }

  void unsubscribeFromEvent(String eventType) {
    if (!this._eventSubscriptions.containsKey(eventType)) {
      return;
    }

    this._eventSubscriptions.remove(eventType);
  }
}
