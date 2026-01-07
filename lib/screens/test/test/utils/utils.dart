class Utils {
  static List<Map<String, dynamic>> getIceServers() {
    return [
      // STUN
      {
        'urls': 'stun:stun.relay.metered.ca:80',
      },

      // TURN UDP
      {
        'urls': 'turn:global.relay.metered.ca:80',
        'username': '273fe7dbf04b56d09d97c590',
        'credential': 'Eb5gC0BrTVvnaiYm',
      },

      // TURN TCP
      {
        'urls': 'turn:global.relay.metered.ca:80?transport=tcp',
        'username': '273fe7dbf04b56d09d97c590',
        'credential': 'Eb5gC0BrTVvnaiYm',
      },

      // TURN UDP 443
      {
        'urls': 'turn:global.relay.metered.ca:443',
        'username': '273fe7dbf04b56d09d97c590',
        'credential': 'Eb5gC0BrTVvnaiYm',
      },

      // TURN TLS (BEST for strict networks)
      {
        'urls': 'turns:global.relay.metered.ca:443?transport=tcp',
        'username': '273fe7dbf04b56d09d97c590',
        'credential': 'Eb5gC0BrTVvnaiYm',
      },
    ];
  }
}
