from sqlalchemy import Column, Integer, String, ForeignKey, UniqueConstraint, DateTime, Boolean
from app.database import Base
from sqlalchemy.orm import relationship
import datetime

class User(Base):
    __tablename__ = 'users'

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    password = Column(String)
    is_beta_tester = Column(Boolean, default=False)

    profile = relationship("UserProfile", back_populates="user", uselist=False)
    round_participations = relationship("RoundPlayer", back_populates="user")
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

class Round(Base):
    __tablename__ = "rounds"

    id = Column(Integer, primary_key=True)
    name = Column(String)
    creator_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    is_active = Column(Boolean, default=True)

    players = relationship("RoundPlayer", back_populates="round")
    gelbfelder = relationship("Gelbfeld", back_populates="round")

class RoundPlayer(Base):
    __tablename__ = "round_players"

    id = Column(Integer, primary_key=True)
    round_id = Column(Integer, ForeignKey("rounds.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)  # Wenn Freund
    guest_name = Column(String, nullable=True)  # Wenn Gast
    points = Column(Integer, default=0)

    round = relationship("Round", back_populates="players")
    user = relationship("User", back_populates="round_participations", foreign_keys=[user_id])
    gelbfelder = relationship("Gelbfeld", back_populates="player")

class Gelbfeld(Base):
    __tablename__ = "gelbfelds"

    id = Column(Integer, primary_key=True)
    round_id = Column(Integer, ForeignKey("rounds.id"), nullable=False)
    round_player_id = Column(Integer, ForeignKey("round_players.id"), nullable=False)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)

    round = relationship("Round", back_populates="gelbfelder")
    player = relationship("RoundPlayer", back_populates="gelbfelder")

class UserStatistics(Base):
    __tablename__ = 'user_statistics'

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    total_rounds = Column(Integer, default=0)
    total_points = Column(Integer, default=0)
    total_gelbfelder = Column(Integer, default=0)
    best_score_in_round = Column(Integer, default=0)

    user = relationship("User", backref="statistics")