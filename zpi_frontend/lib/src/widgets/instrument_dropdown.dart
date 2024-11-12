import 'package:flutter/material.dart';

class InstrumentDropdown extends StatefulWidget {
  @override
  _InstrumentDropdownState createState() => _InstrumentDropdownState();
}

class _InstrumentDropdownState extends State<InstrumentDropdown> {
  final List<String> items = ['flute', 'trumpet', 'piano', 'violin'];
  String? selectedItem;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedItem,
      hint: const Text("Select an instrument"),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          selectedItem = newValue;
        });
      },
      decoration: InputDecoration(
        labelText: "Select instrument",
        border: OutlineInputBorder(),
      ),
    );
  }
}
