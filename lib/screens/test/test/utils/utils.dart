class Utils {
  static List<Map<String, String>> getIceServers() {
    //! Change the TURN information in the lib/utils/utils.dart file
    //! Some services that provide free TURN include;
    //! - https://www.metered.ca/stun-turn

    return [
      // {"url": "stun:stun.l.google.com:19302"},
      // // relay1.expressturn.com:3480
      {
        "urls": "turn:relay1.expressturn.com:3480",
        "username": "efCZROI01OLPMN8I36",
        "credential": "UZJ6nsqQoCXfVm6S",
      },
    ];
  }
}
