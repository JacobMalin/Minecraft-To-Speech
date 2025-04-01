import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:nyxx/nyxx.dart';

import '../main/settings/settings_box.dart';
import 'path_formatting.dart';

/// A model for the discord bot.
class DiscordModel extends ChangeNotifier {
  /// A model for the discord bot.
  factory DiscordModel() => _instance;

  DiscordModel._() {
    unawaited(_restartBot());

    Stream.periodic(const Duration(milliseconds: 100)).listen((_) async {
      if (_queue.isEmpty) return;
      if (_bot?.isRateLimited ?? false) return;

      final String message = _queue.removeFirst();
      await _bot?.send(message);
    });
  }

  static final _instance = DiscordModel._();

  /// The discord bot key format regex.
  static const tokenFormat = r'[\w-]{24}\.[\w-]{6}\.[\w-]{38}';

  _DiscordBot? _bot;
  final Queue _queue = Queue();

  /// The discord bot key.
  String? get botKey => SettingsBox.botKey;
  set botKey(String? key) {
    if (key == botKey) return;

    SettingsBox.botKey = key;
    unawaited(_restartBot());

    notifyListeners();
  }

  Future<void> _restartBot() async {
    await _bot?.close();

    if (botKey == null || !RegExp(DiscordModel.tokenFormat).hasMatch(botKey!)) {
      return;
    }

    _bot = _DiscordBot(botKey!);
  }

  /// Add a message to the discord bot queue.
  void send(String message) {
    _queue.add(message);
  }

  /// Clear the discord bot queue.
  Future<void> clear() async {
    _queue.clear();
  }
}

class _DiscordBot {
  _DiscordBot(String token) : _token = token {
    unawaited(_init());
  }

  final String _token;
  NyxxGateway? _client;

  /// Whether the bot is rate limited.
  var isRateLimited = false;

  Future<void> _init() async {
    try {
      _client = await Nyxx.connectGateway(
        _token,
        GatewayIntents.allUnprivileged | GatewayIntents.messageContent,
        options: GatewayClientOptions(
          plugins: [logging, cliIntegration, ignoreExceptions],
        ),
      );
    } catch (e) {
      if (e is HttpResponseError) {
        final HttpResponseError error = e;

        if (error.statusCode == 401) {
          if (kDebugMode) print('Discord: Invalid token!');
        } else {
          if (kDebugMode) print('Discord: $e');
          rethrow;
        }
      } else {
        if (kDebugMode) print('Discord: $e');
        rethrow;
      }
    }

    if (_client == null) return;

    _client?.httpHandler.onRateLimit.listen((info) {
      isRateLimited = true;
      Future.delayed(info.delay, () => isRateLimited = false);
    });

    final User botUser = await _client!.users.fetchCurrentUser();
    _client!.onMessageCreate.listen((event) async {
      if (event.mentions.contains(botUser)) {
        final String message = event.message.content.toLowerCase();

        if (message.contains('help')) {
          await event.message.channel.sendMessage(
            MessageBuilder(
              content: 'Available commands:\n'
                  'help - Show this help message\n'
                  'here - Move chat logs to this channel',
            ),
          );
        }

        // Here command
        else if (message.contains('here')) {
          SettingsBox.botChannel = event.message.channel.id.value;
          await event.message.channel.sendMessage(
            MessageBuilder(content: 'Chat logs moved to this channel!'),
          );
        }

        // Generic response
        else {
          await event.message.channel.sendMessage(
            MessageBuilder(
              content: 'Minecraft To Speech bot online!\n'
                  'Send `@${botUser.username} help` for available commands',
            ),
          );
        }
      }
    });
  }

  Future<void> close() async => _client?.close();

  Future<void> send(String message) async {
    if (_client == null || SettingsBox.botChannel == null) return;

    final String msg =
        message.trim().isEmpty ? PathFormatting.zeroWidthSpace : message;

    await (_client!.channels[Snowflake(SettingsBox.botChannel!)]
            as PartialTextChannel)
        .sendMessage(
      MessageBuilder(content: msg),
    );
  }
}
