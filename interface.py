"""
interface.py

Handles interface.

Jacob Malin
"""

import sys
import os

import PySimpleGUI as sg

import sound
import ui
from file import File

default_font = ('Fixedsys', 11, 'normal')

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
def update_colors(window, files):
    for i, file in enumerate(files):
        text_color = 'green' if file.is_on else 'red'
        window['-FILE_LIST-'].set_index_color(i, background_color=text_color, highlight_background_color=text_color)

# Contains the main while loop, opens and maintains the GUI
def interface(s, base_path):
    # List of files
    files = []

    # Recall save stuff
    files = s.recall()

    # Create layout
    layout = ui.define_layout(files, base_path)

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
    update_colors(window, files)

    # Start sound thread
    sound.init()

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
                sound.clear()
            else:
                window['-POWER_DISPLAY-'].update(source=os.path.join(base_path, 'img', 'on_light.png'), subsample=3)

            curr_file(values).is_on = not curr_file(values).is_on

            # Fix the colors
            update_colors(window, files)

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
                update_colors(window, files)  # Colors get removed on update for some reason, so this fixes that

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
                update_colors(window, files)  # Colors get removed on update for some reason, so this fixes that

                # Show "No File Selected" message and hide control panel
                window['-NO_FILE-'].update(visible=True)
                window['-RIGHT-'].update(visible=False)

        # If no other event occurs within the time limit
        elif event == '-TIMEOUT-':
            pass

        ## After Events ##

        # Check for file update
        for file in files:
            if file.is_on and os.path.exists(file.path):
                if file.fp is None:
                    file.fp = open(file.path, "r", errors="ignore")
                    file.fp.seek(0, os.SEEK_END)
                elif file.fp.name is not file.path:
                    file.fp.close()
                    file.fp = open(file.path, "r", errors="ignore")
                    file.fp.seek(0, os.SEEK_END)
                else:
                    data = file.fp.readline()
                    if '[CHAT]' in data:
                        # Remove [CHAT]
                        data = data[data.index('[CHAT]') + 7:]

                        # Remove all minecraft format tags
                        split_data = data.split('§')
                        data = split_data.pop(0)
                        for d in split_data:
                            data += d[1:]

                        # Username says ...
                        preface = ""
                        left_carrot = data.find('<')
                        right_carrot = data.find('>')
                        if left_carrot == 0 and right_carrot > 0:
                            username = data[1:right_carrot]
                            data = data[right_carrot+1:]
                            preface = username + " says"


                        # Replace all carrots with spaces
                        data = data.replace('<', ' ')
                        data = data.replace('>', ' ')

                        

                        if data != '' and data != '\n':
                            print(repr(data))
                            sound.play(preface + data)

    # On exit from loop:

    # Clean up file pointers
    for file in files:
        if file.fp:
            file.fp.close()
            file.fp = None

    # Save data
    s.save(files)

    # Cleanup
    sound.exit()
    window.close()