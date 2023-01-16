

import 'package:flutter/material.dart';

class LongTapSlider extends StatefulWidget {
  final Widget child;
  final VoidCallback actionCallback;
  final Icon actionIcon;

  const LongTapSlider({Key? key, required this.child, required this.actionCallback, required this.actionIcon}) : super(key: key);

  @override
  State<LongTapSlider> createState() => _LongTapSliderState();
}

class _LongTapSliderState extends State<LongTapSlider> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _animation;
  bool isForward = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _animation = Tween<Offset>(
      begin: const Offset(0.0, 0.0),
      end: const Offset(-0.1, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInCubic,
    ));
  }

  void startAnimation(bool forward) {
    if(isForward == forward) {
      return;
    }
    isForward = forward;
    if(isForward) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () { widget.actionCallback(); },
              icon: widget.actionIcon,
            ),
          ),
        ),
        GestureDetector(
          onLongPress: () {
            setState(() { startAnimation(!isForward); });
          },
          onTap: () {
            if(isForward) {
              setState(() { startAnimation(!isForward); });
            }
          },
          child: SlideTransition(
            position: _animation,
            child: widget.child,
          ),
        ),
      ]
    );
  }
}
