import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animations/widget/widget_flip_panel.dart';

class ScreenPaperFlip extends StatefulWidget {
  const ScreenPaperFlip({super.key});

  @override
  State<ScreenPaperFlip> createState() => _ScreenPaperFlipState();
}

class _ScreenPaperFlipState extends State<ScreenPaperFlip> {
  final digits = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Paper Flip")),
      body: SafeArea(
        child: Center(
          child: WidgetFlipPanel.builder(
            itemBuilder: (context, index) {
              return Container(
                alignment: Alignment.center,
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.primaries[Random().nextInt(15)],
                  borderRadius: BorderRadius.all(Radius.circular(4.0)),
                ),
                child: Text('${digits[index]}'),
              );
            },
            itemCount: digits.length,
            period: Duration(milliseconds: 1000),
            loop: -1,
          ),
        ),
      ),
    );
  }
}
