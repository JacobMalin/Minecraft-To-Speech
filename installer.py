import PyInstaller.__main__

if __name__ == '__main__':
    PyInstaller.__main__.run([
        'app.py',
        '-F',
        '-n=Minecraft To Speech',
        '--add-data=img/mts_icon.ico;img',
        '--add-data=img/on_light.png;img',
        '--add-data=img/off_light.png;img',
        '-w',
        '-i=img/mts_icon.ico'
    ])
