import fire

import urllib.request
import urllib.parse

def fetch_url(url, method='GET', headers={}, data=None):
    with urllib.request.urlopen(urllib.request.Request(url, method=method, headers=headers, data=urllib.parse.urlencode(data).encode('utf-8') if data else None)) as response:
        return response.read()



if __name__ == '__main__':
    fire.Fire()