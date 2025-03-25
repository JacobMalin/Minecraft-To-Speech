import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../setup/discord_model.dart';
import 'settings_box.dart';

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
    return Consumer<SettingsModel>(
      builder: (context, settings, child) {
        final brightnessValue = settings.themeMode == ThemeMode.system
            ? Theme.of(context).brightness == Brightness.dark
            : settings.themeMode == ThemeMode.dark;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 402,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchTile(
                    text: 'Dark Mode',
                    value: brightnessValue,
                    onChanged: () => settings.themeMode =
                        brightnessValue ? ThemeMode.light : ThemeMode.dark,
                  ),
                  SwitchTile(
                    text: 'Hide Update Messages',
                    value: settings.hideUpdate,
                    onChanged: () => settings.hideUpdate = !settings.hideUpdate,
                  ),
                  SwitchTile(
                    text: 'Automatically Update',
                    value: settings.autoUpdate,
                    onChanged: () => settings.autoUpdate = !settings.autoUpdate,
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        );
      },
    );
  }
}

class _TtsSettings extends StatelessWidget {
  const _TtsSettings();

  // TODO: Add tts options

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('No settings yet!'));
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

  String? get _errorText {
    final String text = _controller.text;
    if (text.isEmpty) return null;
    if (!RegExp(DiscordModel.tokenFormat).hasMatch(text)) {
      return 'Invalid token format!';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final String? botKey =
        Provider.of<DiscordModel>(context, listen: false).botKey;
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
        Consumer<DiscordModel>(
          builder: (context, discord, child) => IntrinsicWidth(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Enter a token to enable the discord bot!',
                errorText: _errorText,
              ),
              onChanged: (newKey) => discord.botKey = newKey,
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
            child: Consumer<SettingsModel>(
              builder: (context, settings, child) {
                return Switch(
                  value: settings.themeMode == ThemeMode.system
                      ? Theme.of(context).brightness == Brightness.dark
                      : settings.themeMode == ThemeMode.dark,
                  onChanged: (mode) => settings.themeMode =
                      mode ? ThemeMode.dark : ThemeMode.light,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// A tile with a switch and text. A better version of SwitchListTile.
class SwitchTile extends StatelessWidget {
  /// A tile with a switch and text. A better version of SwitchListTile.
  const SwitchTile({
    required String text,
    required bool value,
    required VoidCallback onChanged,
    super.key,
  })  : _text = text,
        _value = value,
        _onChanged = onChanged;

  final String _text;
  final bool _value;
  final VoidCallback _onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton(
          style: ButtonStyle(
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            textStyle: WidgetStatePropertyAll(
              Theme.of(context).textTheme.bodySmall,
            ),
            foregroundColor: WidgetStatePropertyAll(
              Theme.of(context).colorScheme.onSurface,
            ),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 2),
            ),
          ),
          onPressed: _onChanged,
          child: Text(
            _text,
            style:
                Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 14),
          ),
        ),
        const Spacer(),
        SizedBox(
          height: 30,
          child: FittedBox(
            fit: BoxFit.fill,
            child: Switch(
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              value: _value,
              onChanged: (_) => _onChanged(),
            ),
          ),
        ),
      ],
    );
  }
}
