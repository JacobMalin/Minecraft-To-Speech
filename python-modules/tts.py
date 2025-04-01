from tts_thread import TTSThread, Command
from queue import Queue

class TTS:
	def __init__(self):

		self.q = Queue()
		self.setQ = Queue()
		self.cmdQ = Queue()
		self.respQ = Queue()

		self.t = TTSThread(self.q, self.setQ, self.cmdQ, self.respQ)

	def speak(self, message):
		self.q.put(message)

	def set_voice(self, voice):
		self.setQ.put(Command.VOICE)
		self.setQ.put(voice)
		return self.respQ.get()

	def set_volume(self, volume):
		self.setQ.put(Command.VOLUME)
		self.setQ.put(volume)

	def set_rate(self, rate):
		self.setQ.put(Command.RATE)
		self.setQ.put(rate)

	def get_voices(self):
		self.cmdQ.put(Command.GET_VOICES)
		return self.respQ.get()

	def clear(self):
		self.q.put(None)
		self.cmdQ.put(Command.CLEAR)

	def exit(self):
		self.cmdQ.put(Command.EXIT)