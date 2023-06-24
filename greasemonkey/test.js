// ==UserScript==
// @name         New Userscript
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  try to take over the world!
// @author       You
// @match        *://*/*
// @grant        GM_registerMenuCommand
// ==/UserScript==

(function () {
  "use strict";

  var menuItems = [
    {
      name: "菜单1",
      action: function () {
        alert("菜单2");
      },
    },
    {
      name: "菜单2",
      action: function () {
        alert("菜单2");
      },
    },
    {
        name: "菜单3",
        action: function () {
          alert("菜单2");
        },
      },
      {
        name: "菜单4",
        action: function () {
          alert("菜单2");
        },
      },
      {
        name: "菜单5",
        action: function () {
          alert("菜单2");
        },
      },
      {
        name: "菜单6",
        action: function () {
          alert("菜单2");
        },
      },
      {
        name: "菜单7",
        action: function () {
          alert("菜单2");
        },
      },
      {
        name: "菜单8",
        action: function () {
          alert("菜单2");
        },
      },
      {
        name: "菜单9",
        action: function () {
          alert("菜单2");
        },
      },
      
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
      item.action();
      menuContainer.style.display = "none";
    });

    menuContainer.appendChild(menuItem);
  });

  // 创建按钮
  var button = document.createElement("button");
  button.innerHTML = "菜单";

  Object.assign(button.style, {
    padding: "5px",
    backgroundColor: "grey",
    borderRadius: "0.5rem",
    border: "0",
    color: "white",
    position: "fixed",
    top: "10%",
    left: "10%",
  });


  // 添加按钮点击事件
  button.addEventListener("mousedown", function (event) {
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
})();
