from fastapi import FastAPI
from app.apis import router  # Import the router from apis.py
from app.database import Base, engine  # Import Base and engine to create the database tables
from fastapi.middleware.cors import CORSMiddleware

# Create the database tables if they don't exist
Base.metadata.create_all(bind=engine)


app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # or restrict to your frontend URL like "http://localhost:5000"
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
# Include the router with the API routes
app.include_router(router)
