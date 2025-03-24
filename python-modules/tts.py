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
		while not self.q.empty():
			self.q.get()
		self.cmdQ.put(Command.CLEAR)

	def exit(self):
		self.cmdQ.put(Command.EXIT)