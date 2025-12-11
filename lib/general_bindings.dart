import 'package:get/get.dart';
import 'package:lightlevelpsychosolutionsadmin/repository/authentication_repositories/authentication_repository.dart';

import 'auth_guard.dart';


class GeneralBindings extends Bindings {
  @override
  void dependencies() {

    Get.put(AuthTokenGuard(), permanent: true); // 🔥 start listening HERE

    Get.put(AuthRepository());
  }
}
