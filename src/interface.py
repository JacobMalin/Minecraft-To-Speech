"""
interface.py

Handles interface.

Jacob Malin
"""

from multiprocessing import Manager
import sys
import os

import PySimpleGUI as sg

from bot import Bot
import sound
import ui
from file import File

class Interface():
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

    def send(self, data, is_tts, is_bot):
        if '[CHAT]' in data:
            print(repr(data))
            # Remove up to [CHAT]
            chatless_data = data[data.index('[CHAT]') + 7:]
            print(repr(chatless_data))

            # Remove all minecraft format tags
            split_data = chatless_data.split('§')
            tagless_data = split_data.pop(0)
            for d in split_data:
                tagless_data += d[1:]
            print(repr(tagless_data))

            # Username says ...
            username = ''
            contents = ''
            preface = ''
            left_carrot = tagless_data.find('<')
            right_carrot = tagless_data.find('>')
            if left_carrot == 0 and right_carrot > 0:
                username = tagless_data[1:right_carrot]
                contents = tagless_data[right_carrot+2:]
                preface = username + " says "
            else:
                contents = tagless_data
            print(repr(username))
            print(repr(contents))
            print(repr(preface))

            # Replace all carrots with spaces
            contents = contents.replace('<', ' ')
            contents = contents.replace('>', ' ')
            print(repr(contents))

            if contents != '' and contents != '\n':
                print(repr(contents))
                msg = preface + contents
                if is_tts: sound.play(msg)
                if is_bot: self.bot.send(tagless_data)


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
        self.bot = Bot(self.ns, self.s.bot_token)
        self.bot.start()

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
                self.options_visible(True)

            elif event == '-CLOSE_OPTIONS-':
                get_token = self.window['-BOT_KEY-'].get()
                if self.s.bot_token != get_token:
                    self.s.bot_token = get_token
                    self.s.bot_channel = self.ns.bot_channel

                    self.bot.terminate()
                    self.bot.join()
                    self.bot.close()

                    print("Bot reset.")

                    self.bot = Bot(self.ns, self.s.bot_token)
                    self.bot.start()

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
                    self.bot.clear()
                else:
                    self.window['-POWER_DISPLAY-'].update(source=os.path.join(self.base_path, 'img', 'on_light.png'), subsample=3)

                self.curr_file(values).is_on = not self.curr_file(values).is_on

                # Fix the colors
                self.update_colors()
            
            # When the tts button is pushed
            elif event == '-TTS_TOGGLE-':
                self.curr_file(values).is_tts ^= 1 # toggle value

                color = 'green' if self.curr_file(values).is_tts else 'red'
                self.window['-TTS_TOGGLE-'].update(button_color=color)
            
            # When the bot button is pushed
            elif event == '-BOT_TOGGLE-':
                self.curr_file(values).is_bot ^= 1 # toggle value

                color = 'green' if self.curr_file(values).is_bot else 'red'
                self.window['-BOT_TOGGLE-'].update(button_color=color)

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
                    self.window['-FILE_NAME-'].update(value='Current File:\n' + shortened_path)

                    # Update power button
                    img = 'on_light.png' if self.curr_file(values).is_on else 'off_light.png'
                    self.window['-POWER_DISPLAY-'].update(source=os.path.join(self.base_path, 'img', img), subsample=3)
                        
                    # Update tts button
                    color = 'green' if self.curr_file(values).is_tts else 'red'
                    self.window['-TTS_TOGGLE-'].update(button_color=color)

                    # Update bot button
                    color = 'green' if self.curr_file(values).is_bot else 'red'
                    self.window['-BOT_TOGGLE-'].update(button_color=color)
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
                        self.send(data, file.is_tts, file.is_bot)

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
        self.s.bot_channel = self.ns.bot_channel
        self.bot.terminate()
        self.bot.join()
        self.bot.close()

        # Save data
        self.s.save()