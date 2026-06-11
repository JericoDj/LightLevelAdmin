import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lightlevelpsychosolutionsadmin/controllers/notification_controller.dart';
import 'package:lightlevelpsychosolutionsadmin/utils/app_messenger.dart';
import 'package:lightlevelpsychosolutionsadmin/utils/colors.dart';

class NotificationsScreen extends StatelessWidget {
  final NotificationController notificationController = Get.put(NotificationController());
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Send Push Notifications', style: TextStyle(color: MyColors.color1, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: Center(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24.0),
          margin: const EdgeInsets.only(top: 40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Broadcast Notification',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: MyColors.color1),
              ),
              const SizedBox(height: 10),
              Obx(() => Text(
                    _audienceDescription(notificationController.target.value),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  )),
              const SizedBox(height: 30),

              // RECIPIENTS
              const Text('Send To', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Obx(() => Wrap(
                    spacing: 8,
                    children: [
                      _targetChip(notificationController, NotificationTarget.all, 'All Users'),
                      _targetChip(notificationController, NotificationTarget.company, 'Company'),
                      _targetChip(notificationController, NotificationTarget.specific, 'Specific User'),
                    ],
                  )),
              const SizedBox(height: 16),

              // CONDITIONAL TARGET PICKER
              Obx(() {
                if (notificationController.isLoadingOptions.value) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  );
                }
                switch (notificationController.target.value) {
                  case NotificationTarget.company:
                    return _companyDropdown(notificationController);
                  case NotificationTarget.specific:
                    return _userDropdown(notificationController);
                  case NotificationTarget.all:
                    return const SizedBox.shrink();
                }
              }),

              const SizedBox(height: 20),
              const Text('Notification Title', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'e.g. New Wellness Feature!',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Notification Message', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _bodyController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Type the message body here...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Obx(() => ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyColors.color1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: notificationController.isSending.value
                      ? null
                      : () {
                          if (_titleController.text.trim().isEmpty || _bodyController.text.trim().isEmpty) {
                            showAppSnackBar("Please enter both title and message.", isError: true);
                            return;
                          }
                          notificationController.sendNotification(
                            _titleController.text.trim(),
                            _bodyController.text.trim(),
                          ).then((_) {
                            _titleController.clear();
                            _bodyController.clear();
                          });
                        },
                  child: notificationController.isSending.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Send Notification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _audienceDescription(NotificationTarget target) {
    switch (target) {
      case NotificationTarget.all:
        return 'This notification will be sent to all active users on the mobile app.';
      case NotificationTarget.company:
        return 'This notification will be sent to every user in the selected company.';
      case NotificationTarget.specific:
        return 'This notification will be sent only to the selected user.';
    }
  }

  Widget _targetChip(NotificationController controller, NotificationTarget value, String label) {
    final bool selected = controller.target.value == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => controller.target.value = value,
      selectedColor: MyColors.color1,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: selected ? MyColors.color1 : Colors.grey.shade300),
      ),
    );
  }

  Widget _companyDropdown(NotificationController controller) {
    return Obx(() {
      final items = controller.companies;
      if (items.isEmpty) {
        return const Text('No companies found.', style: TextStyle(color: Colors.grey));
      }
      return DropdownButtonFormField<String>(
        value: controller.selectedCompanyId.value,
        isExpanded: true,
        decoration: InputDecoration(
          hintText: 'Select a company',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        items: items
            .map((c) => DropdownMenuItem<String>(
                  value: c['id'],
                  child: Text(c['name'] ?? c['id']!),
                ))
            .toList(),
        onChanged: (val) => controller.selectedCompanyId.value = val,
      );
    });
  }

  Widget _userDropdown(NotificationController controller) {
    return Obx(() {
      final items = controller.users;
      if (items.isEmpty) {
        return const Text('No users with a device token found.', style: TextStyle(color: Colors.grey));
      }
      return DropdownButtonFormField<String>(
        value: controller.selectedUserId.value,
        isExpanded: true,
        decoration: InputDecoration(
          hintText: 'Select a user',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        items: items
            .map((u) => DropdownMenuItem<String>(
                  value: u['id'],
                  child: Text(u['name'] ?? u['id']!, overflow: TextOverflow.ellipsis),
                ))
            .toList(),
        onChanged: (val) => controller.selectedUserId.value = val,
      );
    });
  }
}
