from pydantic import BaseModel
from typing import List, Optional

class RegisterRequest(BaseModel):
    username: str
    email: str
    password: str

class TokenRequest(BaseModel):
    token: str

class LoginRequest(BaseModel):
    username_or_email: str
    password: str
    
class BioRequest(BaseModel):
    token: str
    bio: str
    
class AddFriendRequest(BaseModel):
    friend_username: str
    token: str 

class SearchUsersRequest(TokenRequest):
    query: str
    
class PlayerInput(BaseModel):
    user_id: Optional[int] = None  # Wenn Freund
    guest_name: Optional[str] = None  # Wenn Gast

class CreateRoundInput(BaseModel):
    name: str
    token: str
    players: List[PlayerInput]

class AddPointInput(BaseModel):
    round_id: int
    round_player_id: int
    token: str