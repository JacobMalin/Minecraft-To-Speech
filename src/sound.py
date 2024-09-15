"""
sound.py

Uses pytts to speak messages.

Jacob Malin
"""

from queue import Queue
import pyttsx3
from threading import Thread

EXIT = "exit"
CLEAR = "clear"

q = Queue()
commQ = Queue()

def init():
    # create a queue to send commands from the main thread
    global t
    t = TTSThread(q)  # note: thread is auto-starting

def play(text):
    q.put(" " + text)

def exit():
    q.put(EXIT)

def clear():
    while not q.empty():
        q.get()
    q.put(CLEAR)

# Thread for Text to Speech Engine borrowed from https://stackoverflow.com/questions/63892455/running-pyttsx3-inside-a-game-loop
class TTSThread(Thread):
    def __init__(self, queue):
        Thread.__init__(self)
        self.queue = queue
        self.daemon = True
        self.start()
        

    def run(self):
        engine = pyttsx3.init()
        engine.startLoop(False)
        t_running = True
        while t_running:
            if self.queue.empty() or engine.isBusy():
                engine.iterate()
            else:
                data = self.queue.get()
                if data == EXIT:
                    t_running = False
                elif data == CLEAR:
                    engine.stop()
                else:
                    engine.say(data)
        engine.endLoop()