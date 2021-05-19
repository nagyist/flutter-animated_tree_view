import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tree_structure_view/listenable_node/base/node_update_notifier.dart';
import 'package:tree_structure_view/node/base/i_node.dart';
import 'package:tree_structure_view/tree_list_views/controllers/animated_list_controller.dart';
import 'package:tree_structure_view/tree_list_views/controllers/tree_list_view_controller.dart';
import 'package:tree_structure_view/tree_list_views/widgets/expandable_node_item.dart';

typedef LeveledItemWidgetBuilder<T extends INode<T>> = Widget Function(
    BuildContext context, int level, INode<T> item);

const DEFAULT_INDENT_PADDING = 24.0;
const DEFAULT_EXPAND_ICON = const Icon(Icons.keyboard_arrow_down);
const DEFAULT_COLLAPSE_ICON = const Icon(Icons.keyboard_arrow_up);

/// The default [TreeListView] uses a [Node] internally, which is based on the
/// [Map] data structure for maintaining the children states.
/// The [Node] does not allow insertion and removal of
/// items at index positions. This allows for more efficient insertion and
/// retrieval of items at child nodes, as child items can be readily accessed
/// using the map keys.
///
/// The complexity for accessing child nodes in [TreeListView] is simply O(node_level).
/// e.g. for path './.level1/level2', complexity is simply O(2).
///
/// For a [TreeListView] that allows for insertion and removal of
/// items at index positions, use the alternate [IndexedTreeListView].
///
abstract class ITreeListView<T extends INode<T>> extends StatefulWidget {
  final ITreeListViewController<T> controller;
  final LeveledItemWidgetBuilder<T> builder;
  final bool showExpansionIndicator;
  final Icon expandIcon;
  final Icon collapseIcon;
  final double indentPadding;
  final ValueSetter<T>? onItemTap;
  final bool? primary;
  final ScrollPhysics? physics;
  final bool? shrinkWrap;
  final EdgeInsetsGeometry? padding;

  const ITreeListView({
    Key? key,
    required this.builder,
    required this.controller,
    this.onItemTap,
    this.primary,
    this.physics,
    this.shrinkWrap,
    this.padding,
    this.showExpansionIndicator = true,
    this.indentPadding = DEFAULT_INDENT_PADDING,
    this.expandIcon = DEFAULT_EXPAND_ICON,
    this.collapseIcon = DEFAULT_COLLAPSE_ICON,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ITreeListViewState<T>();
}

class _ITreeListViewState<T extends INode<T>> extends State<ITreeListView<T>> {
  static const TAG = "TreeListView";

  StreamSubscription<NodeAddEvent<T>>? _addedNodesSubscription;
  StreamSubscription<NodeInsertEvent<T>>? _insertNodesSubscription;

  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();

    final animatedListController = AnimatedListController<T>(
      listKey: listKey,
      listenableNode: widget.controller.root,
      removedItemBuilder: buildRemovedItem,
    );

    widget.controller.attach(animatedListController);
    observeTreeUpdates();
  }

  Widget build(BuildContext context) {
    final list = widget.controller.animatedListController.list;

    return AnimatedList(
      key: listKey,
      initialItemCount: list.length,
      controller: widget.controller.scrollController,
      primary: widget.primary,
      physics: widget.physics,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap!,
      itemBuilder: (context, index, animation) => ExpandableNodeItem<T>(
        builder: widget.builder,
        animatedListController: widget.controller.animatedListController,
        scrollController: widget.controller.scrollController,
        node: widget.controller.animatedListController.list[index],
        animation: animation,
        indentPadding: widget.indentPadding,
        showExpansionIndicator: widget.showExpansionIndicator,
        expandIcon: widget.expandIcon,
        collapseIcon: widget.collapseIcon,
        onItemTap: widget.onItemTap,
      ),
    );
  }

  Widget buildRemovedItem(
          T item, BuildContext context, Animation<double> animation) =>
      ExpandableNodeItem<T>(
        builder: widget.builder,
        animatedListController: widget.controller.animatedListController,
        scrollController: widget.controller.scrollController,
        node: item,
        remove: true,
        animation: animation,
        indentPadding: widget.indentPadding,
        showExpansionIndicator: widget.showExpansionIndicator,
        expandIcon: widget.expandIcon,
        collapseIcon: widget.collapseIcon,
        onItemTap: widget.onItemTap,
      );

  void observeTreeUpdates() {
    _addedNodesSubscription = widget.controller.root.addedNodes
        .listen(_handleItemAdditionEvent);
    _insertNodesSubscription = widget.controller.root.insertedNodes
        .listen(_handleItemInsertEvent);
  }

  void cancelTreeUpdates() {
    _addedNodesSubscription?.cancel();
    _insertNodesSubscription?.cancel();
  }

  void _handleItemAdditionEvent(NodeAddEvent<T> event) {
    Future.delayed(
      Duration(milliseconds: 300),
      () => widget.controller.scrollController.scrollToIndex(
        widget.controller.animatedListController
            .indexOf(event.items.first as T),
      ),
    );
  }

  void _handleItemInsertEvent(NodeInsertEvent<T> event) {
    Future.delayed(
      Duration(milliseconds: 300),
      () => widget.controller.scrollController.scrollToIndex(
        widget.controller.animatedListController
            .indexOf(event.items.first as T),
      ),
    );
  }

  @override
  void dispose() {
    cancelTreeUpdates();
    super.dispose();
  }
}
