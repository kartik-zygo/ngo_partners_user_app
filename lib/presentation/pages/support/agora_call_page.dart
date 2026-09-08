import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/socket_service.dart';
import '../../../domain/entities/support_call_entity.dart';
import '../../../domain/usecases/app_usecases.dart';

class AgoraCallPage extends StatefulWidget {
  final String callId;
  final String callType; // 'voice' or 'video'
  final String displayName;

  const AgoraCallPage({
    super.key,
    required this.callId,
    required this.callType,
    required this.displayName,
  });

  @override
  State<AgoraCallPage> createState() => _AgoraCallPageState();
}

class _AgoraCallPageState extends State<AgoraCallPage> {
  final _getCallStatus = GetIt.instance<GetCallStatusUseCase>();
  final _getAgoraToken = GetIt.instance<GetAgoraTokenUseCase>();
  final _updateCallStatus = GetIt.instance<UpdateCallStatusUseCase>();
  final _socketService = GetIt.instance<SocketService>();

  // Call state
  String _status = 'ringing';
  bool _fetchingToken = false;
  bool _engineReady = false; // true after channel joined
  String? _error;

  // Permissions
  bool _permissionsChecked = false;
  bool _permissionsGranted = false;

  // Agora
  RtcEngine? _engine;
  AgoraTokenEntity? _tokenEntity;
  bool _previewInitialized = false; // engine ready for local preview (pre-join)
  int? _remoteUid;

  // Preview retry (server may only issue token after agent accepts)
  Timer? _previewRetryTimer;
  int _previewRetryCount = 0;

  // Controls
  bool _muted = false;
  bool _speakerOn = true;
  bool _cameraOn = true;

  // Timers / subscriptions
  Timer? _durationTimer;
  Timer? _pollTimer;
  int _durationSeconds = 0;
  StreamSubscription<Map<String, dynamic>>? _callStatusSub;
  StreamSubscription<bool>? _connSub;

  bool get _isVideo => widget.callType == 'video';
  bool get _isActive => _remoteUid != null && _engineReady;
  bool get _showLocalPreview =>
      (_previewInitialized || _engineReady) && _cameraOn && _engine != null;

  @override
  void initState() {
    super.initState();
    _listenToSocket();
    _requestPermissionsEarly();
  }

  @override
  void dispose() {
    _callStatusSub?.cancel();
    _connSub?.cancel();
    _socketService.leaveCall(widget.callId);
    _pollTimer?.cancel();
    _durationTimer?.cancel();
    _previewRetryTimer?.cancel();
    _engine?.stopPreview();
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  // ── Permissions ───────────────────────────────────────────────────────────

  Future<void> _requestPermissionsEarly() async {
    final permissions = _isVideo
        ? [Permission.microphone, Permission.camera]
        : [Permission.microphone];

    final statuses = await permissions.request();
    if (!mounted) return;

    final allGranted =
        statuses.values.every((s) => s == PermissionStatus.granted);

    setState(() {
      _permissionsChecked = true;
      _permissionsGranted = allGranted;
    });

    // For video calls, try to pre-initialize the camera so the user sees
    // themselves immediately during the ringing phase.
    if (allGranted && _isVideo) {
      _tryPreFetchTokenForPreview();
    }
  }

  // ── Pre-fetch token to show camera during ringing ─────────────────────────

  Future<void> _tryPreFetchTokenForPreview() async {
    if (_engine != null || _fetchingToken) return;
    _previewRetryTimer?.cancel();
    try {
      final token = await _getAgoraToken(widget.callId);
      if (!mounted || _engine != null) return;
      _previewRetryCount = 0;
      setState(() => _tokenEntity = token);
      await _initEngineForPreview(token);
    } catch (_) {
      // Server may only issue a token after the agent accepts — retry during ringing.
      if (_status == 'ringing' && _previewRetryCount < 8 && mounted) {
        _previewRetryCount++;
        _previewRetryTimer = Timer(
          Duration(seconds: _previewRetryCount <= 2 ? 2 : 4),
          _tryPreFetchTokenForPreview,
        );
      }
    }
  }

  Future<void> _initEngineForPreview(AgoraTokenEntity token) async {
    if (_engine != null) return;

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(
      appId: token.appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine!.registerEventHandler(_buildEventHandler());

    await _engine!.enableAudio();
    await _engine!.setEnableSpeakerphone(_speakerOn);

    if (_isVideo) {
      await _engine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 360),
          frameRate: 15,
          bitrate: 0,
          orientationMode: OrientationMode.orientationModeAdaptive,
        ),
      );
      await _engine!.enableVideo();
      await _engine!.enableLocalVideo(true);
      await _engine!.muteLocalVideoStream(false);
      await _engine!.startPreview();
    }

