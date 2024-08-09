"""
sound.py

Uses pytts to speak messages.

Jacob Malin
"""

import pyttsx3

engine = pyttsx3.init()

def play(text, add_speed=0):
    rate = engine.getProperty('rate')
    engine.setProperty('rate', int(rate) + add_speed)
    engine.say(text)
    engine.runAndWait()