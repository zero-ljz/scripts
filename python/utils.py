import re
import fire

import urllib.request
import urllib.parse

def fetch_url(url, method='GET', headers={}, data=None):
    with urllib.request.urlopen(urllib.request.Request(url, method=method, headers=headers, data=urllib.parse.urlencode(data).encode('utf-8') if data else None)) as response:
        return response.read()


def convert_to_snakecase(text):
    # 使用正则表达式将驼峰命名转为下划线命名
    return re.sub(r'([a-z0-9])([A-Z])', r'\1_\2', text).lower()

def convert_to_camelcase(text, capitalize_first=False):
    # 将下划线命名转为驼峰命名
    out = ''.join(x.capitalize() for x in text.split('_'))
    return out if capitalize_first else out[0].lower() + out[1:]

def convert_keys(func, data):
    if isinstance(data, dict):
        return {(func(k) if isinstance(k, str) else k): convert_keys(func, v) for k, v in data.items()}
    elif isinstance(data, list):
        return [convert_keys(func, item) for item in data]
    else:
        return data

if __name__ == '__main__':
    fire.Fire()