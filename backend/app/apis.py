from fastapi import APIRouter, HTTPException, Depends, UploadFile, File, Form, Query # type: ignore
from fastapi.responses import StreamingResponse # type: ignore
from sqlalchemy.orm import Session # type: ignore
from sqlalchemy import or_, func # type: ignore
from app.models import User, UserProfile, UserFriendship, Round, RoundPlayer, Gelbfeld
from app.utils import hash_password, verify_password, whoami, create_access_token
from app.database import get_db
from app.schemas import RegisterRequest, TokenRequest, CreateRoundInput, PlayerInput, AddPointInput, LoginRequest, BioRequest, AddFriendRequest, SearchUsersRequest
from uuid import uuid4
import datetime
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
    username_or_email_lower = request.username_or_email.lower()

    user = db.query(User).filter(
        or_(
            func.lower(User.username) == username_or_email_lower,
            func.lower(User.email) == username_or_email_lower
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

    _, ext = os.path.splitext(file.filename.lower())

    # Validate file type
    allowed_extensions = {".png", ".jpg", ".jpeg", ".gif"}

        # Validate extension and content type
    if ext not in allowed_extensions or not file.content_type.startswith("image/"):
        print(f"Invalid file type: {file.content_type}, extension: {ext}")
        raise HTTPException(status_code=400, detail="Only image files (.png, .jpg, .jpeg, .gif) are allowed.")

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
        file_path = "/home/jasper/workspace/GelbApp/backend/app/assets/no_profile.jpg" 

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


@router.post("/add_friend")
def add_friend(req: AddFriendRequest, db: Session = Depends(get_db)):
    email = whoami(req.token)
    user = db.query(User).filter(User.email == email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Can't add yourself
    if req.friend_username == user.username or req.friend_username == user.email:
        raise HTTPException(status_code=400, detail="Cannot add yourself as a friend")

    friend = db.query(User).filter(
        (User.username == req.friend_username) | (User.email == req.friend_username)
    ).first()
    if not friend:
        raise HTTPException(status_code=404, detail="Friend not found")

    # Check if friendship already exists in either direction
    existing_friendship = db.query(UserFriendship).filter(
        (((UserFriendship.user_id == user.id) & (UserFriendship.friend_id == friend.id)) |
        ((UserFriendship.user_id == friend.id) & (UserFriendship.friend_id == user.id))) &
        (UserFriendship.status != "rejected")
    ).first()


    if existing_friendship:
        raise HTTPException(status_code=400, detail="Friend request already exists or you are already friends")
    
    rejected_friendship = db.query(UserFriendship).filter(
        (((UserFriendship.user_id == user.id) & (UserFriendship.friend_id == friend.id)) |
        ((UserFriendship.user_id == friend.id) & (UserFriendship.friend_id == user.id))) &
        (UserFriendship.status == "rejected")
    ).first()

    if rejected_friendship:
        db.delete(rejected_friendship)
        db.commit()  # commit the delete before new insert
        
    new_friendship = UserFriendship(user_id=user.id, friend_id=friend.id, status="pending")
    db.add(new_friendship)
    db.commit()

    return {"message": "Friend request sent."}

@router.post("/accept_friend")
def accept_friend(request_id: int, token: TokenRequest, db: Session = Depends(get_db)):
    email = whoami(token.token)
    user = db.query(User).filter(User.email == email).first()

    friendship = db.query(UserFriendship).filter(
        UserFriendship.id == request_id,
        UserFriendship.friend_id == user.id,
        UserFriendship.status == "pending"
    ).first()

    if not friendship:
        raise HTTPException(status_code=404, detail="Friend request not found")

    friendship.status = "accepted"
    db.commit()

    return {"message": "Friend request accepted"}

@router.post("/reject_friend")
def reject_friend(request_id: int, token: TokenRequest, db: Session = Depends(get_db)):
    email = whoami(token.token)
    user = db.query(User).filter(User.email == email).first()

    friendship = db.query(UserFriendship).filter(
        UserFriendship.id == request_id,
        UserFriendship.friend_id == user.id,
        UserFriendship.status == "pending"
    ).first()

    if not friendship:
        raise HTTPException(status_code=404, detail="Friend request not found")

    friendship.status = "rejected"
    db.commit()

    return {"message": "Friend request rejected"}

@router.post("/cancel_friend_request")
def cancel_friend_request(request_id: int, token: TokenRequest, db: Session = Depends(get_db)):
    email = whoami(token.token)
    user = db.query(User).filter(User.email == email).first()

    friendship = db.query(UserFriendship).filter(
        UserFriendship.id == request_id,
        UserFriendship.user_id == user.id,
        UserFriendship.status == "pending"
    ).first()

    if not friendship:
        raise HTTPException(status_code=404, detail="Request not found")

    db.delete(friendship)
    db.commit()

    return {"message": "Friend request canceled"}

@router.delete("/remove_friend/{friend_id}")
def remove_friend(friend_id: int, token: TokenRequest, db: Session = Depends(get_db)):
    email = whoami(token.token)
    user = db.query(User).filter(User.email == email).first()

    friendship = db.query(UserFriendship).filter(
        ((UserFriendship.user_id == user.id) & (UserFriendship.friend_id == friend_id)) |
        ((UserFriendship.user_id == friend_id) & (UserFriendship.friend_id == user.id)),
        UserFriendship.status == "accepted"
    ).first()

    if not friendship:
        raise HTTPException(status_code=404, detail="Friend not found")

    db.delete(friendship)
    db.commit()

    return {"message": "Friend removed"}

@router.post("/friends")
def list_friends(request: TokenRequest, db: Session = Depends(get_db)):
    email = whoami(request.token)
    user = db.query(User).filter(User.email == email).first()

    friendships = db.query(UserFriendship).filter(
        ((UserFriendship.user_id == user.id) | (UserFriendship.friend_id == user.id)) &
        (UserFriendship.status == "accepted")
    ).all()

    friends = []
    for f in friendships:
        friend_id = f.friend_id if f.user_id == user.id else f.user_id
        friend = db.query(User).filter(User.id == friend_id).first()
        friends.append({
            "id": friend.id,
            "username": friend.username,
            "email": friend.email
        })

    return {"friends": friends}

@router.post("/friend_requests/incoming")
def incoming_requests(request: TokenRequest, db: Session = Depends(get_db)):
    email = whoami(request.token)
    user = db.query(User).filter(User.email == email).first()

    requests = db.query(UserFriendship).filter(
        UserFriendship.friend_id == user.id,
        UserFriendship.status == "pending"
    ).all()

    result = [
        {"request_id": f.id, "from_user_id": f.user_id, "username": db.query(User).get(f.user_id).username}
        for f in requests
    ]
    return {"incoming_requests": result}

@router.post("/friend_requests/outgoing")
def outgoing_requests(request: TokenRequest, db: Session = Depends(get_db)):
    email = whoami(request.token)
    user = db.query(User).filter(User.email == email).first()

    requests = db.query(UserFriendship).filter(
        UserFriendship.user_id == user.id,
        UserFriendship.status == "pending"
    ).all()

    result = [
        {"request_id": f.id, "to_user_id": f.friend_id, "username": db.query(User).get(f.friend_id).username}
        for f in requests
    ]
    return {"outgoing_requests": result}

@router.post("/search_users")
def search_users(request: SearchUsersRequest, db: Session = Depends(get_db)):
    email = whoami(request.token)
    current_user = db.query(User).filter(User.email == email).first()

    if not current_user:
        raise HTTPException(status_code=404, detail="User not found")

    results = db.query(User).filter(
        ((User.username.ilike(f"%{request.query}%")) | (User.email.ilike(f"%{request.query}%"))) &
        (User.id != current_user.id)
    ).limit(10).all()

    users_with_status = []
    for user in results:
        friendship = db.query(UserFriendship).filter(
            ((UserFriendship.user_id == current_user.id) & (UserFriendship.friend_id == user.id)) |
            ((UserFriendship.user_id == user.id) & (UserFriendship.friend_id == current_user.id))
        ).first()

        status = friendship.status if friendship else "none"
        users_with_status.append({
            "username": user.username,
            "email": user.email,
            "status": status
        })

    return users_with_status

@router.post("/rounds/create")
def create_round(data: CreateRoundInput, db: Session = Depends(get_db)):
    print("Creating round with data:", data)
    # Creator holen
    email = whoami(data.token)
    
    if not email:
        return {"error": "Invalid token"}

    creator = db.query(User).filter_by(email=email).first()
    if not creator:
        return {"error": "Username not found for the provided token"}
    
    already_exists = db.query(Round).filter_by(name=data.name, creator_id=creator.id).first()
    if already_exists:
        return {"error": "A round with this name already exists for this user"}
    
    player_already_exists = db.query(RoundPlayer).filter(
        (RoundPlayer.guest_name == data.name) | 
        (RoundPlayer.user_id == creator.id) & (RoundPlayer.round.has(name=data.name))
    ).first()
    if player_already_exists:
        return {"error": "A player with this name already exists in a round for this user"}
    
    new_round = Round(name=data.name, creator_id=creator.id)
    db.add(new_round)
    db.flush()

    creator_player = RoundPlayer(round_id=new_round.id, user_id=creator.id)
    db.add(creator_player)

    for player_data in data.players:
        if player_data.user_id is not None:
            user = db.query(User).filter_by(id=player_data.user_id).first()
            if not user:
                print(f"User with ID {player_data.user_id} not found, skipping player addition.")
                continue
            round_player = RoundPlayer(round_id=new_round.id, user_id=user.id)
        elif player_data.guest_name:
            round_player = RoundPlayer(round_id=new_round.id, guest_name=player_data.guest_name)
        else:
            continue 
        db.add(round_player)

    db.commit()

    return {"message": "Created Round", "round_id": new_round.id}


@router.post("/points/add")
def add_point(data: AddPointInput, db: Session = Depends(get_db)):

    valid_token = whoami(data.token)
    if not valid_token:
        return {"error": "Invalid token"}

    player = db.query(RoundPlayer).filter_by(id=data.round_player_id).first()
    if not player:
        return {"error": "Player not found"}

    if player.round_id != data.round_id:
        return {"error": "Player does not belong to the specified round"}

    player.points += 1

    gelb = Gelbfeld(
        round_id=data.round_id,
        round_player_id=player.id
    )
    db.add(gelb)
    db.commit()

    return {
        "message": "Point added",
        "player_id": player.id,
        "points": player.points
    }

@router.get("/rounds/{round_id}/scores")
def get_scores(round_id: int, db: Session = Depends(get_db)):
    gelbfields = len(db.query(Gelbfeld).filter_by(round_id=round_id).all())


    round = db.query(Round).filter_by(id=round_id).first()
    if not round:
        return {"error": "Round not found"}

    scores = []
    for p in round.players:
        if p.user:
            scores.append({
                "name": p.user.username,
                "points": p.points,
                "player_id": p.id,
                "is_guest": False
            })
        else:
            scores.append({
                "name": p.guest_name,
                "points": p.points,
                "player_id": p.id,
                "is_guest": True,
            })

    return {"round_id": round_id,"field_count":gelbfields ,"round_name": round.name,"player_count": len(round.players),"scores": scores}

@router.delete("/rounds/{round_id}/delete")
def delete_round(round_id: int, token_request: str, db: Session = Depends(get_db)):
    round = db.query(Round).filter_by(id=round_id).first()
    if not round:
        return {"error": "Round not found"}
    print(token)
    if token_request != round.creator_id:
        return {"error": "You are not authorized to delete this round"}
    
    db.delete(round)
    db.commit()

    return {"message": "Round deleted"}