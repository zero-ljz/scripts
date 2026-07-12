// ==UserScript==
// @name         清除当前网站缓存和数据
// @namespace    local.clear-site-data
// @version      1.1.0
// @description  清除当前网站的缓存、存储、Cookie、IndexedDB 和 Service Worker
// @match        http://*/*
// @match        https://*/*
// @grant        GM_registerMenuCommand
// @grant        GM_setValue
// @grant        GM_getValue
// @grant        GM_deleteValue
// @grant        GM_notification
// @run-at       document-start
// ==/UserScript==

(function () {
    'use strict';

    const CACHE_BUSTER = '__tm_fresh_visit__';
    const RESULT_KEY = `clear-site-result:${location.origin}`;

    removeCacheBuster();
    showPreviousResult();

    GM_registerMenuCommand(
        '清除当前网站缓存和数据',
        clearCurrentSiteData
    );

    async function clearCurrentSiteData() {
        const results = [];

        async function runTask(name, callback) {
            try {
                const detail = await callback();

                results.push({
                    项目: name,
                    状态: '完成',
                    详情: detail || ''
                });
            } catch (error) {
                results.push({
                    项目: name,
                    状态: '失败',
                    详情: error?.message || String(error)
                });
            }
        }

        await runTask('注销 Service Worker', unregisterServiceWorkers);
        await runTask('清除 Cache Storage', clearCacheStorage);
        await runTask('清除 IndexedDB', clearIndexedDB);
        await runTask('清除 localStorage', clearLocalStorage);
        await runTask('清除 sessionStorage', clearSessionStorage);
        await runTask('清除 Cookie Store', clearCookieStore);
        await runTask('清除普通 Cookie', clearDocumentCookies);
        await runTask('清除文件系统存储', clearOriginPrivateFileSystem);

        /*
         * GM_setValue 使用的是油猴扩展自身的存储空间，
         * 不属于当前网站，因此不会被网站数据清理影响。
         */
        await GM_setValue(RESULT_KEY, {
            origin: location.origin,
            time: new Date().toLocaleString(),
            results
        });

        reloadWithoutCache();
    }

    async function showPreviousResult() {
        const saved = await GM_getValue(RESULT_KEY, null);

        if (!saved || saved.origin !== location.origin) {
            return;
        }

        await GM_deleteValue(RESULT_KEY);

        console.group(
            `%c当前网站数据已清除：${saved.time}`,
            'font-weight: bold'
        );
        console.table(saved.results);
        console.groupEnd();

        const failedCount = saved.results.filter(
            item => item.状态 === '失败'
        ).length;

        GM_notification({
            title: '网站缓存和数据清理完成',
            text: failedCount
                ? `已重新加载，${failedCount} 个清理项目失败，详情请查看控制台`
                : '已清理并重新加载，详细结果可在控制台中查看',
            timeout: 5000
        });
    }

    async function unregisterServiceWorkers() {
        if (!('serviceWorker' in navigator)) {
            return '当前浏览器不支持';
        }

        const registrations =
            await navigator.serviceWorker.getRegistrations();

        const results = await Promise.allSettled(
            registrations.map(registration =>
                registration.unregister()
            )
        );

        const successCount = results.filter(
            result => result.status === 'fulfilled' && result.value
        ).length;

        return `发现 ${registrations.length} 个，成功注销 ${successCount} 个`;
    }

    async function clearCacheStorage() {
        if (!('caches' in window)) {
            return '当前浏览器不支持';
        }

        const names = await caches.keys();

        const results = await Promise.allSettled(
            names.map(name => caches.delete(name))
        );

        const successCount = results.filter(
            result => result.status === 'fulfilled' && result.value
        ).length;

        return `发现 ${names.length} 个，成功删除 ${successCount} 个`;
    }

    async function clearIndexedDB() {
        if (!('indexedDB' in window)) {
            return '当前浏览器不支持';
        }

        if (typeof indexedDB.databases !== 'function') {
            return '当前浏览器不支持枚举 IndexedDB';
        }

        const databases = await indexedDB.databases();

        const names = databases
            .map(database => database.name)
            .filter(Boolean);

        const results = await Promise.all(
            names.map(deleteIndexedDBDatabase)
        );

        const deletedCount = results.filter(
            result => result === 'success'
        ).length;

        const blockedCount = results.filter(
            result => result === 'blocked'
        ).length;

        return (
            `发现 ${names.length} 个，成功删除 ${deletedCount} 个` +
            (blockedCount ? `，${blockedCount} 个被连接占用` : '')
        );
    }

    function deleteIndexedDBDatabase(name) {
        return new Promise(resolve => {
            let finished = false;

            const finish = result => {
                if (finished) {
                    return;
                }

                finished = true;
                resolve(result);
            };

            const request = indexedDB.deleteDatabase(name);

            request.onsuccess = () => finish('success');
            request.onerror = () => finish('error');

            request.onblocked = () => {
                setTimeout(() => finish('blocked'), 1000);
            };

            setTimeout(() => finish('timeout'), 3000);
        });
    }

    function clearLocalStorage() {
        const count = localStorage.length;
        localStorage.clear();

        return `删除 ${count} 项`;
    }

    function clearSessionStorage() {
        const count = sessionStorage.length;
        sessionStorage.clear();

        return `删除 ${count} 项`;
    }

    async function clearCookieStore() {
        if (!('cookieStore' in window)) {
            return '当前浏览器不支持';
        }

        const cookies = await cookieStore.getAll();

        const results = await Promise.allSettled(
            cookies.map(cookie => {
                const options = {
                    name: cookie.name,
                    path: cookie.path || '/'
                };

                if (cookie.domain) {
                    options.domain = cookie.domain;
                }

                return cookieStore.delete(options);
            })
        );

        const successCount = results.filter(
            result => result.status === 'fulfilled'
        ).length;

        return `发现 ${cookies.length} 个，处理 ${successCount} 个`;
    }

    function clearDocumentCookies() {
        const names = document.cookie
            .split(';')
            .map(item => item.split('=')[0].trim())
            .filter(Boolean);

        const paths = getPossibleCookiePaths();
        const domains = getPossibleCookieDomains();

        for (const name of names) {
            for (const path of paths) {
                expireCookie(name, path);

                for (const domain of domains) {
                    expireCookie(name, path, domain);
                }
            }
        }

        return `处理 ${names.length} 个 JavaScript 可访问 Cookie`;
    }

    function expireCookie(name, path, domain = '') {
        const domainPart = domain
            ? `; Domain=${domain}`
            : '';

        document.cookie =
            `${name}=; ` +
            'Expires=Thu, 01 Jan 1970 00:00:00 GMT; ' +
            'Max-Age=0; ' +
            `Path=${path}` +
            domainPart +
            '; SameSite=Lax';
    }

    function getPossibleCookiePaths() {
        const paths = new Set(['/']);
        const segments = location.pathname
            .split('/')
            .filter(Boolean);

        let currentPath = '';

        for (const segment of segments) {
            currentPath += `/${segment}`;
            paths.add(currentPath);
            paths.add(`${currentPath}/`);
        }

        return [...paths];
    }

    function getPossibleCookieDomains() {
        const hostname = location.hostname;
        const domains = new Set([hostname, `.${hostname}`]);

        if (
            hostname === 'localhost' ||
            /^[\d.]+$/.test(hostname) ||
            hostname.includes(':')
        ) {
            return [...domains];
        }

        const parts = hostname.split('.');

        for (let index = 1; index < parts.length - 1; index++) {
            const domain = parts.slice(index).join('.');

            domains.add(domain);
            domains.add(`.${domain}`);
        }

        return [...domains];
    }

    async function clearOriginPrivateFileSystem() {
        if (
            !navigator.storage ||
            typeof navigator.storage.getDirectory !== 'function'
        ) {
            return '当前浏览器不支持';
        }

        const root = await navigator.storage.getDirectory();
        const names = [];

        for await (const [name] of root.entries()) {
            names.push(name);
        }

        await Promise.allSettled(
            names.map(name =>
                root.removeEntry(name, {
                    recursive: true
                })
            )
        );

        return `删除 ${names.length} 个项目`;
    }

    function reloadWithoutCache() {
        const url = new URL(location.href);

        url.searchParams.set(
            CACHE_BUSTER,
            `${Date.now()}-${Math.random().toString(36).slice(2)}`
        );

        location.replace(url.href);
    }

    function removeCacheBuster() {
        const url = new URL(location.href);

        if (!url.searchParams.has(CACHE_BUSTER)) {
            return;
        }

        url.searchParams.delete(CACHE_BUSTER);

        queueMicrotask(() => {
            history.replaceState(
                history.state,
                '',
                `${url.pathname}${url.search}${url.hash}`
            );
        });
    }
})();