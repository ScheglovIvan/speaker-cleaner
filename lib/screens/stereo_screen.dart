import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme.dart';
import '../util/haptics.dart';

/// Stereo Mixer — the "Stereo" tab (screen 0002).
///
/// Ground truth: source/0002.json (375pt reference). Layout, top to bottom:
///   * "Stereo Mixer" title (bold, ~28pt).
///   * A live waveform panel — rounded card (r=18, 1px #B6DFFF border, faint
///     blue gradient fill) holding 12 animated equalizer bars (w=6, r=3) that
///     share a baseline; bars alternate cyan/blue with a purple accent every
///     fourth bar, matching the native heights.
///   * "Active Channels" section header.
///   * A 2x2 grid of channel toggle cards (#EBF6FF fill, r=20): Left Speaker,
///     Right Speaker (selected by default — bright #007AFF border), Top Earpiece
///     and Auto Cycle. Each card has a white icon disc and a caption.
///   * A full-width "Stop" pill (#FFEAE9 fill, r≈25, red #FF3B30 label).
///
/// The native screen also carried a Google/VTMonet native ad above the content
/// and a banner beneath the tab bar. This clone ships ad-free, so both are
/// dropped and the content sits directly under the title — no reserved gap.
///
/// The bottom tab bar is owned by [AppShell]; this widget renders content only.
class StereoScreen extends StatefulWidget {
  const StereoScreen({super.key});

  @override
  State<StereoScreen> createState() => _StereoScreenState();
}

class _StereoScreenState extends State<StereoScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  // Native default: 'Right Speaker' is selected (blue border).
  int _selected = 1;
  bool _playing = true;

  static const List<_Channel> _channels = <_Channel>[
    _Channel('Left Speaker', Icons.volume_down_rounded),
    _Channel('Right Speaker', Icons.volume_up_rounded),
    _Channel('Top Earpiece', Icons.phone_iphone_rounded),
    _Channel('Auto Cycle', Icons.sync_rounded),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectChannel(int index) {
    Haptics.select();
    setState(() {
      _selected = index;
      _playing = true;
      if (!_controller.isAnimating) _controller.repeat();
    });
  }

  void _stop() {
    Haptics.impact();
    setState(() {
      _playing = false;
      _controller.stop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
                child: Text(
                  context.l10n.tr('Stereo Mixer'),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _WaveformPanel(controller: _controller, playing: _playing),
              const SizedBox(height: 26),
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  context.l10n.tr('Active Channels'),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _channelRow(0, 1),
              const SizedBox(height: 14),
              _channelRow(2, 3),
              const SizedBox(height: 24),
              _StopButton(onTap: _stop),
            ],
          ),
        ),
      ),
    );
  }

  Widget _channelRow(int left, int right) {
    return Row(
      children: [
        Expanded(child: _card(left)),
        const SizedBox(width: 14),
        Expanded(child: _card(right)),
      ],
    );
  }

  Widget _card(int index) => _ChannelCard(
        channel: _channels[index],
        selected: _selected == index,
        onTap: () => _selectChannel(index),
      );
}

class _Channel {
  const _Channel(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Rounded panel with 12 animated equalizer bars sharing a baseline.
class _WaveformPanel extends StatelessWidget {
  const _WaveformPanel({required this.controller, required this.playing});

  final AnimationController controller;
  final bool playing;

  // Native bar heights (source/0002.json), normalised against the tallest bar.
  static const List<double> _base = <double>[
    0.49, 0.63, 0.88, 1.0, 0.90, 0.61, 0.76, 0.97, 0.95, 0.76, 0.53, 0.71,
  ];

  static const Color _cyan = Color(0xFF3FC8ED);
  static const Color _blue = Color(0xFF2196E3);
  static const Color _purpleHi = Color(0xFFB39DFB);
  static const Color _purpleLo = Color(0xFF8B6EF0);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Purely decorative equalizer animation — describe it once and hide the
      // individual bars from the accessibility tree.
      label: context.l10n.tr(
          playing ? 'Audio waveform, playing' : 'Audio waveform, stopped'),
      excludeSemantics: true,
      child: Container(
        height: 128,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF6FF), Color(0xFFF4FBFF)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFB6DFFF), width: 1),
        ),
        child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final t = controller.value;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < _base.length; i++)
                _bar(i, t),
            ],
          );
        },
        ),
      ),
    );
  }

  Widget _bar(int i, double t) {
    final base = _base[i];
    // Idle: a calm silhouette. Playing: bars pulse with a per-bar phase offset.
    final double amp = playing
        ? 0.55 + 0.45 * (0.5 + 0.5 * math.sin(t * 2 * math.pi + i * 0.7))
        : 0.5;
    final double factor = (0.32 + 0.68 * base * amp).clamp(0.12, 1.0);
    final bool purple = i % 4 == 2;
    return Container(
      width: 6,
      height: 64 * factor,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: purple
              ? const [_purpleHi, _purpleLo]
              : const [_cyan, _blue],
        ),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

/// A channel toggle card (#EBF6FF fill, r=20). Selected -> bright blue border.
class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.channel,
    required this.selected,
    required this.onTap,
  });

  final _Channel channel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: context.l10n.tr(channel.label),
      excludeSemantics: true,
      child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFFEBF6FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : const Color(0xFFCFE7FB),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(channel.icon, size: 22, color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.tr(channel.label),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2B2F3B),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

/// Full-width "Stop" pill — light-red fill (#FFEAE9), red label.
class _StopButton extends StatelessWidget {
  const _StopButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Ink(
          height: 51,
          decoration: BoxDecoration(
            color: AppColors.dangerBg,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(
              context.l10n.tr('Stop'),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
