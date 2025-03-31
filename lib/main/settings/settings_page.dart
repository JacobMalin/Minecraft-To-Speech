import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../blacklist/blacklist_model.dart';
import '../../setup/discord_model.dart';
import '../../setup/text_field_context.dart';
import '../instance/tts_model.dart';
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

    final SettingsModel settings =
        Provider.of<SettingsModel>(context, listen: false);
    _tabController = TabController(
      initialIndex: settings.tabIndex,
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
                  onTap: (value) =>
                      Provider.of<SettingsModel>(context, listen: false)
                          .tabIndex = value,
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
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
              width: 394,
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
                  ButtonTile(
                    text: 'Edit Blacklist',
                    buttonChild: const Icon(Icons.edit),
                    onPressed: () async => BlacklistModel.edit(),
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

class _TtsSettings extends StatefulWidget {
  const _TtsSettings();

  // TODO: Add tts options

  @override
  State<_TtsSettings> createState() => _TtsSettingsState();
}

class _TtsSettingsState extends State<_TtsSettings> {
  late String _voice;
  late double _volume;
  late double _rate;

  late final Map<String, String> _voices;

  final _tts = TtsModel();

  @override
  void initState() {
    super.initState();

    _voice = _tts.voice;
    _volume = _tts.volume * 100;
    _rate = _tts.rate;

    unawaited(() async {
      _voices = await _tts.getVoices();
    }());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            DropdownMenu<String>(
              initialSelection: _voice,
              width: 200,
              dropdownMenuEntries: _voices.entries
                  .map(
                    (entry) =>
                        DropdownMenuEntry(value: entry.key, label: entry.value),
                  )
                  .toList(),
              onSelected: (value) async {
                setState(() => _voice = value!);
                await _tts.setVoice(value!);
                await _tts.clear();
                await _tts.speak('Voice set to ${_voices[value]}.');
              },
            ),
            TextButton(
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(
                  Theme.of(context).colorScheme.surfaceBright,
                ),
                minimumSize: const WidgetStatePropertyAll(Size.zero),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                ),
              ),
              onPressed: () async {
                await _tts.clear();
                await _tts
                    .speak('Minecraft to Speech text-to-speech is working!');
              },
              child: const Text('Test'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text('Volume: ${_volume.toInt()}%'),
        const SizedBox(height: 4),
        Row(
          spacing: 8,
          children: [
            const SizedBox(
              width: 24,
              child: Align(alignment: Alignment.centerRight, child: Text('0')),
            ),
            Expanded(
              child: Slider(
                value: _volume,
                onChanged: (value) => setState(() => _volume = value),
                onChangeEnd: (value) async {
                  await _tts.setVolume(value / 100);
                  await _tts.clear();
                  await _tts.speak('Volume set to ${value.toInt()} percent.');
                },
                max: 100,
                label: '${_volume.toInt()}%',
              ),
            ),
            const SizedBox(
              width: 24,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('100'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text('Speech Rate: ${_tts.formatRate(_rate)}'),
        const SizedBox(height: 4),
        Row(
          spacing: 8,
          children: [
            SizedBox(
              width: 24,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('${_tts.rateMin.toInt()}'),
              ),
            ),
            Expanded(
              child: Slider(
                value: _rate,
                onChanged: (value) => setState(() => _rate = value),
                onChangeEnd: (value) async {
                  await _tts.setRate(value);
                  await _tts.clear();
                  await _tts.speak('Speech rate set to ${_tts.rateAsString}.');
                },
                min: _tts.rateMin,
                max: _tts.rateMax,
                divisions:
                    ((_tts.rateMax - _tts.rateMin) / _tts.rateStep).round(),
                label: _tts.formatRate(_rate),
              ),
            ),
            SizedBox(
              width: 24,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('${_tts.rateMax.toInt()}'),
              ),
            ),
          ],
        ),
      ],
    );
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
              contextMenuBuilder: TextFieldContext.builder,
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
        Focus(
          descendantsAreFocusable: false,
          canRequestFocus: false,
          skipTraversal: true,
          child: TextButton(
            style: ButtonStyle(
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              textStyle: WidgetStatePropertyAll(
                Theme.of(context).textTheme.bodySmall,
              ),
              foregroundColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.onSurface,
              ),
              padding: const WidgetStatePropertyAll(EdgeInsets.zero),
            ),
            onPressed: _onChanged,
            child: Text(
              _text,
              style:
                  Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 14),
            ),
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

/// A tile with a button and text.
class ButtonTile extends StatelessWidget {
  /// A tile with a button and text.
  const ButtonTile({
    required String text,
    required Widget buttonChild,
    required VoidCallback onPressed,
    super.key,
  })  : _text = text,
        _buttonChild = buttonChild,
        _onPressed = onPressed;

  final String _text;
  final Widget _buttonChild;
  final VoidCallback _onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          _text,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 14),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: TextButton(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.surfaceBright,
              ),
              padding: const WidgetStatePropertyAll(EdgeInsets.zero),
              minimumSize: const WidgetStatePropertyAll(Size(49, 32)),
            ),
            onPressed: _onPressed,
            child: _buttonChild,
          ),
        ),
      ],
    );
  }
}
