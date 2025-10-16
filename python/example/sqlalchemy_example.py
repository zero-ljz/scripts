import os, datetime
from typing import Any, List, Dict, Tuple, Set
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
    user_id = Column(Integer, ForeignKey('user.id'))
    
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
from sqlalchemy.orm import Session

def execute_query_get_list(
    db: Session,
    stmt: Any,
    sort_by: str | None = None,
    page: int | None = None,
    per_page: int | None = 10,
) -> dict[str, Any]:
    '''
    stmt = (select(*Alarm.__table__.columns))
    count, row_dicts  = execute_query_get_list(db, stmt, page=page, per_page=per_page).values()
    '''
    
    out: dict[str, Any] = {}
    # 排序
    if sort_by:
        for field in sort_by.split(","):
            if ":" in field:
                field_name, sort_order = field.split(":")
                if sort_order.lower() == "desc":
                    stmt = stmt.order_by(desc(field_name))
                else:
                    stmt = stmt.order_by(field_name)
            else:
                stmt = stmt.order_by(field)
    # 分页
    if page:
        count_stmt = select(func.count()).select_from(stmt.alias())
        out["count"] = db.execute(count_stmt).scalar() # 相当于.scalars().first()
        stmt = stmt.offset((page - 1) * per_page).limit(per_page)

    rows = db.execute(stmt).mappings().all() # 类型 List[RowMapping]
    out["data"] = [dict(row) for row in rows]
    return out


# 更新操作
with next(get_db()) as db:
    stmt = insert(User).values(username='user1', password='pass1')
    # stmt = delete(User).where(User.username == 'user1')
    # stmt = update(User).where(User.username == 'user1').values(username='user2')
    db.execute(stmt)
    db.commit()
    
# 单个查询
with next(get_db()) as db:
    # Core 方式
    stmt = select(User).select_from(User).where(User.username == 'user1')
    user: User = db.execute(stmt).first()[0] # 或 user = db.execute(stmt).scalars().one_or_none()
    print(user)
    
    # ORM 方式
    user: User = db.query(User).filter(User.username == 'user1').first()
    print(user)
    
    # 转为字典
    user_dict: Dict[str, Any] = {k: v for k, v in user.__dict__.items() if not k.startswith('_sa_')}
    print(user_dict)

# 多个查询
with next(get_db()) as db:
    # Core 方式
    stmt = select(User).select_from(User).where(and_(User.username == 'user1', User.password == 'pass1')).order_by(desc(User.id)).offset(0).limit(10)
    users: List[User] = db.execute(stmt).scalars().all()
    print(users)
    
    # ORM 方式
    users: List[User] = db.query(User).filter(and_(User.username == 'user1', User.password == 'pass1')).order_by(desc(User.id)).offset(0).limit(10).all()
    print(users)

    # 转为字典列表
    user_dicts: List[Dict[str, Any]] = [{k: v for k, v in obj.__dict__.items() if not k.startswith('_sa_')} for obj in users]
    print(user_dicts)
