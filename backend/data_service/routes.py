from fastapi import APIRouter, UploadFile, File, HTTPException

from utils import save_file

router = APIRouter()

@router.post("/upload")
async def upload_data(file: UploadFile = File(...)):
    """
    Принимает файл и сохраняет в storage
    """
    try:
        path = await save_file(file)
        return {"message": "Файл успешно загружен", "path": path}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
