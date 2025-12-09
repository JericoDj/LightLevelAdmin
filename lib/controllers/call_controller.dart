import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallController {
  MediaStream? localStream;

  Future<void> initLocalStream() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {
        'facingMode': 'user',
      },
    };

    localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
  }

  void toggleMic() {
    final audioTrack = localStream?.getAudioTracks().first;
    if (audioTrack != null) {
      audioTrack.enabled = !audioTrack.enabled;
    }
  }

  void toggleSpeaker(bool enable) {
    Helper.setSpeakerphoneOn(enable);
  }
}
