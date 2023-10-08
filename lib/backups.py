import json
import pathlib
import subprocess
import shutil
import sys

snapshot_dir = pathlib.Path("/tmp/snapshots")
cfg = json.loads(pathlib.Path(sys.argv[1]).read_text())
command = sys.argv[2]
volume = sys.argv[3]
volume_cfg = cfg[volume]
postgres_url = volume_cfg["postgresql"]["url"]
if postgres_url.endswith("/"):
    postgres_url = postgres_url[:-1]

if command == "prepare":
    if snapshot_dir.exists():
        shutil.rmtree(snapshot_dir)
    subprocess.run(volume_cfg["enterMaintenanceMode"], shell=True, check=True)
    for service in volume_cfg["services"]:
        subprocess.run(["systemctl", "stop", service], check=True)
    for db_name in volume_cfg["postgresql"]["databases"]:
        db_dir = snapshot_dir / db_name
        db_dir.mkdir(parents=True)
        shutil.chown(db_dir, "postgres")
        shutil.chown(snapshot_dir, "postgres")
        subprocess.run(
            [
                f"{cfg['sudo']}/bin/sudo",
                "--user=postgres",
                f"{volume_cfg['postgresql']}/bin/pg_dump",
                "--format=directory",
                f"--file={db_dir}",
                f"{postgres_url}/{db_name}",
            ],
            check=True,
        )
        shutil.chown(db_dir, "root")
        shutil.chown(snapshot_dir, "root")

elif command == "cleanup":
    for service in volume_cfg["services"]:
        subprocess.run(["systemctl", "start", service], check=True)
    subprocess.run(volume_cfg["exitMaintenanceMode"], shell=True, check=True)
    shutil.rmtree(snapshot_dir)

else:
    raise NotImplementedError(f"Command {command} is not implemented")
