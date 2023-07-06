#!/usr/bin/env node

const commander = require('commander');
const base64 = require('base-64');
const md5 = require('md5');
const crypto = require('crypto');
const moment = require('moment');
const querystring = require('querystring');
const he = require('he');

const program = new commander.Command();

program
  .version('1.0.0')
  .description('命令行工具');

program
  .command('base64 [text]')
  .option('-d, --decode', '执行解码')
  .description('Base64 编码/解码')
  .action((text, options) => {
    let output = '';
    if (options.decode) {
      output = Buffer.from(text, 'base64').toString('utf-8');
    } else {
      output = Buffer.from(text).toString('base64');
    }
    console.log(output);
  });

program
  .command('md5 [text]')
  .description('MD5 编码')
  .action((text) => {
    const output = md5(text);
    console.log(output);
  });

program
  .command('hash [text]')
  .option('-a, --algorithm <algorithm>', '哈希算法', 'sha256')
  .description('哈希编码')
  .action((text, options) => {
    const algorithm = options.algorithm;
    if (algorithm.startsWith('sha')) {
      const hashAlgorithm = crypto.createHash(algorithm);
      const output = hashAlgorithm.update(text).digest('hex');
      console.log(output);
    } else {
      console.log('Invalid hash algorithm');
    }
  });

program
  .command('hex_binary [text]')
  .option('-d, --decode', '执行解码')
  .description('十六进制转二进制/二进制转十六进制')
  .action((text, options) => {
    let output = '';
    if (options.decode) {
      output = parseInt(text, 2).toString(16);
    } else {
      output = parseInt(text, 16).toString(2);
    }
    console.log(output);
  });

program
  .command('ascii [text]')
  .option('-d, --decode', '执行解码')
  .description('ASCII 编码/解码')
  .action((text, options) => {
    let output = '';
    if (options.decode) {
      output = text.split(' ').map((char) => String.fromCharCode(parseInt(char))).join('');
    } else {
      output = text.split('').map((char) => char.charCodeAt(0)).join(' ');
    }
    console.log(output);
  });

program
  .command('rgb_hex [text]')
  .option('-d, --decode', '执行解码')
  .description('RGB 转十六进制/十六进制转 RGB')
  .action((text, options) => {
    let output = '';
    if (options.decode) {
      const [r, g, b] = text.split(',').map((value) => parseInt(value));
      output = `#${r.toString(16).padStart(2, '0')}${g.toString(16).padStart(2, '0')}${b.toString(16).padStart(2, '0')}`;
    } else {
      output = text
        .split('')
        .map((char) => char.charCodeAt(0).toString(16))
        .join('');
    }
    console.log(output);
  });

program
  .command('datetime_timestamp [text]')
  .option('-d, --decode', '执行解码')
  .description('日期时间转时间戳/时间戳转日期时间')
  .action((text, options) => {
    let output = '';
    if (options.decode) {
      const timestamp = parseInt(text);
      output = moment(timestamp * 1000).format('YYYY-MM-DD HH:mm:ss');
    } else {
      const datetimeObj = moment(text, 'YYYY-MM-DD HH:mm:ss');
      if (datetimeObj.isValid()) {
        output = String(Math.floor(datetimeObj.valueOf() / 1000));
      } else {
        output = 'Invalid datetime, valid example: 1970-01-01 08:00:00';
      }
    }
    console.log(output);
  });

program
  .command('unicode_escape [text]')
  .option('-d, --decode', '执行解码')
  .description('Unicode 转义序列编码/解码')
  .action((text, options) => {
    let output = '';
    if (options.decode) {
      output = he.decode(text);
    } else {
      output = he.encode(text);
    }
    console.log(output);
  });

program
  .command('uri [text]')
  .option('-d, --decode', '执行解码')
  .description('URL 编码/解码')
  .action((text, options) => {
    let output = '';
    if (options.decode) {
      output = querystring.unescape(text);
    } else {
      output = querystring.escape(text);
    }
    console.log(output);
  });

program
  .command('uri_component [text]')
  .option('-d, --decode', '执行解码')
  .description('URL 组件编码/解码')
  .action((text, options) => {
    let output = '';
    if (options.decode) {
      output = querystring.unescape(text);
    } else {
      output = querystring.escape(text).replace('/', '%2F');
    }
    console.log(output);
  });

program
  .command('html_escape [text]')
  .option('-d, --decode', '执行解码')
  .description('HTML 转义编码/解码')
  .action((text, options) => {
    let output = '';
    if (options.decode) {
      output = he.decode(text);
    } else {
      output = he.encode(text);
    }
    console.log(output);
  });

program.parse(process.argv);
