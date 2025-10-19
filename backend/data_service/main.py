from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from intfile import router

app = FastAPI(title="Data Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost", "http://localhost:80"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router, prefix="", tags=["data"])

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "data-service"}