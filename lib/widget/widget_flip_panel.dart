import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animations/utils.dart';

/// A widget for flip panel with built-in animation
/// Content of the panel is built from [IndexedItemBuilder] or [StreamItemBuilder]
///
/// Note: the content size should be equal

class WidgetFlipPanel<T> extends StatefulWidget {
  const WidgetFlipPanel({
    super.key,
    this.indexedItemBuilder,
    this.streamItemBuilder,
    this.itemStream,
    this.itemCount,
    this.period,
    this.duration,
    this.loop,
    this.startIndex,
    this.initValue,
    this.spacing,
    this.direction,
  });

  final IndexedItemBuilder? indexedItemBuilder;
  final StreamItemBuilder<T>? streamItemBuilder;
  final Stream<T>? itemStream;
  final int? itemCount;
  final Duration? period;
  final Duration? duration;
  final int? loop;
  final int? startIndex;
  final T? initValue;
  final double? spacing;
  final FlipDirection? direction;

  /// Create a flip panel from iterable source
  /// [itemBuilder] is called periodically in each time of [period]
  /// The animation is looped in [loop] times before finished.
  /// Setting [loop] to -1 makes flip animation run forever.
  /// The [period] should be two times greater than [duration] of flip animation,
  /// if not the animation becomes jerky/stuttery.
  WidgetFlipPanel.builder({
    super.key,
    @required IndexedItemBuilder? itemBuilder,
    @required this.itemCount,
    @required this.period,
    this.duration = const Duration(milliseconds: 500),
    this.loop = 1,
    this.startIndex = 0,
    this.spacing = 0.5,
    this.direction = FlipDirection.up,
  }) : assert(itemBuilder != null),
       assert(itemCount != null),
       assert(startIndex! < itemCount!),
       assert(period == null || period.inMilliseconds >= 2 * duration!.inMilliseconds),
       indexedItemBuilder = itemBuilder,
       streamItemBuilder = null,
       itemStream = null,
       initValue = null;

  /// Create a flip panel from stream source
  /// [itemBuilder] is called whenever a new value is emitted from [itemStream]
  const WidgetFlipPanel.stream({
    super.key,
    @required this.itemStream,
    @required StreamItemBuilder<T>? itemBuilder,
    this.initValue,
    this.duration = const Duration(milliseconds: 1000),
    this.spacing = 0.5,
    this.direction = FlipDirection.up,
  }) : assert(itemStream != null),
       indexedItemBuilder = null,
       streamItemBuilder = itemBuilder,
       itemCount = 0,
       period = null,
       loop = 0,
       startIndex = 0;

  @override
  State<WidgetFlipPanel> createState() => _WidgetFlipPanelState<T>();
}

class _WidgetFlipPanelState<T> extends State<WidgetFlipPanel> with TickerProviderStateMixin {
  AnimationController? acFlipPanel;
  Animation? flipAnimation;
  int? currentIndex;
  bool? isReversePhase;
  bool? isStreamMode;
  bool? running;
  final perspective = 0.003;
  final zeroAngle = 0.0001;
  int loop = 0;
  T? currentValue, nextValue;
  Timer? timer;
  StreamSubscription<T>? subscription;

  Widget? child1, child2;
  Widget? upperChild1, upperChild2;
  Widget? lowerChild1, lowerChild2;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.startIndex;
    isStreamMode = widget.itemStream != null;
    isReversePhase = false;
    running = false;
    loop = 0;

