import os
import subprocess

if __name__ == '__main__':
    os.chdir('python-modules')
    subprocess.run(['pyinstaller', './main.py', '--name', 'tts_server', '--onefile'])