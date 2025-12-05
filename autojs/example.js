/**
 * ============================================================
 * Hamibot 脚本编写指南
 * ============================================================
 */

// ---------------- 1. 初始化与配置 ----------------

// [必选] 检查无障碍服务
// 脚本启动前必须调用。如果无障碍服务未开启，会跳转到设置页面让用户开启。
auto.waitFor(); 

// [配置] 设定屏幕分辨率 (推荐)
// 如果脚本中包含具体的坐标点击 (click(x,y))，必须设置开发时的分辨率，
// 这样在不同手机上运行时，Auto.js 会自动缩放坐标，防止点歪。
// setScreenMetrics(1080, 2400); 

// 定义全局变量
// 应用包名，用于定位 ID
let packageName = "com.tencent.mm";
// 示例：每次任务要传入的参数
let argsList = [
    { "name": "好友A" },
    { "name": "好友B" }
];

// ---------------- 2. 主流程控制 ----------------

// 这里的双层循环用于持续监控和执行任务
for (let i = 0; i < 99999; i++) { // 外层死循环，让脚本一直运行
    
    // 遍历所有店铺
    for (let args of argsList) {
        // 调用封装好的业务逻辑函数
        main(args);
        // [等待] 每次循环后休息1秒，避免操作过快被检测或手机卡顿
        sleep(1000); 
    }
    
    // 一轮全部跑完后，长休眠20秒
    sleep(20000);
}

// ---------------- 3. 业务逻辑函数 ----------------

function main(obj) {
    // === 步骤一：查找控件并点击 (基础用法) ===
    
    // [链式调用] 查找控件：
    // id(): 指定资源ID
    // className(): 指定控件类型 (TextView, ImageView等)
    uiselector = id(packageName + ":id/tab_item_name").className("android.widget.TextView")

    // text(): 指定精确文本
    uiselector = uiselector.text("我的");
    // textMatches(/(管理员|创建者)/): 使用正则表达式匹配文本
    uiselector = uiselector.textMatches(/(管理员|创建者)/);
    // textContains(): 包含某文本即可，比 text() 更宽松
    uiselector = uiselector.textContains("管理员");
    
    // waitFor(): 专门用于等待控件出现。如果没出现会一直卡在这里，直到出现。
    uiselector.waitFor();
    // findOne(): 执行查找，阻塞直到找到1个控件为止 (也可以设置超时 findOne(2000))
    widget = uiselector.findOne();  
    // 获取控件的 bounds (坐标范围)，传入自定义点击函数
    click_(widget.bounds());


    // === 步骤三：滚动查找 (常用模式) ===
    
    // 先找到列表容器，用于确定滑动的区域
    let item_listWidget = id(packageName + ":id/item_list")
        .className("androidx.recyclerview.widget.RecyclerView")
        .findOne();

    // 定义目标控件的选择器 (注意：这里还没开始找，只是定义特征)
    // textContains(): 包含某文本即可，比 text() 更宽松
    let targetSelector = id(packageName + ":id/account_name_tv")
        .className("android.widget.TextView")
        .textContains(storeName);

    // [逻辑] 循环滚动直到找到目标
    // .exists() 用于判断当前屏幕上是否存在该控件，返回 true/false，不会阻塞
    while (!targetSelector.exists()) { 
        // swipe(x1, y1, x2, y2, duration)
        // 从列表中心向下滑动 (模拟手指上滑，内容往下走)
        // bounds().centerX() 获取控件中心X坐标
        swipe(
            item_listWidget.bounds().centerX(), 
            item_listWidget.bounds().centerY(), 
            item_listWidget.bounds().centerX(), 
            item_listWidget.bounds().centerY() - 1250, // Y轴向上减小，代表手指向上滑
            500 // 滑动耗时500毫秒
        );
        // 每次滑动后必须再次检查目标是否出现
        // 注意：这里重新赋值是为了刷新检测状态，虽然在 Auto.js Pro/Hamibot 中 selector 可复用，但逻辑上这样写更清晰
        targetSelector = id(packageName + ":id/account_name_tv")
            .className("android.widget.TextView")
            .textContains(storeName); 
    }
    
    // 循环结束后，说明 exists() 为真，执行点击
    widget = targetSelector.findOne();
    click_(widget.bounds());


    // === 步骤四：特殊查找算法 ===
    
    // selector().algorithm('BFS'): 使用广度优先搜索算法查找控件
    // 在复杂布局中，有时默认算法找不到，切换 BFS 可能有效
    widget = selector().text('综合排序').algorithm('BFS').findOne();
    click_(widget.bounds());

    // === 步骤五：处理弹窗 (健壮性处理) ===
    
    // 场景：点击后可能会有成功提示框，需要关闭
    let closeBtnSelector = id(packageName + ":id/ic_colse").className("android.widget.ImageView");
    
    // waitFor(): 专门用于等待控件出现。如果没出现会一直卡在这里，直到出现。
    // 相比 findOne()，waitFor() 没有返回值，只是单纯的"等"。
    closeBtnSelector.waitFor(); 
    
    widget = closeBtnSelector.findOne();
    click_(widget.bounds());

    // === 步骤六：根据层级查找 ===
    
    // depth(20): 限制查找深度。有时页面有多个相同 ID 的列表，通过深度区分。
    let rv_listWidget = id(packageName + ":id/rv_list")
        .className("androidx.recyclerview.widget.RecyclerView")
        .depth(20)
        .findOne();  
    // 简单的滑动操作
    swipe(
        rv_listWidget.bounds().centerX(), 
        rv_listWidget.bounds().centerY(), 
        rv_listWidget.bounds().centerX(), 
        rv_listWidget.bounds().centerY()-1250, 
        500
    );
    sleep(2000);
}

