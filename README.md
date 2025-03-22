# Minecraft To Speech

Reads Minecraft chat messages from .log files using OS-specific text-to-speech.
Can also display the chat messages to a discord server.

## Discord Bot

Using the discord functionality requires creating a discord bot from the discord bot [developer portal](https://discord.com/developers/applications).

## UTF-8 characters

If minecraft logs are outputing with ??? in place of unicode characters, add `-Dfile.encoding=UTF-8` to your minecraft client's additional arguments.