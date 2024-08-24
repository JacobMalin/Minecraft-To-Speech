"""
bot.py

Discord bot for publishing messages read from minecraft chat.

Jacob Malin
"""

from multiprocessing import Process, Queue

import discord
from discord.ext import commands, tasks

class DiscordBot(commands.Bot):
    def __init__(self, ns, q):
        intents = discord.Intents.default()
        intents.message_content = True

        self.ns = ns
        self.q = q

        super().__init__(command_prefix=commands.when_mentioned_or('/'), intents=intents)

        @self.hybrid_command(name="here", description="sets chat publishing channel")
        async def here(ctx):
            self.ns.bot_channel = ctx.channel.id
            print(f"Chat logs moved to {ctx.channel} ({ctx.channel.id})")
            await ctx.send("Chat logs moved to this channel.")

        @self.command()
        async def sync(ctx):
            await self.bot.tree.sync()
            print("Command tree synced.")
            await ctx.send('Command tree synced.')

    async def on_ready(self):
        await self.add_cog(MessageCog(self, self.ns, self.q))
        print(f'We have logged in as {self.user}')

    async def on_message(self, message):
        if message.author == self.user:
            return

        await self.process_commands(message)



class Bot(Process):
    def __init__(self, ns, token):
        super(Bot, self).__init__()
        self.ns = ns
        self.token = token
        self.q = Queue()

    def run(self):
        self.bot = DiscordBot(self.ns, self.q)

        if self.token == "":
            return

        try:
            self.bot.run(self.token)
        except(discord.errors.LoginFailure):
            print("Failed to Login")
    
    def send(self, msg):
        self.q.put(msg)

    def clear(self):
        while not self.q.empty():
            self.q.get()

from discord.ext import tasks, commands

class MessageCog(commands.Cog):
    def __init__(self, bot, ns, q):
        self.bot = bot
        self.ns = ns
        self.q = q
        self.send_message.start()

    def cog_unload(self):
        self.send_message.cancel()

    @tasks.loop(seconds=0.5)
    async def send_message(self):
        if not self.q.empty():
            msg = self.q.get()
            channel = self.bot.get_channel(self.ns.bot_channel)
            await channel.send(msg)