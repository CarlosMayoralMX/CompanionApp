import 'package:flutter/material.dart';
import './demos/push.dart';
import 'package:qrcode_reader/qrcode_reader.dart';

import './services/auth.dart';

class PairingScreen extends StatefulWidget {
  @override
  PairingState createState() {
    return PairingState();
  }
}

enum Step { intro, pairing }

class PairingState extends State<PairingScreen> {
  Step step = Step.intro;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Get started..."),
        ),
        body: Builder(builder: (BuildContext context) {
          return Container(
              padding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
              child: this.renderBody(context));
        }));
  }

  Widget renderBody(BuildContext context) {
    switch (this.step) {
      case Step.intro:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: ListView(
                children: <Widget>[
                  Image.asset('assets/qrcode.png'),
                  Text(
                    '''To use the companion app, you need to pair the app with your Kumulos account.

In the Kumulos console, go to your companion app and click pair your device.

When the QR code is shown, click the scan button below.
''',
                  ),
                ],
              ),
            ),
            Container(
                child: RaisedButton(
                    textColor: Colors.white,
                    shape: StadiumBorder(),
                    onPressed: () async {
                      var code = await new QRCodeReader().scan();

                      if (null == code) {
                        final snackBar = SnackBar(
                            content: Text(
                                'Scanning failed, please enable the camera & try again...'));
                        Scaffold.of(context).showSnackBar(snackBar);
                        return;
                      }

                      pairWithCode(context, code);
                    },
                    child: Text('SCAN')))
          ],
        );
      case Step.pairing:
        return Center(
          child: CircularProgressIndicator(),
        );
      default:
        return Text('Not implemented...');
    }
  }

  pairWithCode(BuildContext context, String code) async {
    setState(() {
      step = Step.pairing;
    });

    try {
      final result = await PairingManager.instance.pairWithCode(code);

      String message = 'Welcome, ${result.user.email}';
      if (result.user.forename != null && result.user.forename != '') {
        message = 'Welcome, ${result.user.forename}';
      }

      final snackBar = SnackBar(content: Text(message));
      Scaffold.of(context).showSnackBar(snackBar);

      await Future.delayed(Duration(seconds: 2));

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => PushDemoScreen()));
    } on Exception {
      this.setState(() {
        step = Step.intro;
      });
      final snackBar =
          SnackBar(content: Text('Pairing has failed, please try again...'));
      Scaffold.of(context).showSnackBar(snackBar);
      return;
    }
  }
}

class UnpairedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Padding(
      padding: EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // TODO some cute graphic?
          Text(
              'Your device has been unpaired from the app on your account. Please close and then reopen the app to start again or pair your device with a different app on your account.')
        ],
      ),
    ));
  }
}
