import 'package:flutter/material.dart';
import './location.dart';

import '../services/kumulos.dart';
import './eventSubscriptionsManager.dart';
import './demo.dart' show DemoContainer;
import 'dart:io' show Platform;
import 'dart:core';
import './inApp.dart';

enum PushStep { pushRegister, pushUnauthorized, waitingForPush, pushReceived }

class PushDemoScreen extends StatefulWidget {
  @override
  PushDemoState createState() {
    return PushDemoState();
  }
}

const registerCopy =
    '''Push Notifications are one of the most effective ways to keep users engaged with the app.

You can schedule campaigns from the console or send automatically in response to events.

To explore, please allow permission to send and receive push notifications.
''';

class PushDemoState extends State<PushDemoScreen> {
  PushStep step = PushStep.pushRegister;
  EventSubscriptionsManager eventSubscriptionsManager =
      new EventSubscriptionsManager();

  String title = '';
  String message = '';

  @override
  Widget build(BuildContext context) {
    String title;
    String skipTitle;
    Widget child;
    Widget actionButton;

    title = 'Push Notifications';

    switch (this.step) {
      case PushStep.pushRegister:
        child = Text(registerCopy);
        actionButton = RaisedButton(
          textColor: Colors.white,
          shape: StadiumBorder(),
          onPressed: () {
            requestPushToken();
          },
          child: Text('REGISTER FOR PUSH'),
        );
        break;
      case PushStep.pushUnauthorized:
        child = Text(
            'As you have you have not given permission, you won\'t receive any push notifications. If you want to change this, go to Settings on your device and allow notifications for this app.');
        break;
      case PushStep.waitingForPush:
        child = Column(
          children: <Widget>[
            Center(
              child: CircularProgressIndicator(),
            ),
            Center(
              child: Padding(
                  padding: EdgeInsets.only(top: 28.0),
                  child:
                      Text('In the console, send yourself a notification...')),
            ),
          ],
        );
        break;
      case PushStep.pushReceived:
        child = Column(
          children: <Widget>[
            Center(
              child: Text('The notification you sent has been received.'),
            ),
            Padding(
                padding: EdgeInsets.only(top: 10.0),
                child: Center(
                  child: Card(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          leading: Icon(Icons.album),
                          title: Text(this.title),
                          subtitle: Text(this.message),
                        ),
                      ],
                    ),
                  ),
                ))
          ],
        );
        skipTitle = 'NEXT';
        break;
      default:
        return Text('Not implemented...');
    }

    return DemoContainer(
        title: title,
        skipTitle: skipTitle,
        headerImage: 'assets/push.png',
        heroTag: 'push',
        onSkip: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => InAppDemo()));

          if (step != PushStep.pushReceived) {
            Kumulos.instance.trackStepSkipped('push');
          }
        },
        child: child,
        actionButton: actionButton);
  }

  requestPushToken() async {
    if (Platform.isIOS) {
      eventSubscriptionsManager.subscribeToEvent(
          "pushRegistered", pushRegisteredHandler);
      eventSubscriptionsManager.subscribeToEvent(
          "pushUnauthorized", pushUnauthorizedHandler);
    }

    await Kumulos.instance.pushRegister();

    if (Platform.isAndroid) {
      this.pushRegisteredHandler(null);
    }
  }

  void pushUnauthorizedHandler(Map result) async {
    eventSubscriptionsManager.unsubscribeFromEvent("pushRegistered");
    eventSubscriptionsManager.unsubscribeFromEvent("pushUnauthorized");

    if (this.mounted && step == PushStep.pushRegister) {
      setState(() {
        step = PushStep.pushUnauthorized;
      });
    }
  }

  void pushRegisteredHandler(Map result) async {
    if (Platform.isIOS) {
      eventSubscriptionsManager.unsubscribeFromEvent("pushRegistered");
      eventSubscriptionsManager.unsubscribeFromEvent("pushUnauthorized");
    }

    if (this.mounted && step == PushStep.pushRegister) {
      setState(() {
        step = PushStep.waitingForPush;
      });

      eventSubscriptionsManager.subscribeToEvent(
          "pushReceived", pushReceivedHandler);
    }
  }

  void pushReceivedHandler(Map result) async {
    eventSubscriptionsManager.unsubscribeFromEvent("pushReceived");

    if (this.mounted && step == PushStep.waitingForPush) {
      setState(() {
        step = PushStep.pushReceived;
        title = result['title'];
        message = result['message'];
      });

      await Kumulos.instance.trackEventImmediately('companion.pushReceived');

      Kumulos.instance.trackStepCompleted('push');
    }
  }
}
