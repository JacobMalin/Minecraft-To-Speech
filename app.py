"""
Minecraft To Speech

Reads from .log files and outputs to a discord bot ECHO. Intended to be used with discord Text to Speech to output
minecraft chat to a discord server.

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
  - Add 'file remove' button
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
  - Text output (either txt file or get discord working w/ andrew)
  - Make it so all instances have equal priority (It swaps back and forth between files)
  - Refactor gui (get miah to)
 
Gui needs:
  - Left side
      - List box
      - Colored items in listbox
      - Add file
      - Remove file
  - Two versions of right side
      - No file selected
          - A message indicating that no file is selected
      - A file is selected
          - Name of selected file
          - Power button
          - Power indicator
        
"""

appname = 'MinecraftToSpeech'
appauthor = 'Vos'
base_path = getattr(sys, '_MEIPASS', os.getcwd())
default_font = ('Fixedsys', 11, 'normal')
save_dir = user_data_dir(appname, appauthor)
save_path = os.path.join(save_dir, 'save.pickle')
version = "1.1.0"

# List of files
files = []


# Stores the file infos
@dataclass
class File:
    path: string
    is_on: bool = False
    fp = None

    def __str__(self):
        return self.path


# Get the path name, required to fix pyinstaller apps
def get_path(filename):
    if hasattr(sys, "_MEIPASS"):
        # noinspection PyProtectedMember
        return os.path.join(sys._MEIPASS, filename)
    else:
        return filename


# Gets the file selected in the listbox
def curr_file(values):
    if values['-FILE_LIST-']:
        return values['-FILE_LIST-'][0]

    return None


# Color the file names
def update_colors(window):
    for i, file in enumerate(files):
        text_color = 'green' if file.is_on else 'red'
        window['-FILE_LIST-'].Widget.itemconfig(i, bg=text_color)


# Contains the main while loop, opens and maintains the GUI
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

    # The left side of the window. Contains Listbox, file add, and file remove
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
                [
                    [
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
                        ),
                    ],
                    [
                        sg.Button(
                            'Remove File',
                            pad=0,
                            key='-FILE_REMOVE-'
                        )
                    ]
                ],
                pad=((10, 0), (8, 0)),
                vertical_alignment='top'
            )
        ]
    ]

    # Right side of window. Contains "No file found" message OR control panel for file
    right_col = [
        [
            sg.Text(
                'Current File: ',
                key='-FILE_NAME-',
                pad=((2, 0), 0)
            )
        ],
        [
            sg.Image(
                os.path.join(base_path, 'img', 'off_light.png'),
                pad=((33, 0), (10, 0)),
                key='-POWER_DISPLAY-',
                subsample=3
            ),
            sg.Button(
                '-POWER-',
                size=8,
                pad=((21, 0), (11, 0))
            )
        ]
    ]

    # Main window layout
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

    # Color the file names
    update_colors(window)

    # Event Loop to process "events" and get the "values" of the inputs
    while True:
        # Read event
        event, values = window.read(timeout=10, timeout_key='-TIMEOUT-')

        # On window close event
        if event == sg.WIN_CLOSED:  # if user closes window
            break

        # When the power button is pushed
        elif event == '-POWER-':
            # If the current file is on
            if curr_file(values).is_on:
                window['-POWER_DISPLAY-'].update(source=os.path.join(base_path, 'img', 'off_light.png'), subsample=3)
                if curr_file(values).fp is not None:
                    curr_file(values).fp.close()
                    curr_file(values).fp = None
            else:
                window['-POWER_DISPLAY-'].update(source=os.path.join(base_path, 'img', 'on_light.png'), subsample=3)

            curr_file(values).is_on = not curr_file(values).is_on

            # Fix the colors
            update_colors(window)

        # When the list of files is touched
        elif event == '-FILE_LIST-':
            # If a file is selected
            if curr_file(values):
                # Hide "No File Selected" message and show control panel
                window['-NO_FILE-'].update(visible=False)
                window['-RIGHT-'].update(visible=True)

                # Display currently selected path, which is shortened to 30 chars
                max_path_len = 30
                shortened_path = '...' + curr_file(values).path[-(max_path_len - 3):] \
                    if len(curr_file(values).path) > max_path_len else curr_file(values).path
                window['-FILE_NAME-'].update(value='Current Channel:\n' + shortened_path)

                # Update power button
                if curr_file(values).is_on:
                    window['-POWER_DISPLAY-'].update(source=os.path.join(base_path, 'img', 'on_light.png'), subsample=3)
                else:
                    window['-POWER_DISPLAY-'].update(source=os.path.join(base_path, 'img', 'off_light.png'),
                                                     subsample=3)
            else:
                # Hide control panel and show "No File Selected" Message
                window['-RIGHT-'].update(visible=False)
                window['-NO_FILE-'].update(visible=True)

        # When the file add button is used
        elif event == '-FILE_ADD-':
            # if the file is not already in the list, and it returned a real file
            if values['-FILE_ADD-'] not in [file.path for file in files] and values['-FILE_ADD-'] != '':
                files += [File(values['-FILE_ADD-'])]

                window['-FILE_LIST-'].update(values=files)
                update_colors(window)  # Colors get removed on update for some reason, so this fixes that

        # When the file remove button is used
        elif event == '-FILE_REMOVE-':
            # If a file is selected
            if curr_file(values):
                # Clean up file
                if curr_file(values).fp:
                    curr_file(values).fp.close()
                    curr_file(values).fp = None

                # Remove from files list
                files.remove(curr_file(values))

                # Update the listbox
                window['-FILE_LIST-'].update(values=files)
                update_colors(window)  # Colors get removed on update for some reason, so this fixes that

        # If no other event occurs within the time limit
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

    # On exit from loop:

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