    acFlipPanel =
        AnimationController(vsync: this, duration: widget.duration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              isReversePhase = true;
              acFlipPanel!.reverse();
            }
            if (status == AnimationStatus.dismissed) {
              currentValue = nextValue;
              running = false;
            }
          })
          ..addListener(() {
            setState(() {
              running = true;
            });
          });

    flipAnimation = Tween(begin: zeroAngle, end: math.pi / 2).animate(acFlipPanel!);

    if (widget.period != null) {
      timer = Timer.periodic(widget.period!, (_) {
        if (widget.loop! < 0 || loop < widget.loop!) {
          if (currentIndex! + 1 == widget.itemCount! - 2) {
            loop++;
          }
          currentIndex = (currentIndex! + 1) % widget.itemCount!;
          child1 = null;
          isReversePhase = false;
          acFlipPanel!.forward();
        } else {
          timer!.cancel();
          currentIndex = (currentIndex! + 1) % widget.itemCount!;
          setState(() {
            running = false;
          });
        }
      });
    }

    if (isStreamMode!) {
      currentValue = widget.initValue;
      subscription =
          widget.itemStream!.distinct().listen((value) {
                if (currentValue == null) {
                  currentValue = value;
                } else if (value != currentValue) {
                  nextValue = value;
                  child1 = null;
                  isReversePhase = false;
                  acFlipPanel!.forward();
                }
              })
              as StreamSubscription<T>;
    } else if (widget.loop! < 0 || loop < widget.loop!) {
      acFlipPanel!.forward();
    }
  }

  @override
  void dispose() {
    acFlipPanel!.dispose();
    if (subscription != null) subscription!.cancel();
    if (timer != null) timer!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    buildChildWidgetIfNeeded(context);
    return buildPanel();
  }

  void buildChildWidgetIfNeeded(BuildContext context) {
    Widget makeUpperClip(Widget widget) {
      return ClipRect(child: Align(alignment: Alignment.topCenter, heightFactor: 0.5, child: widget));
    }

    Widget makeLowerClip(Widget widget) {
      return ClipRect(child: Align(alignment: Alignment.bottomCenter, heightFactor: 0.5, child: widget));
    }

    if (running!) {
      if (child1 == null) {
        child1 =
            child2 ??
            (isStreamMode!
                ? widget.streamItemBuilder!(context, currentValue)
                : widget.indexedItemBuilder!(context, currentIndex! % widget.itemCount!));
        child2 = null;
        upperChild1 = upperChild2 ?? makeUpperClip(child1!);
        lowerChild1 = lowerChild2 ?? makeLowerClip(child1!);
      }

      if (child2 == null) {
        child2 =
            isStreamMode!
                ? widget.streamItemBuilder!(context, nextValue)
                : widget.indexedItemBuilder!(context, (currentIndex! + 1) % widget.itemCount!);
        upperChild2 = makeUpperClip(child2!);
        lowerChild2 = makeLowerClip(child2!);
      }
    } else {
      child1 =
          child2 ??
          (isStreamMode!
              ? widget.streamItemBuilder!(context, currentValue)
              : widget.indexedItemBuilder!(context, currentIndex! % widget.itemCount!));
      upperChild1 = upperChild2 ?? makeUpperClip(child1!);
      lowerChild1 = lowerChild2 ?? makeLowerClip(child1!);
    }
  }

  Widget buildUpperFlipPanel() =>
      widget.direction == FlipDirection.up
          ? Stack(
            children: [
              Transform(
                alignment: Alignment.bottomCenter,
                transform:
                    Matrix4.identity()
                      ..setEntry(3, 2, perspective)
                      ..rotateX(zeroAngle),
                child: upperChild1,
              ),
              Transform(
                alignment: Alignment.bottomCenter,
                transform:
                    Matrix4.identity()
                      ..setEntry(3, 2, perspective)
                      ..rotateX(isReversePhase! ? flipAnimation!.value : math.pi / 2),
                child: upperChild2,
              ),
            ],
          )
          : Stack(
            children: [
              Transform(
                alignment: Alignment.bottomCenter,
                transform:
                    Matrix4.identity()
                      ..setEntry(3, 2, perspective)
                      ..rotateX(zeroAngle),
                child: upperChild2,
              ),
              Transform(
                alignment: Alignment.bottomCenter,
                transform:
                    Matrix4.identity()
                      ..setEntry(3, 2, perspective)
                      ..rotateX(isReversePhase! ? math.pi / 2 : flipAnimation!.value),
                child: upperChild1,
              ),
            ],
          );

  Widget buildLowerFlipPanel() =>
      widget.direction == FlipDirection.up
          ? Stack(
            children: [
              Transform(
                alignment: Alignment.topCenter,
                transform:
                    Matrix4.identity()
                      ..setEntry(3, 2, perspective)
                      ..rotateX(zeroAngle),
                child: lowerChild2,
              ),
              Transform(
                alignment: Alignment.topCenter,
                transform:
                    Matrix4.identity()
                      ..setEntry(3, 2, perspective)
                      ..rotateX(isReversePhase! ? math.pi / 2 : flipAnimation!.value),
                child: lowerChild1,
              ),
            ],
          )
          : Stack(
            children: [
              Transform(
                alignment: Alignment.topCenter,
                transform:
                    Matrix4.identity()
                      ..setEntry(3, 2, perspective)
                      ..rotateX(zeroAngle),
                child: lowerChild1,
              ),
              Transform(
                alignment: Alignment.topCenter,
                transform:
                    Matrix4.identity()
                      ..setEntry(3, 2, perspective)
                      ..rotateX(isReversePhase! ? flipAnimation!.value : math.pi / 2),
                child: lowerChild2,
              ),
            ],
          );

  Widget buildPanel() {
    return running!
        ? Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            buildUpperFlipPanel(),
            Padding(padding: EdgeInsets.only(top: widget.spacing!)),
            buildLowerFlipPanel(),
          ],
        )
        : isStreamMode! && currentValue == null
        ? Container()
        : Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Transform(
              alignment: Alignment.bottomCenter,
              transform:
                  Matrix4.identity()
                    ..setEntry(3, 2, perspective)
                    ..rotateX(zeroAngle),
              child: upperChild1,
            ),
            Padding(padding: EdgeInsets.only(top: widget.spacing!)),
            Transform(
              alignment: Alignment.topCenter,
              transform:
                  Matrix4.identity()
                    ..setEntry(3, 2, perspective)
                    ..rotateX(zeroAngle),
              child: lowerChild1,
            ),
          ],
        );
  }
}
