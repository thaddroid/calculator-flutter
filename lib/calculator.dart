import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'display.dart';
import 'key-controller.dart';
import 'key-pad.dart';
import 'processor.dart';

class Calculator extends StatefulWidget {
  Calculator({Key key}) : super(key: key);

  @override
  _CalculatorState createState() => _CalculatorState();
}

class _CalculatorState extends State<Calculator> {
  String _output;

  @override
  void initState() {
    KeyController.listen((event) => Processor.process(event));
    Processor.listen((data) => setState(() {
          _output = data;
        }));
    Processor.refresh();
    super.initState();
  }

  String _formatDisplay(String data) {
    var f = NumberFormat("#,###.#", "en_US");
    return f.format(double.parse(data));
  }

  @override
  void dispose() {
    KeyController.dispose();
    Processor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size screen = MediaQuery.of(context).size;

    double buttonSize = screen.width / 4;
    double displayHeight = screen.height - (buttonSize * 5) - 50;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Display(
            value: _output,
            height: displayHeight,
          ),
          KeyPad()
        ],
      ),
    );
  }
}
