#!/usr/bin/env node

const { Command } = require('commander');
const crypto = require('crypto');
// Node.js 18+ 自带 fetch，低于 18 请取消下面这行的注释并安装 node-fetch
// const fetch = require('node-fetch'); 

const program = new Command();

// --- 0. 基础辅助函数 (适配 Node.js) ---

// 模拟 request2
async function request2(options) {
    const { url, method = 'GET', headers = {}, body } = options;
    try {
        const response = await fetch(url, {
            method,
            headers,
            body: typeof body === 'object' ? JSON.stringify(body) : body
        });
        
        if (!response.ok) {
            throw new Error(`HTTP Error: ${response.status}`);
        }
        
        return await response.json();
    } catch (e) {
        return new Error(e.message);
    }
}

// 模拟合并 URL
function mergeUrl(baseUrl, relativeUrl) {
    return new URL(relativeUrl, baseUrl).toString();
}

// Crypto 辅助函数 (适配腾讯云签名)
async function sha256(str) {
    return crypto.createHash('sha256').update(str).digest('hex');
}

async function hmacSha256ByString(key, msg) {
    return crypto.createHmac('sha256', key).update(msg).digest(); // 返回 Buffer 用于后续计算
}

async function hmacSha256ByArrayBuffer(key, msg) {
    // key 可能是 Buffer 或 String
    return crypto.createHmac('sha256', key).update(msg).digest();
}

// 基础类
class Translation {
    constructor(serviceConfig, generalConfig) {
        this.serviceConfig = serviceConfig || {};
    }
    async detectLanguage(text) { return 'auto'; } // 简化探测
}

// --- 1. Service: Google (无需 Key) ---
const googleLangMap = new Map([
    ["auto", "auto"], ["zh-CN", "zh-CN"], ["zh-TW", "zh-TW"], ["en", "en"], ["ja", "ja"], ["ko", "ko"], ["fr", "fr"], ["de", "de"], ["ru", "ru"]
]);
const googleLangMapReverse = new Map(Array.from(googleLangMap).map(([k, v]) => [v, k]));

class Google extends Translation {
    constructor(config) {
        super(config);
        this.apiUrl = "https://translate.googleapis.com/translate_a/single";
    }

    async translate(payload) {
        let { text, from, to } = payload;
        let adaptedFrom = googleLangMap.get(from) || "auto";
        let adaptedTo = googleLangMap.get(to) || to;
        
        const params = new URLSearchParams({
            client: "gtx", dt: "t", sl: adaptedFrom, tl: adaptedTo, q: text
        });
        
        const data = await request2({ url: `${this.apiUrl}?${params.toString()}` });
        
        if (data instanceof Error) throw data;
        if (!data[0] || data[0].length <= 0) throw new Error("API Response Error");

        return {
            text: data[0].map((item) => item[0]).filter(Boolean).join(""),
            from: googleLangMapReverse.get(data[2]) || "auto",
            to
        };
    }
}

// --- 2. Service: Tencent (需要 SecretId/SecretKey) ---
const tencentLangMap = new Map([
    ["auto", "auto"], ["zh-CN", "zh"], ["en", "en"], ["ja", "jp"], ["ko", "kr"]
]);
const tencentLangMapReverse = new Map(Array.from(tencentLangMap).map(([k, v]) => [v, k]));

class Tencent extends Translation {
    constructor(config) {
        super(config);
        this.secretId = config.secretId;
        this.secretKey = config.secretKey;
        if (!this.secretId || !this.secretKey) {
            // 稍后在 execute 时会检查，但在实例化允许为空以便显示帮助
        }
    }

    static getUTCDate(dateObj) {
        let year = dateObj.getUTCFullYear();
        let month = `${dateObj.getUTCMonth() + 1}`.padStart(2, "0");
        let date = `${dateObj.getUTCDate()}`.padStart(2, "0");
        return `${year}-${month}-${date}`;
    }

