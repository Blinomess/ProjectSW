from fastapi.middleware.cors import CORSMiddleware
from fastapi import FastAPI
from routes import router
from database import Base, engine, SessionLocal
import models

app = FastAPI()

origins = [
    "http://localhost",
    "http://localhost:80"
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup_event():
    try:
        Base.metadata.create_all(bind=engine)
        print("Database tables created successfully")
    except Exception as e:
        print(f"Error creating database tables: {e}")

app.include_router(router, prefix="", tags=["auth"])

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "auth-service"}