# -*- coding: utf-8 -*-
"""
WeRoBot Lean Architecture Template (SME Platinum Edition)
Author: Senior Python Architect
Date: 2025-12-05
Description:
    专为中小型项目打造的高内聚、低耦合单文件架构。
    集成了配置管理、业务分层、CLI运维工具、健康检查与性能监控。

Dependencies:
    pip install werobot gunicorn
"""

import os
import sys
import re
import time
import logging
import argparse
import dataclasses
from typing import Optional, Dict, Any

from werobot import WeRoBot
from werobot.messages.messages import TextMessage
from werobot.replies import TextReply

# ==============================================================================
# [Layer 1] 配置与常量 (Configuration)
# 设计意图：使用 dataclass 冻结配置，优先读取环境变量，符合 12-factor App 原则
# 未来拆分建议: src/config.py
# ==============================================================================

@dataclasses.dataclass(frozen=True)
class Config:
    # 核心凭证
    TOKEN: str = os.getenv("WECHAT_TOKEN", "dev_token_default")
    APP_ID: str = os.getenv("WECHAT_APP_ID", "")
    APP_SECRET: str = os.getenv("WECHAT_APP_SECRET", "")
    
    # 安全配置 (生产环境建议开启消息加密)
    ENCODING_AES_KEY: Optional[str] = os.getenv("WECHAT_AES_KEY", None)

    # 运行时配置
    HOST: str = os.getenv("APP_HOST", "0.0.0.0")
    PORT: int = int(os.getenv("APP_PORT", 8888))
    DEBUG: bool = os.getenv("APP_DEBUG", "True").lower() == "true"
    
    # Session 策略：SME 项目推荐文件存储，简单可靠，重启不丢状态
    SESSION_STORAGE: str = "file"

# ==============================================================================
# [Layer 2] 基础设施 (Infrastructure)
# 设计意图：封装日志、异常基类与监控装饰器，为上层业务提供支撑
# 未来拆分建议: src/utils/
# ==============================================================================

def setup_logger(name: str) -> logging.Logger:
    """初始化结构化日志"""
    logger = logging.getLogger(name)
    if not logger.handlers:
        logger.setLevel(logging.INFO)
        handler = logging.StreamHandler()
        # 格式包含：时间、级别、模块名、行号，便于排查
        formatter = logging.Formatter(
            '[%(asctime)s] %(levelname)s [%(module)s:%(lineno)d]: %(message)s'
        )
        handler.setFormatter(formatter)
        logger.addHandler(handler)
    return logger

logger = setup_logger("app")

class BusinessException(Exception):
    """
    业务异常基类
    用于中断处理流程并返回给用户提示，但不触发系统 Error 报警
    """
    pass

def timeit(func):
    """性能监控装饰器：记录 Handler 处理耗时"""
    def wrapper(*args, **kwargs):
        start = time.time()
        result = func(*args, **kwargs)
        cost = (time.time() - start) * 1000
        # 超过 1000ms 记录为警告
        if cost > 1000:
            logger.warning(f"🐢 Handler [{func.__name__}] slow: {cost:.2f}ms")
        else:
            logger.info(f"⚡ Handler [{func.__name__}] cost: {cost:.2f}ms")
        return result
    return wrapper

# ==============================================================================
# [Layer 3] 业务服务层 (Service Layer)
# 设计意图：纯 Python 类，不依赖 WeRoBot。负责"脏活累活"（查库、API），便于单元测试
# 未来拆分建议: src/services/
# ==============================================================================

class WeatherService:
    """示例：天气业务逻辑"""
    @staticmethod
    def get_weather(city: str) -> str:
        if not city:
            # 抛出业务异常，由 Handler 层捕获并转述给用户
            raise BusinessException("请指定城市名称，例如：'天气 北京'")
            
        logger.info(f"Fetching weather for: {city}")
        # 模拟外部 API 调用
        if city == "火星":
            raise BusinessException("暂不支持地外行星天气查询。")
            
        return f"🌤 【{city}】今日晴朗，气温 24℃，适合上线代码。"

class AuthService:
    """示例：用户鉴权逻辑"""
    @staticmethod
    def get_user_profile(openid: str) -> Dict[str, Any]:
        # 模拟 DB 查询
        return {
            "uid": openid[-6:],
            "level": "VIP",
            "credits": 1024
        }

# ==============================================================================
# [Layer 4] 消息控制器 (Handlers)
# 设计意图：负责"路由参数解析" -> "调用 Service" -> "异常捕获" -> "返回结果"
# 未来拆分建议: src/handlers.py
# ==============================================================================

# 预编译正则，提升高并发下的匹配性能
RE_WEATHER = re.compile(r"^天气\s*(.*)", re.I)
RE_PROFILE = re.compile(r"^(我的|info|profile)", re.I)
RE_HELP    = re.compile(r"^(help|帮助|菜单)$", re.I)

@timeit
def weather_handler(message, session):
    """处理天气请求"""
    match = RE_WEATHER.match(message.content.strip())
    city = match.group(1).strip() if match else ""
    
    try:
        return WeatherService.get_weather(city)
    except BusinessException as e:
        return f"⚠️ {str(e)}"
    except Exception as e:
        logger.error(f"System Error in weather_handler: {e}", exc_info=True)
        return "服务开小差了，请稍后再试。"

