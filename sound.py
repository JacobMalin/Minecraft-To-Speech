"""
sound.py

Uses pytts to speak messages.

Written by Jacob Malin
"""

import pyttsx3


def play(text, add_speed=0):
    engine = pyttsx3.init()
    rate = engine.getProperty('rate')
    engine.setProperty('rate', int(rate) + add_speed)
    engine.say(text)
    engine.runAndWait()

