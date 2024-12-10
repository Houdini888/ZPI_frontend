import 'package:flutter/material.dart';
import 'package:zpi_frontend/src/services/websocket_iconservice.dart';

class IconSelector extends StatefulWidget {
  final String username;
  final String group;
  final String device;
  final bool isAdmin;

  const IconSelector({
    Key? key,
    required this.username,
    required this.group,
    required this.device,
    required this.isAdmin,
  }) : super(key: key);

  @override
  _IconSelectorState createState() => _IconSelectorState();
}

class _IconSelectorState extends State<IconSelector> {
  late WebSocket_IconService _wsService;
  Set<String> _selectedSymbols = {};

  @override
  void initState() {
    super.initState();
    _wsService = WebSocket_IconService(
      username: widget.username,
      group: widget.group,
      device: widget.device,
    );

    _wsService.symbolStream.listen((symbolString) {
      setState(() {
        // Parse the received symbol string (e.g., "ds,koda") into a set
        if (symbolString == null || symbolString.isEmpty) {
          _selectedSymbols = {};
        } else {
          _selectedSymbols =
              symbolString.split(',').where((s) => s.isNotEmpty).toSet();
        }
      });
    });
  }

  @override
  void dispose() {
    _wsService.close();
    super.dispose();
  }

  void _toggleSymbol(String symbol) {
    if (!widget.isAdmin) return;

    setState(() {
      if (_selectedSymbols.contains(symbol)) {
        _selectedSymbols.remove(symbol);
      } else {
        _selectedSymbols.add(symbol);
      }
    });
    // Send updated selection as a comma-separated string
    _wsService.sendSymbol(_selectedSymbols.join(','));
  }

  @override
  Widget build(BuildContext context) {
    final bool dsSelected = _selectedSymbols.contains("ds");
    final bool kodaSelected = _selectedSymbols.contains("koda");

    // Admin View: Show both symbols, allow toggling, indicate selection
    if (widget.isAdmin) {
      Widget dsWidget = _buildSelectableSymbol(
        imagePath: 'assets/images/ds.png',
        isSelected: dsSelected,
        onTap: () => _toggleSymbol("ds"),
      );

      Widget kodaWidget = _buildSelectableSymbol(
        imagePath: 'assets/images/koda.png',
        isSelected: kodaSelected,
        onTap: () => _toggleSymbol("koda"),
      );

      return Container(
        width: 120, // Fixed width
        height: 60, // Fixed height
        padding: const EdgeInsets.all(6.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade200, // Optional: Light grey background
          border: Border.all(color: Colors.grey, width: 1.0), // Thin grey border
          borderRadius: BorderRadius.circular(8.0), // Rounded corners
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Wrap tightly around children
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            dsWidget,
            const SizedBox(width: 10), // Reduced spacing for compactness
            kodaWidget,
          ],
        ),
      );
    } else {
      // Non-Admin View: Show only selected symbols
      List<Widget> visibleSymbols = [];
      if (dsSelected) {
        visibleSymbols.add(_buildNonAdminSymbol('assets/images/ds.png'));
      }
      if (kodaSelected) {
        visibleSymbols.add(_buildNonAdminSymbol('assets/images/koda.png'));
      }

      return Container(
        width: 120, // Fixed width
        height: 60, // Fixed height
        padding: const EdgeInsets.all(6.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade200, // Optional: Light grey background
          border: Border.all(color: Colors.grey, width: 1.0), // Thin grey border
          borderRadius: BorderRadius.circular(8.0), // Rounded corners
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: visibleSymbols.isNotEmpty
                ? visibleSymbols
                    .map((w) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: w,
                        ))
                    .toList()
                : [
                    // Optionally, you can add a placeholder icon or leave it empty
                    // Example placeholder:
                    Icon(
                      Icons.music_note,
                      color: Colors.grey.shade400,
                      size: 40,
                    ),
                  ],
          ),
        ),
      );
    }
  }

  // Builds a symbol widget for admin with selectable state
  Widget _buildSelectableSymbol({
    required String imagePath,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          border: isSelected
              ? Border.all(color: Colors.blue, width: 2.0)
              : null, // Blue border if selected
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.all(2.0),
        child: Opacity(
          opacity: isSelected ? 1.0 : 0.4, // More transparent if not selected
          child: Image.asset(
            imagePath,
            width: 40, // Adjusted size for compactness
            height: 40,
          ),
        ),
      ),
    );
  }

  // Builds a symbol widget for non-admin users (no interaction)
  Widget _buildNonAdminSymbol(String imagePath) {
    return Image.asset(
      imagePath,
      width: 40, // Adjusted size for compactness
      height: 40,
    );
  }
}
