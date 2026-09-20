import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';

/// Shared form controls so every screen's dialogs look and behave the same.

InputDecoration adminInput(String label, {String? hint, Widget? suffix}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    suffixIcon: suffix,
    labelStyle: const TextStyle(color: AdminColors.textMuted, fontSize: 12),
    hintStyle: const TextStyle(color: AdminColors.textMuted, fontSize: 12),
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
  );
}

class AdminTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;

  const AdminTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: AdminColors.textPrimary, fontSize: 13),
        decoration: adminInput(label, hint: hint),
      ),
    );
  }
}

class AdminDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const AdminDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Guard against a value that is not in the list, which throws.
    final values = items.map((i) => i.value).toSet();
    final safe = values.contains(value) ? value : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: safe,
        isExpanded: true,
        dropdownColor: AdminColors.surfaceDark,
        style: const TextStyle(color: AdminColors.textPrimary, fontSize: 13),
        decoration: adminInput(label),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}

/// Builds dropdown entries from a list of API records.
List<DropdownMenuItem<String>> itemsFrom(
  List<dynamic> records, {
  List<String> labelKeys = const ['nameEn', 'name', 'code', 'registrationCode'],
}) {
  return records.map<DropdownMenuItem<String>>((r) {
    String label = 'Unnamed';
    for (final k in labelKeys) {
      final v = r[k];
      if (v != null && v.toString().trim().isNotEmpty) {
        label = v.toString();
        break;
      }
    }
    return DropdownMenuItem<String>(
      value: r['id']?.toString(),
      child: Text(label, overflow: TextOverflow.ellipsis),
    );
  }).toList();
}

/// A consistent dialog shell with Cancel / Save buttons.
Future<void> showAdminDialog({
  required BuildContext context,
  required String title,
  required Widget content,
  required Future<void> Function() onSave,
  String saveLabel = 'Save',
  double width = 460,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AdminColors.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title,
          style: const TextStyle(color: AdminColors.textPrimary, fontSize: 16)),
      content: SizedBox(
        width: width,
        child: SingleChildScrollView(child: content),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel',
              style: TextStyle(color: AdminColors.textMuted)),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await onSave();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.primary,
            foregroundColor: Colors.black,
          ),
          child: Text(saveLabel),
        ),
      ],
    ),
  );
}

/// Confirmation before anything destructive.
Future<bool> confirmDelete(BuildContext context, String what) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AdminColors.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete',
          style: TextStyle(color: AdminColors.textPrimary, fontSize: 16)),
      content: Text('Delete $what? This cannot be undone.',
          style: const TextStyle(color: AdminColors.textSecondary, fontSize: 13)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel',
              style: TextStyle(color: AdminColors.textMuted)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.error,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? AdminColors.error : AdminColors.success,
      duration: Duration(seconds: error ? 6 : 3),
    ),
  );
}

/// The empty / error / loading states every list screen needs, so a failed
/// request stops looking identical to "there is nothing here".
class ListState extends StatelessWidget {
  final bool loading;
  final String? error;
  final bool empty;
  final String emptyMessage;
  final VoidCallback onRetry;
  final Widget child;

  const ListState({
    super.key,
    required this.loading,
    required this.error,
    required this.empty,
    required this.emptyMessage,
    required this.onRetry,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: AdminColors.primary),
      );
    }
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AdminColors.error, size: 40),
            const SizedBox(height: 12),
            Text(error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AdminColors.error, fontSize: 13)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.primary,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      );
    }
    if (empty) {
      return Center(
        child: Text(emptyMessage,
            style: const TextStyle(color: AdminColors.textMuted, fontSize: 13)),
      );
    }
    return child;
  }
}

/// A dismissible-looking banner shown above a list when its load failed, so an
/// error stops being indistinguishable from "there is nothing here".
class ErrorBanner extends StatelessWidget {
  final String? error;
  final VoidCallback onRetry;

  const ErrorBanner({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (error == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(28, 12, 28, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AdminColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.error),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AdminColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error!,
              style: const TextStyle(color: AdminColors.error, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: AdminColors.error),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
