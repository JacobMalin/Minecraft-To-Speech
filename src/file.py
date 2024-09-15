"""
file.py

Describes a file.

Jacob Malin
"""

import string
from dataclasses import dataclass

# Stores the file info
@dataclass
class File:
    path: string

    is_on: bool = False
    is_tts: bool = True
    is_bot: bool = False

    fp = None

    def __str__(self):
        return self.path