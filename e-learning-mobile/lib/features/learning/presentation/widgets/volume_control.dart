import 'package:flutter/material.dart';

/// Applies volume serially so an older platform command cannot win a drag race.
class VolumeControl extends StatefulWidget {
  const VolumeControl({
    super.key,
    required this.volume,
    required this.onChanged,
    this.onInteractionChanged,
  });
  final double volume;
  final Future<void> Function(double) onChanged;
  final ValueChanged<bool>? onInteractionChanged;

  @override
  State<VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends State<VolumeControl> {
  Future<void> _open() async {
    widget.onInteractionChanged?.call(true);
    try {
      await showDialog<void>(
        context: context,
        builder: (_) =>
            _VolumeDialog(initial: widget.volume, apply: widget.onChanged),
      );
    } finally {
      if (mounted) widget.onInteractionChanged?.call(false);
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Âm lượng',
    padding: const EdgeInsets.all(3),
    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
    onPressed: _open,
    icon: Icon(
      widget.volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
      color: Colors.white,
      size: 18,
    ),
  );
}

class _VolumeDialog extends StatefulWidget {
  const _VolumeDialog({required this.initial, required this.apply});
  final double initial;
  final Future<void> Function(double) apply;
  @override
  State<_VolumeDialog> createState() => _VolumeDialogState();
}

class _VolumeDialogState extends State<_VolumeDialog> {
  late double _confirmed = widget.initial.clamp(0, 1);
  double? _pending;
  bool _applying = false;
  String? _error;

  Future<void> _change(double value) async {
    _pending = value;
    if (_applying) return;
    _applying = true;
    while (_pending != null && mounted) {
      final next = _pending!;
      _pending = null;
      try {
        await widget.apply(next);
        if (mounted) {
          setState(() {
            _confirmed = next;
            _error = null;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => _error = 'Không thể đổi âm lượng. Vui lòng thử lại.');
        }
      }
    }
    _applying = false;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Âm lượng ${(_confirmed * 100).round()}%'),
    content: SizedBox(
      width: 280,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: _confirmed,
            onChanged: _change,
            semanticFormatterCallback: (v) => '${(v * 100).round()}%',
          ),
          if (_error != null) Text(_error!),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Đóng'),
      ),
    ],
  );
}
