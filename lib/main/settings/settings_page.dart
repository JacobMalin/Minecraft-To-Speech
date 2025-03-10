import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'settings_model.dart';

/// The settings page. This page allows the user to change settings.
class SettingsPage extends StatefulWidget {
  /// The settings page. This page allows the user to change settings.
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      animationDuration: Duration.zero,
      length: 3,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 11,
        horizontal: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Row(
            children: [
              Text(
                'Settings',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontSize: 26,
                    ),
              ),
              const Spacer(),
              SizedBox(
                height: 30,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: const [
                    Tab(text: 'General'),
                    Tab(text: 'Text-to-Speech'),
                    Tab(text: 'Discord'),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: const <Widget>[
                _GeneralSettings(),
                _TtsSettings(),
                _DiscordSettings(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneralSettings extends StatelessWidget {
  const _GeneralSettings();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 20,
      children: [
        _BrightnessSwitch(),
      ],
    );
  }
}

class _TtsSettings extends StatelessWidget {
  const _TtsSettings();

  // TODO: Add tts options

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('2'));
  }
}

class _DiscordSettings extends StatelessWidget {
  const _DiscordSettings();

  // TODO: Add discord settings / bot monitor

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 20,
      children: [
        _TokenField(),
      ],
    );
  }
}

class _TokenField extends StatefulWidget {
  const _TokenField();

  @override
  State<_TokenField> createState() => _TokenFieldState();
}

class _TokenFieldState extends State<_TokenField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final String? botKey =
        Provider.of<SettingsModel>(context, listen: false).botKey;
    _controller = TextEditingController(text: botKey);
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Add run in background option
    // TODO: Add open on startup option

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Discord Bot Token',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 10),
        Selector<SettingsModel, String?>(
          selector: (context, settings) => settings.botKey,
          builder: (context, botKey, child) => IntrinsicWidth(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter a token to enable the discord bot!',
              ),
              onChanged: (newKey) => botKey = newKey,
            ),
          ),
        ),
      ],
    );
  }
}

class _BrightnessSwitch extends StatelessWidget {
  const _BrightnessSwitch();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dark Mode',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 30,
          child: FittedBox(
            fit: BoxFit.fill,
            child: Selector<SettingsModel, ThemeMode>(
              selector: (context, settings) => settings.themeMode,
              builder: (context, themeMode, child) {
                return Switch(
                  value: themeMode == ThemeMode.system
                      ? Theme.of(context).brightness == Brightness.dark
                      : themeMode == ThemeMode.dark,
                  onChanged: (mode) =>
                      themeMode = mode ? ThemeMode.dark : ThemeMode.light,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
