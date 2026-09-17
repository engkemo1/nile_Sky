import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';

/// Balloons, pilots and drivers all belong to an operator, and the backend
/// rejects a create without `operatorId`. This is the shared picker for it.
class OperatorPicker extends StatelessWidget {
  final List<dynamic> operators;
  final String? value;
  final ValueChanged<String?> onChanged;

  const OperatorPicker({
    super.key,
    required this.operators,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        dropdownColor: AdminColors.surfaceDark,
        style: const TextStyle(color: AdminColors.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          labelText: 'Operator',
          labelStyle: const TextStyle(color: AdminColors.textMuted, fontSize: 12),
          filled: true,
          fillColor: AdminColors.surfaceDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AdminColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AdminColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AdminColors.primary),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        items: operators
            .map<DropdownMenuItem<String>>((o) => DropdownMenuItem<String>(
                  value: o['id']?.toString(),
                  child: Text(
                    (o['nameEn'] ?? o['name'] ?? 'Unnamed').toString(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
