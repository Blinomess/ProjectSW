import os
import aiofiles

STORAGE_DIR = "storage"
os.makedirs(STORAGE_DIR, exist_ok=True)

async def save_file(file):
    file_path = os.path.join(STORAGE_DIR, file.filename)
    async with aiofiles.open(file_path, 'wb') as f:
        content = await file.read()
        await f.write(content)
    return file_path
