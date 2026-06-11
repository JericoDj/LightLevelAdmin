import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WaitingTimeWidget extends StatefulWidget {
  final Timestamp? queuedAt;
  final TextStyle? style;

  const WaitingTimeWidget({Key? key, this.queuedAt, this.style}) : super(key: key);

  @override
  _WaitingTimeWidgetState createState() => _WaitingTimeWidgetState();
}

class _WaitingTimeWidgetState extends State<WaitingTimeWidget> {
  Timer? _timer;
  String _waitingTime = "0m 0s";

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    if (widget.queuedAt == null) {
      if (mounted) {
        setState(() {
          _waitingTime = "Unknown";
        });
      }
      return;
    }

    final now = DateTime.now();
    final queuedTime = widget.queuedAt!.toDate();
    final difference = now.difference(queuedTime);

    if (difference.isNegative) {
      if (mounted) setState(() => _waitingTime = "0m 0s");
      return;
    }

    final minutes = difference.inMinutes;
    final seconds = difference.inSeconds % 60;
    final hours = difference.inHours;

    String newTime;
    if (hours > 0) {
      newTime = "${hours}h ${minutes % 60}m ${seconds}s";
    } else {
      newTime = "${minutes}m ${seconds}s";
    }

    if (mounted) {
      setState(() {
        _waitingTime = newTime;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      "Wait Time: $_waitingTime",
      style: widget.style ?? const TextStyle(color: Colors.black87),
    );
  }
}
