import os, datetime
from sqlalchemy import Integer, Float, Numeric, String, Text, Unicode, Boolean, DateTime, Date, Time
from sqlalchemy import Table, Column, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship, declarative_base

Base = declarative_base()

class BaseMixin:
    id = Column(Integer, primary_key=True)
    created_at = Column(DateTime, default=datetime.datetime.now(datetime.timezone.utc))
    updated_at = Column(DateTime, default=datetime.datetime.now(datetime.timezone.utc), onupdate=datetime.datetime.now(datetime.timezone.utc))
    is_active = Column(Boolean, default=True)
    
class User(Base, BaseMixin):
    __tablename__ = 'user'
    username = Column(String(255), nullable=False, comment="用户名")
    password = Column(String(255), nullable=False, comment="密码")
    
    tags = relationship('Tag', secondary="user_tag_association", back_populates='users')
    followers = relationship("Follow", back_populates="followed", foreign_keys='Follow.followed_id')
    following = relationship("Follow", back_populates="follower", foreign_keys='Follow.follower_id')

    def __str__(self):
        return self.username

class Follow(Base, BaseMixin):
    __tablename__ = 'follow'
    follower_id = Column(Integer, ForeignKey('user.id'))
    followed_id = Column(Integer, ForeignKey('user.id'))
    
    follower = relationship("User", foreign_keys=[follower_id], back_populates="following")
    followed = relationship("User", foreign_keys=[followed_id], back_populates="followers")

class Article(Base, BaseMixin):
    __tablename__ = 'article'
    title = Column(String(255), nullable=False, comment="标题")
    content = Column(Text, nullable=False, comment="正文")
    
    user = relationship('User', backref='articles')

    def __str__(self):
        return self.title

class Tag(Base, BaseMixin):
    __tablename__ = 'tag'
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), unique=True, index=True)
    users = relationship('User', secondary="user_tag_association", back_populates='tags')

# 多对多关联表
user_tag_association = Table(
    'user_tag_association', Base.metadata,
    Column('user_id', Integer, ForeignKey('user.id')),
    Column('tag_id', Integer, ForeignKey('tag.id'))
)


from sqlalchemy import create_engine, inspect
from sqlalchemy.orm import sessionmaker

# DATABASE_URL = 'sqlite+pysqlite:///:memory:'
# DATABASE_URL = 'mysql+pymysql://root:123123@127.0.0.1:3306/db1'
DATABASE_URL = 'sqlite:///./db.sqlite3'

engine = create_engine(DATABASE_URL, echo=False)

if 'user' not in inspect(engine).get_table_names():
    Base.metadata.create_all(engine)
    print('All table created')

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
        
from sqlalchemy import insert, delete, update, select, func, text, and_, or_, not_, desc, asc

with next(get_db()) as db:
    user = db.query(User).first()
    print(user)
