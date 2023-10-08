import sys
import requests
import pathlib
import json
import logging
import retry

logging.basicConfig()
requests_get = retry.retry(exceptions=requests.exceptions.RequestException, tries=10, delay=10)(requests.get)

cfg = json.loads(pathlib.Path(sys.argv[1]).read_text())
ip = requests_get(cfg["ipProvider"]).text.strip()

for cfg_entry in cfg["entries"]:
    print(f"Updating {cfg_entry['host']}.{cfg_entry['domain']} @ {cfg_entry['server']} -> {ip} with {cfg_entry['protocol']}")
    if cfg_entry["protocol"] == "namecheap":
        print(requests_get(
            f"https://{cfg_entry['server']}/update",
            params={
                "host": cfg_entry["host"],
                "domain": cfg_entry["domain"],
                "password": pathlib.Path(cfg_entry["passwordFile"]).read_text(),
                "ip": ip,
            },
        ).text)
    else:
        raise NotImplementedError(f"{cfg_entry['protocol']} is not implemented")
