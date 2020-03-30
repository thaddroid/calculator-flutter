import 'dart:async';
import 'dart:collection';

import 'package:flutter_calculator/calculator-key.dart';
import 'package:flutter_calculator/key-controller.dart';
import 'package:stack/stack.dart';

import 'key-symbol.dart';

abstract class Processor {
  static KeySymbol _operator;
  static String _valA = '0';
  static String _valB = '0';
  static String _result;
  static int maxDigit = 9;
  static String _currentValue;
  static Stack<KeySymbol> _processStack = Stack();
  static int _size = 0;
  static bool _shouldCalculateProduct = false;

  static StreamController _controller = StreamController();
  static Stream get _stream => _controller.stream;

  static StreamSubscription listen(Function handler) =>
      _stream.listen(handler as dynamic);
  static void refresh() => _fire(_output);

  static void _fire(String data) => _controller.add(_output);

  static String get _output => _currentValue == null ? '0' : _currentValue;

  static dispose() => _controller.close();

  static process(dynamic event) {
    CalculatorKey key = (event as KeyEvent).key;
    switch (key.symbol.type) {
      case KeyType.FUNCTION:
        return handleFunction(key);
      case KeyType.OPERATOR:
        return handleOperator(key);
      default:
        return handleInteger(key);
    }
  }

  static void handleFunction(CalculatorKey key) {
    Map<KeySymbol, dynamic> table = {
      Keys.clear: () => _clear(),
      Keys.sign: () => _sign(),
      Keys.percent: () => _percent(),
      Keys.decimal: () => _decimal()
    };

    table[key.symbol]();
    refresh();
  }

  static String _newCalculate(
      KeySymbol valBSymbol, KeySymbol operatorSymbol, KeySymbol valASymbol) {
    String valA = (valASymbol == null) ? "0" : valASymbol.value;
    String valB = (valBSymbol == null) ? valA : valBSymbol.value;

    Map<KeySymbol, dynamic> table = {
      Keys.divide: (a, b) => (a / b),
      Keys.multiply: (a, b) => (a * b),
      Keys.subtract: (a, b) => (a - b),
      Keys.add: (a, b) => (a + b),
    };

    double result =
        table[operatorSymbol](double.parse(valA), double.parse(valB));
    String str = result.toString();

    while ((str.contains('.') && str.endsWith('0')) || str.endsWith('.')) {
      str = str.substring(0, str.length - 1);
    }

    return str;
  }

  static void addToStack(KeySymbol keySymbol) {
    _size++;
    _processStack.push(keySymbol);
  }

  static KeySymbol removeFromStack() {
    _size--;
    return _processStack.pop();
  }

  static void clearStack() {
    while (_processStack.isNotEmpty) {
      _processStack.pop();
    }
    _size = 0;
  }

  static void handleOperator(CalculatorKey key) {
    KeySymbol operator = key.symbol;

    if (_currentValue == null) {
      if (operator == Keys.equals) {
        if (_processStack.top().isOperator) {
          addToStack(KeySymbol(_currentValue));
        }
        while (_processStack.isNotEmpty) {
          _currentValue = _newCalculate(
              removeFromStack(), removeFromStack(), removeFromStack());
          if (_processStack.isEmpty) break;
          addToStack(KeySymbol(_currentValue));
        }
        addToStack(KeySymbol(_currentValue));
        refresh();
        return;
      }

      if (_processStack.top().isOperator) {
        removeFromStack();
      } else {
        addToStack(Keys.zero);
      }
      addToStack(operator);
      return;
    } else {
      if (_shouldCalculateProduct) {
        addToStack(KeySymbol(_currentValue));
        _currentValue = _newCalculate(
            removeFromStack(), removeFromStack(), removeFromStack());
        _shouldCalculateProduct = false;
        refresh();
      }

      addToStack(KeySymbol(_currentValue));
      _currentValue = null;
      _shouldCalculateProduct = false;

      if (operator.isFirstPriorityOperator) {
        _shouldCalculateProduct = true;

        addToStack(operator);
        return;
      }
    }

    if (_size < 3) {
      addToStack(operator);
      return;
    }

    while (_processStack.isNotEmpty) {
      _currentValue = _newCalculate(
          removeFromStack(), removeFromStack(), removeFromStack());
      if (_processStack.isEmpty) break;
      addToStack(KeySymbol(_currentValue));
    }
    addToStack(KeySymbol(_currentValue));
    addToStack(operator);
    refresh();

    _currentValue = null;
  }

  static void handleInteger(CalculatorKey key) {
    String val = key.symbol.value;
    _currentValue = (_currentValue == null) ? val : _currentValue + val;
    refresh();
  }

  static void _clear() {
    _currentValue = null;
    _shouldCalculateProduct = false;
    clearStack();
  }

  static void _sign() {
    _currentValue = (_currentValue.contains('-')
        ? _currentValue.substring(1)
        : '-' + _currentValue);
  }

  static String calcPercent(String x) => (double.parse(x) / 100).toString();

  static void _percent() {
    if (_valB != '0' && !_valB.contains('.')) {
      _valB = calcPercent(_valB);
    } else if (_valA != '0' && !_valA.contains('.')) {
      _valA = calcPercent(_valA);
    }
  }

  static void _decimal() {
    if (_valB != '0' && !_valB.contains('.')) {
      _valB = _valB + '.';
    } else if (_valA != '0' && !_valA.contains('.')) {
      _valA = _valA + '.';
    }
  }

  static bool _calculate() {
    if (_operator == null || _valB == '0') {
      return false;
    }

    Map<KeySymbol, dynamic> table = {
      Keys.divide: (a, b) => (a / b),
      Keys.multiply: (a, b) => (a * b),
      Keys.subtract: (a, b) => (a - b),
      Keys.add: (a, b) => (a + b),
    };

    double result = table[_operator](double.parse(_valA), double.parse(_valB));
    String str = result.toString();

    while ((str.contains('.') && str.endsWith('0')) || str.endsWith('.')) {
      str = str.substring(0, str.length - 1);
    }

    _result = str;
    refresh();
    return true;
  }

  static void _condense() {
    _valA = _result;
    _valB = '0';
    _result = _operator = null;
  }
}