    if (mounted) setState(() => _previewInitialized = true);
  }

  RtcEngineEventHandler _buildEventHandler() {
    return RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        if (_isVideo) {
          _engine?.enableLocalVideo(true);
          _engine?.muteLocalVideoStream(false);
          _engine?.updateChannelMediaOptions(const ChannelMediaOptions(
            publishCameraTrack: true,
            publishMicrophoneTrack: true,
            autoSubscribeAudio: true,
            autoSubscribeVideo: true,
          ));
        }
        if (mounted) setState(() => _engineReady = true);
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        if (mounted) {
          setState(() => _remoteUid = remoteUid);
          _startDurationTimer();
        }
      },
      onUserOffline: (connection, remoteUid, reason) {
        if (!mounted) return;
        _durationTimer?.cancel();
        setState(() => _remoteUid = null);
        _doEndCall();
      },
      onError: (errCode, msg) {
        if (mounted) setState(() => _error = 'Agora error: $msg ($errCode)');
      },
    );
  }

  // ── WebSocket listener ────────────────────────────────────────────────────

  void _listenToSocket() {
    _socketService.joinCall(widget.callId);

    _connSub = _socketService.connectionStream.listen((connected) {
      if (connected && mounted) _socketService.joinCall(widget.callId);
    });

    _callStatusSub = _socketService.callStatusStream.listen((data) {
      if (!mounted) return;
      final eventCallId = data['id'] as String?;
      if (eventCallId != null && eventCallId != widget.callId) return;
      final next = data['status'] as String? ?? '';
      if (next.isEmpty || next == _status) return;
      _pollTimer?.cancel();
      _applyStatus(next);
    });

    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollStatus());
  }

  Future<void> _pollStatus() async {
    if (_status != 'ringing' || !mounted) {
      _pollTimer?.cancel();
      return;
    }
    try {
      final call = await _getCallStatus(widget.callId);
      if (!mounted) return;
      final next = _callStatusString(call.status);
      if (next == _status) return;
      _pollTimer?.cancel();
      _applyStatus(next);
    } catch (_) {}
  }

  void _applyStatus(String next) {
    setState(() => _status = next);
    if (next == 'accepted' && !_fetchingToken) {
      _fetchTokenAndJoin();
    } else if (next == 'rejected' || next == 'ended') {
      _durationTimer?.cancel();
      if (mounted) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    }
  }

  String _callStatusString(CallStatus s) {
    switch (s) {
      case CallStatus.accepted:
        return 'accepted';
      case CallStatus.rejected:
        return 'rejected';
      case CallStatus.ended:
        return 'ended';
      default:
        return 'ringing';
    }
  }

  // ── Agora join channel ────────────────────────────────────────────────────

  Future<void> _fetchTokenAndJoin() async {
    setState(() => _fetchingToken = true);
    try {
      // Ensure permissions before proceeding
      if (!_permissionsGranted) {
        await _requestPermissionsEarly();
        if (!mounted) return;
        if (!_permissionsGranted) {
          setState(() {
            _error = _isVideo
                ? 'Camera and microphone access is required for video calls.\nPlease grant permissions in Settings.'
                : 'Microphone access is required for voice calls.\nPlease grant permissions in Settings.';
            _fetchingToken = false;
          });
          return;
        }
      }

      // Reuse pre-fetched token if available, otherwise fetch now
      final token = _tokenEntity ?? await _getAgoraToken(widget.callId);
      if (!mounted) return;
      if (_tokenEntity == null) setState(() => _tokenEntity = token);

      // Initialize engine if the pre-fetch didn't run (voice calls or failed pre-fetch)
      if (_engine == null) {
        await _initEngineForPreview(token);
        if (!mounted) return;
      }

      await _joinChannel(token);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to connect: ${e.toString().replaceFirst('Exception: ', '')}';
        _fetchingToken = false;
      });
    }
  }

  Future<void> _joinChannel(AgoraTokenEntity token) async {
    await _engine!.joinChannel(
      token: token.token,
      channelId: token.channelName,
      uid: token.uid,
      options: ChannelMediaOptions(
        autoSubscribeAudio: true,
        autoSubscribeVideo: _isVideo,
        publishMicrophoneTrack: true,
        publishCameraTrack: _isVideo,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
    // _engineReady is set via onJoinChannelSuccess callback
  }

  // ── Controls ──────────────────────────────────────────────────────────────

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(
        const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _durationSeconds++);
    });
  }

  Future<void> _toggleMute() async {
    _muted = !_muted;
    await _engine?.muteLocalAudioStream(_muted);
    setState(() {});
  }

  Future<void> _toggleSpeaker() async {
    _speakerOn = !_speakerOn;
    await _engine?.setEnableSpeakerphone(_speakerOn);
    setState(() {});
  }

  Future<void> _toggleCamera() async {
    _cameraOn = !_cameraOn;
    await _engine?.enableLocalVideo(_cameraOn);
    setState(() {});
  }

  Future<void> _switchCamera() async {
    await _engine?.switchCamera();
  }

  Future<void> _endCall() async {
    _pollTimer?.cancel();
    _durationTimer?.cancel();
    await _doEndCall();
  }

  Future<void> _doEndCall() async {
    _socketService.leaveCall(widget.callId);
    try {
      await _updateCallStatus(callId: widget.callId, status: 'ended');
    } catch (_) {}
    await _engine?.leaveChannel();
    if (mounted) Navigator.of(context).pop();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _durationLabel() {
    final m = (_durationSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_durationSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _statusLabel {
    switch (_status) {
      case 'accepted':
        return _isActive ? 'Connected' : 'Connecting...';
      case 'rejected':
        return 'Call rejected';
      case 'ended':
        return 'Call ended';
      default:
        return 'Ringing...';
    }
  }

  Color get _statusColor {
    switch (_status) {
      case 'accepted':
        return AppColors.success;
      case 'rejected':
      case 'error':
        return AppColors.error;
      case 'ended':
        return AppColors.textMuted;
      default:
        return AppColors.warning;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_error != null) return _buildErrorScreen();

    // Show permission prompt before anything else
    if (!_permissionsChecked) return _buildPermissionLoadingScreen();
    if (!_permissionsGranted) return _buildPermissionDeniedScreen();

    return _isVideo ? _buildVideoScreen() : _buildVoiceScreen();
  }

  // ── Permission screens ────────────────────────────────────────────────────

  Widget _buildPermissionLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: const SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 20),
              Text(
                'Checking permissions...',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isVideo ? Icons.videocam_off_rounded : Icons.mic_off_rounded,
                  color: AppColors.error,
                  size: 64,
                ),
                const SizedBox(height: 20),
                Text(
                  _isVideo
                      ? 'Camera & Microphone Required'
                      : 'Microphone Required',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _isVideo
                      ? 'Please allow camera and microphone access to make video calls.'
                      : 'Please allow microphone access to make voice calls.',
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: () async {
                    await openAppSettings();
                    if (mounted) {
                      setState(() => _permissionsChecked = false);
                      _requestPermissionsEarly();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.settings_rounded, size: 18),
                  label: const Text('Open Settings',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white54, fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Voice screen ──────────────────────────────────────────────────────────

  Widget _buildVoiceScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _StatusPill(label: _statusLabel, color: _statusColor),
              const SizedBox(height: 48),
              _CallerAvatar(name: widget.displayName, size: 96),
              const SizedBox(height: 16),
              Text(
                widget.displayName,
                style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                _isActive
                    ? _durationLabel()
                    : _status == 'ringing'
                        ? 'Waiting for agent...'
                        : '',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: _isActive ? AppColors.success : Colors.white54,
                ),
              ),
              const Spacer(),
              if (_isActive) _buildWaveform(),
              const Spacer(),
              _buildVoiceControls(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaveform() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(11, (i) {
        final heights = [
          16.0, 24.0, 36.0, 48.0, 56.0, 64.0, 56.0, 48.0, 36.0, 24.0, 16.0
        ];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: _AnimatedBar(height: heights[i], delay: i * 80),
        );
      }),
    );
  }

  Widget _buildVoiceControls() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _CallControlButton(
              icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
              label: _muted ? 'Unmute' : 'Mute',
              active: _muted,
              onTap: _isActive ? _toggleMute : null,
            ),
            _CallControlButton(
              icon: _speakerOn
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              label: _speakerOn ? 'Speaker' : 'Earpiece',
              active: false,
              onTap: _isActive ? _toggleSpeaker : null,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _EndCallButton(onTap: _endCall),
      ],
    );
  }

  // ── Video screen ──────────────────────────────────────────────────────────

  Widget _buildVideoScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote video (full screen) or waiting state
          _buildRemoteVideo(),
          // Local video (top-right overlay) — shown as soon as preview is ready
          if (_showLocalPreview) _buildLocalVideoOverlay(),
          // Top status bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _StatusPill(label: _statusLabel, color: _statusColor),
                    const Spacer(),
                    if (_isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _durationLabel(),
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(child: _buildVideoControls()),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoteVideo() {
    if (!_engineReady || _remoteUid == null || _tokenEntity == null) {
      return Container(
        color: const Color(0xFF0F172A),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CallerAvatar(name: widget.displayName, size: 80),
              const SizedBox(height: 16),
              Text(
                _statusLabel,
                style:
                    AppTextStyles.bodyLarge.copyWith(color: Colors.white70),
              ),
              if (_status == 'ringing') ...[
                const SizedBox(height: 12),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine!,
        canvas: VideoCanvas(uid: _remoteUid!),
        connection: RtcConnection(channelId: _tokenEntity!.channelName),
        useAndroidSurfaceView: true,
      ),
    );
  }

  Widget _buildLocalVideoOverlay() {
    return Positioned(
      top: 80,
      right: 16,
      child: Container(
        width: 100,
        height: 150,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
          color: Colors.black,
        ),
        child: AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: _engine!,
            canvas: const VideoCanvas(uid: 0),
            useAndroidSurfaceView: true,
          ),
        ),
      ),
    );
  }

  Widget _buildVideoControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CallControlButton(
                icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                label: _muted ? 'Unmute' : 'Mute',
                active: _muted,
                onTap: _showLocalPreview ? _toggleMute : null,
                dark: true,
              ),
              _CallControlButton(
                icon: _cameraOn
                    ? Icons.videocam_rounded
                    : Icons.videocam_off_rounded,
                label: _cameraOn ? 'Camera' : 'Cam Off',
                active: !_cameraOn,
                onTap: _showLocalPreview ? _toggleCamera : null,
                dark: true,
              ),
              _CallControlButton(
                icon: Icons.flip_camera_ios_rounded,
                label: 'Flip',
                active: false,
                onTap: _showLocalPreview ? _switchCamera : null,
                dark: true,
              ),
              _CallControlButton(
                icon: _speakerOn
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                label: 'Speaker',
                active: false,
                onTap: _isActive ? _toggleSpeaker : null,
                dark: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _EndCallButton(onTap: _endCall),
        ],
      ),
    );
  }

  // ── Error screen ──────────────────────────────────────────────────────────

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 56),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Something went wrong',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CallerAvatar extends StatelessWidget {
  final String name;
  final double size;
  const _CallerAvatar({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 2,
      height: size * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF0EA5E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: AppTextStyles.displayMedium.copyWith(
          color: Colors.white,
          fontSize: size * 0.6,
        ),
      ),
    );
  }
}

class _EndCallButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EndCallButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        icon: const Icon(Icons.call_end_rounded, size: 22),
        label: const Text('End Call',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _CallControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  final bool dark;

  const _CallControlButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = active
        ? AppColors.primary.withValues(alpha: 0.25)
        : dark
            ? Colors.white12
            : AppColors.primarySurface;
    final border =
        active ? AppColors.primary : (dark ? Colors.white24 : AppColors.borderPrimary);
    final fg =
        active ? AppColors.primary : (dark ? Colors.white : AppColors.primary);

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1.0,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: Border.all(color: border),
              ),
              child: Icon(icon, color: fg, size: 22),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: dark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedBar extends StatefulWidget {
  final double height;
  final int delay;
  const _AnimatedBar({required this.height, required this.delay});

  @override
  State<_AnimatedBar> createState() => _AnimatedBarState();
}

class _AnimatedBarState extends State<_AnimatedBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _anim = Tween<double>(begin: 6, end: widget.height).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 4,
        height: _anim.value,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
