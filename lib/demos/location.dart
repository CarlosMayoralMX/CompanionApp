import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './analytics.dart';
import './demo.dart' show DemoContainer;
import '../services/kumulos.dart';

enum DemoStep { INTRO, AUTHED, NOT_AUTHED }

class LocationDemo extends StatefulWidget {
  @override
  State<LocationDemo> createState() {
    return LocationDemoState();
  }
}

const introCopy =
    '''Geofences let you target users within a specific area or a certain radius of a point on a map (e.g. within 1000m of a retail outlet that is running a promotion).

You can send notifications to all users who are in a geofence or trigger notifications when they enter or exit the geofence.

Share your location so we can deliver relevant content to you.
''';

class LocationDemoState extends State<LocationDemo> {
  static const _platform = MethodChannel('com.kumulos.companion.location');

  DemoStep step = DemoStep.INTRO;

  LocationDemoState() {
    _platform.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'locationAuthorized':
          setState(() {
            step = DemoStep.AUTHED;
          });
          Kumulos.instance.trackStepCompleted('location');
          break;
        case 'locationNotAuthorized':
          setState(() {
            step = DemoStep.NOT_AUTHED;
          });
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DemoContainer(
      title: 'Geolocation',
      headerImage: 'assets/location.png',
      heroTag: 'location',
      skipTitle: step == DemoStep.AUTHED ? 'NEXT' : null,
      onSkip: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => AnalyticsDemo()));

        if (step != DemoStep.AUTHED) {
          Kumulos.instance.trackStepSkipped('location');
        }
      },
      child: buildBody(),
      actionButton: step == DemoStep.INTRO
          ? RaisedButton(
              textColor: Colors.white,
              shape: StadiumBorder(),
              onPressed: () {
                requestLocationUpdates();
              },
              child: Text('SHARE MY LOCATION'),
            )
          : null,
    );
  }

  Widget buildBody() {
    switch (step) {
      case DemoStep.INTRO:
        return Text(introCopy);
      case DemoStep.AUTHED:
        return Text(
            '''Great, as you're sharing your location, you can now explore all of the geofencing features in the console.

If you're following the pairing wizard, you should now see your current location on the map.''');

      case DemoStep.NOT_AUTHED:
        return Text(
            'As you have not shared your location, you won\'t receive notifications based on your physical location. If you want to change this, go to Settings on your device and share your location with this app.');
    }

    return Text('Not implemented...');
  }

  requestLocationUpdates() async {
    await _platform.invokeMethod('requestLocation');
  }
}
