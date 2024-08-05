
import pickle
from functools import wraps
from hashlib import md5
import inspect

def cache_obj(expire_time=60):
    '''
    缓存函数返回的对象装饰器
    :param expire_time: 过期时间, 秒
    :param save_path: 缓存文件保存路径
    :return:
    
    示例:
    @cache_obj(expire_time=60)
    def get_current_time():
        return datetime.datetime.now()
    '''
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            # 获取函数签名并绑定参数
            sig = inspect.signature(func)
            bound_args = sig.bind(*args, **kwargs)
            bound_args.apply_defaults()
            # 创建一个已排序的参数元组以生成唯一的文件名
            args_tuple = tuple(sorted(bound_args.arguments.items()))

            file_path = f"./cache/{func.__name__}_{md5(str(args_tuple).encode('utf-8')).hexdigest()}.pkl"
            refresh = kwargs.get('refresh', False)

            try:
                with open(file_path, "rb") as f:
                    obj = pickle.load(f)
            except (FileNotFoundError, EOFError, ValueError):
                obj = None

            if not obj or os.path.getmtime(file_path) + expire_time < time.time() or refresh:
                print(f"{func.__name__}{str(args_tuple)} 重新调用获取新对象")
                obj = func(*args, **kwargs)
                with open(file_path, "wb") as f:
                    pickle.dump(obj, f)
            return obj
        return wrapper
    return decorator

def cache_data(expire_time=60):
    def decorator(func):
        def wrapper(*args, **kwargs):
            file_path = f"./cache/{func.__name__}_cache.json"
            refresh = kwargs.get('refresh', False)
            
            try:
                with open(file_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
            except FileNotFoundError:
                data = {}
            
            if not data or os.path.getmtime(file_path) + expire_time < time.time() or refresh:
                print("重新获取数据")
                data = func(*args, **kwargs)
                with open(file_path, "w", encoding="utf-8") as f:
                    json.dump(data, f, ensure_ascii=False, indent=4, default=lambda o: str(o))
            return data
        return wrapper
    return decorator


# import httpx
def get_access_token():
    try:
        with open("access_token.json", "r") as f:
            data = json.load(f)
    except FileNotFoundError:
        data = {}
    if not data or data["expire_time"] < time.time():
        print("重新获取access_token")
        payload = {}
        data = httpx.post(f"https://example.com", json=payload, verify=False).json()
        if data.get('errorcode') != 0:
            print(data)
            return
        data["expire_time"] = int(data["expires_in"]) + int(time.time())
        with open("access_token.json", "w") as f:
            json.dump(data, f)
    return data["access_token"]

def get_value():
    global data
    if "data" not in globals():
        data = {}
    if "expire_time" not in data or data['expire_time'] < time.time():
        data["a"] = 1
        data["expire_time"] = 10 + int(time.time())
    return data["value"]


