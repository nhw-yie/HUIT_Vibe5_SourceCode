import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddressSearchField extends StatefulWidget {
  final TextEditingController controller;
  final Function(double lat, double lng) onSelected;
  final String labelText;
  final Icon prefixIcon;

  const AddressSearchField({
    super.key,
    required this.controller,
    required this.onSelected,
    required this.labelText,
    required this.prefixIcon,
  });

  @override
  State<AddressSearchField> createState() => _AddressSearchFieldState();
}

class _AddressSearchFieldState extends State<AddressSearchField> {
  List<Map<String, dynamic>> suggestions = [];
  Timer? _debounce;

  void fetchSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() => suggestions = []);
      return;
    }

    try {
      final url =
          'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&addressdetails=1&limit=5&countrycodes=vn';
      final res = await http.get(Uri.parse(url));
      final data = json.decode(res.body) as List;
      setState(() {
        suggestions = data.map((e) => e as Map<String, dynamic>).toList();
      });
    } catch (e) {
      setState(() => suggestions = []);
    }
  }

  void onChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      fetchSuggestions(value);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: widget.labelText,
            prefixIcon: widget.prefixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          onChanged: onChanged,
        ),
        if (suggestions.isNotEmpty)
          Container(
            color: Colors.white,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final item = suggestions[index];
                return ListTile(
                  title: Text(item['display_name']),
                  onTap: () {
                    widget.controller.text = item['display_name'];
                    suggestions = [];
                    widget.onSelected(
                      double.parse(item['lat']),
                      double.parse(item['lon']),
                    );
                    setState(() {});
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
