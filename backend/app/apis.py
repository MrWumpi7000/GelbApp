from fastapi import APIRouter, HTTPException, Depends, UploadFile, File, Form # type: ignore
from fastapi.responses import StreamingResponse # type: ignore
from sqlalchemy.orm import Session # type: ignore
from sqlalchemy import or_ # type: ignore
from app.models import User, UserProfile
from app.utils import hash_password, verify_password, whoami, create_access_token
from app.database import get_db
from app.schemas import RegisterRequest, TokenRequest, LoginRequest, BioRequest
from uuid import uuid4
import os
import shutil

UPLOAD_DIR = "uploads"

router = APIRouter()

@router.post("/register")
def register_user(request: RegisterRequest, db: Session = Depends(get_db)):
    existing_user = db.query(User).filter(User.username == request.username).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Username already taken")
    
    existing_email = db.query(User).filter(User.email == request.email).first()
    if existing_email:
        raise HTTPException(status_code=400, detail="Email already registered")

    hashed_password = hash_password(request.password)

    db_user = User(username=request.username, email=request.email, password=hashed_password)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)

    access_token = create_access_token(data={"email": request.email})

    return {"access_token": access_token, "token_type": "bearer"}



@router.post("/login")
def login_user(request: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(
        or_(
            User.username == request.username_or_email,
            User.email == request.username_or_email
        )
    ).first()
    
    if not user:
        raise HTTPException(status_code=400, detail="Invalid username or password")
    
    if not verify_password(request.password, user.password):
        raise HTTPException(status_code=400, detail="Invalid username or password")
    
    access_token = create_access_token(data={"email": user.email})
    
    return {"access_token": access_token, "token_type": "bearer"}
    

@router.post("/whoami")
def whoami_endpoint(request: TokenRequest, db: Session = Depends(get_db)):
    email = whoami(request.token)
    if email is None:
        raise HTTPException(status_code=401, detail="Invalid token")
    
    user = db.query(User).filter(User.email == email).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    
    return {"username": user.username, "email": user.email}

@router.post("/upload_profile_picture")
def upload_profile_picture(
    token: str = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    # Get user's email from token
    email = whoami(token)
    user = db.query(User).filter(User.email == email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Validate file type
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Only image uploads allowed.")

    # Generate secure unique filename
    ext = os.path.splitext(file.filename)[1].lower()
    filename = f"{uuid4().hex}{ext}"
    file_location = os.path.join(UPLOAD_DIR, filename)

    # Save the new file
    with open(file_location, "wb") as f:
        shutil.copyfileobj(file.file, f)

    # Get or create profile
    profile = db.query(UserProfile).filter(UserProfile.user_id == user.id).first()
    if not profile:
        profile = UserProfile(user_id=user.id)
        db.add(profile)
        db.commit()
        db.refresh(profile)

    # Delete the old profile picture if it exists and is not the default
    old_path = profile.profile_picture
    if old_path and os.path.exists(old_path) and not old_path.endswith("no_profile_picture.jpg"):
        try:
            os.remove(old_path)
        except Exception as e:
            print(f"Failed to delete old profile picture: {e}")

    # Update with new picture
    profile.profile_picture = file_location
    db.commit()

    return {"info": "Profile picture uploaded.", "path": file_location}

@router.post("/profile_picture")
def get_profile_picture(
    token_request: TokenRequest,
    db: Session = Depends(get_db)
):
    # Extract email from token
    email = whoami(token_request.token)
    user = db.query(User).filter(User.email == email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    profile = db.query(UserProfile).filter(UserProfile.user_id == user.id).first()
    
    # Use custom profile picture if it exists, else fallback
    if profile and profile.profile_picture and os.path.exists(profile.profile_picture):
        file_path = profile.profile_picture
    else:
        file_path = "/home/jasper/workspace/GelbApp/backend/app/assets/no_profile.jpg"  # <-- Your default picture path

    if not os.path.exists(file_path):
        raise HTTPException(status_code=500, detail="Default profile picture missing")

    def iterfile():
        with open(file_path, mode="rb") as file_like:
            yield from file_like

    # Determine content-type
    ext = os.path.splitext(file_path)[1].lower()
    content_type = {
        ".png": "image/png",
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".gif": "image/gif"
    }.get(ext, "application/octet-stream")

    return StreamingResponse(iterfile(), media_type=content_type)

@router.post("/update_bio")
def update_bio(request: BioRequest, db: Session = Depends(get_db)):
    email = whoami(request.token)
    user = db.query(User).filter(User.email == email).first()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    profile = db.query(UserProfile).filter(UserProfile.user_id == user.id).first()
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")

    profile.bio = request.bio
    db.commit()

    return {"message": "Bio updated successfully."}

@router.get("/all_users")
def get_all_users(db: Session = Depends(get_db)):
    users = db.query(User).all()
    users_data = db.query(UserProfile).all()
    return {"users": users, "profiles": users_data}