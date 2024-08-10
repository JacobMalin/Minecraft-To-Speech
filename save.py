"""
save.py

Handles save and recall.

Jacob Malin
"""

import os.path

import pickle
from appdirs import user_data_dir

class Save():
    def __init__(self, appname, appauthor):
        self.save_dir = user_data_dir(appname, appauthor)
        self.save_path = os.path.join(self.save_dir, 'save.pickle')

    def recall(self):
        if os.path.isfile(self.save_path):
            try:
                with open(self.save_path, "rb") as fp:
                    print('Save opened')
                    return pickle.load(fp)
            except (EOFError, ValueError):
                print('Save failed to parse')
        else:
            print('No save file')

        return []

    def save(self, files):
        os.makedirs(self.save_dir, exist_ok=True)
        with open(self.save_path, "wb") as fp:
            pickle.dump(files, fp)