    async signedRequest({ secretId, secretKey, action, payload, service, version }) {
        let host = `${service}.tencentcloudapi.com`;
        let now = new Date();
        let timestamp = Math.floor(now.valueOf() / 1000).toString(); // 腾讯云要求秒级时间戳
        let canonicalRequest = ["POST", "/", "", "content-type:application/json; charset=utf-8", `host:${host}`, "", "content-type;host", await sha256(payload)].join("\n");
        
        let datestamp = Tencent.getUTCDate(now);
        let stringToSign = ["TC3-HMAC-SHA256", timestamp, `${datestamp}/${service}/tc3_request`, await sha256(canonicalRequest)].join("\n");

        let secretDate = await hmacSha256ByString(`TC3${secretKey}`, datestamp); // key, msg
        let secretService = await hmacSha256ByArrayBuffer(secretDate, service);
        let secretSigning = await hmacSha256ByArrayBuffer(secretService, "tc3_request");
        let signature = (await hmacSha256ByArrayBuffer(secretSigning, stringToSign)).toString('hex');

        return request2({
            url: `https://${host}`,
            method: "POST",
            headers: {
                "Content-Type": "application/json; charset=utf-8",
                "Host": host,
                "X-TC-Action": action,
                "X-TC-Timestamp": timestamp,
                "X-TC-Region": "ap-guangzhou",
                "X-TC-Version": version,
                "Authorization": `TC3-HMAC-SHA256 Credential=${secretId}/${datestamp}/${service}/tc3_request, SignedHeaders=content-type;host, Signature=${signature}`
            },
            body: payload
        });
    }

    async translate(payload) {
        if (!this.secretId || !this.secretKey) throw new Error("Tencent Cloud requires --secret-id and --secret-key");
        
        let { text, from, to } = payload;
        let reqPayload = JSON.stringify({
            ProjectId: 0,
            Source: tencentLangMap.get(from) || "auto",
            SourceText: text,
            Target: tencentLangMap.get(to) || to
        });

        let data = await this.signedRequest({
            secretId: this.secretId, secretKey: this.secretKey,
            action: "TextTranslate", payload: reqPayload, service: "tmt", version: "2018-03-21"
        });

        if (data instanceof Error) throw data;
        if (data.Response && data.Response.Error) throw new Error(data.Response.Error.Message);

        return {
            text: data.Response.TargetText,
            from: tencentLangMapReverse.get(data.Response.Source) || from,
            to: tencentLangMapReverse.get(data.Response.Target) || to
        };
    }
}

// --- 3. Service: Transmart (腾讯交互翻译) ---
const transmartLangMap = new Map([["auto", "auto"], ["zh-CN", "zh"], ["en", "en"]]);

class Transmart extends Translation {
    constructor(config) {
        super(config);
        // Node 环境没有 navigator，伪造一个 clientKey
        const fakeUA = "Mozilla/5.0 (Node.js CLI) TransmartClient";
        this.clientKey = Buffer.from("transmart_crx_" + fakeUA).toString('base64').slice(0, 100);
    }

    async translate(payload) {
        let { text, to } = payload;
        let remoteTo = transmartLangMap.get(to) || to;
        
        let reqBody = JSON.stringify({
            header: { fn: "auto_translation_block", client_key: this.clientKey },
            source: { text_block: text, lang: "auto", orig_url: "http://localhost" },
            target: { lang: remoteTo }
        });

        let data = await request2({
            url: "https://transmart.qq.com/api/imt",
            method: "POST",
            body: reqBody
        });

        if (data instanceof Error) throw data;
        if (data.header && data.header.ret_code !== "succ") throw new Error(data.message || data.header.ret_code);

        return { text: data.auto_translation, from: "auto", to };
    }
}

// --- 4. Service: TenAlpha (微信翻译) ---
// 该接口通常用于小程序，可能有Referer限制，Node中尽量模拟
const tenAlphaLangMap = new Map([["auto", "auto"], ["zh-CN", "zh"], ["en", "en"]]);
const tenAlphaLangMapReverse = new Map(Array.from(tenAlphaLangMap).map(([k, v]) => [v, k]));

class TenAlpha extends Translation {
    async translate(payload) {
        let { text, from, to } = payload;
        const params = new URLSearchParams({
            source: tenAlphaLangMap.get(from) || from,
            target: tenAlphaLangMap.get(to) || to,
            sourceText: text,
            platform: "WeChat_APP",
            candidateLangs: "en|zh",
            guid: "cli_user" // 随机固定一个
        });

        const data = await request2({
            url: `https://wxapp.translator.qq.com/api/translate?${params.toString()}`,
            headers: {
                "content-type": "application/json",
                "Host": "wxapp.translator.qq.com",
                "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 16_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 MicroMessenger/8.0.32(0x18002035) NetType/WIFI Language/zh_TW",
                "Referer": "https://servicewechat.com/wxb1070eabc6f9107e/117/page-frame.html"
            }
        });

        if (data instanceof Error) throw data;
        return {
            text: data.targetText,
            from: tenAlphaLangMapReverse.get(data.source) || from,
            to: tenAlphaLangMapReverse.get(data.target) || to
        };
    }
}

