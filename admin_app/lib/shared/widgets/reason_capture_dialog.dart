import 'package:flutter/material.dart';

/// Presents a text-field dialog that collects a mandatory reason before a
/// sensitive admin action is confirmed.
///
/// Returns the trimmed reason string when the admin confirms, or `null` if
/// the dialog is cancelled or dismissed.
class ReasonCaptureDialog extends StatefulWidget {
  const ReasonCaptureDialog({
    super.key,
    required this.title,
    required this.actionLabel,
    this.hint = 'Describe the reason for this action…',
    this.warningText,
    this.minLength = 10,
  });

  final String title;
  final String actionLabel;
  final String hint;
  final String? warningText;
  final int minLength;

  /// Convenience constructor that shows the dialog and returns the result.
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String actionLabel,
    String hint = 'Describe the reason for this action…',
    String? warningText,
    int minLength = 10,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ReasonCaptureDialog(
        title: title,
        actionLabel: actionLabel,
        hint: hint,
        warningText: warningText,
        minLength: minLength,
      ),
    );
  }

  @override
  State<ReasonCaptureDialog> createState() => _ReasonCaptureDialogState();
}

class _ReasonCaptureDialogState extends State<ReasonCaptureDialog> {
  final _controller = TextEditingController();
  bool _valid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final valid = value.trim().length >= widget.minLength;
    if (valid != _valid) setState(() => _valid = valid);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.warningText != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.warningText!,
                  style: const TextStyle(color: Color(0xFF92400E)),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 3,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: widget.hint,
                helperText: 'Minimum ${widget.minLength} characters required.',
                border: const OutlineInputBorder(),
                errorText: _controller.text.isNotEmpty && !_valid
                    ? 'Too short — add more detail.'
                    : null,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _valid ? () => Navigator.of(context).pop(_controller.text.trim()) : null,
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}