@timeit
def profile_handler(message, session):
    """处理用户信息请求"""
    info = AuthService.get_user_info(message.source)
    return (
        f"👤 用户面板\n"
        f"------------\n"
        f"ID: {info['uid']}\n"
        f"等级: {info['level']}\n"
        f"积分: {info['credits']}"
    )

def help_handler(message):
    return (
        "🤖 智能助手指令集：\n"
        "1. 天气 [城市]\n"
        "2. 我的信息\n"
        "3. 帮助"
    )

def subscribe_handler(message):
    logger.info(f"New User Subscribed: {message.source}")
    return "🎉 欢迎关注！回复 '帮助' 查看功能。"

def fallback_handler(message):
    """兜底逻辑：处理未匹配的消息"""
    # 可以在这里接入 LLM (ChatGPT/DeepSeek)
    return f"收到: {message.content}\n(指令未识别，请回复 '帮助')"

# ==============================================================================
# [Layer 5] 扩展与运维工具 (Extensions & Ops)
# 设计意图：包含健康检查、菜单同步等非核心业务功能
# 未来拆分建议: src/ops.py
# ==============================================================================

MENU_DATA = {
    "button": [
        {"type": "click", "name": "今日天气", "key": "MENU_WEATHER_DEFAULT"},
        {
            "name": "更多服务",
            "sub_button": [
                {"type": "view", "name": "官方文档", "url": "https://werobot.readthedocs.io"},
                {"type": "click", "name": "关于我们", "key": "MENU_ABOUT"}
            ]
        }
    ]
}

def setup_health_check(robot: WeRoBot):
    """注入健康检查接口，供 SLB/K8s/监控系统 使用"""
    @robot.app.route('/health')
    def health():
        return {"status": "ok", "ts": int(time.time())}

def sync_menu(robot: WeRoBot):
    """发布自定义菜单"""
    if not Config.APP_ID or not Config.APP_SECRET:
        print("❌ Error: APP_ID and APP_SECRET are required for menu update.")
        return
    try:
        print("🔄 Syncing menu to WeChat server...")
        robot.client.create_menu(MENU_DATA)
        print("✅ Menu updated successfully.")
    except Exception as e:
        print(f"❌ Menu update failed: {e}")

# ==============================================================================
# [Layer 6] 应用组装 (Application Factory)
# 设计意图：将分散的组件组装成 Robot 实例，集中管理路由注册顺序
# 未来拆分建议: src/app.py
# ==============================================================================

def create_app() -> WeRoBot:
    robot = WeRoBot(token=Config.TOKEN)
    
    # 注入配置
    robot.config.update({
        "APP_ID": Config.APP_ID,
        "APP_SECRET": Config.APP_SECRET,
        "ENCODING_AES_KEY": Config.ENCODING_AES_KEY
    })
    
    # 1. 注册消息路由 (Filters) - 注意顺序
    robot.filter(RE_HELP)(help_handler)
    robot.filter(RE_WEATHER)(weather_handler)
    robot.filter(RE_PROFILE)(profile_handler)
    
    # 2. 注册事件路由
    robot.subscribe(subscribe_handler)
    
    # 3. 注册兜底路由 (必须最后)
    robot.text(fallback_handler)
    
    # 4. 全局错误兜底
    @robot.error
    def system_error_handler(error):
        logger.error(f"🔥 Critical Runtime Error: {error}", exc_info=True)
        return "系统繁忙 (Internal Error)"
        
    # 5. 挂载扩展
    setup_health_check(robot)
    
    return robot

# ==============================================================================
# [Layer 7] 入口与 CLI (Entry Point)
# 设计意图：单一入口文件，既是 WSGI Server 入口，也是 CLI 管理工具
# ==============================================================================

# 实例化应用 (供 WSGI Server 如 Gunicorn 调用)
robot_app = create_app()
application = robot_app.wsgi

def main():
    """CLI 命令行入口"""
    parser = argparse.ArgumentParser(description="WeRoBot Application Manager")
    parser.add_argument("command", choices=["run", "menu", "check"], help="Action to perform")
    
    args = parser.parse_args()
    
    if args.command == "run":
        print(f"🚀 Starting Dev Server on {Config.HOST}:{Config.PORT} [Debug={Config.DEBUG}]")
        try:
            robot_app.run(
                server='auto',
                host=Config.HOST,
                port=Config.PORT,
                debug=Config.DEBUG
            )
        except KeyboardInterrupt:
            print("\n🛑 Server stopped.")
            
    elif args.command == "menu":
        sync_menu(robot_app)
        
    elif args.command == "check":
        print("🔍 Configuration Check:")
        print(f" - Token:   {'✅ Set' if Config.TOKEN else '❌ Missing'}")
        print(f" - AppID:   {'✅ Set' if Config.APP_ID else '❌ Missing'}")
        print(f" - AESKey:  {'🔒 Enabled' if Config.ENCODING_AES_KEY else '⚪ Disabled'}")
        print("✅ Config valid.")

if __name__ == "__main__":
    # 默认行为：如果直接运行且无参数，打印帮助
    if len(sys.argv) == 1:
        sys.argv.append("--help")
    main()