import os
import PyInstaller.__main__

spec = os.path.join(os.getcwd(), 'build_tools', 'chat_process.spec')

PyInstaller.__main__.run([spec])