#!/usr/bin/env python3

import datetime, sys, atexit, os, io, time, argparse, logging, subprocess
import json, re, sqlite3
import random

app_name = os.path.splitext(os.path.basename(__file__))[0]

logging.basicConfig(filename=app_name + '.log', level=logging.INFO)
conn = sqlite3.connect(os.path.basename(app_name + '.db'))

def cache_data(expire_time=60, save_path=None):
    def decorator(func):
        def wrapper(*args, **kwargs):
            file_path = save_path or f"{func.__name__}_cache.json"
            refresh = kwargs.get('refresh', False)
            
            try:
                with open(file_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
            except FileNotFoundError:
                data = {}
            
            if not data or os.path.getmtime(file_path) + expire_time < time.time() or refresh:
                print("重新获取数据")
                data = func(*args, **kwargs)
                with open(file_path, "w", encoding="utf-8") as f:
                    json.dump(data, f, ensure_ascii=False, indent=4)
            return data
        return wrapper
    return decorator

def insert_update(conn, data_row: dict, table_name: str='tb1', filter: dict=None) -> int:
    """根据filter过滤条件，更新或插入"""
    cursor = conn.cursor()
    query = f"INSERT INTO {table_name} ({', '.join(data_row)}) VALUES ({', '.join(['?'] * len(data_row))})"
    args = tuple(data_row.values())
    if filter:
        cursor.execute(f"SELECT * FROM {table_name} WHERE {' AND '.join([f'{key} = ?' for key in filter])}", tuple(filter.values()))
        if cursor.fetchone():
            query = f"UPDATE {table_name} SET {', '.join([f'{key} = ?' for key in data_row])} WHERE {' AND '.join([f'{key} = ?' for key in filter])}"
            args = tuple(data_row.values()) + tuple(filter.values())
    cursor.execute(query, args)
    cursor.close()
    conn.commit()
    return cursor.rowcount

def create_table(conn, data_row: dict, table_name: str='tb1', drop: bool=False) -> None:
    cursor = conn.cursor()
    if drop:
        cursor.execute(f'DROP TABLE IF EXISTS {table_name}')
    data_type_mapping = {
        int: "INTEGER",
        float: "REAL",
        bool: "BOOLEAN",
        datetime.datetime: "DATETIME",
        datetime.date: "DATE",
        datetime.time: "TIME",
        datetime.timedelta: "TIMESTAMP",
    }
    columns = [f"{column} {data_type_mapping.get(type(value), 'TEXT')}" for column, value in data_row.items()]
    cursor.execute(f"CREATE TABLE IF NOT EXISTS {table_name} (\n    id INTEGER PRIMARY KEY,\n    {', '.join(columns)}\n);")
    cursor.close()
    conn.commit()

def insert_data(conn, data_row: dict, table_name: str='tb1'):
    cursor = conn.cursor()
    try:
        cursor.execute(f"INSERT INTO {table_name} ({', '.join(data_row)}) VALUES ({', '.join(['?'] * len(data_row))})", tuple(data_row.values()))
    except Exception as e:
        print(f"Error inserting data: {e}")
    cursor.close()
    conn.commit()

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-d', '--debug', action='store_true', help='Debug mode')
    args = parser.parse_args()

    print(app_name)
    print()