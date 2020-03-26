import 'package:flutter/material.dart';

class Display extends StatelessWidget {
  const Display({Key key, this.value, this.height}) : super(key: key);

  final String value;
  final double height;

  String get _output => value.toString();
  double get _margin => (height / 10);

  @override
  Widget build(BuildContext context) {
    TextStyle style = Theme.of(context).textTheme.headline2.copyWith(
        color: Colors.white, fontWeight: FontWeight.w300, fontSize: 55);

    return Container(
      padding: EdgeInsets.only(top: _margin, bottom: _margin),
      constraints: BoxConstraints.expand(height: height),
      child: Container(
        padding: EdgeInsets.only(left: 32, right: 32),
        constraints: BoxConstraints.expand(height: height - (_margin)),
        alignment: Alignment.bottomRight,
        child: Text(
          _output,
          style: style,
          maxLines: 1,
          textAlign: TextAlign.right,
        ),
      ),
    );
  }
}
