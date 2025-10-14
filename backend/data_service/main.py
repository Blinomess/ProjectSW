from fastapi import FastAPI
from routes import router

app = FastAPI(title="Data Service")

app.include_router(router, prefix="/data", tags=["Data"])
