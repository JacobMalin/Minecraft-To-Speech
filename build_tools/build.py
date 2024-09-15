import os
import PyInstaller.__main__

mts_spec = os.path.join(os.getcwd(), 'build_tools', 'MTS.spec')

PyInstaller.__main__.run([mts_spec])