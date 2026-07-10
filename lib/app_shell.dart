import 'package:flutter/material.dart';

import 'l10n/app_strings.dart';
import 'screen_registry.dart';
import 'theme.dart';
import 'util/haptics.dart';

/// Bottom UITabBar-style shell holding the four primary tabs
/// (Cleaner / Mode / dB Meter / Stereo). The active tab is shown in a
/// blue->teal gradient pill, matching the native design.
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index = widget.initialTab.clamp(0, kTabScreenIds.length - 1);

  static const List<_TabDef> _tabs = <_TabDef>[
    _TabDef('Cleaner', Icons.cleaning_services_outlined),
    _TabDef('Mode', Icons.tune),
    _TabDef('dB Meter', Icons.graphic_eq),
    _TabDef('Stereo', Icons.spatial_audio_off),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = kTabScreenIds
        .map((id) => KeyedSubtree(key: ValueKey(id), child: buildScreenById(context, id)))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: _GradientTabBar(
        index: _index,
        tabs: _tabs,
        onChanged: (i) {
          if (i == _index) return;
          Haptics.select();
          setState(() => _index = i);
        },
      ),
    );
  }
}

class _TabDef {
  const _TabDef(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _GradientTabBar extends StatelessWidget {
  const _GradientTabBar({
    required this.index,
    required this.tabs,
    required this.onChanged,
  });

  final int index;
  final List<_TabDef> tabs;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.neutralBorder, width: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            for (var i = 0; i < tabs.length; i++)
              Expanded(
                child: _TabButton(
                  def: tabs[i],
                  selected: i == index,
                  onTap: () => onChanged(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.def, required this.selected, required this.onTap});

  final _TabDef def;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(def.icon,
            size: 20, color: selected ? Colors.white : AppColors.textSecondary),
        if (selected) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              context.l10n.tr(def.label),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ],
    );

    // The label text is only painted for the selected tab, so give every tab a
    // spoken name and selected state for screen readers (VoiceOver/TalkBack).
    return Semantics(
      button: true,
      selected: selected,
      label: context.l10n.tr(def.label),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 44,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.ctaGradient : null,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );
  }
}
