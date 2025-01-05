import json
import pathlib
import subprocess
import shutil
import sys

snapshot_dir = pathlib.Path("/tmp/snapshots")
cfg = json.loads(pathlib.Path(sys.argv[1]).read_text())
command = sys.argv[2]
volume = sys.argv[3]
if volume not in cfg["paas"]["volumes"]:
    raise KeyError(f"{volume} not found in cfg['paas']['volumes'] ({cfg['paas']['volumes']})")
volume_cfg = cfg["paas"]["volumes"][volume]
postgres_socket = cfg["paas"]["sql"]["socket"]


if command == "prepare":
    if snapshot_dir.exists():
        shutil.rmtree(snapshot_dir)
    subprocess.run(volume_cfg["enterMaintenanceMode"], shell=True, check=True)
    for service in volume_cfg["services"]:
        subprocess.run(["systemctl", "stop", service], check=True)
    for db_name in volume_cfg["databases"]:
        db_dir = snapshot_dir / db_name
        db_dir.mkdir(parents=True)
        shutil.chown(db_dir, "postgres")
        shutil.chown(snapshot_dir, "postgres")
        subprocess.run(
            [
                f"{cfg['pkgs']['sudo']}/bin/sudo",
                "--user=postgres",
                f"{cfg['pkgs']['postgresql']}/bin/pg_dump",
                "--format=directory",
                f"--file={db_dir}",
                f"--host={postgres_socket}",
                f"--dbname={db_name}",
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
