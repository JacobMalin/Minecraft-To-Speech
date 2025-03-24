"""
tts_thread.py

Uses pytts to speak messages.

Jacob Malin
"""

from enum import Enum
from threading import Thread

import pyttsx3

class Command(Enum):
    EXIT = 0
    CLEAR = 1

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
                if cmd == Command.EXIT:
                    t_running = False
                elif cmd == Command.CLEAR:
                    engine.stop()
            elif not self.queue.empty() and not engine.isBusy():
                data = self.queue.get()
                engine.say(data)
            else:
                engine.iterate()

        # After termination
        engine.endLoop()