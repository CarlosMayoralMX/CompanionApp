import 'package:flutter/services.dart';

class Kumulos {
  static final Kumulos instance = Kumulos();
  static const _companionChannel = MethodChannel('com.kumulos.flutter');
  static const _pushChannel = MethodChannel('com.kumulos.companion.push');

  Future<void> init(String apiKey, String secretKey) async {
    return _companionChannel.invokeMethod('init', [apiKey, secretKey]);
  }

  Future<String> getInstallId() async {
    return _companionChannel.invokeMethod('getInstallId');
  }

  Future<void> trackEvent(String type,
      [Map<String, dynamic> properties]) async {
    return _companionChannel
        .invokeMethod('trackEvent', [type, properties, false]);
  }

  Future<void> trackEventImmediately(String type,
      [Map<String, dynamic> properties]) async {
    return _companionChannel
        .invokeMethod('trackEvent', [type, properties, true]);
  }

  Future<void> pushRegister() async {
    return _pushChannel.invokeMethod('pushRegister');
  }

  Future<void> trackStepCompleted(String tutorial) async {
    Map<String, String> properties = new Map();
    properties['tutorial'] = tutorial;

    await instance.trackEventImmediately(
        'companion.tutorial.completed', properties);
  }

  Future<void> trackStepSkipped(String tutorial) async {
    Map<String, String> properties = new Map();
    properties['tutorial'] = tutorial;

    await instance.trackEventImmediately(
        'companion.tutorial.skipped', properties);
  }
}
