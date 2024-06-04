import json
import smtplib
import pathlib
import sys
import retry

cfg = json.loads(pathlib.Path(sys.argv[1]).read_text())

Constructor = (smtplib.SMTP_SSL if cfg["security"] == "ssl" else smtplib.SMTP)
server = retry.retry(tries=10, delay=10)(Constructor)(cfg["host"], cfg["port"])
if cfg["security"] == "startls":
    server.starttls()
server.login(cfg["username"], pathlib.Path(cfg["passwordFile"]).read_text().strip())
server.ehlo_or_helo_if_needed()
server.quit()
