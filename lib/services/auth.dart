import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:package_info/package_info.dart';
import './kumulos.dart';

class AppMeta {
  final String name;
  final String apiKey;
  final String secretKey;

  AppMeta({this.name, this.apiKey, this.secretKey});

  factory AppMeta.fromJson(Map<String, dynamic> json) {
    return AppMeta(
        name: json['name'],
        apiKey: json['apiKey'],
        secretKey: json['secretKey']);
  }
}

class UserMeta {
  final String forename;
  final String surname;
  final String email;

  UserMeta({this.forename, this.surname, this.email});

  factory UserMeta.fromJson(Map<String, dynamic> json) {
    return UserMeta(
        forename: json['forename'],
        surname: json['surname'],
        email: json['email']);
  }
}

class PairingState {
  final AppMeta app;
  final UserMeta user;

  PairingState({this.app, this.user});

  factory PairingState.fromJson(Map<String, dynamic> json) {
    return PairingState(
        app: AppMeta.fromJson(json['app']),
        user: UserMeta.fromJson(json['user']));
  }
}

class PairingManager {
  static final instance = PairingManager();
  static const _platform = MethodChannel('com.kumulos.companion.pairing');

  PairingState _state;
  bool _paired = false;

  Future<void> loadState() async {
    final sp = await SharedPreferences.getInstance();

    if (!sp.containsKey('pairingResponse')) {
      return;
    }

    final response = sp.get('pairingResponse');
    _state = PairingState.fromJson(json.decode(response));
    _paired = true;
  }

  bool isPaired() {
    return _paired;
  }

  Future<PairingState> pairWithCode(String code) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    final installId = await Kumulos.instance.getInstallId();
    final data = {
      'code': code,
      'uuid': installId,
      'version': packageInfo.version
    };

    final url = 'https://accounts.app.delivery/companion-auth';

    final response = await http.post(url, body: json.encode(data), headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to pair');
    }

    _state = PairingState.fromJson(json.decode(response.body));

    await Kumulos.instance.init(_state.app.apiKey, _state.app.secretKey);
    // Sleep a little to allow install tracking event to be persisted prior to flushing.
    // Install tracking is two discrete jobs on the local work queue and it's possible
    // for the companion.paired event to interleave the jobs, causing the install tracking
    // event to be left behind on the device :-\
    await Future.delayed(Duration(seconds: 2));
    await Kumulos.instance.trackEventImmediately('companion.paired');

    final sp = await SharedPreferences.getInstance();
    sp.setString('pairingResponse', response.body);

    _paired = true;

    return _state;
  }

  Future<void> unpair() async {
    var sp = await SharedPreferences.getInstance();
    await sp.clear();
    return _platform.invokeMethod('unpair');
  }
}
