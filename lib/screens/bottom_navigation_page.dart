/*
 *     Copyright (C) 2026 Gab Nikumura (Nanoid modifications)
 *     Copyright (C) 2026 Valeri Gokadze (original work)
 *
 *     Nanoid is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Nanoid is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Nanoid, including how to contribute,
 *     please visit: https://github.com/gabcodingapp-dev/Nanoid
 */

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nanoid/constants/app_constants.dart';
import 'package:nanoid/extensions/l10n.dart';
import 'package:nanoid/main.dart';
import 'package:nanoid/services/settings_manager.dart';
import 'package:nanoid/utilities/flutter_bottom_sheet.dart'
    show closeCurrentBottomSheet;
import 'package:nanoid/widgets/fluid_background.dart';
import 'package:nanoid/widgets/liquid_glass.dart';
import 'package:nanoid/widgets/mini_player.dart';

class BottomNavigationPage extends StatefulWidget {
  const BottomNavigationPage({required this.child, super.key});

  final StatefulNavigationShell child;

  @override
  State<BottomNavigationPage> createState() => _BottomNavigationPageState();
}

class _BottomNavigationPageState extends State<BottomNavigationPage> {
  late final _miniPlayerVisibilityStream = audioHandler.mediaItem
      .map((mediaItem) => mediaItem != null)
      .distinct();

  bool? _previousOfflineMode;

