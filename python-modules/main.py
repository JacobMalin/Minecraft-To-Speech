from enum import Enum
from tts import TTS

import sys
import json
import asyncio
import functools
import websockets

t = TTS()

async def handler(websocket, stop):
    try:
        async for message in websocket:
            split = message.split(" ", 1)
            
            match split[0]:
                case Header.EXIT.value:
                    t.exit()
                    await websocket.send(f"Exiting...")
                    await websocket.close()
                    stop.set_result(None)
                case Header.CLEAR.value:
                    t.clear()
                    await websocket.send(f"Clearing queue")
                case Header.MSG.value:
                    t.speak(split[1])
                    await websocket.send(f"Message received")
                case Header.VOICE.value:
                    voice = split[1]
                    await websocket.send(f"Voice set to {t.set_voice(voice)}")
                case Header.GET_VOICES.value:
                    voices = t.get_voices()
                    await websocket.send(f"Voices: {json.dumps(voices)}")
                case Header.VOLUME.value:
                    vol = float(split[1])
                    t.set_volume(vol)
                    await websocket.send(f"Volume set to {vol}")
                case Header.RATE.value:
                    rate = float(split[1])
                    t.set_rate(rate)
                    await websocket.send(f"Rate set to {rate}")
    except websockets.ConnectionClosed:
        t.exit()
        print("Exiting...")

async def main(port):
    loop = asyncio.get_event_loop()
    stop = loop.create_future()
    
    partial_handler = functools.partial(handler, stop=stop)
    async with websockets.serve(partial_handler, "localhost", port) as server:
        await stop
        t.exit()
        
class Header(Enum):
    EXIT = "EXT"
    CLEAR = "CLR"
    MSG = "MSG"
    VOICE = "VOC"
    GET_VOICES = "GVC"
    VOLUME = "VOL"
    RATE = "RTE"

if __name__ == "__main__":
    port = 53827
    
    if len(sys.argv) >= 3 and sys.argv[1] == '--port':
        port = int(sys.argv[2])
    
    asyncio.run(main(port))