// ==UserScript==
// @name         全局工具箱
// @namespace    http://iapp.run
// @version      2.0.0
// @description  全能网页工具箱：翻译、搜索、去除限制、提取图片、夜间模式等。支持悬浮球拖拽与现代化UI。
// @author       zero-ljz
// @homepage     https://github.com/zero-ljz/scripts/blob/main/greasemonkey/tools.js
// @match        *://*/*
// @grant        GM_registerMenuCommand
// @grant        GM_info
// @grant        GM_xmlhttpRequest
// @grant        GM_getValue
// @grant        GM_setValue
// @grant        GM_addStyle
// @grant        GM_setClipboard
// @grant        GM_openInTab
// @require      https://openuserjs.org/src/libs/sizzle/GM_config.js
// @require      https://cdnjs.cloudflare.com/ajax/libs/qrcode/1.4.4/qrcode.min.js
// @license      MIT
// ==/UserScript==

(function () {
    "use strict";

    // --- 0. Trusted Types 策略 (修复 Strict CSP 报错) ---
    const policy = window.trustedTypes?.createPolicy?.('gm-toolbox-policy', {
        createHTML: (string) => string,
    }) || { createHTML: (string) => string };

    // 封装一个安全的 innerHTML 赋值函数
    const setHTML = (element, html) => {
        element.innerHTML = policy.createHTML(html);
    };


    //Config
    const CONSTANTS = {
        Z_INDEX: 2147483647,
        THEME_COLOR: '#007AFF', // iOS Blue
        GLASS_BG: 'rgba(255, 255, 255, 0.75)',
        GLASS_BG_DARK: 'rgba(30, 30, 30, 0.85)',
        ANIMATION_SPEED: '0.25s'
    };

    // 运行时状态
    const STATE = {
        isDarkMode: false,
        isEyeProtect: false
    };

    // --- 1. 样式系统 (CSS) ---
    GM_addStyle(`
        /* === 样式隔离与重置 (核心修复) === */
        /* 强制重置面板内所有元素的盒模型和基础属性 */
        #gm-toolbox-panel, #gm-toolbox-panel * {
            box-sizing: border-box !important;
            font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", Helvetica, sans-serif !important;
            line-height: 1.5 !important;
        }

        /* 悬浮球 */
        #gm-float-btn {
            position: fixed;
            width: 44px !important;
            height: 44px !important;
            border-radius: 50% !important;
            background: ${CONSTANTS.GLASS_BG_DARK};
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px);
            box-shadow: 0 4px 15px rgba(0,0,0,0.2);
            z-index: ${CONSTANTS.Z_INDEX};
            cursor: move;
            display: flex !important;
            align-items: center !important;
            justify-content: center !important;
            color: white !important;
            font-size: 20px !important;
            user-select: none;
            transition: transform 0.1s, background ${CONSTANTS.ANIMATION_SPEED};
            border: 1px solid rgba(255,255,255,0.1) !important;
            margin: 0 !important;
            padding: 0 !important;
            box-sizing: border-box !important;
        }
        #gm-float-btn:hover { transform: scale(1.1); background: #000; }
        #gm-float-btn:active { transform: scale(0.95); }

        /* 主菜单面板 */
        #gm-toolbox-panel {
            position: fixed;
            display: none;
            width: 340px !important;
            max-height: 80vh !important;
            overflow-y: auto !important;
            background: ${CONSTANTS.GLASS_BG_DARK};
            backdrop-filter: blur(16px);
            -webkit-backdrop-filter: blur(16px);
            border-radius: 16px !important;
            box-shadow: 0 10px 40px rgba(0,0,0,0.4) !important;
            z-index: ${CONSTANTS.Z_INDEX};
            padding: 16px !important;
            color: #fff !important;
            border: 1px solid rgba(255,255,255,0.08) !important;
            opacity: 0;
            transform: scale(0.95);
            transition: opacity ${CONSTANTS.ANIMATION_SPEED}, transform ${CONSTANTS.ANIMATION_SPEED};
            /* 强制重置文本对齐 */
            text-align: left !important;
            letter-spacing: normal !important;
        }
        #gm-toolbox-panel.show { opacity: 1; transform: scale(1); }

        /* 滚动条隐藏但可滚动 */
        #gm-toolbox-panel::-webkit-scrollbar { width: 4px; }
        #gm-toolbox-panel::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.2); border-radius: 2px; }

        /* 分类标题 */
        .gm-category-title {
            font-size: 12px !important;
            color: rgba(255,255,255,0.5) !important;
            margin: 12px 0 8px 4px !important;
            padding: 0 !important;
            font-weight: 700 !important;
            text-transform: uppercase;
            letter-spacing: 1px !important;
            line-height: 1.2 !important;
            border: none !important;
        }
        .gm-category-title:first-child { margin-top: 0 !important; }

        /* 网格布局 */
        .gm-grid {
            display: grid !important;
            grid-template-columns: repeat(2, 1fr) !important;
            gap: 8px !important;
            border: none !important;
            margin: 0 !important;
            padding: 0 !important;
        }

        /* 功能按钮 - 深度重置 */
        .gm-tool-btn {
            background: rgba(255,255,255,0.05) !important;
            border: none !important;
            color: #eee !important;
            padding: 10px 12px !important;
            margin: 0 !important; /* 核心：防止网页给button加margin */
            width: 100% !important; /* 核心：强制填满网格 */
            height: auto !important;
            min-height: 40px !important; /* 核心：防止高度塌陷 */
            border-radius: 8px !important;
            cursor: pointer;
            font-size: 13px !important;
            text-align: left !important;
            display: flex !important;
            align-items: center !important;
            justify-content: flex-start !important;
            transition: all 0.2s;
            user-select: none;
            outline: none !important;
            box-shadow: none !important;
            /* 覆盖可能存在的伪元素 */
            position: relative !important;
            text-shadow: none !important;
        }
        .gm-tool-btn:hover { background: ${CONSTANTS.THEME_COLOR} !important; color: #fff !important; transform: translateY(-1px); }
        .gm-tool-btn .icon {
            margin-right: 8px !important;
            font-size: 16px !important;
            line-height: 1 !important;
            display: inline-block !important;
            width: auto !important;
            font-weight: normal !important;
        }

         /* 开关指示点 */
        .gm-dot {
            width: 6px; height: 6px; border-radius: 50%;
            background: #ccc; margin-left: auto;
        }
        .gm-tool-btn.active .gm-dot { background: #34C759; box-shadow: 0 0 5px #34C759; }

        /* Toast 提示框 */
        #gm-toast {
            position: fixed;
            top: 20px;
            left: 50%;
            transform: translateX(-50%) translateY(-100%);
            background: rgba(0,0,0,0.85);
            color: #fff;
            padding: 10px 20px !important;
            border-radius: 50px !important;
            z-index: ${CONSTANTS.Z_INDEX + 10};
            font-size: 14px !important;
            opacity: 0;
            transition: all 0.3s cubic-bezier(0.68, -0.55, 0.27, 1.55);
            pointer-events: none;
            backdrop-filter: blur(5px);
            white-space: pre-wrap;
            text-align: center;
            max-width: 80vw;
            box-shadow: 0 5px 15px rgba(0,0,0,0.3) !important;
            border: 1px solid rgba(255,255,255,0.1) !important;
        }
        #gm-toast.show { transform: translateX(-50%) translateY(0); opacity: 1; }

        /* 结果展示弹窗 */
        #gm-result-modal {
            position: fixed;
            top: 50%; left: 50%;
            transform: translate(-50%, -50%);
            width: 500px !important;
            max-width: 90vw !important;
            background: #fff !important;
            color: #333 !important;
            border-radius: 12px !important;
            padding: 20px !important;
            z-index: ${CONSTANTS.Z_INDEX + 20};
            box-shadow: 0 20px 60px rgba(0,0,0,0.3) !important;
            display: none;
            flex-direction: column !important;
            text-align: left !important;
        }
        #gm-result-header { display: flex !important; justify-content: space-between !important; align-items: center !important; margin-bottom: 15px !important; border-bottom: 1px solid #eee !important; padding-bottom: 10px !important; }
        #gm-result-title { font-weight: bold !important; font-size: 16px !important; color: #000 !important; }
        #gm-result-close { cursor: pointer; padding: 5px; font-weight: bold; color: #999; font-family: sans-serif !important; }
        #gm-result-content { max-height: 60vh !important; overflow-y: auto !important; white-space: pre-wrap !important; font-family: monospace !important; line-height: 1.5 !important; font-size: 14px !important; background: #f9f9f9 !important; padding: 10px !important; border-radius: 6px !important; color: #333 !important; border: 1px solid #eee !important; }
        #gm-result-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: ${CONSTANTS.Z_INDEX + 15}; display: none; backdrop-filter: blur(2px); }
    `);

    // --- 2. 辅助函数 (Utils) - 已修复 TrustedHTML 问题 ---
    const Utils = {
        getSelection: () => {
            const text = window.getSelection().toString().trim();
            return text.length > 0 ? text : null;
        },
        prompt: (msg, defaultVal = "") => {
            return prompt(msg, defaultVal);
        },
        toast: (msg, duration = 3000) => {
            const toast = document.getElementById('gm-toast');
            toast.textContent = msg; // 纯文本用 textContent 很安全
            toast.classList.add('show');
            clearTimeout(toast.timer);
            toast.timer = setTimeout(() => toast.classList.remove('show'), duration);
        },
        modal: (title, content) => {
            const modal = document.getElementById('gm-result-modal');
            const overlay = document.getElementById('gm-result-overlay');
            const contentBox = document.getElementById('gm-result-content');

            document.getElementById('gm-result-title').textContent = title;

            // 智能判断：如果是字符串，使用安全HTML设置；如果是DOM元素，直接追加
            if (typeof content === 'string') {
                setHTML(contentBox, content);
            } else if (content instanceof Node) {
                contentBox.innerHTML = ''; // 清空
                contentBox.appendChild(content);
            }

            modal.style.display = 'flex';
            overlay.style.display = 'block';
        },
        copy: (text) => {
            try {
                GM_setClipboard(text);
                Utils.toast('✅ 已复制到剪贴板');
            } catch (e) {
                navigator.clipboard.writeText(text).then(() => Utils.toast('✅ 已复制'));
            }
        }
    };

    // --- 3. 功能定义 (保留所有原有功能) ---
    // 为了更好的UI，我们给功能加了图标和分类
    const TOOLS = {
        "常用工具": [
            {
                name: "朗读文本", icon: "🗣️",
                action: () => {
                    let q = Utils.getSelection() || Utils.prompt("请输入朗读文本：");
                    if (q) window.speechSynthesis.speak(new window.SpeechSynthesisUtterance(q));
                }
            },
            {
                name: "生成二维码", icon: "📱",
                action: () => {
                    let q = Utils.getSelection() || window.location.href;
                    if (!q) return;

                    // 1. 创建 UI 容器
                    const wrapper = document.createElement('div');
                    wrapper.style.cssText = "display:flex; flex-direction:column; align-items:center; justify-content:center; padding:10px;";

                    const codeContainer = document.createElement('div');
                    // 使用 flex 居中
                    codeContainer.style.cssText = "background:white; padding:15px; border-radius:8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); display: flex; justify-content: center; align-items: center;";
                    wrapper.appendChild(codeContainer);

                    const textTip = document.createElement('div');
                    textTip.style.cssText = "text-align:center; font-size:12px; color:#999; margin-top:10px; word-break:break-all; max-width:250px; line-height: 1.4;";
                    textTip.textContent = q.length > 100 ? q.substring(0, 100) + '...' : q;
                    wrapper.appendChild(textTip);

                    // 2. 显示模态框
                    Utils.modal("📱 二维码生成", wrapper);

                    // 3. 延时调用库生成 (确保库已加载)
                    setTimeout(() => {
                        // node-qrcode 库加载后会暴露全局变量 QRCode
                        if (typeof QRCode !== 'undefined' && QRCode.toCanvas) {
                            // 创建 Canvas 元素
                            const canvas = document.createElement('canvas');
                            codeContainer.appendChild(canvas);

                            // 调用库绘制
                            // 优点：自动处理UTF-8中文，自动选择版本(不会overflow)
                            QRCode.toCanvas(canvas, q, {
                                width: 256,        // 宽度
                                margin: 0,         // 边距 (我们在外层容器控制了padding，这里设0)
                                color: {
                                    dark: '#000000',  // 前景色
                                    light: '#ffffff'  // 背景色
                                },
                                errorCorrectionLevel: 'M' // 中等容错率，平衡容量和清晰度
                            }, function (error) {
                                if (error) {
                                    console.error(error);
                                    codeContainer.innerHTML = `<span style="color:red">生成失败: ${error.message}</span>`;
                                }
                            });
                        } else {
                            Utils.toast("❌ QRCode库未加载");
                        }
                    }, 50);
                }
            },
            {
                name: "翻译文本", icon: "🌐",
                action: () => {
                    let q = Utils.getSelection() || Utils.prompt("请输入翻译文本：");
                    if (!q) return;
                    GM_xmlhttpRequest({
                        method: "GET",
                        url: "http://translate.google.com/translate_a/single?client=gtx&dt=t&dj=1&ie=UTF-8&sl=auto&tl=zh&q=" + encodeURIComponent(q),
                        onload: function (response) {
                            try {
                                const obj = JSON.parse(response.responseText);
                                let res = obj.sentences.map(s => s.trans).join("");
                                Utils.modal("翻译结果", res);
                            } catch (e) { Utils.toast("翻译解析失败"); }
                        }
                    });
                }
            },
            {
                name: "翻译整页", icon: "🔄",
                action: () => {
                    Utils.toast("⏳ 开始分析并翻译页面，这可能需要一点时间...");

                    // 1. 提取自你提供代码的核心 Google API 逻辑
                    // 使用 GM_xmlhttpRequest 绕过浏览器的 COEP 安全策略
                    const googleTranslateAPI = (text) => {
                        return new Promise((resolve, reject) => {
                            GM_xmlhttpRequest({
                                method: "GET",
                                // 这是你代码中 _Google 类使用的接口 (GTX)
                                url: "https://translate.googleapis.com/translate_a/single?" + new URLSearchParams({
                                    client: "gtx",
                                    dt: "t",
                                    sl: "auto",  // 源语言自动
                                    tl: "zh-CN", // 目标语言中文
                                    q: text
                                }).toString(),
                                onload: function(response) {
                                    try {
                                        const data = JSON.parse(response.responseText);
                                        // 解析逻辑参考了你的代码：result.data[0].map...
                                        if (data && data[0]) {
                                            const result = data[0].map(item => item[0]).join("");
                                            resolve(result);
                                        } else {
                                            resolve(text); // 失败返回原文
                                        }
                                    } catch (e) {
                                        reject(e);
                                    }
                                },
                                onerror: reject
                            });
                        });
                    };

                    // 2. DOM 遍历与批量翻译核心
                    // 这是一个简化的 DOM 遍历器，只翻译可见的文本节点
                    async function translatePage() {
                        // 获取所有非空、可见的文本节点
                        const walker = document.createTreeWalker(
                            document.body,
                            NodeFilter.SHOW_TEXT,
                            {
                                acceptNode: function(node) {
                                    // 过滤掉脚本、样式、空文本
                                    const tag = node.parentElement.tagName;
                                    if (["SCRIPT", "STYLE", "NOSCRIPT", "CODE", "PRE"].includes(tag)) return NodeFilter.FILTER_REJECT;
                                    if (node.textContent.trim().length === 0) return NodeFilter.FILTER_REJECT;
                                    return NodeFilter.FILTER_ACCEPT;
                                }
                            }
                        );

                        const textNodes = [];
                        let node;
                        while (node = walker.nextNode()) {
                            textNodes.push(node);
                        }

                        Utils.toast(`🔍 发现 ${textNodes.length} 个文本段落，开始翻译...`);

                        // 3. 批量处理 (为了防止请求过快被封，每次处理一小批)
                        const BATCH_SIZE = 10; // 并发数
                        let completed = 0;

                        // 简单的队列处理
                        for (let i = 0; i < textNodes.length; i += BATCH_SIZE) {
                            const batch = textNodes.slice(i, i + BATCH_SIZE);
                            const promises = batch.map(async (textNode) => {
                                try {
                                    const originalText = textNode.textContent.trim();
                                    // 只有纯英文/非中文才翻译 (简单判断)
                                    if (!/[\u4e00-\u9fa5]/.test(originalText) && originalText.length > 2) {
                                        const translated = await googleTranslateAPI(originalText);
                                        if (translated && translated !== originalText) {
                                            textNode.textContent = translated;
                                            // 标记一下颜色，让人知道这里被翻译了
                                            if(textNode.parentElement) textNode.parentElement.style.backgroundColor = "rgba(255, 255, 0, 0.1)";
                                        }
                                    }
                                } catch (e) {
                                    console.error("翻译片段失败", e);
                                }
                            });

                            await Promise.all(promises);
                            completed += batch.length;

                            // 每完成50个节点提示一下进度
                            if (i % 50 === 0) {
                                Utils.toast(`正在翻译... ${Math.min(100, Math.round(completed / textNodes.length * 100))}%`);
                            }
                        }

                        Utils.toast("✅ 页面翻译完成");
                    }

                    translatePage();
                }
            },
            
           
        ],
        "搜索增强": [
            {
                name: "谷歌搜索", icon: "🔍",
                action: () => {
                    let q = Utils.getSelection() || Utils.prompt("请输入搜索内容：");
                    if (q) window.open("https://www.google.com/search?q=" + encodeURIComponent(q).replace(/ /g, "+"));
                }
            },
            {
                name: "谷歌搜中文", icon: "🇨🇳",
                action: () => {
                    let q = Utils.getSelection() || Utils.prompt("搜中文：");
                    if (q) window.open("https://www.google.com/search?lr=lang_zh-CN&q=" + encodeURIComponent(q).replace(/ /g, "+"));
                }
            },
            {
                name: "谷歌搜本站", icon: "🏢",
                action: () => {
                    let q = Utils.getSelection() || Utils.prompt("站内搜：");
                    if (q) location.href = "http://www.google.com/search?num=100&q=site:" + encodeURIComponent(location.hostname) + ' "' + encodeURIComponent(q.replace(/\"/g, "")) + '"';
                }
            },
            {
                name: "维基百科", icon: "📖",
                action: () => {
                    let q = Utils.getSelection() || Utils.prompt("搜维基：");
                    if (q) window.open("https://zh.wikipedia.org/wiki/" + encodeURIComponent(q));
                }
            },
            
            {
                name: "谷歌词典", icon: "📕",
                action: () => {
                    let q = Utils.getSelection() || Utils.prompt("查词：");
                    if (q) window.open("https://www.google.com/search?q=define:" + encodeURIComponent(q), "new", "width=800,height=600");
                }
            },
            {
                name: "有道词典", icon: "📗",
                action: () => {
                    let q = Utils.getSelection() || Utils.prompt("查词：");
                    if (q) window.open("http://dict.youdao.com/w/eng/" + encodeURIComponent(q), "new", "width=800,height=600");
                }
            }
        ],
        "网页与浏览": [
            
            {
                name: "翻译页面(谷歌)", icon: "🇬",
                action: () => location.href = "https://translate.google.com/translate?sl=auto&tl=zh-CN&u=" + encodeURIComponent(location.href)
            },
            {
                name: "翻译页面(有道)", icon: "🇾",
                action: () => location.href = "http://webtrans.yodao.com/webTransPc/index.html#/?from=auto&to=auto&type=1&url=" + encodeURIComponent(location.href)
            },
            {
                name: "页面快照(Cache)", icon: "📸",
                action: () => location.href = "http://www.google.com/search?q=cache:" + encodeURIComponent(document.location.href)
            },
            {
                name: "网页时光机", icon: "🕰️",
                action: () => location.href = "http://web.archive.org/" + encodeURIComponent(document.location.href)
            },
            {
                name: "类似网站(Global)", icon: "🔗",
                action: () => window.open("https://www.similarweb.com/zh-tw/website/" + window.location.host + "/competitors/")
            },
            {
                name: "类似网站(Similar)", icon: "🔗",
                action: () => {
                    const domain = window.location.hostname.split(".").slice(-2).join(".");
                    window.open("https://www.similarsites.com/site/" + domain);
                }
            },
            {
                name: "类似网站(SiteLike)", icon: "🔗",
                action: () => window.open("https://www.sitelike.org/similar/" + window.location.host + "")
            }
        ],
        "黑客与开发": [
            {
                name: "解除限制", icon: "🔓",
                action: () => {
                    // 增强版解除限制
                    const events = ["copy", "cut", "contextmenu", "selectstart", "mousedown", "mouseup", "mousemove", "keydown", "keypress", "keyup"];
                    events.forEach(e => document.documentElement.addEventListener(e, evt => { evt.stopPropagation(); }, { capture: true }));
                    const style = document.createElement('style');
                    style.innerHTML = `* { user-select: text !important; -webkit-user-select: text !important; }`;
                    document.body.appendChild(style);
                    Utils.toast("🔓 已尝试解除右键和复制限制");
                }
            },
            {
                name: "显示密码", icon: "👀",
                action: () => {
                    document.querySelectorAll("input[type='password']").forEach(el => el.type = "text");
                    Utils.toast("👀 密码已明文显示");
                }
            },
            {
                name: "图片提取", icon: "🖼️",
                action: () => {
                    const imgs = Array.from(document.querySelectorAll('img'))
                        .map(img => ({ src: img.src || img.dataset.src, w: img.naturalWidth, h: img.naturalHeight }))
                        .filter(i => i.src && i.w > 50 && i.h > 50); // 过滤小图

                    if (imgs.length === 0) return Utils.toast("⚠️ 未找到有效图片");

                    const div = document.createElement('div');
                    div.className = 'gm-img-grid';
                    imgs.forEach(img => {
                        const item = document.createElement('div');
                        item.className = 'gm-img-item';
                        item.title = "点击复制链接，按住Ctrl点击下载";
                        setHTML(item, `<img src="${img.src}"><div class="gm-img-size">${img.w}x${img.h}</div>`);

                        item.onclick = (e) => {
                            if (e.ctrlKey) {
                                const a = document.createElement('a');
                                a.href = img.src;
                                a.download = 'image.png';
                                a.click();
                            } else {
                                Utils.copy(img.src);
                            }
                        };
                        div.appendChild(item);
                    });

                    const info = document.createElement('p');
                    info.style.marginBottom = '10px';
                    info.textContent = `共找到 ${imgs.length} 张图片 (点击复制URL / Ctrl+点击下载)`;

                    const wrapper = document.createElement('div');
                    wrapper.appendChild(info);
                    wrapper.appendChild(div);
                    Utils.modal("图片提取器", wrapper);
                }
            },
            {
                name: "屏幕取色", icon: "🎨",
                action: async () => {
                    if (!window.EyeDropper) return Utils.toast("⚠️ 您的浏览器不支持取色 API (需 Chrome 95+)");
                    try {
                        const ed = new window.EyeDropper();
                        const result = await ed.open();
                        Utils.copy(result.sRGBHex);
                        Utils.toast(`🎨 颜色 ${result.sRGBHex} 已复制`);
                    } catch (e) {
                        if(!e.toString().includes('canceled')) Utils.toast("❌ 取色失败");
                    }
                }
            },
            {
                name: "护眼模式", icon: "👁️",
                action: (btn) => {
                    STATE.isEyeProtect = !STATE.isEyeProtect;
                    let mask = document.getElementById('gm-eye-protect');
                    if (!mask) {
                        mask = document.createElement('div');
                        mask.id = 'gm-eye-protect';
                        mask.style.cssText = "position:fixed;top:0;left:0;width:100vw;height:100vh;background:rgba(255, 240, 0, 0.15);mix-blend-mode:multiply;pointer-events:none;z-index:2147483647;display:none;";
                        document.body.appendChild(mask);
                    }
                    mask.style.display = STATE.isEyeProtect ? 'block' : 'none';
                    btn.classList.toggle('active', STATE.isEyeProtect);
                    Utils.toast(STATE.isEyeProtect ? "✅ 护眼模式已开启" : "🚫 护眼模式已关闭");
                },
                hasDot: true
            },
            {
                name: "暗黑模式", icon: "🌙",
                action: (btn) => {
                    STATE.isDarkMode = !STATE.isDarkMode;
                    let style = document.getElementById('gm-dark-mode-style');
                    if (!style) {
                        style = document.createElement('style');
                        style.id = 'gm-dark-mode-style';
                        style.innerHTML = `html { filter: invert(1) hue-rotate(180deg) !important; } img, video, iframe { filter: invert(1) hue-rotate(180deg) !important; }`;
                        document.head.appendChild(style);
                        style.disabled = true;
                    }
                    style.disabled = !STATE.isDarkMode;
                    btn.classList.toggle('active', STATE.isDarkMode);
                    Utils.toast(STATE.isDarkMode ? "🌙 智能夜间模式已开启" : "☀️ 已恢复日间模式");
                },
                hasDot: true
            },
            {
                name: "编辑网页", icon: "✏️",
                action: () => {
                    const isEditable = document.body.contentEditable === 'true';
                    document.body.contentEditable = !isEditable;
                    document.designMode = !isEditable ? 'on' : 'off';
                    Utils.toast(isEditable ? "🔒 已关闭编辑模式" : "✏️ 网页可随意编辑");
                }
            },
            {
                name: "屏蔽元素", icon: "🚫",
                action: () => {
                    Utils.toast("请点击要屏蔽的元素 (按ESC取消)");
                    const handler = (e) => {
                        e.preventDefault();
                        e.stopPropagation();
                        e.target.style.display = 'none';
                        document.removeEventListener('click', handler, true);
                        Utils.toast("🚫 元素已隐藏");
                    };
                    document.addEventListener('click', handler, true);
                }
            },

            {
                name: "网页标注(Spacing)", icon: "📏",
                action: () => {
                    // 使用动态导入，不阻塞主线程
                    const script = document.createElement('script');
                    script.src = "https://unpkg.com/spacingjs";
                    document.body.appendChild(script);
                    Utils.toast("📏 按住 Alt 键查看元素间距");
                }
            },
            {
                name: "执行JS", icon: "💻",
                action: () => {
                    let q = Utils.getSelection() || Utils.prompt("输入JavaScript代码：", "alert('Hello')");
                    if (q) {
                        try { eval(q); } catch(e) { Utils.modal("Error", e); }
                    }
                }
            },
            {
                name: "调试信息", icon: "🐞",
                action: () => {
                    const info = `
Title: ${document.title}
URL: ${location.href}
UserAgent: ${navigator.userAgent}
Screen: ${screen.width}x${screen.height}
Cookie: ${document.cookie}
LastModified: ${document.lastModified}
                    `.trim();
                    console.log(info);
                    Utils.modal("页面调试信息", info);
                }
            }
        ]
    };

    // --- 4. 配置系统 (GM_config) ---
    // 保留配置项，但简化操作
    const DEFAULT_CONFIG = {
        btn_text: "🛠️",
        init_pos_top: "15%",
        init_pos_left: "10px"
    };

    const gmc = new GM_config({
        id: "ToolboxConfig",
        title: "工具箱设置",
        fields: {
            btn_text: { label: "按钮图标/文字", type: "text", default: DEFAULT_CONFIG.btn_text },
            show_button: { label: "显示悬浮球", type: "checkbox", default: true }
        },
        events: {
            save: () => {
                gmc.close();
                updateButtonState();
            }
        }
    });

    // 额外的设置项：脚本设置
    TOOLS["常用工具"].unshift({
        name: "脚本设置", icon: "⚙️",
        action: () => gmc.open()
    });
    TOOLS["常用工具"].unshift({
        name: "隐藏按钮", icon: "🙈",
        action: () => {
            const btn = document.getElementById('gm-float-btn');
            if(btn) {
              btn.style.setProperty('display', 'none', 'important');
            }
            Utils.toast("按钮已隐藏，请在脚本管理器菜单重新开启或刷新页面");
        }
    });

    // --- 5. UI 构建与事件逻辑 ---

    function createUI() {
        // 1. Toast
        const toast = document.createElement('div');
        toast.id = 'gm-toast';
        document.body.appendChild(toast);

        // 2. Modal
        const overlay = document.createElement('div');
        overlay.id = 'gm-result-overlay';
        const modal = document.createElement('div');
        modal.id = 'gm-result-modal';

        // 使用 setHTML 安全插入结构
        setHTML(modal, `
            <div id="gm-result-header"><span id="gm-result-title">Title</span><span id="gm-result-close">✕</span></div>
            <div id="gm-result-content"></div>
        `);

        document.body.appendChild(overlay);
        document.body.appendChild(modal);

        const closeFn = () => { modal.style.display = 'none'; overlay.style.display = 'none'; };
        document.getElementById('gm-result-close').onclick = closeFn;
        overlay.onclick = closeFn;

        // 3. Float Button
        const btn = document.createElement('div');
        btn.id = 'gm-float-btn';
        // 使用 setHTML
        setHTML(btn, gmc.get('btn_text'));

        const savedTop = GM_getValue('pos_top', DEFAULT_CONFIG.init_pos_top);
        const savedLeft = GM_getValue('pos_left', DEFAULT_CONFIG.init_pos_left);
        btn.style.top = savedTop;
        btn.style.left = savedLeft;

        if (!gmc.get('show_button')) btn.style.setProperty('display', 'none', 'important');
        document.body.appendChild(btn);

        // 4. Panel
        const panel = document.createElement('div');
        panel.id = 'gm-toolbox-panel';

        for (const [category, items] of Object.entries(TOOLS)) {
            const title = document.createElement('div');
            title.className = 'gm-category-title';
            title.innerText = category;
            panel.appendChild(title);

            const grid = document.createElement('div');
            grid.className = 'gm-grid';

            items.forEach(tool => {
                const b = document.createElement('button');
                b.className = 'gm-tool-btn';
                let html = `<span class="icon">${tool.icon}</span>${tool.name}`;
                if (tool.hasDot) html += `<div class="gm-dot"></div>`;
                // 使用 setHTML
                setHTML(b, html);
                b.onclick = (e) => {
                    e.stopPropagation();
                    // 如果不是切换类功能，点击后自动关闭面板
                    if (!tool.hasDot) togglePanel(false);
                    try { tool.action(b); } catch (err) { console.error(err); Utils.toast("❌ Error: " + err.message); }
                    togglePanel(false);
                };
                grid.appendChild(b);
            });
            panel.appendChild(grid);
        }
        document.body.appendChild(panel);

        // ... (后续的拖拽和事件监听逻辑保持不变，不需要改动) ...
        // ... 请确保原本 createUI 函数后面关于 addEventListener 的代码还保留着 ...
        let isDragging = false;
        let hasMoved = false;
        let startX, startY, initLeft, initTop;

        btn.addEventListener('mousedown', (e) => {
            if (e.button !== 0) return;
            isDragging = true;
            hasMoved = false;
            startX = e.clientX;
            startY = e.clientY;
            const rect = btn.getBoundingClientRect();
            initLeft = rect.left;
            initTop = rect.top;
            btn.style.transition = 'none';
            e.preventDefault();
        });

        window.addEventListener('mousemove', (e) => {
            if (!isDragging) return;
            const dx = e.clientX - startX;
            const dy = e.clientY - startY;
            if (Math.abs(dx) > 3 || Math.abs(dy) > 3) hasMoved = true;
            let newLeft = initLeft + dx;
            let newTop = initTop + dy;
            const maxLeft = window.innerWidth - btn.offsetWidth;
            const maxTop = window.innerHeight - btn.offsetHeight;
            newLeft = Math.max(0, Math.min(newLeft, maxLeft));
            newTop = Math.max(0, Math.min(newTop, maxTop));
            btn.style.left = newLeft + 'px';
            btn.style.top = newTop + 'px';
        });

        window.addEventListener('mouseup', () => {
            if (!isDragging) return;
            isDragging = false;
            btn.style.transition = `transform 0.1s, background ${CONSTANTS.ANIMATION_SPEED}`;
            if (hasMoved) {
                GM_setValue('pos_top', btn.style.top);
                GM_setValue('pos_left', btn.style.left);
            }
        });

        btn.addEventListener('click', () => { if (!hasMoved) togglePanel(); });

        document.addEventListener('click', (e) => {
            if (panel.classList.contains('show') && !panel.contains(e.target) && e.target !== btn && !btn.contains(e.target)) {
                togglePanel(false);
            }
        });

        function togglePanel(forceState) {
            const isVisible = panel.classList.contains('show');
            const shouldShow = forceState !== undefined ? forceState : !isVisible;
            if (shouldShow) {
                const btnRect = btn.getBoundingClientRect();
                const panelWidth = 340;
                const panelHeight = Math.min(window.innerHeight * 0.8, 600);
                let left = btnRect.right + 15;
                let top = btnRect.top;
                if (left + panelWidth > window.innerWidth) left = btnRect.left - panelWidth - 15;
                if (top + panelHeight > window.innerHeight) top = window.innerHeight - panelHeight - 20;
                if (top < 10) top = 10;
                panel.style.left = left + 'px';
                panel.style.top = top + 'px';
                panel.style.display = 'block';
                requestAnimationFrame(() => panel.classList.add('show'));
            } else {
                panel.classList.remove('show');
                setTimeout(() => { if (!panel.classList.contains('show')) panel.style.display = 'none'; }, 300);
            }
        }
    }

    // 更新按钮状态（用于配置保存后）
    function updateButtonState() {
        let btn = document.getElementById('gm-float-btn');
        if(!btn) return;
        btn.innerHTML = gmc.get('btn_text');
        if (gmc.get('show_button')) {
             btn.style.setProperty('display', 'flex', 'important');
        } else {
             btn.style.setProperty('display', 'none', 'important');
        }
    }

    // 注册油猴菜单命令（作为备用入口）
    GM_registerMenuCommand("打开工具箱面板", () => {
        const panel = document.getElementById('gm-toolbox-panel');
        // 如果没有显示按钮，临时显示面板在屏幕中心
        if(!document.getElementById('gm-float-btn').offsetParent) {
             if(panel) {
                 panel.style.top = '100px';
                 panel.style.left = '50%';
                 panel.style.transform = 'translateX(-50%)';
                 panel.style.display = 'block';
                 setTimeout(()=> panel.classList.add('show'), 10);
             }
        } else {
            // 模拟点击按钮
             document.getElementById('gm-float-btn').click();
        }
    });

    GM_registerMenuCommand("打开脚本设置界面", () => {
        gmc.open();
    });

    GM_registerMenuCommand("重置悬浮球位置", () => {
        const btn = document.getElementById('gm-float-btn');
        if(btn) {
            btn.style.top = DEFAULT_CONFIG.init_pos_top;
            btn.style.left = DEFAULT_CONFIG.init_pos_left;
            GM_setValue('pos_top', DEFAULT_CONFIG.init_pos_top);
            GM_setValue('pos_left', DEFAULT_CONFIG.init_pos_left);
            Utils.toast("已重置位置");
        }
    });

    // --- 启动脚本 ---
    // 延迟加载，确保页面主体渲染完成，减少冲突
    setTimeout(createUI, 300);

})();