from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy.orm import Session
from database import SessionLocal
import models, utils
from pydantic import BaseModel

class UserModel(BaseModel):
    username: str
    password: str


router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/register")
def register(user: UserModel, db: Session = Depends(get_db)):

    if db.query(models.User).filter_by(username=user.username).first():
        raise HTTPException(status_code=400, detail="User already exists")
    
    user_obj = models.User(
        username=user.username, 
        password_hash=utils.hash_password(user.password)
    )

    db.add(user_obj)
    db.commit()
    db.refresh(user_obj)
    return {"message": "User registered successfully"}

@router.post("/login")
def login(user: UserModel, db: Session = Depends(get_db)):

    db_user = db.query(models.User).filter_by(username=user.username).first()
    if not db_user or not utils.verify_password(user.password, db_user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    session_id = utils.generate_session_id()
    session_obj = models.Session(user_id=db_user.id, session_token=session_id)
    db.add(session_obj)
    db.commit()
    db.refresh(session_obj)
    return {"message": "Login successful", "session_id": session_id}

@router.post("/logout")
def logout(data: dict = Body(...), db: Session = Depends(get_db)):
    session_id = data.get("session_id")
    if not session_id:
        raise HTTPException(status_code=400, detail="Missing session_id")

    session = db.query(models.Session).filter_by(session_token=session_id).first()
    if session:
        db.delete(session)
        db.commit()
    return {"message": "Logged out"}

@router.get("/check-session")
def check_session(session_id: str, db: Session = Depends(get_db)):
    session = db.query(models.Session).filter_by(session_token=session_id).first()
    if not session:
        raise HTTPException(status_code=401, detail="Session invalid")
    return {"user_id": session.user_id}
