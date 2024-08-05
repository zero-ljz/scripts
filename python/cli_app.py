#!/usr/bin/env python3

import datetime, sys, atexit, os, io, time, argparse, logging, subprocess
import json, re, sqlite3
import random

script_name = os.path.splitext(os.path.basename(__file__))[0]
logging.basicConfig(filename=script_name + '.log', level=logging.INFO)
conn = sqlite3.connect(script_name + '.sqlite3')

cursor = conn.cursor()
cursor.row_factory = sqlite3.Row

sql = "SELECT name FROM sqlite_master WHERE type='table'"
rows = cursor.execute(sql).fetchall()

cursor.close()
conn.commit()

conn.close()


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-d', '--debug', action='store_true', help='Debug mode')
    args = parser.parse_args()

    print(script_name)
    print()






