from fastapi import FastAPI, HTTPException
import csv, os

app = FastAPI()
STORAGE_DIR="/app/storage"

@app.get("/analyze/{filename}")
def analyze_file(filename: str):
    file_path = os.path.join(STORAGE_DIR, filename)

    if not os.path.exists(file_path): raise HTTPException(status_code=404, detail="Файл не найден")
    with open(file_path, "r", encoding="utf-8", newline="") as csvfile:
        reader = csv.reader(csvfile)

        numeric_sums = []
        numeric_counts = []
        numeric_max = []
        col_count = 0
        preview_lines = []

        for i, row in enumerate(reader):
            if i == 0:
                col_count = len(row)
                numeric_sums = [0.0] * col_count
                numeric_counts = [0] * col_count
                numeric_max = [float('-inf')] * col_count

            if i < 5:
                preview_lines.append(", ".join(row))

            for j, value in enumerate(row):
                try:
                    num = float(value)
                    numeric_sums[j] += num
                    numeric_counts[j] += 1
                    if num > numeric_max[j]:
                        numeric_max[j] = num
                except (ValueError, TypeError):
                    continue

        numeric_avgs = [
            round(numeric_sums[j] / numeric_counts[j], 2) if numeric_counts[j] else None
            for j in range(col_count)
        ]
        numeric_sums = [round(s, 2) if c > 0 else None for s, c in zip(numeric_sums, numeric_counts)]
        numeric_max = [round(m, 2) if m != float('-inf') else None for m in numeric_max]

        return {

            "preview": "\n".join(preview_lines),
            "columns": col_count,
            "sums": numeric_sums,
            "averages": numeric_avgs,
            "max_values": numeric_max,
            
        }