  /// Track the previously selected shell branch to detect reselects.
  int? _previousShellIndex;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.child.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        final currentIndex = widget.child.currentIndex;
        if (currentIndex != 0) {
          widget.child.goBranch(0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: ValueListenableBuilder<bool>(
        valueListenable: offlineMode,
        builder: (context, isOfflineMode, _) {
          if (_previousOfflineMode != null &&
              _previousOfflineMode != isOfflineMode) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              _handleOfflineModeChange(isOfflineMode);
            });
          }
          _previousOfflineMode = isOfflineMode;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isLargeScreen = MediaQuery.of(context).size.width >= 600;
              final items = _getNavigationItems(isOfflineMode);

              return Scaffold(
                // The Fluid backdrop sits behind everything, so it shows
                // through the transparent scaffold and any glass chrome.
                backgroundColor: fluidThemeEnabled.value
                    ? Colors.transparent
                    : null,
                body: _FluidBackdrop(
                  child: SafeArea(
                  child: Row(
                    children: [
                      if (isLargeScreen)
                        NavigationRail(
                          labelType: NavigationRailLabelType.selected,
                          destinations: items
                              .map(
                                (item) => NavigationRailDestination(
                                  icon: Icon(item.icon),
                                  selectedIcon: Icon(item.selectedIcon),
                                  label: Text(item.label),
                                ),
                              )
                              .toList(),
                          selectedIndex: _getCurrentIndex(items, isOfflineMode),
                          onDestinationSelected: (index) =>
                              _onTabTapped(index, items),
                        ),
                      Expanded(
                        child: StreamBuilder<bool>(
                          initialData: audioHandler.mediaItem.value != null,
                          stream: _miniPlayerVisibilityStream,
                          builder: (context, snapshot) {
                            final mediaQuery = MediaQuery.of(context);
                            final isMiniPlayerVisible = snapshot.data ?? false;
                            final bottomPadding = !isMiniPlayerVisible
                                ? mediaQuery.padding.bottom
                                : mediaQuery.padding.bottom +
                                      miniPlayerTotalHeight;

                            return Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                MediaQuery(
                                  data: mediaQuery.copyWith(
                                    padding: mediaQuery.padding.copyWith(
                                      bottom: bottomPadding,
                                    ),
                                  ),
                                  child: widget.child,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  child: MiniPlayer(),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                ),
                bottomNavigationBar: !isLargeScreen
                    ? ValueListenableBuilder<bool>(
                        valueListenable: liquidGlassEnabled,
                        builder: (context, glass, _) {
                          final bar = NavigationBar(
                            // Let the glass supply the fill; M3's surface tint
                            // would otherwise sit opaquely on top of the blur.
                            backgroundColor: glass
                                ? Colors.transparent
                                : null,
                            surfaceTintColor: glass
                                ? Colors.transparent
                                : null,
                            elevation: glass ? 0 : null,
                            selectedIndex: _getCurrentIndex(
                              items,
                              isOfflineMode,
                            ),
                            labelBehavior:
                                languageSetting == const Locale('en', '')
                                ? NavigationDestinationLabelBehavior
                                      .onlyShowSelected
                                : NavigationDestinationLabelBehavior.alwaysHide,
                            onDestinationSelected: (index) =>
                                _onTabTapped(index, items),
                            destinations: items
                                .map(
                                  (item) => NavigationDestination(
                                    icon: Icon(item.icon),
                                    selectedIcon: Icon(item.selectedIcon),
                                    label: item.label,
                                  ),
                                )
                                .toList(),
                          );

                          if (!glass) return bar;

                          return LiquidGlass(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(26),
                            ),
                            blur: 28,
                            child: bar,
                          );
                        },
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  List<_NavigationItem> _getNavigationItems(bool isOfflineMode) {
    final items = <_NavigationItem>[
      _NavigationItem(
        icon: FluentIcons.home_24_regular,
        selectedIcon: FluentIcons.home_24_filled,
        label: context.l10n?.home ?? 'Home',
        shellIndex: 0,
      ),
    ];

    // Only add search tab in online mode
    if (!isOfflineMode) {
      items.add(
        _NavigationItem(
          icon: FluentIcons.search_24_regular,
          selectedIcon: FluentIcons.search_24_filled,
          label: context.l10n?.search ?? 'Search',
          shellIndex: 1,
        ),
      );
    }

    items.addAll([
      _NavigationItem(
        icon: FluentIcons.book_24_regular,
        selectedIcon: FluentIcons.book_24_filled,
        label: context.l10n?.library ?? 'Library',
        shellIndex: 2,
      ),
      _NavigationItem(
        icon: FluentIcons.settings_24_regular,
        selectedIcon: FluentIcons.settings_24_filled,
        label: context.l10n?.settings ?? 'Settings',
        shellIndex: 3,
      ),
    ]);

    return items;
  }

  void _handleOfflineModeChange(bool isOfflineMode) {
    if (!mounted) return;

    final currentRoute = GoRouterState.of(context).matchedLocation;

    // If we're switching to offline mode and currently on search tab
    if (isOfflineMode && currentRoute.startsWith('/search')) {
      // Navigate to home
      widget.child.goBranch(0);
    }
  }

  void _onTabTapped(int index, List<_NavigationItem> items) {
    if (index < items.length) {
      final item = items[index];
      final isReselect = _previousShellIndex == item.shellIndex;

      // Close any open bottom sheet before switching tabs
      closeCurrentBottomSheet();

      // If user taps the same tab again, reset it to initial state.
      // Otherwise, preserve the branch state.
      if (isReselect) {
        widget.child.goBranch(item.shellIndex, initialLocation: true);
      } else {
        widget.child.goBranch(item.shellIndex);
      }

      _previousShellIndex = item.shellIndex;
    }
  }

  int _getCurrentIndex(List<_NavigationItem> items, bool isOfflineMode) {
    final currentShellIndex = widget.child.currentIndex;

    if (items.isEmpty) return 0;

    // Try to find the current shell index in the available items
    final matchedIndex = items.indexWhere(
      (item) => item.shellIndex == currentShellIndex,
    );
    if (matchedIndex != -1) return matchedIndex;

    // If the Search branch (1) is active but Search is hidden in offline mode,
    // fall back to the Home tab.
    if (isOfflineMode && currentShellIndex == 1) return 0;

    // Final fallback: return the first tab to keep UI in a valid state.
    return 0;
  }
}

class _NavigationItem {
  const _NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.shellIndex,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int shellIndex;
}

/// Paints the Fluid backdrop behind [child] while the Fluid theme is active,
/// and gets completely out of the way when it is not.
class _FluidBackdrop extends StatelessWidget {
  const _FluidBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: fluidThemeEnabled,
      builder: (context, enabled, _) {
        if (!enabled) return child;
        return Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surface,
                child: const FluidBackground(),
              ),
            ),
            child,
          ],
        );
      },
    );
  }
}
