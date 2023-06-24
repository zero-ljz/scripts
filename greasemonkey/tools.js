// ==UserScript==
// @name         全局工具箱
// @namespace    http://iapp.run
// @version      1.0
// @description  Tools Menu：添加一个菜单按钮到网页左侧，里面有很多小工具
// @author       zero-ljz
// @license MIT
// @match        *://*/*
// @grant        GM_registerMenuCommand
// @grant        GM_xmlhttpRequest
// ==/UserScript==

(function () {
  "use strict";

  var menuItems = [
    { name: "显示/隐藏按钮", action: toggleButton },
    {
      name: "输出调试信息",
      action: function () {
        // 获取当前活动元素
        var activeElement = document.activeElement;
        // 获取页面中的选中文本内容
        var selectedText = window.getSelection().toString();

        console.log("Selected Text:", selectedText);
        console.log("activeElement tagName:", activeElement.tagName);

        // 获取剪贴板的文本
        navigator.clipboard
          .readText()
          .then(function (text) {
            // 打印剪贴板的内容
            console.log("ClipboardText:", text);
          })
          .catch(function (error) {
            console.error("Error reading clipboard:", error);
          });

        console.log(
          "location.href: " +
            window.document.location.href +
            "\nlocation.host: " +
            window.document.location.host +
            "\nlocation.pathname: " +
            window.document.location.pathname +
            "\nlocation.search: " +
            window.document.location.search +
            "\nreferrer: " +
            window.document.referrer +
            "\ntitle: " +
            window.document.title +
            "\ncharacterSet: " +
            window.document.characterSet +
            "\ncontentType: " +
            window.document.contentType +
            "\ndoctype: " +
            window.document.doctype +
            "\nreadyState: " +
            window.document.readyState +
            "\nlastModified: " +
            window.document.lastModified
        );
      }
    },
    {
      name: "屏蔽焦点元素",
      action: function () {
        // document.activeElement.style.pointerEvents = "none";
        // document.activeElement.style.opacity = "0.5";
        document.activeElement.style.display = "none";
      }
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
      }
    },
    {
      name: "执行JS表达式并显示结果",
      action: function () {
        let q = window.getSelection().toString();
        if (!q) q = prompt("你没有选中任何文本，请输入：", "");
        if (q != null) alert(eval(q));
      }
    },
    {
      name: "显示密码框的密码",
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
      }
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
      }
    },

    {
      name: "谷歌翻译页面",
      action: function () {
        location.href =
          "https://translate.google.com/translate?sl=auto&tl=zh-CN&u=" +
          encodeURIComponent(location.href);
      }
    },

    {
      name: "有道翻译页面",
      action: function () {
        location.href =
          "http://webtrans.yodao.com/webTransPc/index.html#/?from=auto&to=auto&type=1&url=" +
          encodeURIComponent(location.href);
      }
    },

    {
      name: "谷歌翻译文本",
      action: function () {
        let q = window.getSelection().toString();
        if (q == "") {
          q = prompt("你没有选中任何文本，请输入", "");
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
            }
          });
        }
      }
    },

    {
      name: "谷歌页面快照",
      action: function () {
        document.location.href =
          "http://www.google.com/search?q=cache:" +
          escape(document.location.href);
      }
    },
    {
      name: "谷歌新牛津词典",
      action: function () {
        let q = window.getSelection().toString();
        if (!q) q = prompt("你没有选中任何文本，请输入：", "");
        if (q != null)
          window.open(
            "https://www.google.com/search?q=define:" + encodeURIComponent(q),
            "new",
            "location=no, toolbar=no"
          );
      }
    },
    {
      name: "谷歌搜中文",
      action: function () {
        let q = window.getSelection().toString();
        if (!q) q = prompt("你没有选中任何文本，请输入：", "");
        if (q != null)
          window.open(
            "https://www.google.com/search?lr=lang_zh-CN&q=" +
              encodeURIComponent(q).replace(/ /g, "+")
          );
      }
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
      }
    },

    {
      name: "维基百科",
      action: function () {
        let q = window.getSelection().toString();
        if (!q) q = prompt("你没有选中任何文本，请输入：", "");
        if (q != null)
          window.open("https://zh.wikipedia.org/wiki/" + encodeURIComponent(q));
      }
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
      }
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
      }
    },
    {
      name: "网页标注（按住alt）",
      action: function () {
        !(function () {
          fetch("https://unpkg.com/spacingjs").then(async (res) =>
            eval(await res.text())
          );
        })();
      }
    },
    {
      name: "生成二维码",
      action: function () {
        let q = window.getSelection().toString();
        if (!q) q = prompt("你没有选中任何文本，请输入", "");
        if (q != null)
          window.open(
            "https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=" +
              encodeURIComponent(q),
            "new",
            "location=no, toolbar=no"
          );
      }
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
      }
    },
    {
      name: "页面存档",
      action: function () {
        document.location.href =
          "http://web.archive.org/" + escape(document.location.href);
      }
    },
    {
      name: "朗读文本",
      action: function () {
        let q = window.getSelection().toString();
        if (!q)
          q = prompt(
            "You didn%27t select any text.  Enter a search phrase:",
            ""
          );
        if (q != null)
          window.speechSynthesis.speak(new window.SpeechSynthesisUtterance(q));
      }
    },
    { name: "2", action: function () {} },
    { name: "3", action: function () {} }
  ];

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
`;

  // 创建菜单项
  menuItems.forEach(function (item) {
    var menuItem = document.createElement("div");
    menuItem.innerHTML = item.name;
    menuItem.style.cursor = "pointer";
    menuItem.style.marginBottom = "5px";

    menuItem.addEventListener("mousedown", function (event) {
      event.preventDefault(); // 阻止获取焦点
      item.action();
      menuContainer.style.display = "none";
    });

    menuContainer.appendChild(menuItem);
  });

  // 创建按钮
  var button = document.createElement("button");
  button.innerHTML = "〓";
  Object.assign(button.style, {
    padding: "5px",
    backgroundColor: "grey",
    color: "white",
    position: "fixed",
    top: "10%",
    left: "10px"
  });

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

  // 全局变量，用于跟踪按钮的显示状态
  var isButtonVisible = true;

  // 切换按钮的显示状态
  function toggleButton() {
    if (isButtonVisible) {
      button.style.display = "none";
    } else {
      button.style.display = "block";
    }
    isButtonVisible = !isButtonVisible;
  }
})();
