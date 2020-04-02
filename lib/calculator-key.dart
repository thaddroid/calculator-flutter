import 'package:flutter/material.dart';

import 'key-controller.dart';
import 'key-symbol.dart';

abstract class Keys {
  static const KeySymbol clear = const KeySymbol('AC');
  static const KeySymbol sign = const KeySymbol('±');
  static const KeySymbol percent = const KeySymbol('%');
  static const KeySymbol divide = const KeySymbol('÷');
  static const KeySymbol multiply = const KeySymbol('x');
  static const KeySymbol subtract = const KeySymbol('-');
  static const KeySymbol add = const KeySymbol('+');
  static const KeySymbol equals = const KeySymbol('=');
  static const KeySymbol decimal = const KeySymbol('.');

  static const KeySymbol zero = const KeySymbol('0');
  static const KeySymbol one = const KeySymbol('1');
  static const KeySymbol two = const KeySymbol('2');
  static const KeySymbol three = const KeySymbol('3');
  static const KeySymbol four = const KeySymbol('4');
  static const KeySymbol five = const KeySymbol('5');
  static const KeySymbol six = const KeySymbol('6');
  static const KeySymbol seven = const KeySymbol('7');
  static const KeySymbol eight = const KeySymbol('8');
  static const KeySymbol nine = const KeySymbol('9');
}

class CalculatorKey extends StatelessWidget {
  CalculatorKey({this.symbol});

  final KeySymbol symbol;

  Color get color {
    switch (symbol.type) {
      case KeyType.FUNCTION:
        return Color.fromARGB(255, 196, 196, 196);
      case KeyType.OPERATOR:
        return Color.fromARGB(255, 234, 134, 54);
      case KeyType.INTEGER:
      default:
        return Color.fromARGB(255, 64, 64, 64);
    }
  }

  static dynamic _fire(CalculatorKey key) => KeyController.fire(KeyEvent(key));

  @override
  Widget build(BuildContext context) {
    double size = (MediaQuery.of(context).size.width - 20) / 4;
    TextStyle style = Theme.of(context).textTheme.headline4.copyWith(
        color: (symbol.type == KeyType.FUNCTION) ? Colors.black : Colors.white);

    return Container(
      width: (symbol == Keys.zero) ? (size * 2) : size,
      padding: EdgeInsets.all(6),
      height: size,
      child: Theme(
        data: ThemeData(splashColor: Colors.white),
        child: RawMaterialButton(
          onPressed: () => _fire(this),
          child: Text(symbol.value, style: style),
          shape: (symbol == Keys.zero)
              ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))
              : CircleBorder(),
          elevation: 4,
          fillColor: color,
          padding: EdgeInsets.all(10),
        ),
      ),
    );
  }
}
