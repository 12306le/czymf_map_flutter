import 'dart:ui';

import 'package:flutter/material.dart';

class FluxdoShell extends StatelessWidget {
  const FluxdoShell({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.body,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final useRail = MediaQuery.sizeOf(context).width >= 840;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Row(
        children: [
          if (useRail)
            _FluxdoRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: destinations,
            ),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: useRail
          ? null
          : NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: destinations,
            ),
    );
  }
}

class _FluxdoRail extends StatelessWidget {
  const _FluxdoRail({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.86),
            border: Border(
              right: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: SafeArea(
            child: SizedBox(
              width: 72,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Icon(
                    Icons.explore_rounded,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(height: 16),
                  ...destinations.asMap().entries.map((entry) {
                    final selected = entry.key == selectedIndex;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Tooltip(
                        message: entry.value.label,
                        child: Material(
                          color: selected
                              ? colorScheme.secondaryContainer
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => onDestinationSelected(entry.key),
                            child: SizedBox(
                              height: 56,
                              child: IconTheme(
                                data: IconThemeData(
                                  color: selected
                                      ? colorScheme.onSecondaryContainer
                                      : colorScheme.onSurfaceVariant,
                                ),
                                child: Center(
                                  child: selected
                                      ? entry.value.selectedIcon
                                      : entry.value.icon,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FluxdoSearchField extends StatelessWidget {
  const FluxdoSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: '清除',
                icon: const Icon(Icons.close_rounded),
                onPressed: onClear,
              ),
      ),
    );
  }
}

class FluxdoEmptyState extends StatelessWidget {
  const FluxdoEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
