import 'package:flutter/material.dart';
import './home.dart';
import './services/auth.dart';
import './pairing.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return SplashScreenState();
  }
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    loadData();
  }

  loadData() async {
    await PairingManager.instance.loadState();

    await Future.delayed(Duration(seconds: 2));

    if (PairingManager.instance.isPaired()) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          settings: RouteSettings(isInitialRoute: true),
          builder: (context) => HomeScreen()));
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          settings: RouteSettings(isInitialRoute: true),
          builder: (context) => PairingScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Spacer(flex: 2),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
              Image.asset(
                'assets/kumulos_logo.png',
                width: 200,
              )
            ]),
            Spacer(flex: 1),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                  Color.fromARGB(200, 0, 165, 209)),
              strokeWidth: 1.6,
            ),
            Spacer(flex: 4),
          ],
        ),
      ),
    );
  }
}
