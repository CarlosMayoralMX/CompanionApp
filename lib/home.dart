import 'package:flutter/material.dart';
import './services/auth.dart';
import './demos/demo.dart';
import './pairing.dart' show UnpairedScreen;
import './demos/analytics.dart';
import './demos/demo.dart' show DemoScreen;
import './demos/push.dart';
import './demos/location.dart';

enum ConfirmAction { CANCEL, ACCEPT }

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: CustomScrollView(
      slivers: <Widget>[
        SliverAppBar(
          pinned: true,
          floating: false,
          expandedHeight: 150,
          title: Text('Kumulos'),
        ),
        SliverList(
          delegate: SliverChildListDelegate(<Widget>[
            _renderCard(context,
                title: 'Push Notifications',
                description: 'Keep users engaged with push notifications.',
                heroTag: 'push',
                image: 'assets/push.png',
                destination:
                    MaterialPageRoute(builder: (context) => PushDemoScreen())),
            _renderCard(context,
                title: 'Geolocation',
                description:
                    'Deliver highly relevant content based on users physical location.',
                heroTag: 'location',
                image: 'assets/location.png',
                destination:
                    MaterialPageRoute(builder: (context) => LocationDemo())),
            _renderCard(context,
                title: 'Analytics',
                description:
                    'Use analytics to trigger timely interactions and increase retention and conversion.',
                heroTag: 'analytics',
                image: 'assets/analytics.png',
                destination:
                    MaterialPageRoute(builder: (context) => AnalyticsDemo())),
            Container(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: FlatButton(
                    onPressed: () async {
                      final result = await _confirmUnpairing(context);

                      if (ConfirmAction.ACCEPT != result) {
                        return;
                      }

                      await PairingManager.instance.unpair();

                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              settings: RouteSettings(isInitialRoute: true),
                              builder: (context) => UnpairedScreen()));
                    },
                    child: Text('UNPAIR COMPANION APP')))
          ]),
        )
      ],
    ));
  }

  Widget _renderCard(BuildContext context,
      {@required String title,
      @required String description,
      @required String heroTag,
      @required String image,
      Route destination}) {
    final nav = () {
      Navigator.push(
          context,
          destination ??
              MaterialPageRoute(
                builder: (context) => DemoScreen(
                      demo: title,
                    ),
              ));
    };

    return Card(
        margin: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: InkWell(
          // highlightColor: Colors.blueGrey[100],
          splashColor: Colors.blueGrey[50],
          onTap: nav,
          child: Column(
            children: <Widget>[
              Hero(child: Image.asset(image), tag: heroTag),
              Text(
                title,
                style: Theme.of(context).textTheme.headline,
                textAlign: TextAlign.left,
              ),
              Container(
                child: Text(
                  description,
                  style: Theme.of(context).textTheme.body2,
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
                FlatButton(
                  splashColor: Color.fromARGB(0, 0, 0, 0),
                  highlightColor: Color.fromARGB(0, 0, 0, 0),
                  textColor: Theme.of(context).accentColor,
                  onPressed: nav,
                  child: Text('EXPLORE DEMO'),
                )
              ])
            ],
          ),
        ));
  }

  Future<ConfirmAction> _confirmUnpairing(BuildContext context) async {
    return showDialog<ConfirmAction>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Unpair Companion App?'),
          content: const Text(
              'This will reset the companion app and allow you to pair with another app on your account.'),
          actions: <Widget>[
            FlatButton(
              child: const Text('UNPAIR'),
              onPressed: () {
                Navigator.of(context).pop(ConfirmAction.ACCEPT);
              },
            ),
            FlatButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop(ConfirmAction.CANCEL);
              },
            )
          ],
        );
      },
    );
  }
}
