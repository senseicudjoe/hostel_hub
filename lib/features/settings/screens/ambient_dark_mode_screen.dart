import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Ambient Dark Mode Settings Screen
//
// Lets the user choose between three strategies:
//   Manual   — simple on/off toggle
//   Scheduled — dark mode between two times (overnight supported)
//   Sensor   — follows the ambient light sensor (Android only)
// ─────────────────────────────────────────────────────────────────────────────

class AmbientDarkModeScreen extends ConsumerStatefulWidget {
  const AmbientDarkModeScreen({super.key});

  @override
  ConsumerState<AmbientDarkModeScreen> createState() =>
      _AmbientDarkModeScreenState();
}

class _AmbientDarkModeScreenState
    extends ConsumerState<AmbientDarkModeScreen> {
  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(themeModeProvider.notifier);
    final themeMode = ref.watch(themeModeProvider);
    final config = notifier.config;
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Dark Mode')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Status banner ─────────────────────────────────────────────────
          _StatusBanner(isDark: isDark, strategy: config.strategy),
          const SizedBox(height: 20),

          // ── Mode selector ─────────────────────────────────────────────────
          _SectionLabel(text: 'MODE'),
          _ModeCard(
            config: config,
            onStrategyChanged: (strategy) {
              notifier.updateConfig(config.copyWith(strategy: strategy));
            },
          ),
          const SizedBox(height: 20),

          // ── Strategy-specific settings ────────────────────────────────────
          if (config.strategy == DarkModeStrategy.manual) ...[
            _SectionLabel(text: 'SETTINGS'),
            _ManualCard(
              isDark: config.manualDark,
              onChanged: (v) =>
                  notifier.updateConfig(config.copyWith(manualDark: v)),
            ),
          ] else if (config.strategy == DarkModeStrategy.scheduled) ...[
            _SectionLabel(text: 'SCHEDULE'),
            _ScheduleCard(config: config, notifier: notifier),
          ] else if (config.strategy == DarkModeStrategy.sensor) ...[
            _SectionLabel(text: 'SENSOR SETTINGS'),
            _SensorCard(config: config, notifier: notifier),
          ],

          const SizedBox(height: 24),
          _HintCard(strategy: config.strategy),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Banner
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.isDark, required this.strategy});

  final bool isDark;
  final DarkModeStrategy strategy;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardDark
            : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.dividerDark
              : AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              key: ValueKey(isDark),
              size: 32,
              color: isDark ? Colors.white70 : AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDark ? 'Dark Mode is Active' : 'Light Mode is Active',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _strategyLabel(strategy),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _strategyLabel(DarkModeStrategy s) => switch (s) {
        DarkModeStrategy.manual => 'Controlled manually',
        DarkModeStrategy.scheduled => 'Following your schedule',
        DarkModeStrategy.sensor => 'Following ambient light sensor',
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Mode Selector Card
// ─────────────────────────────────────────────────────────────────────────────

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.config, required this.onStrategyChanged});

  final DarkModeConfig config;
  final ValueChanged<DarkModeStrategy> onStrategyChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingsContainer(
      child: Column(
        children: [
          _ModeOption(
            icon: Icons.toggle_on_rounded,
            title: 'Manual',
            subtitle: 'Turn dark mode on or off yourself',
            selected: config.strategy == DarkModeStrategy.manual,
            onTap: () => onStrategyChanged(DarkModeStrategy.manual),
          ),
          Divider(height: 1, color: AppColors.dividerOf(context)),
          _ModeOption(
            icon: Icons.schedule_rounded,
            title: 'Scheduled',
            subtitle: 'Switch automatically between set times',
            selected: config.strategy == DarkModeStrategy.scheduled,
            onTap: () => onStrategyChanged(DarkModeStrategy.scheduled),
          ),
          Divider(height: 1, color: AppColors.dividerOf(context)),
          _ModeOption(
            icon: Icons.sensors_rounded,
            title: 'Ambient Sensor',
            subtitle: 'Responds to the room\'s light level',
            selected: config.strategy == DarkModeStrategy.sensor,
            onTap: () => onStrategyChanged(DarkModeStrategy.sensor),
          ),
        ],
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.primary
        : AppColors.textMutedOf(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textOf(context),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textMutedOf(context),
        ),
      ),
      trailing: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade400,
            width: 2,
          ),
        ),
        child: selected
            ? Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Manual Settings Card
// ─────────────────────────────────────────────────────────────────────────────

class _ManualCard extends StatelessWidget {
  const _ManualCard({required this.isDark, required this.onChanged});

  final bool isDark;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingsContainer(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          color: AppColors.textMutedOf(context),
          size: 22,
        ),
        title: Text(
          'Dark Mode',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textOf(context),
          ),
        ),
        subtitle: Text(
          isDark ? 'Currently on' : 'Currently off',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMutedOf(context),
          ),
        ),
        trailing: Switch(value: isDark, onChanged: onChanged),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Schedule Settings Card
// ─────────────────────────────────────────────────────────────────────────────

class _ScheduleCard extends ConsumerWidget {
  const _ScheduleCard({required this.config, required this.notifier});

  final DarkModeConfig config;
  final AmbientThemeNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startTime = TimeOfDay(
      hour: config.scheduleStartHour,
      minute: config.scheduleStartMinute,
    );
    final endTime = TimeOfDay(
      hour: config.scheduleEndHour,
      minute: config.scheduleEndMinute,
    );

