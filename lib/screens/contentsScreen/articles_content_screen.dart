import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../models/articles_model.dart';
import '../../utils/colors.dart'; // Ensure this import is correct
import '../../providers/articles_provider.dart';
import '../../utils/rich_text_controller.dart';

class ArticlesContentScreen extends StatefulWidget {
  const ArticlesContentScreen({super.key, required List<Article> articles});

  @override
  State<ArticlesContentScreen> createState() => _ArticlesContentScreenState();
}

class _ArticlesContentScreenState extends State<ArticlesContentScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _deleteArticle(
      BuildContext context, ArticlesProvider provider, int articleIndex) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Article'),
          content: const Text(
            'Remove this article from Mind Hub?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await provider.deleteArticle(articleIndex);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Article deleted successfully.')),
    );
  }

  void _formatText(TextEditingController controller, String tag, {String? value}) {
    final selection = controller.selection;
    final text = controller.text;

    if (selection.start == -1) return;

    final String openTag = value != null ? '<$tag=$value>' : '<$tag>';
    final String closeTag = '</${tag.split('=').first}>';

    // Special Handling for Color: Prevent nesting by removing existing color tags in selection
    if (tag == 'color') {
      final selectedPart = selection.textInside(text);
      // Remove existing color tags from selected text
      final cleanSelected =
          selectedPart.replaceAll(RegExp(r'<color=#.*?>|</color>'), '');

      final newText = text.replaceRange(
          selection.start, selection.end, '$openTag$cleanSelected$closeTag');
      controller.value = controller.value.copyWith(
        text: newText,
        selection: TextSelection(
          baseOffset: selection.start,
          extentOffset: selection.start +
              openTag.length +
              cleanSelected.length +
              closeTag.length,
        ),
      );
      return;
    }

    // Toggle Detection: Check if already wrapped
    if (selection.start >= openTag.length &&
        selection.end <= text.length - closeTag.length) {
      String prefix =
          text.substring(selection.start - openTag.length, selection.start);
      String suffix =
          text.substring(selection.end, selection.end + closeTag.length);

      if (prefix == openTag && suffix == closeTag) {
        final newText = text.replaceRange(
            selection.end, selection.end + closeTag.length, '');
        final finalText = newText.replaceRange(
            selection.start - openTag.length, selection.start, '');
        controller.value = controller.value.copyWith(
          text: finalText,
          selection: TextSelection(
            baseOffset: selection.start - openTag.length,
            extentOffset: selection.end - openTag.length,
          ),
        );
        return;
      }
    }

    // Toggle Detection: Check if selection contains tags
    if (selection.start < selection.end) {
      String selectedPart = text.substring(selection.start, selection.end);
      if (selectedPart.startsWith(openTag) && selectedPart.endsWith(closeTag)) {
        final innerText = selectedPart.substring(
            openTag.length, selectedPart.length - closeTag.length);
        final finalText =
            text.replaceRange(selection.start, selection.end, innerText);
        controller.value = controller.value.copyWith(
          text: finalText,
          selection: TextSelection(
            baseOffset: selection.start,
            extentOffset: selection.start + innerText.length,
          ),
        );
        return;
      }
    }

    if (selection.start == selection.end) {
      // No text selected, insert tags and place cursor in between
      final newText = text.replaceRange(
          selection.start, selection.end, '$openTag$closeTag');
      controller.value = controller.value.copyWith(
        text: newText,
        selection:
            TextSelection.collapsed(offset: selection.start + openTag.length),
      );
    } else {
      // Text selected, wrap it
      final selectedText = selection.textInside(text);
      final newText = text.replaceRange(
          selection.start, selection.end, '$openTag$selectedText$closeTag');
      controller.value = controller.value.copyWith(
        text: newText,
        selection: TextSelection(
          baseOffset: selection.start,
          extentOffset: selection.start +
              openTag.length +
              selectedText.length +
              closeTag.length,
        ),
      );
    }
  }

  void _clearFormatting(TextEditingController controller) {
    final selection = controller.selection;
    final text = controller.text;
    if (selection.start == -1) return;

    if (selection.start == selection.end) {
      return;
    }

    final selectedPart = selection.textInside(text);
    final cleanText = selectedPart.replaceAll(RegExp(r'<[^>]+>'), '');

    final newText = text.replaceRange(selection.start, selection.end, cleanText);
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection(
        baseOffset: selection.start,
        extentOffset: selection.start + cleanText.length,
      ),
    );
  }

  void _pickColor(BuildContext context, TextEditingController controller) {
    Color currentColor = Colors.blue;
    final TextEditingController hexController = TextEditingController(
        text: '#${currentColor.value.toRadixString(16).substring(2).toUpperCase()}');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Pick Text Color'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ColorPicker(
                    pickerColor: currentColor,
                    onColorChanged: (color) {
                      setStateDialog(() {
                        currentColor = color;
                        hexController.text =
                            '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
                      });
                    },
                    colorPickerWidth: 300,
                    pickerAreaHeightPercent: 0.7,
                    enableAlpha: false,
                    displayThumbColor: true,
                    paletteType: PaletteType.hsvWithHue,
                    labelTypes: const [], // Hide default labels to use our custom one
                    pickerAreaBorderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(2),
                      topRight: Radius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: hexController,
                    decoration: const InputDecoration(
                      labelText: 'Manual Hex Value',
                      prefixText: '#',
                      border: OutlineInputBorder(),
                      hintText: 'RRGGBB',
                    ),
                    onChanged: (val) {
                      if (val.length == 6) {
                        try {
                          final color =
                              Color(int.parse('0xFF${val.toUpperCase()}'));
                          setStateDialog(() {
                            currentColor = color;
                          });
                        } catch (_) {}
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyColors.color2,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Apply'),
                onPressed: () {
                  final hex =
                      '#${currentColor.value.toRadixString(16).substring(2).toUpperCase()}';
                  _formatText(controller, 'color', value: hex);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFormattingToolbar(TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToolbarButton(
            icon: Icons.format_bold,
            tooltip: 'Bold',
            onPressed: () => _formatText(controller, 'b'),
          ),
          _buildToolbarButton(
            icon: Icons.format_italic,
            tooltip: 'Italic',
            onPressed: () => _formatText(controller, 'i'),
          ),
          _buildToolbarButton(
            icon: Icons.format_underlined,
            tooltip: 'Underline',
            onPressed: () => _formatText(controller, 'u'),
          ),
          _buildToolbarButton(
            icon: Icons.palette_outlined,
            tooltip: 'Text Color',
            onPressed: () => _pickColor(context, controller),
          ),
          _buildToolbarButton(
            icon: Icons.format_clear,
            tooltip: 'Clear Formatting',
            onPressed: () => _clearFormatting(controller),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 18, color: Colors.grey[700]),
      onPressed: onPressed,
      tooltip: tooltip,
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      splashRadius: 20,
    );
  }

  Future<void> _onArticleSelected(
      BuildContext context, ArticlesProvider provider, int index) async {
    if (provider.selectedArticleIndex == index) return;

    if (provider.hasUnsavedChanges(provider.selectedArticleIndex)) {
      final bool? shouldSave = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Unsaved Changes'),
            content: const Text(
                'You have unsaved changes in the current article. Do you want to save them before switching?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(null),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Discard'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.green),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );

      if (shouldSave == null) return;

      if (shouldSave) {
        provider.saveArticleLocally(provider.selectedArticleIndex);
        await provider.updateFirestoreOrderAndTitles();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Changes saved.')),
          );
        }
      } else {
        provider.discardChanges(provider.selectedArticleIndex);
      }
    }

    provider.selectArticle(index);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ArticlesProvider>();
    final fetchedArticles = provider.fetchedArticles;
    final isReordering = provider.isReordering;
    final selectedArticleIndex = provider.selectedArticleIndex;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: AppBar(
          backgroundColor: Colors.green[800],
          elevation: 0,
          title: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Mindhub Article Contents',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: MediaQuery.of(context).size.width * 0.012,
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () => provider.pickImageAndAdd(),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              const Divider(height: 20),
              Listener(
                onPointerSignal: (pointerSignal) {
                  if (pointerSignal is PointerScrollEvent) {
                    if (_scrollController.hasClients &&
                        pointerSignal.scrollDelta.dy != 0) {
                      final double newOffset = _scrollController.offset +
                          pointerSignal.scrollDelta.dy;
                      _scrollController.position.jumpTo(
                        newOffset.clamp(
                          _scrollController.position.minScrollExtent,
                          _scrollController.position.maxScrollExtent,
                        ),
                      );
                    }
                  }
                },
                child: SizedBox(
                  height: 250,
                  child: fetchedArticles.isEmpty
                      ? const Center(child: Text('No uploaded articles found.'))
                      : Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          child: isReordering
                              ? ReorderableListView(
                                  scrollController: _scrollController,
                                  scrollDirection: Axis.horizontal,
                                  onReorder: provider.onReorder,
                                  children: [
                                    ...fetchedArticles.map((article) {
                                      return Container(
                                        key: ValueKey(article['thumbnail']),
                                        width: 200,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        child: Column(
                                          children: [
                                            Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: Image.network(
                                                    article['thumbnail'],
                                                    height: 160,
                                                    width: 200,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 4,
                                                  left: 4,
                                                  child: IconButton(
                                                    icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red),
                                                    tooltip: 'Delete article',
                                                    onPressed: () =>
                                                        _deleteArticle(
                                                      context,
                                                      provider,
                                                      fetchedArticles
                                                          .indexOf(article),
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 4,
                                                  right: 4,
                                                  child: Icon(Icons.drag_handle,
                                                      color: Colors.grey[600],
                                                      size: 20),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4.0),
                                              child: Text(
                                                article['title'],
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                )
                              : ListView(
                                  controller: _scrollController,
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    ...fetchedArticles.map((article) {
                                      int index =
                                          fetchedArticles.indexOf(article);
                                      bool isSelected =
                                          index == selectedArticleIndex;
                                      return GestureDetector(
                                        onTap: () => _onArticleSelected(
                                            context, provider, index),
                                        child: Container(
                                          height: 120,
                                          width: 200,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          decoration: isSelected
                                              ? BoxDecoration(
                                                  border: Border.all(
                                                      color: MyColors.color2,
                                                      width: 3),
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                )
                                              : null,
                                          child: Column(
                                            children: [
                                              Expanded(
                                                child: Stack(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      child: Image.network(
                                                        article['thumbnail'],
                                                        height: 113,
                                                        width: 200,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: 4,
                                                      right: 4,
                                                      child: IconButton(
                                                        icon: const Icon(
                                                            Icons.delete,
                                                            color: Colors.red),
                                                        tooltip:
                                                            'Delete article',
                                                        onPressed: () =>
                                                            _deleteArticle(
                                                                context,
                                                                provider,
                                                                index),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 4.0),
                                                child: Text(
                                                  article['title'],
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Editing Section
              if (fetchedArticles.isNotEmpty &&
                  selectedArticleIndex >= 0 &&
                  selectedArticleIndex < fetchedArticles.length) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Highlight text & use the toolbar to apply Bold (<b>), Italic (<i>), or Underline (<u>).',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                Builder(
                  builder: (context) {
                    final i = selectedArticleIndex;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Editing Article ${i + 1}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: MyColors.color2,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: () => provider.changeArticleImage(i),
                                icon: const Icon(Icons.image),
                                label: const Text('Change Photo'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: MyColors.color2,
                                  foregroundColor: MyColors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormattingToolbar(
                                  fetchedArticles[i]['controller']),
                              TextField(
                                controller: fetchedArticles[i]['controller'],
                                decoration: const InputDecoration(
                                  labelText: 'Article Title',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Paragraphs',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => provider.addParagraph(i),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Paragraph'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: MyColors.color2,
                                  foregroundColor: MyColors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          for (int j = 0;
                              j <
                                  fetchedArticles[i]['paragraphControllers']
                                      .length;
                              j++) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildFormattingToolbar(fetchedArticles[i]
                                          ['paragraphControllers'][j]),
                                      TextField(
                                        controller: fetchedArticles[i]
                                            ['paragraphControllers'][j],
                                        maxLines: null,
                                        decoration: InputDecoration(
                                          labelText: 'Paragraph ${j + 1}',
                                          border: const OutlineInputBorder(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (j > 0)
                                  IconButton(
                                    icon: const Icon(Icons.arrow_upward),
                                    onPressed: () =>
                                        provider.moveParagraphUp(i, j),
                                  ),
                                if (j <
                                    fetchedArticles[i]['paragraphControllers']
                                            .length -
                                        1)
                                  IconButton(
                                    icon: const Icon(Icons.arrow_downward),
                                    onPressed: () =>
                                        provider.moveParagraphDown(i, j),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle,
                                      color: Colors.red),
                                  onPressed: () =>
                                      provider.removeParagraph(i, j),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Sources',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => provider.addSource(i),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Source'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: MyColors.color2,
                                  foregroundColor: MyColors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          for (int j = 0;
                              j <
                                  fetchedArticles[i]['sourcesControllers']
                                      .length;
                              j++) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: fetchedArticles[i]
                                        ['sourcesControllers'][j],
                                    decoration: InputDecoration(
                                      labelText: 'Source ${j + 1}',
                                      border: const OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle,
                                      color: Colors.red),
                                  onPressed: () => provider.removeSource(i, j),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.save,
                                  color: MyColors.color2),
                              label: const Text('Save Current Article'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: MyColors.greyLight,
                                foregroundColor: MyColors.color2,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(
                                      color: MyColors.color2, width: 1),
                                ),
                                elevation: 4,
                              ),
                              onPressed: () async {
                                provider
                                    .saveArticleLocally(selectedArticleIndex);
                                await provider.updateFirestoreOrderAndTitles();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Article saved to Firestore ✅')),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 20),

              GestureDetector(
                onTap: () {
                  provider.toggleReordering();
                },
                child: Container(
                  height: 40,
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: MyColors.color2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isReordering ? Icons.check : Icons.swap_vert,
                        color: MyColors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isReordering ? 'Done' : 'Rearrange',
                        style: const TextStyle(
                          color: MyColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
