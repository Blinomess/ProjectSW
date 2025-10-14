from fastapi import FastAPI, UploadFile, File, Depends, HTTPException, APIRouter, Request, Form
from fastapi.responses import FileResponse, JSONResponse
from sqlalchemy.orm import Session
import models
import schemas
import crud
import re
from database import engine, SessionLocal
import os, csv

models.Base.metadata.create_all(bind=engine)

app = FastAPI()
router = APIRouter()

STORAGE_DIR = "storage"

MAX_FILE_SIZE = 1024 * 1024 * 1024

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.middleware("http")
async def limit_upload_size(request: Request, call_next):
    content_length = request.headers.get('content-length')
    if content_length and int(content_length) > MAX_FILE_SIZE:
        return JSONResponse(content={"detail": "File too large"}, status_code=413)
    return await call_next(request)

@router.post("/upload")
async def upload_data(
    file: UploadFile = File(...),
    title: str = Form(None),
    description: str = Form(None),
    db: Session = Depends(get_db)
):
    file_location = os.path.join(STORAGE_DIR, file.filename)
    with open(file_location, "wb") as f:
        f.write(await file.read())

    result_summary = None
    if file.filename.lower().endswith(".csv"):
        with open(file_location, newline="", encoding="utf-8") as csvfile:
            reader = csv.reader(csvfile)
            numeric_values = []
            for row in reader:
                for val in row:
                    val = val.strip().replace(',', '.')
                    if re.match(r"^-?\d+(\.\d+)?$", val):  # только числа
                        numeric_values.append(float(val))
            
            if numeric_values:
                result_summary = {
                    "sum": sum(numeric_values),
                    "average": sum(numeric_values) / len(numeric_values),
                    "count": len(numeric_values)
                }

    filetype = "photo" if file.filename.endswith(".jpeg") or file.filename.endswith(".png") or file.filename.endswith(".jpg") else "csv" if file.filename.endswith(".csv") else "other"

    metadata = schemas.FileMetadataCreate(
        filename=file.filename,
        title=title,
        description=description,
        filetype=filetype,
        result_summary=result_summary
    )

    db_file = crud.create_file_metadata(db, metadata)
    return db_file

@router.get("/download/{filename}")
async def download_data(filename: str):
    file_path = os.path.join(STORAGE_DIR, filename)
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Файл не найден")
    
    return FileResponse(file_path)

@router.get("/files")
async def list_files(db: Session = Depends(get_db)):
    return crud.get_all_files(db)

@router.delete("/files/{filename}")
async def delete_file(filename: str, db: Session = Depends(get_db)):
    file_path = os.path.join(STORAGE_DIR, filename)
    if os.path.exists(file_path):
        os.remove(file_path)

    deleted = crud.delete_file_metadata(db, filename)
    if not deleted:
        raise HTTPException(status_code=404, detail="Файл не найден в базе данных")

    return {"detail": f"Файл {filename} удалён полностью"}

@router.get("/preview/{filename}")
async def preview_csv(filename: str):
    file_path = os.path.join(STORAGE_DIR, filename)
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Файл не найден")

    if not filename.lower().endswith(".csv"):
        raise HTTPException(status_code=400, detail="Можно просматривать только CSV файлы")

    try:
        with open(file_path, "r", encoding="utf-8", newline="") as csvfile:
            reader = csv.reader(csvfile)
            preview_lines = []
            numeric_sums = []
            numeric_counts = []
            numeric_max = []
            col_count = 0

            for i, row in enumerate(reader):
                if i == 0:
                    col_count = len(row)
                    numeric_sums = [0.0] * col_count
                    numeric_counts = [0] * col_count
                    numeric_max = [float('-inf')] * col_count

                if i < 10:
                    preview_lines.append(", ".join(row))

                if i < 100:
                    for j, value in enumerate(row):
                        try:
                            num = float(value)
                            numeric_sums[j] += num
                            numeric_counts[j] += 1
                            if num > numeric_max[j]:
                                numeric_max[j] = num
                        except (ValueError, TypeError):
                            pass

            preview_text = "\n".join(preview_lines) if preview_lines else "Файл пуст"

            numeric_avgs = [
                round(numeric_sums[j] / numeric_counts[j], 2) if numeric_counts[j] > 0 else None
                for j in range(col_count)
            ]
            numeric_sums = [round(s, 2) if c > 0 else None for s, c in zip(numeric_sums, numeric_counts)]
            numeric_max = [round(m, 2) if m != float('-inf') else None for m in numeric_max]

            return {
                "preview": preview_text,
                "columns": col_count,
                "sums": numeric_sums,
                "averages": numeric_avgs,
                "max_values": numeric_max
            }

    except UnicodeDecodeError:
        raise HTTPException(status_code=400, detail="Ошибка чтения файла (не UTF-8)")