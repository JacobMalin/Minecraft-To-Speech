"""
Minecraft To Speech

Reads from .log files and outputs to a discord bot ECHO. Intended to use with discord Text to Speech to output minecraft
chat to a discord server.

Written by Jacob Malin
GUI and image design by Miah Sandvik
"""

import string
import sys
import os.path

import pickle
from dataclasses import dataclass

import PySimpleGUI as sg
from appdirs import *

from sound import play

"""
TODO:
 - Add 'file remove' button and change 'find file' to 'add file'
 - Make right col only appear when a file is selected
 - Make right col reflect File dataclass for currently selected file
 - Add guild changer in gui
 - Check if bot is alive
 - Merge messages together per second and implement a queue probably in File data type
 - Version check on load save
 - Clear queue on exit / power off
 - Finish coloring listbox by is_on
 - Voice selector
 - Volume slider
 - Speed slider
"""

appname = 'MinecraftToSpeech'
appauthor = 'Vos'
base_path = getattr(sys, '_MEIPASS', os.getcwd())
default_font = ('Fixedsys', 11, 'normal')
save_dir = user_data_dir(appname, appauthor)
save_path = os.path.join(save_dir, 'save.pickle')
version = "1.1.0"


files = []


@dataclass
class File:
    path: string
    guild: string = "Discord Server"
    channel: string = "general"
    is_on: bool = False
    fp = None

    def __str__(self):
        return self.path


def get_path(filename):
    if hasattr(sys, "_MEIPASS"):
        return os.path.join(sys._MEIPASS, filename)
    else:
        return filename


def curr_file(values):
    if values['-FILE_LIST-']:
        return values['-FILE_LIST-'][0]

    return None


def interface():
    global files

    # Recall save stuff
    if os.path.isfile(save_path):
        try:
            with open(save_path, "rb") as fp:
                files = pickle.load(fp)
                print('Save opened')
        except (EOFError, ValueError):
            files = []
            print('Save failed to parse')
    else:
        print('No save file')

    # Create GUI
    sg.theme('DarkTeal6')  # Add a touch of color
    # All the stuff inside your window.
    left_col = [
        [
            sg.Listbox(
                files,
                enable_events=True,
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
                        key='-FILE_ADD-',
                        enable_events=True,
                        visible=False
                    ),
                    sg.FileBrowse(
                        'Add File',
                        target='-FILE_ADD-',
                        file_types=[('Log Files', '.log'), ('ALL Files', '*.* *')],
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
                'Current Channel: ',
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
                visible=False,
                vertical_alignment='top',
                key='-RIGHT-'
            ),
            sg.Text(
                'No File Selected',
                pad=((26, 12), (19, 0)),
                key='-NO_FILE-'
            )
        ]
    ]

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
    # window['-FILE_LIST-'].update(set_to_index=0)

    # For file in files change color to match is_on

    for i, file in enumerate(files):
        text_color = 'green' if file.is_on else 'red'
        window['-FILE_LIST-'].Widget.itemconfig(i, bg=text_color)

    # Event Loop to process "events" and get the "values" of the inputs
    while True:
        event, values = window.read(timeout=10, timeout_key='-TIMEOUT-')
        if event == sg.WIN_CLOSED:  # if user closes window
            break
        elif event == 'Select':
            temp_channel = values['-CHANNEL_INPUT-']
            if temp_channel != "":
                curr_file(values).channel = temp_channel
                window['-CHANNEL_INPUT-'].update(value="")
                max_name = 13
                shortened_channel = (curr_file(values).channel[:max_name - 2] + '..') \
                    if len(curr_file(values).channel) > max_name else curr_file(values).channel
                window['-CHANNEL_DISPLAY-'].update(value='Current Channel: ' + shortened_channel)
        elif event == 'Power':
            if curr_file(values).is_on:
                window['-POWER_DISPLAY-'].update(source=os.path.join(base_path, 'img', 'off_light.png'), subsample=3)
                if curr_file(values).fp is not None:
                    curr_file(values).fp.close()
                    curr_file(values).fp = None
            else:
                window['-POWER_DISPLAY-'].update(source=os.path.join(base_path, 'img', 'on_light.png'), subsample=3)

            curr_file(values).is_on = not curr_file(values).is_on
        elif event == '-FILE_LIST-':
            if curr_file(values):
                window['-NO_FILE-'].update(visible=False)
                window['-RIGHT-'].update(visible=True)
                max_name = 13
                shortened_channel = (curr_file(values).channel[:max_name - 2] + '..') \
                    if len(curr_file(values).channel) > max_name else curr_file(values).channel
                window['-CHANNEL_DISPLAY-'].update(value='Current Channel: ' + shortened_channel)
                window['-CHANNEL_INPUT-'].update(value=curr_file(values).channel)
                if curr_file(values).is_on:
                    window['-POWER_DISPLAY-'].update(source=os.path.join(base_path, 'img', 'on_light.png'), subsample=3)
                else:
                    window['-POWER_DISPLAY-'].update(source=os.path.join(base_path, 'img', 'off_light.png'),
                                                     subsample=3)
            else:
                window['-RIGHT-'].update(visible=False)
                window['-NO_FILE-'].update(visible=True)
        elif event == '-FILE_ADD-':
            if values['-FILE_ADD-'] not in [file.path for file in files] and values['-FILE_ADD-'] != '':
                files += [File(values['-FILE_ADD-'])]

                window['-FILE_LIST-'].update(values=files)
        elif event == '-TIMEOUT-':
            # Check for file update
            for file in files:
                if file.is_on and os.path.exists(file.path):
                    if file.fp is None:
                        file.fp = open(file.path, "r")
                        file.fp.seek(0, os.SEEK_END)
                    elif file.fp.name is not file.path:
                        file.fp.close()
                        file.fp = open(file.path, "r")
                        file.fp.seek(0, os.SEEK_END)
                    else:
                        data = file.fp.readline()
                        if '[CHAT]' in data:
                            # Remove [CHAT]
                            data = data[data.index('[CHAT]') + 7:]

                            # Replace all carrots with curly braces
                            data = data.replace('<', '{')
                            data = data.replace('>', '}')

                            # Remove all minecraft format tags
                            split_data = data.split('§')
                            data = split_data.pop(0)
                            for d in split_data:
                                data += d[1:]

                            if data != '' and data != '\n':
                                print(repr(data))
                                play(data)

    # Clean up file pointers
    for file in files:
        if file.fp:
            file.fp.close()
            file.fp = None

    # Save data
    os.makedirs(save_dir, exist_ok=True)
    with open(save_path, "wb") as fp:
        pickle.dump(files, fp)

    # Cleanup
    window.close()


if __name__ == '__main__':
    # Start App
    interface()
