import 'package:flutter/material.dart';
import '../home.dart';

import '../services/kumulos.dart';
import './demo.dart' show DemoContainer;
import 'package:shared_preferences/shared_preferences.dart';

enum DemoStep { INTRO, STEPPER, DROPPED, FINISHED }

class AnalyticsDemo extends StatefulWidget {
  @override
  State<AnalyticsDemo> createState() {
    return AnalyticsDemoState();
  }
}

class StepDefinition {
  String title;
  String subtitle;
  Widget content;

  StepDefinition(
      {@required this.title, @required this.subtitle, @required this.content});
}

final List<StepDefinition> stepperSteps = [
  StepDefinition(
      title: 'Add product to cart',
      subtitle: 'Simulate adding a product to your cart',
      content: null),
  StepDefinition(
      title: 'Checkout',
      subtitle: 'Simulate navigating to checkout',
      content: null),
  StepDefinition(
      title: 'Delivery',
      subtitle: 'Simulate entering delivery details',
      content: null),
  StepDefinition(
      title: 'Payment',
      subtitle: 'Simulate entering payment details',
      content: null),
  StepDefinition(
      title: 'Confirm',
      subtitle: 'Simulate confirming your order',
      content: null),
];

const introCopy =
    '''Analytics gives important insights into who is using an app and how engaged they are, to help you make informed decisions on how to increase retention and conversion.

Track events through the key user journeys of your app and trigger notifications to re-engage users when they drop-off.

Using the example of typical checkout journey, you can send some events to track conversion with funnels or drop-off to trigger automated notifications.
''';

class AnalyticsDemoState extends State<AnalyticsDemo> {
  int _stepperStep = 0;
  DemoStep _step = DemoStep.INTRO;

  static const List _stepToEventNameMapping = [
    'companion.analytics.productAddedToCart',
    'companion.analytics.viewedCheckout',
    'companion.analytics.enteredDeliveryInfo',
    'companion.analytics.enteredPaymentDetails',
    'companion.analytics.completedOrder'
  ];

  @override
  Widget build(BuildContext context) {
    return DemoContainer(
        title: 'Analytics',
        heroTag: 'analytics',
        headerImage: 'assets/analytics.png',
        bodyPadding: _step == DemoStep.STEPPER ? 0 : null,
        skipTitle: _step == DemoStep.FINISHED || _step == DemoStep.DROPPED
            ? 'DONE'
            : null,
        onSkip: () {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  settings: RouteSettings(isInitialRoute: true),
                  builder: (context) => HomeScreen()),
              (route) => false);

          if (_step != DemoStep.FINISHED || _step != DemoStep.DROPPED) {
            Kumulos.instance.trackStepSkipped('analytics');
          }

          finishTheTutorial();
        },
        child: buildBody(),
        actionButton: _step == DemoStep.INTRO
            ? RaisedButton(
                textColor: Colors.white,
                shape: StadiumBorder(),
                onPressed: () {
                  setState(() {
                    _step = DemoStep.STEPPER;
                  });
                },
                child: Text('SEND SOME EVENTS'),
              )
            : null);
  }

  Widget buildBody() {
    switch (_step) {
      case DemoStep.INTRO:
        return Text(introCopy);

      case DemoStep.STEPPER:
        return this.getStepper();

      case DemoStep.DROPPED:
        return Text(
            '''In the console, go to the Analytics section for your app. Click on the Conversion tab to see your progress through the checkout funnel or use the Analytics Explorer to see the events you have sent.

Go to the Push section for your app and click on Automations to see an automated campaign with a rule that will be triggered by the drop-off and fire a notification if you don't complete the checkout journey within an hour.''');

        break;

      case DemoStep.FINISHED:
        return Text(
            'In the console, go to the Analytics section for your app. Click on the Conversion tab to see your progress through the checkout funnel or use the Analytics Explorer to see the events you have sent.');

        break;
    }

    return null;
  }

  Stepper getStepper() {
    return Stepper(
      controlsBuilder: (BuildContext context,
          {VoidCallback onStepContinue, VoidCallback onStepCancel}) {
        final children = <Widget>[
          FlatButton(
              onPressed: _stepperStep > 0 ? onStepCancel : null,
              child: Text('DROP OFF')),
          RaisedButton(
              textColor: Colors.white,
              onPressed: onStepContinue,
              child: Text(
                'SEND',
              ))
        ];

        return Row(children: children);
      },
      physics: NeverScrollableScrollPhysics(),
      steps: stepperSteps
          .asMap()
          .map((index, step) => MapEntry(
              index,
              Step(
                  content: Text(''), //step.content,
                  title: Text(step.title),
                  subtitle: Text(step.subtitle),
                  isActive: _stepperStep == index,
                  state: _stepperStep > index
                      ? StepState.complete
                      : StepState.indexed)))
          .values
          .toList(),
      currentStep: _stepperStep,
      onStepCancel: () {
        setState(() {
          _step = DemoStep.DROPPED;
        });
      },
      onStepContinue: () {
        trackFunnelStepCompleted(_stepperStep);

        if (_stepperStep == stepperSteps.length - 1) {
          setState(() {
            _step = DemoStep.FINISHED;
            _stepperStep = 0;
          });

          Kumulos.instance.trackStepCompleted('analytics');
          finishTheTutorial();
        } else {
          setState(() {
            _stepperStep = _stepperStep + 1;
          });
        }
      },
    );
  }

  void trackFunnelStepCompleted(int _stepCompleted) async {
    await Kumulos.instance
        .trackEventImmediately(_stepToEventNameMapping[_stepCompleted]);
  }

  void finishTheTutorial() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey('tutorialFinished')) {
      return;
    }

    await prefs.setBool('tutorialFinished', true);
  }
}
