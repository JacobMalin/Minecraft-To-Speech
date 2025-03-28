"""
tts_thread.py

Uses pytts to speak messages.

Jacob Malin
"""

from enum import Enum
import math
from threading import Thread

import time
import pyttsx3

class Command(Enum):
    EXIT = 0
    CLEAR = 1
    VOLUME = 2
    RATE = 3

# Thread for Text to Speech Engine borrowed from https://stackoverflow.com/questions/63892455/running-pyttsx3-inside-a-game-loop
class TTSThread(Thread):
    def __init__(self, queue, cmdQueue):
        Thread.__init__(self)
        
        self.queue = queue
        self.cmdQueue = cmdQueue
        
        self.daemon = True
        self.start()

    def run(self):
        engine = pyttsx3.init('sapi5')
        engine.startLoop(False)
        t_running = True
        
        while t_running:
            if not self.cmdQueue.empty():
                cmd = self.cmdQueue.get()
                match cmd:
                    case Command.VOLUME:
                        volume = self.cmdQueue.get()
                        while not math.isclose(engine.getProperty('volume'), volume, abs_tol=0.01):
                            print(engine.getProperty('volume'))
                            print(volume)
                            engine.setProperty('volume', volume)
                    case Command.RATE:
                        rate = self.cmdQueue.get()
                        while not math.isclose(engine.getProperty('rate'), rate, abs_tol=0.01):
                            engine.setProperty('rate', rate)
                    case Command.CLEAR:
                        engine.stop()
                        count = 0
                        while not self.queue.empty() and self.queue.get() != None:
                            count += 1
                        print(f"Cleared {count} messages from queue")
                        time.sleep(0.1)
                    case Command.EXIT:
                        t_running = False
            elif not self.queue.empty() and not engine.isBusy():
                data = self.queue.get()
                engine.say(data)
            else:
                engine.iterate()

        # After termination
        engine.endLoop()