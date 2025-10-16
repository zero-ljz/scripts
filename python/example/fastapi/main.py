from fastapi import FastAPI, HTTPException, Depends, Request, Form
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from pydantic import BaseModel
from typing import List, Optional
import uvicorn

# -----------------------
# 应用初始化
# -----------------------
app = FastAPI(title="FastAPI Demo", version="1.0.0")

# -----------------------
# CORS 中间件
# -----------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # 可以改成具体域名 ["http://localhost:3000"]
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# -----------------------
# 静态文件 & 模板
# -----------------------
app.mount("/static", StaticFiles(directory="static"), name="static")
templates = Jinja2Templates(directory="templates")

# -----------------------
# 模拟数据库 (内存)
# -----------------------
fake_db = {}

# -----------------------
# 数据模型
# -----------------------
class Item(BaseModel):
    name: str
    description: Optional[str] = None
    price: float
    tags: List[str] = []

class ItemOut(Item):
    id: int

# -----------------------
# 依赖项
# -----------------------
def get_token_header(token: str = "fake-super-token"):
    if token != "fake-super-token":
        raise HTTPException(status_code=403, detail="Invalid or missing token")
    return token

# -----------------------
# 路由
# -----------------------
@app.get("/", response_class=HTMLResponse)
async def read_root(request: Request):
    return templates.TemplateResponse("index.html", {"request": request, "title": "FastAPI Demo"})

@app.get("/items/", response_model=List[ItemOut])
async def list_items():
    return list(fake_db.values())

@app.post("/items/", response_model=ItemOut, dependencies=[Depends(get_token_header)])
async def create_item(item: Item):
    item_id = len(fake_db) + 1
    item_out = ItemOut(id=item_id, **item.dict())
    fake_db[item_id] = item_out
    return item_out

@app.get("/items/{item_id}", response_model=ItemOut)
async def get_item(item_id: int):
    if item_id not in fake_db:
        raise HTTPException(status_code=404, detail="Item not found")
    return fake_db[item_id]

@app.put("/items/{item_id}", response_model=ItemOut)
async def update_item(item_id: int, item: Item):
    if item_id not in fake_db:
        raise HTTPException(status_code=404, detail="Item not found")
    updated_item = ItemOut(id=item_id, **item.dict())
    fake_db[item_id] = updated_item
    return updated_item

@app.delete("/items/{item_id}")
async def delete_item(item_id: int):
    if item_id not in fake_db:
        raise HTTPException(status_code=404, detail="Item not found")
    del fake_db[item_id]
    return {"ok": True, "message": f"Item {item_id} deleted"}

# -----------------------
# 表单处理
# -----------------------
@app.post("/login/")
async def login(username: str = Form(...), password: str = Form(...)):
    if username == "admin" and password == "123456":
        return {"message": "Login success", "token": "fake-super-token"}
    return JSONResponse(status_code=401, content={"message": "Invalid credentials"})

# -----------------------
# 全局异常处理
# -----------------------
@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    return JSONResponse(status_code=exc.status_code, content={"error": exc.detail})

# -----------------------
# 启动命令
# -----------------------
if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
