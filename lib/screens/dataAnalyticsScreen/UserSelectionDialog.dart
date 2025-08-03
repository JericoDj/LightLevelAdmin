import 'package:flutter/material.dart';

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
    return AlertDialog(
      title: const Text('Select Users'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            CheckboxListTile(
              title: const Text('Select All'),
              value: isAllSelected,
              onChanged: _toggleSelectAll,
            ),
            const Divider(),
            ...widget.allUsers.map((user) {
              final isSelected = selectedUsers.contains(user);
              return CheckboxListTile(
                title: Text(user),
                value: isSelected,
                onChanged: (bool? checked) {
                  setState(() {
                    checked == true
                        ? selectedUsers.add(user)
                        : selectedUsers.remove(user);
                  });
                },
              );
            }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, selectedUsers),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
