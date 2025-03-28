from tts_thread import TTSThread, Command
from queue import Queue

class TTS:
	def __init__(self):

		self.q = Queue()
		self.cmdQ = Queue()

		self.t = TTSThread(self.q, self.cmdQ)

	def speak(self, message):
		self.q.put(message)

	def clear(self):
		self.q.put(None)
		self.cmdQ.put(Command.CLEAR)

	def set_volume(self, volume):
		self.cmdQ.put(Command.VOLUME)
		self.cmdQ.put(volume)

	def set_rate(self, rate):
		self.cmdQ.put(Command.RATE)
		self.cmdQ.put(rate)

	def exit(self):
		self.cmdQ.put(Command.EXIT)