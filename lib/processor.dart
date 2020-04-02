import 'dart:async';

import 'package:flutter_calculator/calculator-key.dart';
import 'package:flutter_calculator/key-controller.dart';
import 'package:stack/stack.dart';

import 'key-symbol.dart';

// TODO
// implement RxDart, Frappe?
// Handle more than 9 digits
// Make more like iOS

abstract class Processor {
  static int maxDigit = 9;
  static String _currentValue;
  static Stack<KeySymbol> _processStack = Stack();
  static int _size = 0;
  static bool _shouldCalculateProduct = false;
  static bool _haveEqualResult = false;
  static KeySymbol _currentOperator;
  static KeySymbol _currentIncrement;

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
    if (key.symbol != Keys.percent) refresh();
  }

  static String _calculate(
      KeySymbol valBSymbol, KeySymbol operatorSymbol, KeySymbol valASymbol) {
    String valA = (valASymbol == null || valASymbol.value == null)
        ? "0"
        : valASymbol.value;
    String valB = (valBSymbol == null || valBSymbol.value == null)
        ? valA
        : valBSymbol.value;

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

  static String _calculateIncrement(String value) {
    Map<KeySymbol, dynamic> table = {
      Keys.divide: (a, b) => (a / b),
      Keys.multiply: (a, b) => (a * b),
      Keys.subtract: (a, b) => (a - b),
      Keys.add: (a, b) => (a + b),
    };

    double result = table[_currentOperator](
        double.parse(value), double.parse(_currentIncrement.value));
    String str = result.toString();

    while ((str.contains('.') && str.endsWith('0')) || str.endsWith('.')) {
      str = str.substring(0, str.length - 1);
    }

    return str;
  }

  static void _sumUp() {
    while (_processStack.isNotEmpty) {
      _currentValue =
          _calculate(popFromStack(), popFromStack(), popFromStack());
      if (_processStack.isEmpty) break;
      pushToStack(KeySymbol(_currentValue));
    }
  }

  static void pushToStack(KeySymbol keySymbol) {
    _size++;
    _processStack.push(keySymbol);
  }

  static KeySymbol popFromStack() {
    if (_size == 0) return KeySymbol(null);

    _size--;
    return _processStack.pop();
  }

  static void clearStack() {
    while (_processStack.isNotEmpty) {
      _processStack.pop();
    }
    _size = 0;
  }

  static void _updateScreen() {
    refresh();
    _currentValue = null;
  }

  static void _equal() {
    _shouldCalculateProduct = false;

    // 1. empty or only have 1 element
    if (_size <= 1) {
      _currentValue = popFromStack().value;
      return;
    }

    // 2. top element is operator => self operation
    if (_processStack.top().isOperator) {
      KeySymbol topOperator = popFromStack();
      _currentValue = popFromStack().value;

      // if add or subtract
      if (topOperator == Keys.add || topOperator == Keys.subtract) {
        if (_currentOperator != topOperator) {
          _currentOperator = topOperator;
          _currentIncrement = KeySymbol(_currentValue);
        }

        _currentValue = _calculateIncrement(_currentValue);
      } else {
        // if multiply or divide
        // 2.1 size <= 2 e.g. 2 x = => 2 x 2 => 4 x 2
        // 2.2 size > 2 e.g. 1 + 2 x 2 x = => 1 + 4 x 4 => 17 x 4 => 68 x 4
        if (_size > 2) {
          _currentValue = _calculate(
              KeySymbol(_currentValue), popFromStack(), popFromStack());
        }

        if (_currentOperator != topOperator) {
          _currentOperator = topOperator;
          _currentIncrement = KeySymbol(_currentValue);
        }

        _currentValue = _calculateIncrement(_currentValue);

        if (_processStack.isNotEmpty) {
          _currentValue = _calculate(
              KeySymbol(_currentValue), popFromStack(), popFromStack());
        }
      }

      pushToStack(KeySymbol(_currentValue));
      pushToStack(_currentOperator);
      _updateScreen();

      return;
    }

    // 3. top element is digit
    _sumUp();
    refresh(); //we save the final result in _currentValue so don't need to clear it up
    _haveEqualResult = true;
  }

  static void _multiplyOrDivide(KeySymbol operator) {
    if (_shouldCalculateProduct) {
      _currentValue =
          _calculate(popFromStack(), popFromStack(), popFromStack());
      pushToStack(KeySymbol(_currentValue));
      _updateScreen();
    }

    _shouldCalculateProduct = true;
    pushToStack(operator);
  }

  static void _addOrSubtract(KeySymbol operator) {
    // if having valid equation, we have to calculate it first
    if (_size >= 3) {
      _sumUp();
      pushToStack(KeySymbol(_currentValue));
      _updateScreen();
    }

    _shouldCalculateProduct = false;
    pushToStack(operator);
  }

  static void handleOperator(CalculatorKey key) {
    if (_currentValue != null) {
      pushToStack(KeySymbol(_currentValue));
      _currentValue = null;
    }

    if (_processStack.isEmpty) return;

    KeySymbol operator = key.symbol;

    // if top stack is operator, we just need to replace the operator except equal operation
    if (_processStack.top().isOperator && operator != Keys.equals) {
      popFromStack();
      pushToStack(operator);
      return;
    }

    switch (operator) {
      case Keys.equals:
        _equal();
        break;
      case Keys.multiply:
      case Keys.divide:
        _multiplyOrDivide(operator);
        break;
      default:
        _addOrSubtract(operator);
        break;
    }
  }

  static void handleInteger(CalculatorKey key) {
    if (_haveEqualResult) {
      _currentValue = null;
      _haveEqualResult = false;
    }

    String val = key.symbol.value;

    _currentValue = (_currentValue == null) ? val : _currentValue + val;
    refresh();
  }

  static void _clear() {
    _currentValue = null;
    _shouldCalculateProduct = false;
    _currentIncrement = null;
    _currentOperator = null;
    clearStack();
  }

  static void _sign() {
    _currentValue = (_currentValue.contains('-')
        ? _currentValue.substring(1)
        : '-' + _currentValue);
  }

  static String calcPercent(String x) => (double.parse(x) / 100).toString();

  static void _percent() {
    if (_currentValue == null) return;

    _currentValue = calcPercent(_currentValue);
    refresh();
  }

  static void _decimal() {
    if (_currentValue == null) _currentValue = "0";

    if (!_currentValue.contains('.')) {
      _currentValue += '.';
    }
  }
}
