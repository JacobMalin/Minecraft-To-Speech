import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'settings_model.dart';

/// The settings page. This page allows the user to change settings.
class SettingsPage extends StatelessWidget {
  /// The settings page. This page allows the user to change settings.
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const TokenField(),
          const BrightnessSwitch(),
        ],
      ),
    );
  }
}

/// A field to enter the discord bot token.
class TokenField extends StatefulWidget {
  /// A field to enter the discord bot token.
  const TokenField({super.key});

  @override
  State<TokenField> createState() => _TokenFieldState();
}

class _TokenFieldState extends State<TokenField> {
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
    // TODO: Add discord settings / bot monitor
    // TODO: Add tts options
    // TODO: Add background process option
    // TODO: Add open on startup option

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Discord Bot Token',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 10),
        Consumer<SettingsModel>(
          builder: (context, settings, child) => TextField(
            controller: _controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter a token to enable the discord bot!',
            ),
            // TODO: Make 2 lines
            // ignore: avoid_redundant_argument_values
            maxLines: 1,
            onChanged: (newKey) => settings.botKey = newKey,
          ),
        ),
      ],
    );
  }
}

/// A switch to change the brightness mode. Before the user uses the switch, the
/// switch will display the operating system's brightness mode.
class BrightnessSwitch extends StatelessWidget {
  /// A switch to change the brightness mode. Before the user uses the switch,
  /// the switch will display the operating system's brightness mode.
  const BrightnessSwitch({super.key});

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
