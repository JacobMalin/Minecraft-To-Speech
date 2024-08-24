"""
bot.py

Discord bot for publishing messages read from minecraft chat.

Jacob Malin
"""

from multiprocessing import Manager
import signal

import discord
from discord.ext import commands

class Bot(commands.Bot):
    def __init__(self):
        intents = discord.Intents.default()
        intents.message_content = True

        super().__init__(command_prefix=commands.when_mentioned_or('/'), intents=intents)

    async def on_ready(self):
        print(f'We have logged in as {self.user}')

    async def on_message(self, message):
        if message.author == self.user:
            return

        await self.process_commands(message)

def run(nsp, token):
    global ns
    ns = nsp
    bot = Bot()

    if token == "":
        return

    @bot.hybrid_command(name="here", description="sets chat publishing channel")
    async def here(ctx):
        global ns
        ns.bot_channel = ctx.channel.id
        print(f"Chat logs moved to {ctx.channel} ({ctx.channel.id})")
        await ctx.send("Chat logs moved to this channel!")

    @bot.command()
    async def sync(ctx):
        print("sync command")
        if ctx.author.id == 'Owner':
            await bot.tree.sync()
            await ctx.send('Command tree synced.')
        else:
            await ctx.send('You must be the owner to use this command!')

    try:
        bot.run(token)
    except(discord.errors.LoginFailure):
        print("Failed to Login")

