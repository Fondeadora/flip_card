library flip_card;

import 'dart:math';
import 'package:flip_card/flip_card_controller.dart';
import 'package:flutter/material.dart';

enum FlipOrientation {
  VERTICAL,
  HORIZONTAL,
}
enum FlipDirection {
  CLOCKWISE,
  COUNTER_CLOCKWISE,
}

enum CardSide {
  FRONT,
  BACK,
}

enum Fill { none, fillFront, fillBack }

class AnimationCard extends StatelessWidget {
  AnimationCard({this.child, this.animation, this.orientation});

  final Widget? child;
  final Animation<double>? animation;
  final FlipOrientation? orientation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation!,
      builder: (BuildContext context, Widget? child) {
        var transform = Matrix4.identity();
        transform.setEntry(3, 2, 0.001);
        if (orientation == FlipOrientation.VERTICAL) {
          transform.rotateX(animation!.value);
        } else {
          transform.rotateY(animation!.value);
        }
        return Transform(
          transform: transform,
          alignment: Alignment.center,
          child: child,
        );
      },
      child: child,
    );
  }
}

typedef void BoolCallback(bool isFront);

class FlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;

  /// The amount of milliseconds a turn animation will take.
  final int speed;
  final FlipOrientation orientation;
  final FlipDirection direction;
  final VoidCallback? onFlip;
  final BoolCallback? onFlipDone;
  final FlipCardController? controller;
  final Fill fill;

  /// When enabled, the card will flip automatically when touched. This behavior
  /// can be disabled if this is not desired. To manually flip a card from your
  /// code, you could do this:
  ///```dart
  /// GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();
  ///
  /// @override
  /// Widget build(BuildContext context) {
  ///   return FlipCard(
  ///     key: cardKey,
  ///     flipOnTouch: false,
  ///     front: Container(
  ///       child: RaisedButton(
  ///         onPressed: () => cardKey.currentState.toggleCard(),
  ///         child: Text('Toggle'),
  ///       ),
  ///     ),
  ///     back: Container(
  ///       child: Text('Back'),
  ///     ),
  ///   );
  /// }
  ///```
  final bool flipOnTouch;

  final Alignment alignment;

  const FlipCard({
    Key? key,
    required this.front,
    required this.back,
    this.speed = 500,
    this.onFlip,
    this.onFlipDone,
    this.orientation = FlipOrientation.HORIZONTAL,
    this.direction = FlipDirection.CLOCKWISE,
    this.controller,
    this.flipOnTouch = true,
    this.alignment = Alignment.center,
    this.fill = Fill.none,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return FlipCardState();
  }
}

class FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  AnimationController? controller;
  Animation<double>? _frontRotationCW;
  Animation<double>? _frontRotationCCW;
  Animation<double>? _backRotationCW;
  Animation<double>? _backRotationCCW;
  Animation<double>? _wiggle;
  Animation<double>? _wiggleBack;

  bool isFront = true;
  bool isWiggle = false;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        duration: Duration(milliseconds: widget.speed), vsync: this);

    _frontRotationCW = TweenSequence(
      [
        TweenSequenceItem<double>(
          tween: Tween(begin: 0.0, end: pi / 2)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 50.0,
        ),
        TweenSequenceItem<double>(
          tween: ConstantTween<double>(pi / 2),
          weight: 50.0,
        ),
      ],
    ).animate(controller!);

    _frontRotationCCW = TweenSequence(
      [
        TweenSequenceItem<double>(
          tween: Tween(begin: 0.0, end: -pi / 2)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 50.0,
        ),
        TweenSequenceItem<double>(
          tween: ConstantTween<double>(-pi / 2),
          weight: 50.0,
        ),
      ],
    ).animate(controller!);

    _backRotationCW = TweenSequence(
      [
        TweenSequenceItem<double>(
          tween: ConstantTween<double>(-pi / 2),
          weight: 50.0,
        ),
        TweenSequenceItem<double>(
          tween: Tween(begin: -pi / 2, end: 0.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 50.0,
        ),
      ],
    ).animate(controller!);

    _backRotationCCW = TweenSequence(
      [
        TweenSequenceItem<double>(
          tween: ConstantTween<double>(pi / 2),
          weight: 50.0,
        ),
        TweenSequenceItem<double>(
          tween: Tween(begin: pi / 2, end: 0.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 50.0,
        ),
      ],
    ).animate(controller!);

    _wiggle = TweenSequence(
      [
        TweenSequenceItem<double>(
          tween: Tween(begin: 0.0, end: -pi / 8)
              .chain(CurveTween(curve: Curves.easeInOutCubic)),
          weight: 50.0,
        ),
        TweenSequenceItem<double>(
          tween: Tween(begin: -pi / 8, end: pi / 8)
              .chain(CurveTween(curve: Curves.easeInOutCubic)),
          weight: 50.0,
        ),
        TweenSequenceItem<double>(
          tween: Tween(begin: pi / 8, end: 0.0)
              .chain(CurveTween(curve: Curves.easeInOutCubic)),
          weight: 50.0,
        ),
      ],
    ).animate(controller!);

    _wiggleBack = TweenSequence(
      [
        TweenSequenceItem<double>(
          tween: ConstantTween<double>(pi / 2),
          weight: 50.0,
        ),
      ],
    ).animate(controller!);

    controller!.addStatusListener((status) {
      if ((status == AnimationStatus.completed ||
              status == AnimationStatus.dismissed) &&
          !isWiggle) {
        if (widget.onFlipDone != null) widget.onFlipDone!(isFront);
        setState(() {
          isFront = !isFront;
        });
      }
    });

    widget.controller?.state = this;
  }

  void toggleCard() {
    isWiggle = false;

    if (widget.onFlip != null) {
      widget.onFlip!();
    }

    controller!.duration = Duration(milliseconds: widget.speed);
    if (isFront) {
      controller!.forward();
    } else {
      controller!.reverse();
    }
  }

  Future<void> wiggle(Duration? duration) async {
    setState(() {
      isWiggle = true;
    });

    controller!.duration = duration ?? Duration(milliseconds: widget.speed);

    controller!.reset();
    final animation = controller!.forward();
    animation.whenComplete(() {
      controller!.value = isFront ? 0.0 : 1.0;
      setState(() {
        isWiggle = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final frontPositioning = widget.fill == Fill.fillFront ? _fill : _noop;
    final backPositioning = widget.fill == Fill.fillBack ? _fill : _noop;

    final child = Stack(
      alignment: widget.alignment,
      fit: StackFit.passthrough,
      children: <Widget>[
        frontPositioning(_buildContent(front: true)),
        backPositioning(_buildContent(front: false)),
      ],
    );

    /// if we need to flip the card on taps, wrap the content
    if (widget.flipOnTouch) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: toggleCard,
        child: child,
      );
    }
    return child;
  }

  Widget _buildContent({required bool front}) {
    /// pointer events that would reach the backside of the card should be
    /// ignored
    return IgnorePointer(
      /// absorb the front card when the background is active (!isFront),
      /// absorb the background when the front is active
      ignoring: front ? !isFront : isFront,
      child: AnimationCard(
        animation: !isWiggle
            ? front
                ? widget.direction == FlipDirection.CLOCKWISE
                    ? _frontRotationCW
                    : _frontRotationCCW
                : widget.direction == FlipDirection.CLOCKWISE
                    ? _backRotationCW
                    : _backRotationCCW
            : isFront
                ? front
                    ? _wiggle
                    : _wiggleBack
                : front
                    ? _wiggleBack
                    : _wiggle,
        child: front ? widget.front : widget.back,
        orientation: widget.orientation,
      ),
    );
  }

  @override
  void dispose() {
    controller!.dispose();
    super.dispose();
  }
}

Widget _fill(Widget child) => Positioned.fill(child: child);
Widget _noop(Widget child) => child;
