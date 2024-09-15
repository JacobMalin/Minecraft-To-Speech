"""
ui.py

Describes the UI layout.

Jacob Malin
"""

import os
import PySimpleGUI as sg

def define_layout(files, base_path):
    # Create GUI
    sg.theme('DarkTeal6')  # Add a touch of color

    # Top menu bar
    menu_def = [
        [
            '&File', 
            ['&Options::-OPEN_OPTIONS-'],
        ]
    ]

    file_buttons = [
        [
            sg.Input(
                enable_events=True,
                visible=False,
                key='-FILE_ADD-',
            ),
            sg.FileBrowse(
                'Add File',
                target='-FILE_ADD-',
                file_types=[('Log Files', '.log'), ('ALL Files', '*.* *')],
                enable_events=True,
                pad=0,
            )
        ],
        [
            sg.Button(
                'Remove File',
                pad=0,
                key='-FILE_REMOVE-',
            )
        ]
    ]

    # The left side of the window. Contains Listbox, file add, and file remove
    left_col = [
        [
            sg.Listbox(
                files,
                enable_events=True,
                size=(23, 6),
                no_scrollbar=False,
                horizontal_scroll=True,
                highlight_background_color="Gray",
                highlight_text_color="White",
                key="-FILE_LIST-",
                pad=0,
            ),
            sg.Col(
                file_buttons,
                pad=((10, 0), (8, 0)),
                vertical_alignment='top',
            )
        ]
    ]
    
    control_panel = [
        [
            sg.Text(
                'Current File: ',
                key='-FILE_NAME-',
                pad=((2, 0), 0),
            )
        ],
        [
            sg.Image(
                os.path.join(base_path, 'img', 'off_light.png'),
                pad=((33, 0), (10, 0)),
                key='-POWER_DISPLAY-',
                subsample=3
            ),
            sg.Button(
                'POWER',
                size=8,
                pad=((21, 0), (11, 0)),
                key='-POWER-',
            )
        ],
        [
            sg.Button(
                'TTS',
                size=8,
                button_color='green',
                pad=((21, 0), (11, 0)),
                key='-TTS_TOGGLE-',
            ),
            sg.Button(
                'Discord',
                size=8,
                button_color='red',
                pad=((21, 0), (11, 0)),
                key='-BOT_TOGGLE-',
            )
        ]
    ]

    no_file = [
        [
            sg.Text(
                'No File Selected',
            )
        ]
    ]

    # Right side of window. Contains "No file found" message OR control panel for file
    right_col = [
        [
            sg.Col(
                no_file,
                visible=True,
                pad=(0, (17, 0)),
                key='-NO_FILE-',
            ),
            sg.Col(
                control_panel,
                visible=False,
                key='-CONTROL_PANEL-',
            )
        ]
    ]

    # Main window layout
    main_layout = [
        [
            sg.Col(
                left_col,
                pad=((24, 0), (38, 33)),
                vertical_alignment='top',
            ),
            sg.Col(
                right_col,
                pad=((26, 12), 0),
            )
        ]
    ]

    # Options window layout
    options_layout = [
        [
            sg.Text(
                "Discord Bot Token",
            ),
        ],
        [
            sg.Input(
                size=73,
                key='-BOT_KEY-',
            ),
        ],
        [
            sg.Push(),
            sg.Button(
                'Save',
                pad=(0, (10,0)),
                key='-CLOSE_OPTIONS-',
            ),
        ]
    ]

    # Main window layout
    layout = [
        [
            sg.Menu(
                menu_def
            ),
        ],
        [
            sg.pin(sg.Col(
                main_layout,
                key='-MAIN-',
            )),
        ],
        [
            sg.pin(sg.Col(
                options_layout,
                visible=False,
                vertical_alignment='top',
                key='-OPTIONS-',
            )),
        ],
    ]

    return layout