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
                pad=0
            ),
            sg.Col(
                [
                    [
                        sg.Input(
                            key='-FILE_ADD-',
                            enable_events=True,
                            visible=False
                        ),
                        sg.FileBrowse(
                            'Add File',
                            target='-FILE_ADD-',
                            file_types=[('Log Files', '.log'), ('ALL Files', '*.* *')],
                            enable_events=True,
                            pad=0
                        ),
                    ],
                    [
                        sg.Button(
                            'Remove File',
                            pad=0,
                            key='-FILE_REMOVE-'
                        )
                    ]
                ],
                pad=((10, 0), (8, 0)),
                vertical_alignment='top'
            )
        ]
    ]

    # Right side of window. Contains "No file found" message OR control panel for file
    right_col = [
        [
            sg.Text(
                'Current File: ',
                key='-FILE_NAME-',
                pad=((2, 0), 0)
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
                '-POWER-',
                size=8,
                pad=((21, 0), (11, 0))
            )
        ]
    ]

    # Main window layout
    layout = [
        [
            sg.Col(
                left_col,
                pad=((24, 0), (38, 33)),
                vertical_alignment='top'
            ),
            sg.Col(
                right_col,
                pad=((26, 12), (19, 0)),
                visible=False,
                vertical_alignment='top',
                key='-RIGHT-'
            ),
            sg.Text(
                'No File Selected',
                pad=((26, 12), (19, 0)),
                key='-NO_FILE-'
            )
        ]
    ]

    return layout