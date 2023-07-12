#!/usr/bin/env python

# This script reads a Remark42 backup file, flattens the entries and saves to Excel file
# 
# - Requires pandas and openpyxl libraries
#
# ./backup2excel.py backup-atlasview-20230710.gz
#
# You can trigger a backup by connecting to the Remark container and running: backup --url=http://localhost:8080

import json
import gzip
import sys
from pathlib import Path

import pandas as pd

filename = Path(sys.argv[1])
basename = filename.stem

entries = list()

with gzip.open(filename, "r") as handle:
    for line in handle:
        entry = json.loads(line)
        if "id" in entry:
            entry["user_name"] = entry["user"]["name"]
            entry["user_id"] = entry["user"]["id"]
            del(entry["user"])
            entry["locator_url"] = entry["locator"]["url"]
            del(entry["locator"])
            if "edit" in entry:
                del(entry["edit"])
            entries.append(entry)

df = pd.DataFrame(data=entries)

df.to_excel(basename + ".xlsx")


