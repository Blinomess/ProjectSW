from fastapi import APIRouter, Query, HTTPException
from processor import analyze_csv

router = APIRouter()

@router.get("/analyze")
def analyze(file_path: str = Query(..., description="Путь к файлу в storage")):
    """
    Получает путь к файлу и возвращает анализ CSV
    """
    result = analyze_csv(file_path)
    if "error" in result:
        raise HTTPException(status_code=400, detail=result["error"])
    return {"result": result}
