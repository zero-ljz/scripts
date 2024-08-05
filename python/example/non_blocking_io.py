import urllib.request
import urllib.parse

def send_request(url, method='GET', headers={}, data=None):
    if isinstance(data, dict):
        data = urllib.parse.urlencode(data)
        headers['Content-Type'] = 'application/x-www-form-urlencoded'
    req = urllib.request.Request(url, method=method, headers=headers, data=data and data.encode('utf-8'))
    with urllib.request.urlopen(req) as resp:
        return resp.read().decode('utf-8')


import concurrent.futures

urls = ['http://example.com', 'http://iapp.run/echo?1']
headers = {
    'User-Agent': 'MyUserAgent',
    'Authorization': 'Bearer my_token'
}

with concurrent.futures.ThreadPoolExecutor() as executor:
    # 提交每个URL的请求任务给线程池
    futures = {executor.submit(send_request, url, method='GET', headers=headers): url for url in urls}

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
            
            
            
            