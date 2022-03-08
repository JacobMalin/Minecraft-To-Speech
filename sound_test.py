# Import the required module for text
# to speech conversion
import io
import time

from gtts import gTTS
import playsound


# This module is imported so that we can
# play the converted audio
import os

# The text that you want to convert to audio


text = 'This is a short sentence.'

# Language in which you want to convert
language = 'en'

# Passing the text and language to the engine,
# here we have marked slow=False. Which tells
# the module that the converted audio should
# have a high speed
tts = gTTS(text=text, lang=language, slow=False)

if __name__ == '__main__':
    # Saving the converted audio in a mp3 file named
    # welcome
    filename = "abc.mp3"
    tts.save(filename)
    playsound.playsound(filename)
    os.remove(filename)
