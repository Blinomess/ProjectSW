from fastapi import FastAPI
from routes import router

app = FastAPI(title="Processing Service")

app.include_router(router, prefix="/process", tags=["Processing"])
