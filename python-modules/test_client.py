# client.py
import asyncio
import websockets

async def connect_and_send():
    uri = "ws://localhost:53827"
    while True:
        message = input("Enter message to send: ")
        async with websockets.connect(uri) as websocket:
            await websocket.send(message)
            response = await websocket.recv()

if __name__ == "__main__":
    asyncio.run(connect_and_send())