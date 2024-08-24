"""
interface.py

Handles interface.

Jacob Malin
"""

from multiprocessing import Process, Manager
import sys
import os

import PySimpleGUI as sg

import bot
import sound
import ui
from file import File

class Interface():
    # # Get the path name, required to fix pyinstaller apps
    # def get_path(self, filename):
    #     if hasattr(sys, "_MEIPASS"):
    #         # noinspection PyProtectedMember
    #         return os.path.join(sys._MEIPASS, filename)
    #     else:
    #         return filename


    # Gets the file selected in the listbox
    def curr_file(self, values):
        if values['-FILE_LIST-']:
            return values['-FILE_LIST-'][0]

        return None


    # Color the file names
    def update_colors(self):
        for i, file in enumerate(self.s.files):
            text_color = 'green' if file.is_on else 'red'
            self.window['-FILE_LIST-'].set_index_color(i, background_color=text_color, highlight_background_color=text_color)

    def control_visible(self, value):
        self.window['-NO_FILE-'].update(visible=(not value))
        self.window['-CONTROL_PANEL-'].update(visible=value)

    def options_visible(self, value):
        self.window['-MAIN-'].update(visible=(not value))
        self.window['-OPTIONS-'].update(visible=value)


    def __init__(self, s):
        default_font = ('Fixedsys', 11, 'normal')
        self.base_path = getattr(sys, '_MEIPASS', os.getcwd())

        # Load save
        self.s = s

        # Create layout
        layout = ui.define_layout(self.s.files, self.base_path)

        # Create the Window
        self.window = sg.Window(
            'Minecraft To Speech',
            layout,
            font=default_font,
            icon=os.path.join(self.base_path, 'img', 'mts_icon.ico'),
            finalize=True
        )
        # , alpha_channel=0.9, keep_on_top=True, location=(400, 300)

        # Color the file names
        self.update_colors()

        # Start sound thread
        sound.init()

        # Create multiprocessing manager namespace
        manager = Manager()
        self.ns = manager.Namespace()
        self.ns.bot_channel = self.s.bot_channel

        # Start bot
        self.bot_process = Process(target=bot.run, args=[self.ns, self.s.bot_token])
        self.bot_process.start()

    # Contains the main while loop, opens and maintains the GUI
    def loop(self):
        # Event Loop to process "events" and get the "values" of the inputs
        while True:
            # Read event
            event, values = self.window.read(timeout=10, timeout_key='-TIMEOUT-')

            # On window close event
            if event == sg.WIN_CLOSED:  # if user closes window
                break

            elif event == 'Options::-OPEN_OPTIONS-':
                self.window['-BOT_KEY-'].update(value=self.s.bot_token)
                print(self.ns.s.bot_channel)
                self.options_visible(True)

            elif event == '-CLOSE_OPTIONS-':
                get_token = self.window['-BOT_KEY-'].get()
                if self.s.bot_token != get_token:
                    self.s.bot_token = get_token
                    self.s.bot_channel = self.ns.bot_channel

                    self.bot_process.terminate()
                    self.bot_process.join()
                    self.bot_process.close()

                    print("Bot reset")

                    self.bot_process = Process(target=bot.run, args=[self.ns, self.s.bot_token])
                    self.bot_process.start()

                self.options_visible(False)

            # When the power button is pushed
            elif event == '-POWER-':
                # If the current file is on
                if self.curr_file(values).is_on:
                    self.window['-POWER_DISPLAY-'].update(source=os.path.join(self.base_path, 'img', 'off_light.png'), subsample=3)
                    if self.curr_file(values).fp is not None:
                        self.curr_file(values).fp.close()
                        self.curr_file(values).fp = None
                    sound.clear()
                else:
                    self.window['-POWER_DISPLAY-'].update(source=os.path.join(self.base_path, 'img', 'on_light.png'), subsample=3)

                self.curr_file(values).is_on = not self.curr_file(values).is_on

                # Fix the colors
                self.update_colors()

            # When the list of f is touched
            elif event == '-FILE_LIST-':
                # If a file is selected
                if self.curr_file(values):
                    # Hide "No File Selected" message and show control panel
                    self.control_visible(True)

                    # Display currently selected path, which is shortened to 30 chars
                    max_path_len = 30
                    shortened_path = '...' + self.curr_file(values).path[-(max_path_len - 3):] \
                        if len(self.curr_file(values).path) > max_path_len else self.curr_file(values).path
                    self.window['-FILE_NAME-'].update(value='Current Channel:\n' + shortened_path)

                    # Update power button
                    if self.curr_file(values).is_on:
                        self.window['-POWER_DISPLAY-'].update(source=os.path.join(self.base_path, 'img', 'on_light.png'), subsample=3)
                    else:
                        self.window['-POWER_DISPLAY-'].update(source=os.path.join(self.base_path, 'img', 'off_light.png'),
                                                        subsample=3)
                else:
                    # Hide control panel and show "No File Selected" Message
                    self.control_visible(False)

            # When the file add button is used
            elif event == '-FILE_ADD-':
                # if the file is not already in the list, and it returned a real file
                if values['-FILE_ADD-'] not in [file.path for file in self.s.files] and values['-FILE_ADD-'] != '':
                    self.s.files += [File(values['-FILE_ADD-'])]

                    self.window['-FILE_LIST-'].update(values=self.s.files)
                    self.update_colors()  # Colors get removed on update for some reason, so this fixes that

            # When the file remove button is used
            elif event == '-FILE_REMOVE-':
                # If a file is selected
                if self.curr_file(values):
                    # Clean up file
                    if self.curr_file(values).fp:
                        self.curr_file(values).fp.close()
                        self.curr_file(values).fp = None

                    # Remove from file list
                    self.s.files.remove(self.curr_file(values))

                    # Update the listbox
                    self.window['-FILE_LIST-'].update(values=self.s.files)
                    self.update_colors()  # Colors get removed on update for some reason, so this fixes that

                    # Show "No File Selected" message and hide control panel
                    self.control_visible(False)

            # If no other event occurs within the time limit
            elif event == '-TIMEOUT-':
                pass

            else:
                print(event)

            ## After Events ##

            # Check for file update
            for file in self.s.files:
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

    # On exit from loop
    def exit(self):
        # Clean up file pointers
        for file in self.s.files:
            if file.fp:
                file.fp.close()
                file.fp = None

        # Cleanup
        sound.exit()
        self.window.close()

        # Kill bot
        print(self.ns)
        self.s.bot_channel = self.ns.bot_channel
        self.bot_process.terminate()
        self.bot_process.join()
        self.bot_process.close()

        # Save data
        self.s.save()