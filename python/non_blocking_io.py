
import concurrent.futures

from utils import fetch_url
    

urls = ['http://example.com', 'http://iapp.run/echo?1']
headers = {
    'User-Agent': 'MyUserAgent',
    'Authorization': 'Bearer my_token'
}

with concurrent.futures.ThreadPoolExecutor() as executor:
    # 提交每个URL的请求任务给线程池
    futures = {executor.submit(fetch_url, url, method='GET', headers=headers): url for url in urls}

    # 
    
    # 此处可以用list(futures.keys())[0].result()来获取结果，但是会阻塞直到异步操作完成并返回结果

    # 迭代已完成的 Future 对象，并获取结果
    for future in concurrent.futures.as_completed(futures):
        url = futures[future]
        try:
            response = future.result()
            print(f'Successfully fetched URL {url}, response: {response}')
            print()
        except Exception as e:
            print(f'Error fetching URL {url}: {e}')