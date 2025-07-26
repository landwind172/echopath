import 'package:flutter/material.dart';

class VoiceCommandButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String tooltip;
  final IconData icon;

  const VoiceCommandButton({
    super.key,
    required this.onPressed,
    required this.tooltip,
    this.icon = Icons.volume_up,
  });

  @override
  State<VoiceCommandButton> createState() => _VoiceCommandButtonState();
}

class _VoiceCommandButtonState extends State<VoiceCommandButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          border: Border.all(color: Theme.of(context).primaryColor, width: 2),
        ),
        child: IconButton(
          onPressed: () {
            _animationController.forward().then((_) {
              _animationController.reverse();
            });
            widget.onPressed();
          },
          icon: Icon(widget.icon, color: Theme.of(context).primaryColor),
          tooltip: widget.tooltip,
          iconSize: 32,
        ),
      ),
    );
  }
}
