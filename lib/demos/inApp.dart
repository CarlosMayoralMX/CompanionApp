import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import './location.dart';

import '../services/kumulos.dart';
import './demo.dart' show DemoContainer;
import 'dart:core';
import 'package:flutter/services.dart';

class InAppDemo extends StatefulWidget {
  @override
  InAppDemoState createState() {
    return InAppDemoState();
  }
}

const waitingCopy =
    '''In-App Messaging allows you to deliver rich content to users whilst they are in the app.

You can use in-app messaging to boost conversion through the on-boarding journey, highlight special offers, ask users to rate your app, subscribe to receive push notifications and much, much more.

In the console, send yourself an in-app message...
''';

class InAppDemoState extends State<InAppDemo> {
  static const _platform = MethodChannel('com.kumulos.companion.inapp');

  InAppDemoState() {
    _platform.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'inAppReceived':
          Kumulos.instance.trackEventImmediately('companion.inAppReceived');
          Kumulos.instance.trackStepCompleted('inApp');
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => LocationDemo()));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Column(
      children: <Widget>[
        Center(
          child: Padding(
              padding: EdgeInsets.only(top: 28.0), child: Text(waitingCopy)),
        ),
        Center(
          child: CircularProgressIndicator(),
        ),
      ],
    );

    return DemoContainer(
        title: 'In App messages',
        skipTitle: 'SKIP',
        headerImage: 'assets/inapp.png',
        heroTag: 'inApp',
        onSkip: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => LocationDemo()));
          Kumulos.instance.trackStepSkipped('inApp');
        },
        child: child);
  }
}
