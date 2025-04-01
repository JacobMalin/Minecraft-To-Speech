"""
tts_thread.py

Uses pytts to speak messages.

Jacob Malin
"""

from enum import Enum
from queue import Queue
from threading import Thread

import time
import pyttsx3

class Command(Enum):
    EXIT = 0
    CLEAR = 1
    VOICE = 2
    GET_VOICES = 3
    VOLUME = 4
    RATE = 5

# Thread for Text to Speech Engine borrowed from https://stackoverflow.com/questions/63892455/running-pyttsx3-inside-a-game-loop
class TTSThread(Thread):
    def __init__(self, queue : Queue, setQueue : Queue, cmdQueue : Queue, respQueue : Queue):
        Thread.__init__(self)
        
        self.queue = queue
        self.setQueue = setQueue
        self.cmdQueue = cmdQueue
        self.respQueue = respQueue
        
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
                    case Command.GET_VOICES:
                        voices : list[pyttsx3.voice.Voice] = engine.getProperty('voices')
                        voice_list = {voice.id: voice.name for voice in voices}
                        self.respQueue.put(voice_list)
                    case Command.CLEAR:
                        engine.stop()
                        count = 0
                        while not self.queue.empty() and self.queue.get() != None:
                            count += 1
                    case Command.EXIT:
                        t_running = False
            elif not self.setQueue.empty() and not engine.isBusy():
                cmd = self.setQueue.get()
                match cmd:
                    case Command.VOICE:
                        voice = self.setQueue.get()
                        voices = engine.getProperty('voices')
                        voice_list = [voice.id for voice in voices]
                        if voice in voice_list:
                            engine.setProperty('voice', voice)
                        self.respQueue.put(engine.getProperty('voice'))
                    case Command.VOLUME:
                        volume = self.setQueue.get()
                        engine.setProperty('volume', volume)
                    case Command.RATE:
                        rate = self.setQueue.get()
                        engine.setProperty('rate', rate)
            elif not self.queue.empty() and not engine.isBusy():
                data = self.queue.get()
                engine.say(data)
            else:
                engine.iterate()

        # After termination
        engine.endLoop()