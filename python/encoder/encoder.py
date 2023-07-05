import click
import base64
import hashlib
import binascii
import datetime
import urllib.parse
import html

# 命令行选项常量定义
ENCODE_OPTION = '--encode'
DECODE_OPTION = '--decode'


@click.group()
def cli():
    pass


@cli.command()
@click.argument('text')
@click.option(DECODE_OPTION, '-d', is_flag=True, help='Perform decoding')
def base64_(text, decode):
    """
    Base64 编码/解码
    """
    output = ''
    if decode:
        output = base64.b64decode(text).decode('utf-8')
    else:
        output = base64.b64encode(text.encode('utf-8')).decode('utf-8')

    click.echo(output)


@cli.command()
@click.argument('text')
def md5(text):
    """
    MD5 编码
    """
    output = hashlib.md5(text.encode('utf-8')).hexdigest()
    click.echo(output)


@cli.command()
@click.argument('text')
@click.option('--algorithm', '-a', default='sha256', help='Hash algorithm')
def hash(text, algorithm):
    """
    哈希编码
    """
    if algorithm.startswith('sha'):
        hash_algorithm = hashlib.new(algorithm)
        hash_algorithm.update(text.encode('utf-8'))
        output = hash_algorithm.hexdigest()
        click.echo(output)
    else:
        click.echo('Invalid hash algorithm')


@cli.command()
@click.argument('text')
@click.option(DECODE_OPTION, '-d', is_flag=True, help='Perform decoding')
def hex(text, decode):
    """
    十六进制编码/解码
    """
    output = ''
    if decode:
        output = binascii.unhexlify(text).decode('utf-8')
    else:
        output = binascii.hexlify(text.encode('utf-8')).decode('utf-8')

    click.echo(output)


@cli.command()
@click.argument('text')
@click.option(DECODE_OPTION, '-d', is_flag=True, help='Perform decoding')
def bin_(text, decode):
    """
    二进制编码/解码
    """
    output = ''
    if decode:
        output = binascii.unhexlify(hex(int(text, 2))[2:])
        if isinstance(output, bytes):
            output = output.decode('utf-8')
    else:
        output = bin(int(binascii.hexlify(text.encode('utf-8')), 16))[2:]

    click.echo(output)


@cli.command()
@click.argument('text')
@click.option(DECODE_OPTION, '-d', is_flag=True, help='Perform decoding')
def hex_binary(text, decode):
    """
    十六进制转二进制/二进制转十六进制
    """
    output = ''
    if decode:
        output = hex(int(text, 2))[2:]
    else:
        output = bin(int(text, 16))[2:]

    click.echo(output)


@cli.command()
@click.argument('text')
@click.option(DECODE_OPTION, '-d', is_flag=True, help='Perform decoding')
def ascii(text, decode):
    """
    ASCII 编码/解码
    """
    output = ''
    if decode:
        output = ''.join(chr(int(char)) for char in text.split())
    else:
        output = ' '.join(str(ord(char)) for char in text)
        # 其他写法
        # output = ''
        # for char in text:
        #     output += str(ord(char)) + ' '

    click.echo(output)


@cli.command()
@click.argument('text')
@click.option(DECODE_OPTION, '-d', is_flag=True, help='Perform decoding')
def rgb_hex(text, decode):
    """
    RGB 转十六进制/十六进制转 RGB
    """
    output = ''
    if decode:
        text = text.strip('#')
        r = int(text[0:2], 16)
        g = int(text[2:4], 16)
        b = int(text[4:6], 16)
        output = f"{r},{g},{b}"
    else:
        output = '#' + ''.join(hex(int(value))[2:].zfill(2) for value in text.split(','))
        # 其他写法
        # r, g, b = map(int, text.split(','))
        # output = f"#{r:02X}{g:02X}{b:02X}"

    click.echo(output)


@cli.command()
@click.argument('text')
@click.option(DECODE_OPTION, '-d', is_flag=True, help='Perform decoding')
def datetime_timestamp(text, decode):
    """
    日期时间转时间戳/时间戳转日期时间
    """
    output = ''
    if decode:
        try:
            timestamp = int(text)
            output = datetime.datetime.fromtimestamp(timestamp).strftime('%Y-%m-%d %H:%M:%S')
        except ValueError:
            output = 'Invalid timestamp'
    else:
        try:
            datetime_obj = datetime.datetime.strptime(text, "%Y-%m-%d %H:%M:%S")
            output = str(int(datetime_obj.timestamp()))
        except ValueError:
            output = 'Invalid datetime, valid example: 1970-01-01 08:00:00'

    click.echo(output)


@cli.command()
@click.argument('text')
@click.option(DECODE_OPTION, '-d', is_flag=True, help='Perform decoding')
def unicode_escape(text, decode):
    """
    Unicode 转义序列编码/解码
    """
    output = ''
    if decode:
        output = bytes(text, "utf-8").decode("unicode_escape")
        # bytes(text, "utf-8") 使用 UTF-8 编码将字符串转换为字节序列。
        # text.encode("utf-8") 显式地指定使用 UTF-8 编码将字符串转换为字节序列。
    else:
        output = text.encode("unicode_escape").decode("utf-8")

    click.echo(output)


@cli.command()
@click.argument('text')
@click.option(DECODE_OPTION, '-d', is_flag=True, help='Perform decoding')
def uri(text, decode):
    """
    URL 编码/解码
    """
    output = ''
    if decode:
        output = urllib.parse.unquote(text)
    else:
        output = urllib.parse.quote(text, safe=':/?#[]@!$&\'()*+,;=%')

    click.echo(output)


@cli.command()
@click.argument('text')
@click.option(DECODE_OPTION, '-d', is_flag=True, help='Perform decoding')
def uri_component(text, decode):
    """
    URL 组件编码/解码
    """
    output = ''
    if decode:
        output = urllib.parse.unquote(text)
    else:
        output = urllib.parse.quote(text).replace('/', '%2F')

    click.echo(output)


@cli.command()
@click.argument('text')
@click.option(DECODE_OPTION, '-d', is_flag=True, help='Perform decoding')
def html_escape(text, decode):
    """
    HTML 转义编码/解码
    """
    output = ''
    if decode:
        output = html.unescape(text)
        #codecs.encode(text, 'unicode_escape').decode('utf-8')
    else:
        output = html.escape(text)

    click.echo(output)


