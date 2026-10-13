import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../layout/shell_commands.dart';
import '../../../theme/app_tokens.dart';
import '../../../theme/theme_extensions.dart';
import '../cubit/links_view_cubit.dart';
import '../link_query.dart';

class LinksToolbar extends StatefulWidget {
  const LinksToolbar({super.key});

  @override
  State<LinksToolbar> createState() => _LinksToolbarState();
}

class _LinksToolbarState extends State<LinksToolbar> {
  final _controller = TextEditingController();
  final _focus = FocusNode(debugLabel: 'links-search');
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    ShellCommands.focusSearch.addListener(_onFocusCommand);
  }

  void _onFocusCommand() {
    if (!mounted) return;
    _focus.requestFocus();
    _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
  }

  void _onChanged(String value) {
    setState(() {}); // toggles the clear button
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (mounted) context.read<LinksViewCubit>().search(value);
    });
  }

  void _clear() {
    _controller.clear();
    _debounce?.cancel();
    context.read<LinksViewCubit>().search('');
    setState(() {});
  }

  @override
  void dispose() {
    ShellCommands.focusSearch.removeListener(_onFocusCommand);
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final query = context.select<LinksViewCubit, LinkQuery>((cubit) => cubit.state.query);

    final search = SizedBox(
      height: 36,
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        onChanged: _onChanged,
        style: context.text.body,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search by alias, code or URL',
          contentPadding: const EdgeInsets.symmetric(horizontal: Space.s3),
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          prefixIconConstraints: const BoxConstraints(minWidth: 36),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(tooltip: 'Clear search', onPressed: _clear, icon: const Icon(Icons.close_rounded, size: 16)),
        ),
      ),
    );

    final filter = SegmentedButton<LinkFilter>(
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity(horizontal: -2, vertical: -2)),
      segments: const [
        ButtonSegment(value: LinkFilter.all, label: Text('All')),
        ButtonSegment(value: LinkFilter.custom, label: Text('Custom')),
        ButtonSegment(value: LinkFilter.generated, label: Text('Generated')),
      ],
      selected: {query.filter},
      onSelectionChanged: (s) => context.read<LinksViewCubit>().setFilter(s.first),
    );

    final sort = MenuAnchor(
      menuChildren: [
        for (final s in LinkSort.values)
          MenuItemButton(
            leadingIcon: Icon(
              Icons.check_rounded,
              size: 16,
              color: s == query.sort ? c.accent : const Color(0x00000000),
            ),
            onPressed: () => context.read<LinksViewCubit>().setSort(s),
            child: Text(s.label),
          ),
      ],
      builder: (context, controller, _) => OutlinedButton.icon(
        onPressed: () => controller.isOpen ? controller.close() : controller.open(),
        icon: const Icon(Icons.swap_vert_rounded, size: 16),
        label: Text(query.sort.label),
        style: const ButtonStyle(visualDensity: VisualDensity(horizontal: -2, vertical: -2)),
      ),
    );

    // An external reset ("Clear filters") must also clear the text box.
    return BlocListener<LinksViewCubit, LinksViewState>(
      listenWhen: (prev, curr) => prev.query.search.isNotEmpty && curr.query.search.isEmpty,
      listener: (context, _) {
        if (_controller.text.isNotEmpty) setState(_controller.clear);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 640) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                search,
                const SizedBox(height: Space.s2),
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: filter),
                    ),
                    const SizedBox(width: Space.s2),
                    sort,
                  ],
                ),
              ],
            );
          }
          return Row(
            children: [
              ConstrainedBox(constraints: const BoxConstraints(maxWidth: 360), child: search),
              const SizedBox(width: Space.s3),
              filter,
              const Spacer(),
              sort,
            ],
          );
        },
      ),
    );
  }
}
