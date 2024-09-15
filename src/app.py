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
  - Bug where if bot is missing privileged intents, it crashed
 
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

import multiprocessing
from interface import Interface
from save import Save
from file import File



appname = 'MinecraftToSpeech'
appauthor = 'Vos'
version = '1.1.4'



def main():
    # Save object
    s = Save(appname, appauthor, version)
    
    i = Interface(s)
    i.loop()
    i.exit()


if __name__ == '__main__':
    multiprocessing.freeze_support()
    main()