from sqlalchemy import Column, Integer, String, ForeignKey, UniqueConstraint
from app.database import Base
from sqlalchemy.orm import relationship

class User(Base):
    __tablename__ = 'users'

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    password = Column(String)

    profile = relationship("UserProfile", back_populates="user", uselist=False)

    # Friendships initiated by this user
    friends = relationship(
        "UserFriendship",
        foreign_keys="UserFriendship.user_id",
        back_populates="user",
        cascade="all, delete-orphan"
    )

    # Friendships where this user is the recipient
    friend_of = relationship(
        "UserFriendship",
        foreign_keys="UserFriendship.friend_id",
        back_populates="friend",
        cascade="all, delete-orphan"
    )

class UserProfile(Base):
    __tablename__ = 'user_profiles'

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, index=True)
    first_name = Column(String)
    last_name = Column(String)
    bio = Column(String)
    profile_picture = Column(String)

    user = relationship("User", back_populates="profile")

class UserFriendship(Base):
    __tablename__ = 'user_friendships'

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True)
    friend_id = Column(Integer, ForeignKey("users.id"), index=True)
    status = Column(String)  # e.g., "pending", "accepted", "blocked"

    user = relationship("User", foreign_keys=[user_id], back_populates="friends")
    friend = relationship("User", foreign_keys=[friend_id], back_populates="friend_of")

    __table_args__ = (
        UniqueConstraint('user_id', 'friend_id', name='uq_user_friend'),
    )
