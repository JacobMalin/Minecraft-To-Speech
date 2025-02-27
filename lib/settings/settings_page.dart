import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'settings_model.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
  });

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16.0),
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

class TokenField extends StatefulWidget {
  const TokenField({
    super.key,
  });

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
  Widget build(final BuildContext context) {
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
          builder: (final context, final settings, final child) => TextField(
            controller: _controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter a token to enable the discord bot!',
            ),
            // TODO: Make 2 lines
            // ignore: avoid_redundant_argument_values
            maxLines: 1,
            onChanged: (final newKey) => settings.botKey = newKey,
          ),
        ),
      ],
    );
  }
}

class BrightnessSwitch extends StatelessWidget {
  const BrightnessSwitch({
    super.key,
  });

  @override
  Widget build(final BuildContext context) {
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
                builder: (final context, final settings, final child) {
              return Switch(
                value: settings.themeMode == ThemeMode.system
                    ? Theme.of(context).brightness == Brightness.dark
                    : settings.themeMode == ThemeMode.dark,
                onChanged: (final mode) => settings.themeMode =
                    mode ? ThemeMode.dark : ThemeMode.light,
              );
            }),
          ),
        ),
      ],
    );
  }
}
