import subprocess

if __name__ == '__main__':
    subprocess.run(['pyinstaller', './main.py', '--name', 'tts_server', '--onefile'])