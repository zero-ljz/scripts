import datetime
from typing import Any, List, Dict, Optional, Annotated

from sqlalchemy import (
    Integer, String, Text, Boolean, DateTime, ForeignKey, 
    Table, Column, insert, delete, update, select, func, text, and_, or_, not_, desc, asc
)
from sqlalchemy.orm import (
    DeclarativeBase, Mapped, mapped_column, relationship, 
    Session, sessionmaker
)
from sqlalchemy import create_engine, inspect

# --- 1. 基础模型定义 ---

class Base(DeclarativeBase):
    """所有模型的基类"""
    pass

# 定义通用字段类型，减少重复代码
int_pk = Annotated[int, mapped_column(primary_key=True)]
timestamp = Annotated[
    datetime.datetime, 
    mapped_column(default=lambda: datetime.datetime.now(datetime.timezone.utc))
]

class BaseMixin:
    id: Mapped[int_pk]
    created_at: Mapped[timestamp]
    updated_at: Mapped[timestamp] = mapped_column(
        onupdate=lambda: datetime.datetime.now(datetime.timezone.utc)
    )
    is_active: Mapped[bool] = mapped_column(default=True)

# --- 2. 关联表与模型 ---

# 多对多关联表 (保持为 Table 对象在 2.0 中依然是标准做法)
user_tag_association = Table(
    'user_tag_association',
    Base.metadata,
    Column('user_id', ForeignKey('user.id'), primary_key=True),
    Column('tag_id', ForeignKey('tag.id'), primary_key=True)
)

class User(Base, BaseMixin):
    __tablename__ = 'user'
    
    username: Mapped[str] = mapped_column(String(255), nullable=False, comment="用户名")
    password: Mapped[str] = mapped_column(String(255), nullable=False, comment="密码")
    
    # 关系定义
    tags: Mapped[List["Tag"]] = relationship(
        secondary=user_tag_association, back_populates='users'
    )
    # 关注者 (谁在关注我)
    followers: Mapped[List["Follow"]] = relationship(
        "Follow", back_populates="followed", foreign_keys='Follow.followed_id'
    )
    # 关注中 (我在关注谁)
    following: Mapped[List["Follow"]] = relationship(
        "Follow", back_populates="follower", foreign_keys='Follow.follower_id'
    )
    
    # 文章反向引用 (2.0 推荐显式定义或使用 back_populates)
    articles: Mapped[List["Article"]] = relationship(back_populates="user")

    def __str__(self):
        return self.username

class Follow(Base, BaseMixin):
    __tablename__ = 'follow'
    
    follower_id: Mapped[int] = mapped_column(ForeignKey('user.id'))
    followed_id: Mapped[int] = mapped_column(ForeignKey('user.id'))
    
    follower: Mapped["User"] = relationship(
        "User", foreign_keys=[follower_id], back_populates="following"
    )
    followed: Mapped["User"] = relationship(
        "User", foreign_keys=[followed_id], back_populates="followers"
    )

class Article(Base, BaseMixin):
    __tablename__ = 'article'
    
    user_id: Mapped[int] = mapped_column(ForeignKey('user.id'))
    title: Mapped[str] = mapped_column(String(255), nullable=False, comment="标题")
    content: Mapped[str] = mapped_column(Text, nullable=False, comment="正文")
    
    user: Mapped["User"] = relationship("User", back_populates="articles")

    def __str__(self):
        return self.title

class Tag(Base, BaseMixin):
    __tablename__ = 'tag'
    
    name: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    users: Mapped[List["User"]] = relationship(
        secondary=user_tag_association, back_populates='tags'
    )

# --- 3. 数据库连接与工具函数 ---

DATABASE_URL = 'sqlite:///./db.sqlite3'
engine = create_engine(DATABASE_URL, echo=False)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)

def init_db():
    if not inspect(engine).has_table('user'):
        Base.metadata.create_all(engine)
        print('All tables created')

def get_db():
    with SessionLocal() as db:
        yield db

def execute_query_get_list(
    db: Session,
    stmt: Any,
    sort_by: Optional[str] = None,
    page: Optional[int] = None,
    per_page: int = 10,
) -> Dict[str, Any]:
    """
    2.0 风格的通用查询分页封装
    """
    out: Dict[str, Any] = {}
    
    # 排序处理
    if sort_by:
        for field in sort_by.split(","):
            if ":" in field:
                name, order = field.split(":")
                col = text(name)
                stmt = stmt.order_by(desc(col)) if order.lower() == "desc" else stmt.order_by(asc(col))
            else:
                stmt = stmt.order_by(text(field))

    # 分页处理
    if page:
        # 获取总数：2.0 推荐使用 func.count() 配合子查询
        count_stmt = select(func.count()).select_from(stmt.subquery())
        out["count"] = db.execute(count_stmt).scalar_one()
        
        stmt = stmt.offset((page - 1) * per_page).limit(per_page)

    # 执行并转换
    result = db.execute(stmt)
    # 如果查询的是实体对象，需要用 scalars()；如果查询的是特定列，用 mappings()
    # 这里兼容处理：尝试获取映射
    rows = result.mappings().all()
    out["data"] = [dict(row) for row in rows]
    return out

# --- 4. 业务操作示例 ---

if __name__ == "__main__":
    init_db()

    # CUD 操作
    with next(get_db()) as db:
        # 插入
        db.execute(insert(User).values(username='user1', password='pass1'))
        
        # 更新
        db.execute(
            update(User).where(User.username == 'user1').values(username='user_new')
        )
        
        # 删除
        db.execute(delete(User).where(User.username == 'user_new'))
        
        db.commit()

    # 查询操作
    with next(get_db()) as db:
        # 1. 获取单个 ORM 对象 (2.0 推荐)
        stmt = select(User).where(User.username == 'user1')
        user = db.execute(stmt).scalar_one_or_none()
        
        if user:
            print(f"Found user: {user.username}")
            # 2.0 转字典 (排除了 SQLAlchemy 内部状态)
            user_dict = {c.name: getattr(user, c.name) for c in user.__table__.columns}
            print(f"User dict: {user_dict}")

        # 2. 获取列表
        stmt_list = select(User).where(or_(User.id > 0, User.is_active == True))
        users = db.execute(stmt_list).scalars().all()
        print(f"User list: {users}")

        # 3. 使用封装的工具函数 (返回 RowMapping 字典)
        list_data = execute_query_get_list(db, select(User), sort_by="id:desc", page=1)
        print(f"Paginated data: {list_data}")