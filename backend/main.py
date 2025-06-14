from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from app.apis import router  # Import the router from apis.py
from app.database import Base, engine  # Import Base and engine to create the database tables
from fastapi.middleware.cors import CORSMiddleware
from app.models import Round, RoundPlayer, Gelbfeld  # Import your models to ensure they are registered with SQLAlchemy
import os

Base.metadata.create_all(bind=engine)

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

app = FastAPI()

app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # or restrict to your frontend URL like "http://localhost:5000"
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
# Include the router with the API routes
app.include_router(router)
