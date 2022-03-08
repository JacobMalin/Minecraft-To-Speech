import os

import playsound
from gtts import gTTS
import pyttsx3


def play(text, add_speed=0):
    engine = pyttsx3.init()
    rate = engine.getProperty('rate')
    engine.setProperty('rate', rate + add_speed)
    engine.say(text)
    engine.runAndWait()


def play2(text):
    tts = gTTS(text=text, lang='en')
    filename = "temp.mp3"
    tts.save(filename)
    playsound.playsound(filename)
    os.remove(filename)
