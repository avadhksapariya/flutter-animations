import 'dart:math' as math;

import 'package:flutter/material.dart';

class ScreenFlippingCard extends StatefulWidget {
  const ScreenFlippingCard({super.key});

  @override
  State<ScreenFlippingCard> createState() => _ScreenFlippingCardState();
}

class _ScreenFlippingCardState extends State<ScreenFlippingCard> with SingleTickerProviderStateMixin {
  late AnimationController acFlippingCard;
  late Animation<double> cardAnimation;

  @override
  void initState() {
    super.initState();
    acFlippingCard = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(acFlippingCard);

    acFlippingCard.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        acFlippingCard.reverse();
      } else if (status == AnimationStatus.dismissed) {
        acFlippingCard.forward();
      }
    });

    acFlippingCard.forward();
  }

  @override
  void dispose() {
    acFlippingCard.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: cardAnimation,
            builder: (context, child) {
              return Transform(
                alignment: Alignment.center,
                transform:
                    Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(cardAnimation.value * math.pi),
                child: child,
              );
            },
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5.0),
                gradient: LinearGradient(
                  colors: [Colors.blueGrey, Colors.grey],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
