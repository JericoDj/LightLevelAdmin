import 'package:flutter/material.dart';

void showHomePageImagesDialog(BuildContext context) {
  List<Map<String, dynamic>> images = [
    {'title': 'Banner Image 1', 'controller': TextEditingController(text: 'Banner Image 1')},
    {'title': 'Feature Image 2', 'controller': TextEditingController(text: 'Feature Image 2')},
    {'title': 'Slider Image 3', 'controller': TextEditingController(text: 'Slider Image 3')},
    {'title': 'Gallery Image 4', 'controller': TextEditingController(text: 'Gallery Image 4')},
  ];

  bool isArranging = false;
  final ScrollController _scrollController = ScrollController();

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Home Page Images',
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Scaffold(
            backgroundColor: Colors.black.withOpacity(0.5),
            body: Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.65,
                height: MediaQuery.of(context).size.height * 0.5,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Header Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Home Page Images',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                        Row(
                          children: [
                            // Arrange Button
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  isArranging = !isArranging;
                                });
                              },
                              icon: Icon(isArranging ? Icons.check : Icons.swap_vert, color: Colors.blue),
                              label: Text(isArranging ? 'Done' : 'Arrange', style: const TextStyle(color: Colors.blue)),
                            ),
                            // Close Button
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Image List with Reorderable Feature
                    Expanded(
                      child: Row(
                        children: [
                          // Scroll Left Button
                          IconButton(
                            icon: const Icon(Icons.chevron_left, color: Colors.blue, size: 32),
                            onPressed: () {
                              _scrollController.animateTo(
                                _scrollController.offset - 200,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                          ),

                          // Scrollable List
                          Expanded(
                            child: SizedBox(
                              height: 200,
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    if (isArranging)
                                    // Arrange Mode: Drag & Drop
                                      ReorderableListView(
                                        shrinkWrap: true,
                                        scrollDirection: Axis.horizontal,
                                        onReorder: (oldIndex, newIndex) {
                                          if (newIndex > images.length) newIndex = images.length;
                                          if (oldIndex < newIndex) newIndex--;

                                          setState(() {
                                            final movedItem = images.removeAt(oldIndex);
                                            images.insert(newIndex, movedItem);
                                          });
                                        },
                                        children: images.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final img = entry.value;

                                          return Padding(
                                            key: ValueKey(index),
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                            child: Column(
                                              children: [
                                                Stack(
                                                  children: [
                                                    // Image Placeholder
                                                    Container(
                                                      width: 200,
                                                      height: 112,
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey[300],
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: const Center(
                                                        child: Text(
                                                          'Image Here',
                                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                                                        ),
                                                      ),
                                                    ),
                                                    // Drag Handle
                                                    Positioned(
                                                      top: 5,
                                                      right: 5,
                                                      child: Icon(Icons.drag_indicator, color: Colors.blue),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                // Editable Text Field Below Image
                                                SizedBox(
                                                  width: 200,
                                                  child: TextField(
                                                    textAlign: TextAlign.center,
                                                    decoration: InputDecoration(
                                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                                    ),
                                                    controller: img['controller'],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      )
                                    else
                                    // Normal Mode: Static Images with Delete Option
                                      Row(
                                        children: [
                                          ...images.map((img) {
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                              child: Column(
                                                children: [
                                                  Stack(
                                                    children: [
                                                      // Image Placeholder
                                                      Container(
                                                        width: 200,
                                                        height: 112,
                                                        decoration: BoxDecoration(
                                                          color: Colors.grey[300],
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                        child: const Center(
                                                          child: Text(
                                                            'Image Here',
                                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                                                          ),
                                                        ),
                                                      ),
                                                      // Delete Button
                                                      Positioned(
                                                        top: 5,
                                                        right: 5,
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            setState(() {
                                                              images.remove(img);
                                                            });
                                                          },
                                                          child: Container(
                                                            decoration: const BoxDecoration(
                                                              shape: BoxShape.circle,
                                                              color: Colors.red,
                                                            ),
                                                            padding: const EdgeInsets.all(5),
                                                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  // Editable Text Field Below Image
                                                  SizedBox(
                                                    width: 200,
                                                    child: TextField(
                                                      textAlign: TextAlign.center,
                                                      decoration: InputDecoration(
                                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                                      ),
                                                      controller: img['controller'],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),

                                          // "Add New" Button
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                images.add({
                                                  'title': 'New Image',
                                                  'controller': TextEditingController(text: 'New Image')
                                                });
                                              });
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                              child: Column(
                                                children: [
                                                  Container(
                                                    width: 200,
                                                    height: 112,
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue[100],
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: const Center(
                                                      child: Icon(Icons.add, size: 40, color: Colors.blue),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  const Text(
                                                    'Add New',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Scroll Right Button
                          IconButton(
                            icon: const Icon(Icons.chevron_right, color: Colors.blue, size: 32),
                            onPressed: () {
                              _scrollController.animateTo(
                                _scrollController.offset + 200,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Save & Close Buttons
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      child: const Text('Save & Close', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
