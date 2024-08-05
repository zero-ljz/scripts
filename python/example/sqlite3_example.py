import datetime, sys, atexit, os, io, time, argparse, logging, subprocess

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