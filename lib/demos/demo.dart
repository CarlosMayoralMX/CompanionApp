import 'package:flutter/material.dart';
import '../home.dart';
import '../services/kumulos.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ConfirmAction { CANCEL, ACCEPT }

class DemoScreen extends StatelessWidget {
  final String demo;

  DemoScreen({Key key, @required this.demo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Demo time: ' + demo),
      ),
      body: Hero(
        tag: demo,
        child: Placeholder(
          fallbackHeight: 400,
        ),
      ),
    );
  }
}

class DemoContainer extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback onSkip;
  final String skipTitle;
  final String headerImage;
  final String heroTag;
  final double bodyPadding;
  final Widget actionButton;

  DemoContainer(
      {@required this.title,
      @required this.child,
      this.onSkip,
      this.headerImage,
      this.bodyPadding,
      this.heroTag = 'hero',
      this.skipTitle = 'Skip',
      this.actionButton});

  Future<ConfirmAction> _showExitTutorialConfirmationDialog(
      BuildContext context) async {
    return await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: new Text("Leave guided tour"),
              content: new Text(
                  "If you stop following the wizard, you can still explore all the features later."),
              actions: <Widget>[
                new FlatButton(
                  child: new Text("LEAVE"),
                  onPressed: () {
                    Navigator.of(context).pop(ConfirmAction.ACCEPT);
                  },
                ),
                new FlatButton(
                  child: new Text("STAY"),
                  onPressed: () {
                    Navigator.of(context).pop(ConfirmAction.CANCEL);
                  },
                ),
              ]);
        });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          final prefs = await SharedPreferences.getInstance();
          bool tutorialFinished = prefs.containsKey('tutorialFinished');
          if (tutorialFinished) {
            return true;
          }

          final result = await _showExitTutorialConfirmationDialog(context);
          if (result == ConfirmAction.ACCEPT) {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    settings: RouteSettings(isInitialRoute: true),
                    builder: (context) => HomeScreen()),
                (route) => false);

            Kumulos.instance
                .trackEventImmediately('companion.tutorial.aborted');

            await prefs.setBool('tutorialFinished', true);
          }

          return false;
        },
        child: Scaffold(
            persistentFooterButtons: <Widget>[
              onSkip != null
                  ? FlatButton(
                      onPressed: onSkip,
                      child: Text(skipTitle != null ? skipTitle : 'SKIP'),
                    )
                  : null
            ],
            appBar: AppBar(
              title: Text(title),
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: ListView(
                    children: <Widget>[
                      Hero(
                        tag: heroTag,
                        child: this.headerImage == null
                            ? Placeholder(
                                color: Colors.white,
                              )
                            : Image.asset(this.headerImage, fit: BoxFit.cover),
                      ),
                      Container(
                          padding: EdgeInsets.all(this.bodyPadding ?? 24),
                          child: child),
                    ],
                  ),
                ),
                Container(
                    padding: EdgeInsets.only(left: 24, right: 24, bottom: 8),
                    child: this.actionButton)
              ],
            )));
  }
}
