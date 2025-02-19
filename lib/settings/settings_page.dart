import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'settings_model.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Settings",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 15),
          TokenField(),
          SizedBox(height: 10),
          BrightnessSwitch(),
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
    final botKey = Provider.of<SettingsModel>(context, listen: false).botKey;
    _controller = TextEditingController(text: botKey);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Discord Bot Token",
          style: Theme.of(context).textTheme.labelLarge,
        ),
        SizedBox(height: 10),
        Consumer<SettingsModel>(
          builder: (context, settings, child) => TextField(
            controller: _controller,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter a token to enable the discord bot!',
            ),
            onChanged: (newKey) => settings.botKey = newKey,
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Dark Mode",
          style: Theme.of(context).textTheme.labelLarge,
        ),
        SizedBox(height: 5),
        SizedBox(
          height: 30,
          child: FittedBox(
            fit: BoxFit.fill,
            child: Consumer<SettingsModel>(builder: (context, settings, child) {
              return Switch(
                value: settings.themeMode == ThemeMode.system
                    ? Theme.of(context).brightness == Brightness.dark
                    : settings.themeMode == ThemeMode.dark,
                onChanged: (mode) => settings.themeMode =
                    mode ? ThemeMode.dark : ThemeMode.light,
              );
            }),
          ),
        ),
      ],
    );
  }
}