// ---------------- 4. 工具/辅助函数 ----------------

/**
 * 封装的点击函数：点击控件中心点
 * 
 * 为什么不直接用 widget.click()?
 * 1. 很多控件 (如 TextView) 的 clickable 属性为 false，直接调用 widget.click() 无效。
 * 2. click(x, y) 模拟的是手指触摸屏幕，只要算出坐标就能点，成功率更高（前提是控件在屏幕内）。
 * 
 * @param {Rect} rect - 控件的 bounds() 对象
 */
function click_(rect) {
    // 算法：左边距 + (宽度的一半) = 中心 X
    let x = rect.left + ((rect.right - rect.left) / 2);
    // 算法：上边距 + (高度的一半) = 中心 Y
    let y = rect.top + ((rect.bottom - rect.top) / 2);
    
    click(x, y); // 执行全局坐标点击
    sleep(1000); // 每次点击后默认等待1秒，防止操作过快
}

/**
 * 封装的延时函数
 */
function sleep_(s) {
    sleep(s + 2500); // 在传入时间基础上额外增加2.5秒
}

/**
 * 模拟密码键盘点击 (纯坐标流)
 * 注意：这种写法极度依赖屏幕分辨率。如果换手机，坐标大概率会歪。
 * 建议配合 setScreenMetrics 使用。
 */
function pressNum(n) {
    // 定义基准点
    const baseX = 180;
    const baseY = 1800;
    const w = 350; // 宽间距
    const h = 150; // 高间距

    // 建立 0-9 的位置映射 [列, 行]
    // 比如 1是[0,0], 2是[1,0]... 0是[1,3]
    const map = {
        1: [0, 0], 2: [1, 0], 3: [2, 0],
        4: [0, 1], 5: [1, 1], 6: [2, 1],
        7: [0, 2], 8: [1, 2], 9: [2, 2],
        0: [1, 3]
    };

    let [col, row] = map[n];
    
    // 计算并点击
    click_(baseX + col * w, baseY + row * h);
    sleep(120);
}