    return _SettingsContainer(
      child: Column(
        children: [
          _TimeTile(
            icon: Icons.brightness_2_rounded,
            label: 'Dark from',
            time: startTime,
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: startTime,
                helpText: 'Dark mode starts at',
              );
              if (picked != null) {
                notifier.updateConfig(config.copyWith(
                  scheduleStartHour: picked.hour,
                  scheduleStartMinute: picked.minute,
                ));
              }
            },
          ),
          Divider(height: 1, color: AppColors.dividerOf(context)),
          _TimeTile(
            icon: Icons.wb_sunny_rounded,
            label: 'Until',
            time: endTime,
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: endTime,
                helpText: 'Dark mode ends at',
              );
              if (picked != null) {
                notifier.updateConfig(config.copyWith(
                  scheduleEndHour: picked.hour,
                  scheduleEndMinute: picked.minute,
                ));
              }
            },
          ),
        ],
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.icon,
    required this.label,
    required this.time,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
      leading: Icon(icon, color: AppColors.textMutedOf(context), size: 22),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textOf(context),
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          time.format(context),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sensor Settings Card
//
// Uses local state for the slider value so every drag frame is instant.
// The provider (and Hive) are only updated when the user lifts their finger
// (onChangeEnd), preventing the rebuild-on-every-frame bug that made the
// slider feel sticky/unresponsive.
// ─────────────────────────────────────────────────────────────────────────────

class _SensorCard extends ConsumerStatefulWidget {
  const _SensorCard({required this.config, required this.notifier});

  final DarkModeConfig config;
  final AmbientThemeNotifier notifier;

  @override
  ConsumerState<_SensorCard> createState() => _SensorCardState();
}

class _SensorCardState extends ConsumerState<_SensorCard> {
  // Local copy of the threshold — drives the slider display every frame.
  // Only the _committed value goes to the provider / Hive.
  late double _localThreshold;

  @override
  void initState() {
    super.initState();
    _localThreshold = widget.config.luxThreshold;
  }

  @override
  void didUpdateWidget(_SensorCard old) {
    super.didUpdateWidget(old);
    // Sync if the config changed from outside (e.g., a reset) but only when
    // the slider isn't actively being dragged.
    if (old.config.luxThreshold != widget.config.luxThreshold) {
      _localThreshold = widget.config.luxThreshold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final luxAsync = ref.watch(luxReadingProvider);
    final currentLux = luxAsync.value ?? widget.notifier.lastLux;

    return _SettingsContainer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Threshold header row ────────────────────────────────────────
            Row(
              children: [
                Icon(
                  Icons.sensors_rounded,
                  size: 22,
                  color: AppColors.textMutedOf(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Light Threshold',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textOf(context),
                    ),
                  ),
                ),
                // Badge updates every frame because it reads local state.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 100),
                  child: Container(
                    key: ValueKey(_localThreshold.round()),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_localThreshold.round()} lux',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Switch to dark mode when light drops below this level',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMutedOf(context),
              ),
            ),

            // ── Slider ─────────────────────────────────────────────────────
            // onChanged  → local setState only (no provider/Hive write) → smooth
            // onChangeEnd → commit to provider + Hive once drag completes
            Slider(
              value: _localThreshold.clamp(0, 1000),
              min: 0,
              max: 1000,
              divisions: 200,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.primary.withValues(alpha: 0.15),
              onChanged: (v) {
                setState(() => _localThreshold = v);
              },
              onChangeEnd: (v) {
                widget.notifier.updateConfig(
                  widget.config.copyWith(luxThreshold: v.roundToDouble()),
                );
              },
            ),

            // ── Scale labels ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '0 lux\nPitch dark',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textMutedOf(context),
                    ),
                  ),
                  Text(
                    '100 lux\nDim room',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textMutedOf(context),
                    ),
                  ),
                  Text(
                    '1000 lux\nBright office',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textMutedOf(context),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Divider(height: 1, color: AppColors.dividerOf(context)),
            const SizedBox(height: 14),

            // ── Live reading ────────────────────────────────────────────────
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 20,
                  color: AppColors.textMutedOf(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Current reading',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textOf(context),
                    ),
                  ),
                ),
                luxAsync.when(
                  data: (lux) => _LuxBadge(lux: lux, threshold: _localThreshold),
                  loading: () => _LuxBadge(
                    lux: currentLux,
                    threshold: _localThreshold,
                  ),
                  error: (e, _) => Text(
                    'Sensor unavailable',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMutedOf(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LuxBadge extends StatelessWidget {
  const _LuxBadge({required this.lux, required this.threshold});

  final int? lux;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    if (lux == null) {
      return Text(
        'Reading…',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textMutedOf(context),
        ),
      );
    }
    final dark = lux! < threshold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: dark
            ? AppColors.cardDark.withValues(alpha: 0.8)
            : AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            size: 14,
            color: dark ? Colors.white70 : AppColors.warning,
          ),
          const SizedBox(width: 6),
          Text(
            '$lux lux',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: dark ? Colors.white : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hint Card — contextual tips per mode
// ─────────────────────────────────────────────────────────────────────────────

class _HintCard extends StatelessWidget {
  const _HintCard({required this.strategy});

  final DarkModeStrategy strategy;

  @override
  Widget build(BuildContext context) {
    final (icon, text) = switch (strategy) {
      DarkModeStrategy.manual => (
          Icons.info_outline_rounded,
          'Switch dark mode on or off any time from here or from the Profile screen.',
        ),
      DarkModeStrategy.scheduled => (
          Icons.schedule_rounded,
          'The app switches automatically at the times you set — perfect for night reading. Overnight ranges are supported.',
        ),
      DarkModeStrategy.sensor => (
          Icons.sensors_rounded,
          'Hold your phone in normal reading position. Lower the threshold to require a darker room before switching.',
        ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.info),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.textMutedOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared layout helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AppColors.textMutedOf(context),
        ),
      ),
    );
  }
}

class _SettingsContainer extends StatelessWidget {
  const _SettingsContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerOf(context)),
      ),
      child: child,
    );
  }
}
