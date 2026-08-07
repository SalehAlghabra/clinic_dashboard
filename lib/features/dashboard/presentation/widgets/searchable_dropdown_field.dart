import 'package:flutter/material.dart';

/// A searchable dropdown that shows an overlay list filtered by a text field.
/// Works well inside dialogs without relying on native DropdownButton.
class SearchableDropdownField<T> extends StatefulWidget {
  final T? value;
  final List<DropdownItem<T>> items;
  final String labelText;
  final String hintText;
  final ValueChanged<T?> onChanged;

  const SearchableDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.labelText,
    required this.onChanged,
    this.hintText = 'Search...',
  });

  @override
  State<SearchableDropdownField<T>> createState() => _SearchableDropdownFieldState<T>();
}

class DropdownItem<T> {
  final T value;
  final String label;
  final String? subtitle;

  const DropdownItem({required this.value, required this.label, this.subtitle});
}

class _SearchableDropdownFieldState<T> extends State<SearchableDropdownField<T>> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  List<DropdownItem<T>> _filtered = [];
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    // Set initial text if value is already selected
    if (widget.value != null) {
      final match = widget.items.where((i) => i.value == widget.value).firstOrNull;
      if (match != null) _controller.text = match.label;
    }
  }

  @override
  void didUpdateWidget(covariant SearchableDropdownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.value == null) {
      _controller.clear();
    } else if (oldWidget.value != widget.value && widget.value != null) {
      final match = widget.items.where((i) => i.value == widget.value).firstOrNull;
      if (match != null) _controller.text = match.label;
    }
  }

  @override
  void dispose() {
    _closeOverlay();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _openOverlay() {
    if (_isOpen) return;
    _isOpen = true;
    _overlayEntry = _buildOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOpen = false;
  }

  OverlayEntry _buildOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;
    final cardColor = Theme.of(context).cardColor;
    final hintColor = Theme.of(context).hintColor;

    return OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            // Fullscreen backdrop tap target to dismiss dropdown when tapping outside
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  _closeOverlay();
                  _focusNode.unfocus();
                },
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 2),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                color: cardColor,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 220,
                    maxWidth: size.width,
                    minWidth: size.width,
                  ),
                  child: StatefulBuilder(
                    builder: (context, setOverlayState) {
                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: _filtered.isEmpty ? 1 : _filtered.length,
                        itemBuilder: (context, index) {
                          if (_filtered.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No results', style: TextStyle(color: Colors.grey)),
                            );
                          }
                          final item = _filtered[index];
                          return InkWell(
                            onTap: () {
                              _controller.text = item.label;
                              widget.onChanged(item.value);
                              _closeOverlay();
                              _focusNode.unfocus();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item.label,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                  if (item.subtitle != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      item.subtitle!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: hintColor,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filtered = query.isEmpty
          ? widget.items
          : widget.items.where((item) {
              final lq = query.toLowerCase();
              return item.label.toLowerCase().contains(lq) ||
                  (item.subtitle?.toLowerCase().contains(lq) ?? false);
            }).toList();
    });
    // refresh overlay
    _overlayEntry?.markNeedsBuild();
    if (!_isOpen) _openOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _onSearchChanged,
        onTap: () {
          _filtered = widget.items;
          _openOverlay();
        },
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged(null);
                    _filtered = widget.items;
                    if (_isOpen) _overlayEntry?.markNeedsBuild();
                  },
                ),
              const Icon(Icons.arrow_drop_down, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
