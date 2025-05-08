from fastapi import FastAPI
from app.apis import router  # Import the router from apis.py
from app.database import Base, engine  # Import Base and engine to create the database tables

# Create the database tables if they don't exist
Base.metadata.create_all(bind=engine)

app = FastAPI()

# Include the router with the API routes
app.include_router(router)
