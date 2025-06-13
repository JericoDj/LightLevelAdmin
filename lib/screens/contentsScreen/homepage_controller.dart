import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';

class HomePageContentController extends GetxController {
  RxList<Map<String, dynamic>> carouselItems = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadImages();
  }

  Future<void> loadImages() async {
    final doc = await FirebaseFirestore.instance.collection('contents').doc('homescreen').get();
    if (doc.exists) {
      final data = doc.data()!;
      final result = <Map<String, dynamic>>[];

      data.forEach((key, value) {
        if (value is Map && value['url'] != null) {
          result.add({
            'title': value['title'] ?? key,
            'url': value['url'],
          });
        }
      });

      carouselItems.assignAll(result);
    }
  }

}
