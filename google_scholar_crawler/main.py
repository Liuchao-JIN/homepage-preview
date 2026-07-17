"""
Fetch Google Scholar statistics for the site owner and write two JSON files:

  results/gs_data.json            -- full author record (name, indices, counts, publications)
  results/gs_data_shieldsio.json  -- a shields.io "endpoint" payload exposing the citation count

The GitHub Action publishes the `results/` folder to the `google-scholar-stats` branch,
and the homepage renders a live badge from `gs_data_shieldsio.json` via shields.io.

Configure the author id with the GOOGLE_SCHOLAR_ID environment variable
(defaults to Liuchao Jin's public Scholar id).
"""

import json
import os
from datetime import datetime

from scholarly import scholarly

# Public Google Scholar id — https://scholar.google.com/citations?user=iYBWir4AAAAJ
author_id = os.environ.get("GOOGLE_SCHOLAR_ID", "iYBWir4AAAAJ")

author = scholarly.search_author_id(author_id)
scholarly.fill(author, sections=["basics", "indices", "counts", "publications"])

author["updated"] = str(datetime.now())
author["publications"] = {v["author_pub_id"]: v for v in author["publications"]}

os.makedirs("results", exist_ok=True)

with open("results/gs_data.json", "w", encoding="utf-8") as outfile:
    json.dump(author, outfile, ensure_ascii=False)

shieldsio_data = {
    "schemaVersion": 1,
    "label": "citations",
    "message": f"{author.get('citedby', 0)}",
    "color": "9cf",
}

with open("results/gs_data_shieldsio.json", "w", encoding="utf-8") as outfile:
    json.dump(shieldsio_data, outfile, ensure_ascii=False)

print(f"Fetched Scholar stats for {author.get('name')}: "
      f"{author.get('citedby', 0)} citations, h-index {author.get('hindex', 'n/a')}")
