import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/datasources/cross_app_bridge_data_source.dart';

class AgoraCallMockPage extends StatefulWidget {
  const AgoraCallMockPage({
    super.key,
    required this.callId,
    required this.callType,
    required this.targetTeam,
    required this.displayName,
  });

  final String callId;
  final String callType;
  final String targetTeam;
  final String displayName;

  @override
  State<AgoraCallMockPage> createState() => _AgoraCallMockPageState();
}

class _AgoraCallMockPageState extends State<AgoraCallMockPage> {
  final CrossAppBridgeDataSource _bridge = CrossAppBridgeDataSource();

  Timer? _pollTimer;
  Timer? _durationTimer;
  int _seconds = 0;
  String _status = 'ringing';
  String? _agentName;

  bool _muted = false;
  bool _speakerOn = true;
  bool _cameraOn = true;

  bool get _isVideo => widget.callType == 'video';
  bool get _isConnected => _status == 'accepted';

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pollStatus());
    _pollStatus();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _durationTimer?.cancel();
    super.dispose();
  }

  Future<void> _pollStatus() async {
    final call = await _bridge.getCallRequestById(widget.callId);
    if (!mounted || call == null) {
      return;
    }

    final wasConnected = _isConnected;
    setState(() {
      _status = call.status;
      _agentName = call.salesAgentName;
    });

    if (!wasConnected && _isConnected) {
      _durationTimer?.cancel();
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) {
          return;
        }
        setState(() => _seconds++);
      });
    }

    if (_status == 'ended' || _status == 'rejected') {
      _durationTimer?.cancel();
    }
  }

  Future<void> _endCall() async {
    await _bridge.updateCallStatus(callId: widget.callId, status: 'ended');
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  String _durationLabel() {
    final minutes = (_seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  String _statusLabel() {
    switch (_status) {
      case 'accepted':
        return 'Connected${_agentName == null ? '' : ' • $_agentName'}';
      case 'rejected':
        return 'Call rejected by team';
      case 'ended':
        return 'Call ended';
      default:
        return 'Ringing ${widget.targetTeam} team...';
    }
  }

  Color _statusColor() {
    switch (_status) {
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'ended':
        return AppColors.textMuted;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text('Agora ${_isVideo ? 'Video' : 'Voice'} Call (UI Mock)',
            style: AppTextStyles.titleLarge),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 42,
                backgroundColor: AppColors.primarySurface,
                child: Text(
                  widget.displayName.isNotEmpty
                      ? widget.displayName[0].toUpperCase()
                      : 'U',
                  style: AppTextStyles.displayMedium.copyWith(
                    color: AppColors.primary,
                    fontSize: 26,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(widget.displayName, style: AppTextStyles.headlineMedium),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor().withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _statusColor().withValues(alpha: 0.35)),
                ),
                child: Text(
                  _statusLabel(),
                  style: AppTextStyles.caption.copyWith(color: _statusColor()),
                ),
              ),
              const SizedBox(height: 8),
              if (_isConnected)
                Text(_durationLabel(), style: AppTextStyles.headlineSmall),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Center(
                    child: Text(
                      _isVideo
                          ? 'Remote video placeholder\nAgora RTC will be integrated later'
                          : 'Voice waveform placeholder\nAgora RTC will be integrated later',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _controlButton(
                    icon: _muted ? Icons.mic_off : Icons.mic,
                    label: _muted ? 'Unmute' : 'Mute',
                    onTap: () => setState(() => _muted = !_muted),
                  ),
                  _controlButton(
                    icon: _speakerOn ? Icons.volume_up : Icons.volume_off,
                    label: _speakerOn ? 'Speaker' : 'Earpiece',
                    onTap: () => setState(() => _speakerOn = !_speakerOn),
                  ),
                  if (_isVideo)
                    _controlButton(
                      icon: _cameraOn ? Icons.videocam : Icons.videocam_off,
                      label: _cameraOn ? 'Camera' : 'Cam Off',
                      onTap: () => setState(() => _cameraOn = !_cameraOn),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _endCall,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.call_end_rounded),
                  label: const Text('End Call'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(26),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderPrimary),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
