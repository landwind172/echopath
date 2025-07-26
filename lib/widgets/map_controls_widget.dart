import 'package:flutter/material.dart';

class HelpSectionWidget extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const HelpSectionWidget({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}

class MapControlsWidget extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onCurrentLocation;

  const MapControlsWidget({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onCurrentLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26), // 0.1 opacity = 26/255 alpha
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Zoom in button
          _buildControlButton(
            context: context,
            icon: Icons.add,
            onTap: onZoomIn,
            tooltip: 'Zoom In',
          ),
          const Divider(height: 1, thickness: 1),
          // Zoom out button
          _buildControlButton(
            context: context,
            icon: Icons.remove,
            onTap: onZoomOut,
            tooltip: 'Zoom Out',
          ),
          const Divider(height: 1, thickness: 1),
          // Current location button
          _buildControlButton(
            context: context,
            icon: Icons.my_location,
            onTap: onCurrentLocation,
            tooltip: 'Current Location',
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
        ),
      ),
    );
  }
}