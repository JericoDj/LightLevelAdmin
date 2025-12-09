import 'package:flutter/material.dart';

import '../../utils/colors.dart'; // Make sure this path matches your actual color file

class UserSelectionDialog extends StatefulWidget {
  final List<String> allUsers;
  final List<String> initiallySelected;

  const UserSelectionDialog({
    super.key,
    required this.allUsers,
    required this.initiallySelected,
  });

  @override
  State<UserSelectionDialog> createState() => _UserSelectionDialogState();
}

class _UserSelectionDialogState extends State<UserSelectionDialog> {
  late List<String> selectedUsers;

  bool get isAllSelected => selectedUsers.length == widget.allUsers.length;

  @override
  void initState() {
    super.initState();
    selectedUsers = List.from(widget.initiallySelected);
  }

  void _toggleSelectAll(bool? checked) {
    setState(() {
      if (checked == true) {
        selectedUsers = List.from(widget.allUsers);
      } else {
        selectedUsers.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(

      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 500, minWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Users',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                radius: const Radius.circular(8),
                child: ListView(
                  children: [
                    CheckboxListTile(
                      title: const Text('Select All'),
                      value: isAllSelected,
                      onChanged: _toggleSelectAll,
                      activeColor: MyColors.color1,
                    ),
                    const Divider(),
                    ...widget.allUsers.map((user) {
                      final isSelected = selectedUsers.contains(user);
                      return CheckboxListTile(
                        value: isSelected,
                        title: Text(user),
                        activeColor: MyColors.color1,
                        onChanged: (bool? checked) {
                          setState(() {
                            if (checked == true) {
                              selectedUsers.add(user);
                            } else {
                              selectedUsers.remove(user);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MyColors.color1,
                    side: BorderSide(color: MyColors.color1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyColors.color2,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.pop(context, selectedUsers),
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
