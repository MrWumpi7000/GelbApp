from pydantic import BaseModel

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