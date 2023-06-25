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
// @grant        GM_addStyle
// ==/UserScript==

(function () {
  "use strict";

  // 添加毛玻璃框的 CSS 类
  GM_addStyle(`
    .glass-box {
      all: initial;
      transform: translateX(-50%);
      padding: 10px;
      background: rgba(255, 255, 255, 0.8);
      border-radius: 10px;
      box-shadow: 0 2px 5px rgba(0, 0, 0, 0.3);
      backdrop-filter: blur(10px);
    }
  `);

  // 创建消息框元素
  function createMessageBox(message) {
    var messageBox = document.createElement("div");
    messageBox.classList.add("glass-box");

    messageBox.style.position = "fixed";
    messageBox.style.top = "20px"; // 将消息框的位置移到屏幕的上方
    messageBox.style.left = "50%";
    messageBox.style.zIndex = "9999";
    messageBox.style.minWidth = "200px"; // 设置最小宽度
    messageBox.style.minHeight = "100px"; // 设置最小高度

    var messageText = document.createElement("span");
    messageText.textContent = message.replace(/\n/g, "\r\n"); // 替换换行符为回车换行
    messageText.style.whiteSpace = "pre-line"; // 设置样式以支持换行
    messageText.style.color = "blue"; // 设置固定的文字颜色
    messageBox.appendChild(messageText);

    var closeButton = document.createElement("button");
    closeButton.textContent = "关闭";
    closeButton.style.marginLeft = "10px";
    closeButton.style.position = "absolute";
    closeButton.style.bottom = "10px";
    closeButton.style.right = "10px";
    closeButton.addEventListener("click", function () {
      messageBox.style.display = "none";
    });
    messageBox.appendChild(closeButton);

    document.body.appendChild(messageBox);

    return messageBox;
  }

  // 显示消息框
  function showMessage(message, duration) {
    var messageBox = createMessageBox(message);
    setTimeout(function () {
      messageBox.style.display = "none";
    }, duration);
  }

  var menuItems = [
    {
      name: "test",
      action: function () {
        showMessage(
          `这是一
        个自
        定fsd
        义消息框！`,
          2000
        );
      },
    },
    { name: "隐藏按钮", action: toggleButton },
    {
      name: "脚本设置",
      action: function () {
        gmc.open();
      },
    },

    {
      name: "调试信息",
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
      name: "屏蔽元素",
      action: function () {
        let selection = window.getSelection();
        if (selection.toString()) {
          var range = selection.getRangeAt(0); // 获取范围内的节点

          // 递归遍历节点，查找最近的元素节点
          function findClosestElement(node) {
            if (node.nodeType === Node.ELEMENT_NODE) {
              return node; // 当前节点是元素节点，返回
            } else if (node.parentNode) {
              return findClosestElement(node.parentNode); // 继续向上查找父节点
            } else {
              return null; // 未找到包含文本的元素节点
            }
          }

          // 查找包含所选文本的最近的元素节点
          findClosestElement(range.commonAncestorContainer).style.display =
            "none";
        } else {
          document.activeElement.style.display = "none";
        }
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

    {
      name: "显示密码",
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
      name: "执行JS代码",
      action: function () {
        let q = window.getSelection().toString();
        if (!q) q = prompt("你没有选中任何文本，请输入：", "alert()");
        if (q != null) eval(q);
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
      name: "自由编辑网页",
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
      name: "翻译页面-谷歌",
      action: function () {
        location.href =
          "https://translate.google.com/translate?sl=auto&tl=zh-CN&u=" +
          encodeURIComponent(location.href);
      },
    },

    {
      name: "翻译页面-有道",
      action: function () {
        location.href =
          "http://webtrans.yodao.com/webTransPc/index.html#/?from=auto&to=auto&type=1&url=" +
          encodeURIComponent(location.href);
      },
    },

    {
      name: "翻译-谷歌",
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
              showMessage(res, 5000);
            },
          });
        }
      },
    },
    {
      name: "词典-谷歌",
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
      name: "词典-有道",
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
      name: "搜索-谷歌搜本站",
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
      name: "搜索-谷歌搜中文",
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
      name: "搜索-百度",
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
      name: "搜索-维基百科",
      action: function () {
        let q = window.getSelection().toString();
        if (!q) q = prompt("你没有选中任何文本，请输入：", "");
        if (q != null)
          window.open("https://zh.wikipedia.org/wiki/" + encodeURIComponent(q));
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
      name: "谷歌页面快照",
      action: function () {
        document.location.href =
          "http://www.google.com/search?q=cache:" +
          encodeURIComponent(document.location.href);
      },
    },
    {
      name: "类似网站",
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
      name: "网页存档",
      action: function () {
        document.location.href =
          "http://web.archive.org/" +
          encodeURIComponent(document.location.href);
      },
    },
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
  z-index: 9999;
  display: none;
  max-height: 80%; /* 设置最大高度为父元素高度的50% */
  overflow-y: auto; /* 显示滚动条，仅在内容溢出时显示 */
  
  /* background-color: white; */
  border: 1px solid white; 
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
    menuItem.style.color = "#ADADAD";
    menuItem.style.textAlign = "left";

    menuItem.addEventListener("mouseenter", function () {
      menuItem.style.color = "blue"; // 在鼠标悬停时
    });

    menuItem.addEventListener("mouseleave", function () {
      menuItem.style.color = "#ADADAD"; // 在鼠标离开时
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
  button.style.display = GM_getValue("show_button", default_values.show_button)
    ? "block"
    : "none";

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
