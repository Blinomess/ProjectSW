import pandas as pd
import os

def analyze_csv(file_path: str):
    """
    Анализ CSV файла:
    - Количество строк
    - Количество столбцов
    - Список названий столбцов
    """
    if not os.path.exists(file_path):
        return {"error": "Файл не найден"}

    try:
        df = pd.read_csv(file_path)
        return {
            "rows": len(df),
            "columns": len(df.columns),
            "columns_names": df.columns.tolist()
        }
    except Exception as e:
        return {"error": str(e)}
