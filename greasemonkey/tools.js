// ==UserScript==
// @name         全局工具箱
// @namespace    http://iapp.run
// @version      0.1
// @description  添加一个按钮到每个网页左上方的位置，点击后显示工具箱的菜单
// @author       zero-ljz
// @homepage     https://github.com/zero-ljz/scripts/blob/main/greasemonkey/tools.js
// @license MIT
// @match        *://*/*
// @grant        GM_registerMenuCommand
// @grant        GM_info
// @grant        GM_xmlhttpRequest
// @require      https://openuserjs.org/src/libs/sizzle/GM_config.js
// @grant        GM_getValue
// @grant        GM_setValue
// @grant        GM.getValue
// @grant        GM.setValue
// ==/UserScript==

(function () {
  "use strict";

  var menuItems = [
    { name: "临时隐藏按钮", action: toggleButton },
    {
      name: "打开脚本设置",
      action: function () {
        gmc.open();
      },
    },
    {
      name: "打开脚本主页",
      action: function () {
        location.href =
          "https://greasyfork.org/zh-CN/scripts/469339-" +
          encodeURIComponent(GM_info.script.name);
      },
    },

    {
      name: "打印调试信息",
      action: function () {
        console.log(`
          script.name: ${GM_info.script.name}
          script.version: ${GM_info.script.name} ${GM_info.script.version}
          script.description: ${GM_info.script.description}
          script.homepage: ${GM_info.script.homepage}
          script.author: ${GM_info.script.author}

          activeElement: ${document.activeElement}
          activeElement tagName: ${document.activeElement.tagName}
          activeElement type: ${document.activeElement.type}
          activeElement value: ${document.activeElement.value}
          activeElement name: ${document.activeElement.name}
          activeElement id: ${document.activeElement.id}
          activeElement className: ${document.activeElement.className}

          selectedText: ${window.getSelection().toString()}

          URL: ${window.document.URL}
          location.href: ${window.document.location.href}
          location.host: ${window.document.location.host}
          location.pathname: ${window.document.location.pathname}
          location.search: ${window.document.location.search}
          referrer: ${window.document.referrer}
          title: ${window.document.title}
          characterSet: ${window.document.characterSet}
          contentType: ${window.document.contentType}
          doctype: ${window.document.doctype}
          readyState: ${window.document.readyState}
          lastModified: ${window.document.lastModified}
        `);
      },
    },
    {
      name: "屏蔽焦点元素",
      action: function () {
        // document.activeElement.style.pointerEvents = "none";
        // document.activeElement.style.opacity = "0.5";
        document.activeElement.style.display = "none";
      },
    },
    {
      name: "倒计时刷新",
      action: function () {
        const q = prompt("输入毫秒数：");
        if (q !== null) {
          setTimeout(() => {
            location.reload();
          }, parseInt(q));
        }
      },
    },
    {
      name: "执行JS表达式",
      action: function () {
        let q = window.getSelection().toString();
        if (!q) q = prompt("你没有选中任何文本，请输入：", "alert()");
        if (q != null) eval(q);
      },
    },
    {
      name: "显示密码框",
      action: function () {
        /*window.top.document.activeElement.type = "text"; */ !(function () {
          for (
            var t = document.getElementsByTagName("input"), e = 0;
            e < t.length;
            e++
          )
            "password" === t[e].getAttribute("type") &&
              t[e].setAttribute("type", "text");
        })();
      },
    },
    {
      name: "解除网页限制",
      action: function () {
        !(function () {
          function t(e) {
            e.stopPropagation(),
              e.stopImmediatePropagation && e.stopImmediatePropagation();
          }
          document.querySelectorAll("*").forEach((e) => {
            "none" ===
              window
                .getComputedStyle(e, null)
                .getPropertyValue("user-select") &&
              e.style.setProperty("user-select", "text", "important");
          }),
            [
              "copy",
              "cut",
              "contextmenu",
              "selectstart",
              "mousedown",
              "mouseup",
              "mousemove",
              "keydown",
              "keypress",
              "keyup",
            ].forEach(function (e) {
              document.documentElement.addEventListener(e, t, { capture: !0 });
            }),
            alert("解除限制成功啦！");
        })();
      },
    },
    {
      name: "正则查找文本",
      action: function () {
        (function () {
          var count = 0,
            text,
            regexp;
          text = prompt("Search regexp:", "");
          if (text == null || text.length == 0) return;
          try {
            regexp = new RegExp("(" + text + ")", "i");
          } catch (er) {
            alert(
              "Unable to create regular expression using text '" +
                text +
                "'.\n\n" +
                er
            );
            return;
          }
          function searchWithinNode(node, re) {
            var pos, skip, spannode, middlebit, endbit, middleclone;
            skip = 0;
            if (node.nodeType == 3) {
              pos = node.data.search(re);
              if (pos >= 0) {
                spannode = document.createElement("SPAN");
                spannode.style.backgroundColor = "yellow";
                middlebit = node.splitText(pos);
                endbit = middlebit.splitText(RegExp.$1.length);
                middleclone = middlebit.cloneNode(true);
                spannode.appendChild(middleclone);
                middlebit.parentNode.replaceChild(spannode, middlebit);
                ++count;
                skip = 1;
              }
            } else if (
              node.nodeType == 1 &&
              node.childNodes &&
              node.tagName.toUpperCase() != "SCRIPT" &&
              node.tagName.toUpperCase != "STYLE"
            ) {
              for (var child = 0; child < node.childNodes.length; ++child) {
                child = child + searchWithinNode(node.childNodes[child], re);
              }
            }
            return skip;
          }
          window.status = "Searching for " + regexp + "...";
          searchWithinNode(document.body, regexp);
          window.status =
            "Found " +
            count +
            " match" +
            (count == 1 ? "" : "es") +
            " for " +
            regexp +
            ".";
        })();
      },
    },

    {
      name: "自由编辑页面",
      action: function () {
        !(function () {
          "true" === document.body.getAttribute("contenteditable")
            ? (document.body.setAttribute("contenteditable", !1),
              alert("网页不能编辑啦！"))
            : (document.body.setAttribute("contenteditable", !0),
              alert("网页可以编辑啦！"));
        })();
      },
    },

    {
      name: "谷歌翻译页面",
      action: function () {
        location.href =
          "https://translate.google.com/translate?sl=auto&tl=zh-CN&u=" +
          encodeURIComponent(location.href);
      },
    },

    {
      name: "有道翻译页面",
      action: function () {
        location.href =
          "http://webtrans.yodao.com/webTransPc/index.html#/?from=auto&to=auto&type=1&url=" +
          encodeURIComponent(location.href);
      },
    },
    {
      name: "有道词典",
      action: function () {
        let q = window.getSelection().toString();
        if (q == "") {
          q = prompt("你没有选中任何文本，请输入：", "");
        }
        if (q != null)
          window.open(
            "http://dict.youdao.com/w/eng/" + encodeURIComponent(q),
            "new",
            "location=no, toolbar=no"
          );
      },
    },
    {
      name: "谷歌翻译文本",
      action: function () {
        let q = window.getSelection().toString();
        if (q == "") {
          q = prompt("你没有选中任何文本，请输入：", "");
        }
        if (q != null) {
          // 发送翻译请求
          GM_xmlhttpRequest({
            method: "GET",
            url:
              "http://translate.google.com/translate_a/single?client=gtx&dt=t&dj=1&ie=UTF-8&sl=auto&tl=zh&q=" +
              encodeURIComponent(q),
            //data: JSON.stringify({ content: pageContent }),
            //headers: {
            //    'Content-Type': 'application/json'
            //},
            onload: function (response) {
              // 获取翻译结果
              const obj = JSON.parse(response.responseText);
              let res = "";
              for (const [key, value] of Object.entries(obj.sentences)) {
                res += value.trans + "\r\n";
              }
              alert(res);
            },
          });
        }
      },
    },

    {
      name: "谷歌页面快照",
      action: function () {
        document.location.href =
          "http://www.google.com/search?q=cache:" +
          escape(document.location.href);
      },
    },
    {
      name: "谷歌牛津词典",
      action: function () {
        let q = window.getSelection().toString();
        if (!q) q = prompt("你没有选中任何文本，请输入：", "");
        if (q != null)
          window.open(
            "https://www.google.com/search?q=define:" + encodeURIComponent(q),
            "new",
            "location=no, toolbar=no"
          );
      },
    },
    {
      name: "谷歌搜索中文",
      action: function () {
        let q = window.getSelection().toString();
        if (!q) q = prompt("你没有选中任何文本，请输入：", "");
        if (q != null)
          window.open(
            "https://www.google.com/search?lr=lang_zh-CN&q=" +
              encodeURIComponent(q).replace(/ /g, "+")
          );
      },
    },

    {
      name: "百度搜索",
      action: function () {
        let q = window.getSelection().toString();
        if (!q) q = prompt("你没有选中任何文本，请输入：", "");
        if (q != null)
          window.open(
            "http://www.baidu.com/s?wd=" +
              encodeURIComponent(q).replace(/ /g, "+")
          );
      },
    },

    {
      name: "维基百科",
      action: function () {
        let q = window.getSelection().toString();
        if (!q) q = prompt("你没有选中任何文本，请输入：", "");
        if (q != null)
          window.open("https://zh.wikipedia.org/wiki/" + encodeURIComponent(q));
      },
    },

    {
      name: "谷歌站点搜索",
      action: function () {
        let q = window.getSelection().toString();
        if (!q) q = prompt("你没有选中任何文本，请输入：", "");
        if (q != null)
          location = (
            "http://www.google.com/search?num=100&q=site:" +
            encodeURIComponent(location.hostname) +
            ' "' +
            encodeURIComponent(q.replace(/\"/g, "")) +
            '"'
          ).replace(/ /g, "+");
      },
    },

    {
      name: "DeepL翻译",
      action: function () {
        let q = window.getSelection().toString();
        if (!q) q = prompt("你没有选中任何文本，请输入：", "");
        if (q != null)
          window.open(
            "https://www.deepl.com/translator#en/zh/" + encodeURIComponent(q),
            "new",
            "location=no, toolbar=no"
          );
      },
    },
    {
      name: "网页标注",
      action: function () {
        !(function () {
          fetch("https://unpkg.com/spacingjs").then(async (res) =>
            eval(await res.text())
          );
        })();
        alert("按住Alt即可使用");
      },
    },
    {
      name: "生成二维码",
      action: function () {
        let q = window.getSelection().toString();
        if (!q) q = prompt("你没有选中任何文本，请输入：", "");
        if (q != null)
          window.open(
            "https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=" +
              encodeURIComponent(q),
            "new",
            "location=no, toolbar=no"
          );
      },
    },
    {
      name: "站点替代品",
      action: function () {
        window.open(
          "https://www.similarweb.com/zh-tw/website/" +
            window.location.host +
            "/competitors/",
          "new",
          "location=no, toolbar=no"
        );
      },
    },
    {
      name: "页面存档",
      action: function () {
        document.location.href =
          "http://web.archive.org/" + escape(document.location.href);
      },
    },
    {
      name: "朗读文本",
      action: function () {
        let q = window.getSelection().toString();
        if (!q) q = prompt("你没有选中任何文本，请输入：", "");
        if (q != null)
          window.speechSynthesis.speak(new window.SpeechSynthesisUtterance(q));
      },
    },
    { name: "菜单项1", action: function () {} },
    { name: "菜单项2", action: function () {} },
  ];

  let default_values = {
    btn_top: "15%",
    btn_left: "10px",
    show_button: true,
    btn_text: "◯",
  };

  // 创建脚本设置页面实例
  let gmc = new GM_config({
    id: "MyConfig", // The id used for this instance of GM_config
    title: "脚本设置", // Panel Title
    // Fields object
    fields: {
      btn_top: {
        label: "按钮水平坐标",
        type: "text",
        default: default_values.btn_top,
      },
      btn_left: {
        label: "按钮垂直坐标",
        type: "text",
        default: default_values.btn_left,
      },
      show_button: {
        label: "显示按钮",
        type: "checkbox",
        default: default_values.show_button,
      },
      btn_text: {
        label: "按钮文字",
        type: "select",
        options: ["◯", "🌎", "🌏", "🟢", "🔵", "💧", "🍀", "❄", "〓", "╳"],
        default: default_values.btn_text,
      },
    },
    events: {
      init: function () {
        // runs after initialization completes
        // override saved value
        //this.set('Name', 'Mike Medley');
        // open frame
        //this.open();
      },
      save: function () {
        // Save each setting to GM_setValue
        for (var key in this.fields) {
          if (this.fields.hasOwnProperty(key)) {
            var value = this.get(key);
            GM_setValue(key, value);
          }
        }

        this.close();
      },
    },
  });

  // 注册菜单项
  menuItems.forEach(function (item) {
    GM_registerMenuCommand(item.name, item.action);
  });

  // 创建菜单容器
  var menuContainer = document.createElement("div");
  menuContainer.style.cssText = `
  position: fixed;
  padding: 10px;
  background-color: white;
  border: 1px solid black;
  z-index: 9999;
  display: none;
  border-radius: 7px;

  box-shadow: inset 1px 1px rgb(255 255 255 / 20%), inset -1px -1px rgb(255 255 255 / 10%), 1px 3px 24px -1px rgb(0 0 0 / 15%);
  background-color: transparent;
  background-image: linear-gradient(125deg, rgba(255, 255, 255, 0.3), rgba(255, 255, 255, 0.2) 70%);
  -webkit-backdrop-filter: blur(5px);
  backdrop-filter: blur(5px);
`;

  // 创建菜单项
  menuItems.forEach(function (item) {
    var menuItem = document.createElement("div");
    menuItem.innerHTML = item.name;
    menuItem.style.cursor = "pointer";
    menuItem.style.marginBottom = "5px";
    menuItem.style.fontSize = "16px";
    menuItem.style.lineHeight = "1.2";
    menuItem.style.color = "grey";
    menuItem.style.textAlign = "left";

    menuItem.addEventListener("mouseenter", function () {
      menuItem.style.color = "blue"; // 在鼠标悬停时
    });

    menuItem.addEventListener("mouseleave", function () {
      menuItem.style.color = "grey"; // 在鼠标离开时
    });

    menuItem.addEventListener("mousedown", function (event) {
      event.preventDefault(); // 阻止获取焦点
      item.action();
      menuContainer.style.display = "none";
    });

    menuContainer.appendChild(menuItem);
  });

  // 创建按钮
  var button = document.createElement("button");
  button.innerHTML = GM_getValue("btn_text", default_values.btn_text);

  Object.assign(button.style, {
    padding: "5px",
    backgroundColor: "grey",
    borderRadius: "0.5rem",
    border: "0",
    color: "white",
    position: "fixed",
    top: GM_getValue("btn_top", default_values.btn_top),
    left: GM_getValue("btn_left", default_values.btn_left),
  });
  button.style.display = GM_getValue("show_button", default_values.show_button) ? "block" : "none";

  // 添加按钮点击事件
  button.addEventListener("mousedown", function (event) {
    event.preventDefault(); // 阻止获取焦点
    if (menuContainer.style.display === "none") {
      // 获取按钮的相对位置
      var buttonRect = button.getBoundingClientRect();

      // 设置菜单容器的位置
      menuContainer.style.top = buttonRect.top + "px";
      menuContainer.style.left = buttonRect.left + buttonRect.width + 5 + "px";

      menuContainer.style.display = "block";
    } else {
      menuContainer.style.display = "none";
    }
  });

  // 将菜单容器和按钮添加到页面上
  document.body.appendChild(menuContainer);
  document.body.appendChild(button);

  // 切换按钮的显示状态
  function toggleButton() {
    if (button.style.display === "block") {
      button.style.display = "none";
    } else {
      button.style.display = "block";
    }
  }
})();
