"""
Minecraft To Speech

Reads from .log files and outputs to a discord bot ECHO

Written by Jacob Malin
GUI and image design by Miah Sandvik
"""

import string
import sys
from dataclasses import dataclass

import discord
import asyncio
import os.path
import PySimpleGUI as sg
from discord.ext import commands
from appdirs import *

bot = commands.Bot(command_prefix='!')
TOKEN = 'OTQwODY5MDQ2OTMxNDI3MzU0.YgNqlQ.O4GakiXmhm3dVBVIuydPM5PZfT4'
appname = 'MinecraftToSpeech'
appauthor = 'Vos'
base_path = getattr(sys, '_MEIPASS', '.')
save_dir = user_data_dir(appname, appauthor)
save_path = os.path.join(save_dir, 'save')
default_font = ('Fixedsys', 11, 'normal')

is_on = False
curr_file = None

# Saved data
curr_channel = 'general'
log_locations = ['File 1', 'File 2', 'File 3']


@dataclass
class File:
    path: string = ""
    guild: string = "Discord Server"
    channel: string = "general"
    is_on: bool = False


@bot.event
async def on_ready():
    print('Logged on as {0}!'.format(bot.user))


async def write(msg):
    if is_on:
        for guild in bot.guilds:
            channel = discord.utils.get(guild.channels, name=curr_channel)
            if channel:
                await channel.send(msg)

        return 0
    return 1


async def interface():
    global log_locations, curr_channel, is_on, curr_file

    # Recall save stuff
    if os.path.isfile(save_path):
        try:
            with open(save_path, "r") as file:
                contents = file.read()
                contents_split = contents.splitlines()
                curr_channel = contents_split[0]
                for i in range(3):
                    log_locations[i] = contents_split[i + 1]
                print('Save opened:\n' + contents)
        except IndexError:
            curr_channel = 'general'
            log_locations = ['File 1', 'File 2', 'File 3']
            print('Save failed to parse')
    else:
        print('No save file')

    # Create GUI
    sg.theme('DarkTeal6')  # Add a touch of color
    # All the stuff inside your window.
    left_col = [
        [
            sg.Listbox(
                log_locations,
                size=(23, 6),
                no_scrollbar=False,
                horizontal_scroll=True,
                highlight_background_color="Gray",
                highlight_text_color="White",
                key="-FILE_LIST-",
                pad=0
            ),
            sg.Col(
                [[
                    sg.Input(
                        key='-FILE_BROWSE-',
                        enable_events=True,
                        visible=False
                    ),
                    sg.FileBrowse(
                        'Find File',
                        target='-FILE_BROWSE-',
                        file_types=[('Log Files (.log)', '.log'), ('ALL Files', '*.* *')],
                        enable_events=True,
                        pad=0
                    )
                ]],
                pad=((10, 0), (8, 0)),
                vertical_alignment='top'
            )
        ]
    ]

    right_col = [
        [
            sg.Text(
                'Current Channel: ' + curr_channel,
                key='-CHANNEL_DISPLAY-',
                pad=((2, 0), 0)
            )
        ],
        [
            sg.InputText(
                'channel-name',
                size=30,
                key='-CHANNEL_INPUT-',
                pad=(0, (13, 0))
            )
        ],
        [
            sg.Button(
                'Select',
                bind_return_key=True,
                pad=((193, 0), (12, 0))
            )
        ],
        [
            sg.Image(
                os.path.join(base_path, 'img', 'off_light.png'),
                pad=((33, 0), (0, 0)),
                key='-POWER_DISPLAY-',
                subsample=3
            ),
            sg.Button(
                'Power',
                size=8,
                pad=((21, 0), (1, 0))
            )
        ]
    ]

    layout = [
        [
            sg.Col(
                left_col,
                pad=((24, 0), (38, 33)),
                vertical_alignment='top'
            ),
            sg.Col(
                right_col,
                pad=((26, 12), (19, 0)),
                vertical_alignment='top'
            )
        ]
    ]

    # Sleep to finish bot setup
    await asyncio.sleep(0.25)

    # Create the Window
    window = sg.Window(
        'Minecraft To Speech',
        layout,
        font=default_font,
        icon=os.path.join(base_path, 'img', 'mts_icon.ico'),
        finalize=True
    )
    # , alpha_channel=0.9, keep_on_top=True, location=(400, 300)

    # Set file selection
    window['-FILE_LIST-'].update(set_to_index=0)

    # Event Loop to process "events" and get the "values" of the inputs
    while True:
        event, values = window.read(timeout=100, timeout_key='-TIMEOUT-')
        if event == sg.WIN_CLOSED:  # if user closes window
            break
        elif event == 'Select':
            temp_channel = values['-CHANNEL_INPUT-']
            if temp_channel != "":
                curr_channel = temp_channel
                window['-CHANNEL_INPUT-'].update(value="")
                max_name = 13
                shortened_channel = (curr_channel[:max_name - 2] + '..') if len(
                    curr_channel) > max_name else curr_channel
                window['-CHANNEL_DISPLAY-'].update(value='Current Channel: ' + shortened_channel)
        elif event == 'Power':
            if is_on:
                window['-POWER_DISPLAY-'].update(source=os.path.join(base_path, 'img', 'off_light.png'), subsample=3)
                if curr_file is not None:
                    curr_file.close()
                    curr_file = None
            else:
                window['-POWER_DISPLAY-'].update(source=os.path.join(base_path, 'img', 'on_light.png'), subsample=3)

            is_on = not is_on
        elif event == '-FILE_BROWSE-':
            if values['-FILE_BROWSE-'] not in log_locations:
                try:
                    file_index = log_locations.index(values['-FILE_LIST-'][0])
                    log_locations[file_index] = values['-FILE_BROWSE-']

                    window['-FILE_LIST-'].update(values=log_locations)
                except IndexError:
                    pass
        elif event == '-TIMEOUT-':
            # Check for file update
            if is_on and values['-FILE_LIST-'] and os.path.exists(values['-FILE_LIST-'][0]):
                if curr_file is None:
                    curr_file = open(values['-FILE_LIST-'][0], "r")
                    curr_file.seek(0, os.SEEK_END)
                elif curr_file.name is not values['-FILE_LIST-'][0]:
                    curr_file.close()
                    curr_file = open(str(values['-FILE_LIST-'][0]), "r")
                    curr_file.seek(0, os.SEEK_END)
                else:
                    data = curr_file.readline()
                    if '[CHAT]' in data:
                        print(repr(data))
                        # Remove [CHAT]
                        data = data[data.index('[CHAT]') + 7:]

                        # Replace all carrots with curly braces
                        data = data.replace('<', '{')
                        data = data.replace('>', '}')

                        if data != '' and data != '\n':
                            print(repr(data))
                            await write(data)
                            await asyncio.sleep(1)

    # Save data
    os.makedirs(save_dir, exist_ok=True)
    with open(save_path, "w") as file:
        file.write(curr_channel + "\n")
        file.writelines([row + "\n" for row in log_locations])

    # Cleanup
    window.close()


async def main():
    await bot.login(TOKEN)
    asyncio.create_task(bot.connect())

    gui_task = asyncio.create_task(interface())
    await gui_task


if __name__ == '__main__':
    # Start App
    asyncio.run(main())
