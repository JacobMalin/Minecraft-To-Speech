"""
save.py

Handles save and recall.

Jacob Malin
"""

import os.path
import string
from dataclasses import dataclass, field

import pickle
from appdirs import user_data_dir

from file import File
from singleton_meta import SingletonMeta

@dataclass
class SaveData:
    version: string
    files: list[File] = field(default_factory=list)
    bot_token: string = ""
    bot_channel: int = None


class Save(metaclass=SingletonMeta):
    def __init__(self, appname, appauthor, version):
        self.save_dir = user_data_dir(appname, appauthor)
        self.save_path = os.path.join(self.save_dir, 'save.pickle')

        self.data = SaveData(version)

        self.recall()

    def recall(self):
        if os.path.isfile(self.save_path):
            try:
                with open(self.save_path, "rb") as fp:
                    print('Save opened')
                    data = pickle.load(fp)

                    if (not isinstance(data, SaveData)) or (self.data.version != data.version):
                        print('Save version mismatch')

                        self.data = SaveData(self.data.version)

                        if data.files:
                            for file in data.files:

                                if file.path is not None: path = file.path
                                if file.is_on is not None: is_on = file.is_on
                                if file.is_tts is not None: is_tts = file.is_tts
                                if file.is_bot is not None: is_bot = file.is_bot
                                
                                f = File(path=path, is_on=is_on, is_tts=is_tts, is_bot=is_bot)

                                self.data.files += [f]

                        if data.bot_token: self.data.bot_token = data.bot_token
                        if data.bot_channel: self.data.bot_channel = data.bot_channel

                        return

                    self.data = data

                    return
            except (EOFError, ValueError, pickle.UnpicklingError, MemoryError):
                print('Save failed to parse')
        else:
            print('No save file')

        self.files = []
        self.bot_token = ""
        return

    def save(self):
        os.makedirs(self.save_dir, exist_ok=True)
        with open(self.save_path, "wb") as fp:
            pickle.dump(self.data, fp)

    @property
    def files(self):
        return self.data.files

    @files.setter
    def files(self, value):
        self.data.files = value

    @property
    def bot_token(self):
        return self.data.bot_token

    @bot_token.setter
    def bot_token(self, value):
        self.data.bot_token = value

    @property
    def bot_channel(self):
        return self.data.bot_channel

    @bot_channel.setter
    def bot_channel(self, value):
        self.data.bot_channel = value