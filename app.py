"""
Minecraft To Speech

Reads minecraft chat messages from .log files using OS-specific text-to-speech.

Written by Jacob Malin
GUI and image design by Miah Sandvik
"""

"""
TODO:
  - Version check on load save
  - Voice selector
  - Volume slider
  - Speed slider
  - Text output (either txt file or get discord working w/ andrew)
  - Make it so all instances have equal priority (It swaps back and forth between files)
  - Refactor gui (get miah to)
  - Fix broken characters
  - Fix crash at midnight
  - Add discord capabilities
 
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



import sys
import os

import interface as itf
from save import Save



appname = 'MinecraftToSpeech'
appauthor = 'Vos'
version = "1.1.2"

base_path = getattr(sys, '_MEIPASS', os.getcwd())



if __name__ == '__main__':
    # Save object
    s = Save(appname, appauthor)

    # Start App
    itf.interface(s, base_path)