// --- 5. Service: DeepL (Hacked RPC) ---
// 注意：DeepL 的 RPC 接口变动频繁且有严格反爬，这段代码可能不稳定
const deepLLangMap = new Map([["auto", "auto"], ["zh-CN", "ZH"], ["en", "EN"], ["ja", "JA"]]);

function generateTimestamp(text) {
    const iCount = (text.match(/i/g) || []).length;
    const ts = Date.now();
    return iCount ? ts + (iCount - ts % iCount) : ts;
}

function stringifyJson(object) {
    let str = JSON.stringify(object);
    // DeepL 特有的 JSON 格式要求，加上空格
    if ((object.id + 3) % 13 === 0 || (object.id + 5) % 29 === 0) {
        return str.replace('"method":"', '"method" : "');
    }
    return str.replace('"method":"', '"method": "');
}

class DeepL extends Translation {
    async translate(payload) {
        let { text, from, to } = payload;
        let sourceLang = deepLLangMap.get(from) || "auto";
        let targetLang = deepLLangMap.get(to) || "EN";
        
        const id = Math.floor(Math.random() * (1e8 - 1e6) + 1e6);
        const postData = {
            id: id,
            jsonrpc: "2.0",
            method: "LMT_handle_texts",
            params: {
                timestamp: generateTimestamp(text),
                texts: [{ text: text, requestAlternatives: 0 }],
                splitting: "newlines",
                lang: { source_lang_user_selected: sourceLang, target_lang: targetLang }
            }
        };

        const data = await request2({
            url: "https://www2.deepl.com/jsonrpc",
            method: "POST",
            body: stringifyJson(postData),
            headers: {
                "Content-Type": "application/json",
                "Referer": "https://www.deepl.com/"
            }
        });

        if (data instanceof Error) throw data;
        if (data.error) throw new Error(JSON.stringify(data.error));

        const resultText = data.result.texts[0].text;
        return { text: resultText, from, to };
    }
}

// --- CLI 配置 ---

program
    .name('translator')
    .description('Node.js command line translation tool using various services')
    .version('1.0.0');

program
    .command('trans')
    .description('Translate text')
    .argument('<text>', 'The text to translate')
    .option('-e, --engine <engine>', 'Translation engine: google, tencent, transmart, tenalpha, deepl', 'google')
    .option('-f, --from <lang>', 'Source language code (e.g., en, zh-CN)', 'auto')
    .option('-t, --to <lang>', 'Target language code (e.g., zh-CN, en)', 'zh-CN')
    // 腾讯云专用参数
    .option('--secret-id <id>', 'Tencent Cloud SecretId')
    .option('--secret-key <key>', 'Tencent Cloud SecretKey')
    .action(async (text, options) => {
        let engine;
        const config = {
            secretId: options.secretId || process.env.TENCENT_SECRET_ID,
            secretKey: options.secretKey || process.env.TENCENT_SECRET_KEY
        };

        switch (options.engine.toLowerCase()) {
            case 'google':
                engine = new Google(config);
                break;
            case 'tencent':
                engine = new Tencent(config);
                break;
            case 'transmart':
                engine = new Transmart(config);
                break;
            case 'tenalpha':
                engine = new TenAlpha(config);
                break;
            case 'deepl':
                engine = new DeepL(config);
                break;
            default:
                console.error(`❌ Unknown engine: ${options.engine}`);
                process.exit(1);
        }

        try {
            console.log(`\nUsing Engine: \x1b[36m${options.engine}\x1b[0m | ${options.from} -> ${options.to}`);
            console.log(`Original: ${text}`);
            console.log('Translating...');
            
            const result = await engine.translate({
                text: text,
                from: options.from,
                to: options.to
            });

            console.log(`\n\x1b[32mResult:\x1b[0m ${result.text}`);
            // console.log(`(Raw info: ${result.from} -> ${result.to})`);
        } catch (err) {
            console.error(`\n\x1b[31mError:\x1b[0m ${err.message}`);
            if (options.engine === 'tencent' && err.message.includes('requires')) {
                console.log('Hint: Use --secret-id and --secret-key for Tencent Cloud.');
            }
        }
    });

program.parse();