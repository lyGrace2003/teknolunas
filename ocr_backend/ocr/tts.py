import pyttsx3
import json
import base64

engine = pyttsx3.init()

def generate_speech(text):
    engine.say(text)
    engine.runAndWait()
    return engine.get_current_voice().save_audio()
