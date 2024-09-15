import os
import sys
from pathlib import Path
import tkinter
from tkinter import filedialog

def process(data):
	if '[CHAT]' in data:
		# Remove up to [CHAT]
		chatless_data = data[data.index('[CHAT]') + 7:]

		# Remove all minecraft format tags
		split_data = chatless_data.split('§')
		tagless_data = split_data.pop(0)
		for d in split_data:
			tagless_data += d[1:]

		# Username says ...
		username = ''
		contents = ''
		preface = ''
		left_carrot = tagless_data.find('<')
		right_carrot = tagless_data.find('>')
		if left_carrot == 0 and right_carrot > 0:
			username = tagless_data[1:right_carrot]
			contents = tagless_data[right_carrot+2:]
			preface = username + " says "
		else:
			contents = tagless_data

		# Replace all carrots with spaces
		contents = contents.replace('<', ' ')
		contents = contents.replace('>', ' ')

		if contents != '' and contents != '\n':
			msg = preface + contents
			
			return msg
	
	return None

if __name__ == '__main__':
	if len(sys.argv) == 1:
		tkinter.Tk().withdraw() # prevents an empty tkinter window from appearing
		file_names = filedialog.askopenfilenames(filetypes=[('Log Files', '.log'), ('ALL Files', '*.* *')])
	else:
		file_names = sys.argv[1:]

	for file_name in file_names:
		out_name = Path(file_name).with_suffix('.txt')
		out_name = out_name.with_stem(out_name.stem + '-cleaned')

		if os.path.isfile(out_name):
			print(out_name.name + ' already exists.')
			sys.exit(0)

		with open(file_name, 'r', errors="ignore") as fpin:
			with open(out_name, 'w') as fpout:
				for line in fpin:
					out = process(line)
					if out: fpout.write(out)