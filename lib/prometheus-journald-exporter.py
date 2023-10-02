from collections.abc import Mapping, Sequence
import sys
import shutil
import re
import time
import json
import datetime
import shlex
import pathlib
import os
import prometheus_client
import subprocess
import pathlib
import enum
import dataclasses


class Priority(enum.StrEnum):
    emerg = "emerg"
    alert = "alert"
    crit = "crit"
    err = "err"
    warning = "warning"
    notice = "notice"
    info = "info"
    debug = "debug"


@dataclasses.dataclass(frozen=True)
class UnitConfig:
    priority: Priority = Priority.warning
    since: str = "1970-01-01"
    filters_regex: Sequence[str] = ()
    enable: bool = True


@dataclasses.dataclass(frozen=True)
class Config:
    port: int = 38172
    frequency: datetime.timedelta = datetime.timedelta(minutes=30)
    logs_dir: pathlib.Path = pathlib.Path(os.environ.get("LOGS_DIRECTORY", "/var/log/prometheus-journald-exporter"))
    units: Mapping[str, UnitConfig] = dataclasses.field(default_factory=lambda: {
        "default": UnitConfig(),
    })


config_path = sys.argv[1]
config_raw = json.loads(pathlib.Path(config_path).read_text())
units_config_raw = config_raw.get("units", {})
default_config_raw = units_config_raw.get("default", {})


config = Config(
    port=config_raw.get("port", Config().port),
    frequency=(
        datetime.timedelta(minutes=config_raw["frequencyMinutes"])
        if "frequencyMinutes" in config_raw
        else Config().frequency
    ),
    units={
        # Use global-default if none is supplied
        **Config().units,
        **{
            unit: UnitConfig(**{
                # Options come from global-default, user-default, and user's unit config
                **Config().units["default"].__dict__,
                **default_config_raw,
                **unit_config_raw,
            })
            for unit, unit_config_raw in units_config_raw.items()
        },
    },
)


for _ in range(10):
    units_proc = subprocess.run(
        ["systemctl", "show", "*", "--property=Id", "--value"],
        capture_output=True,
        text=True,
        check=False,
    )
    if units_proc.returncode != 0:
        print(units_proc.stdout)
        print(units_proc.stderr)
        time.sleep(3)
        continue
    else:
        break
units_proc.check_returncode()
units = set(
    line.strip()
    for line in units_proc.stdout.split("\n")
    if "." in line
)


log_lines_guage = prometheus_client.Gauge(
    "journald_log_lines",
    "Number of journald log lines at the configured priority since the configured start period.",
    ("unit",),
)


if not config.logs_dir.exists():
    config_logs_dir.mkdir()


def loop() -> None:
    for child in config.logs_dir.iterdir():
        if child.is_dir():
            shutil.rmtree(child)
        else:
            child.unlink()
    for unit in units:
        unit_config = config.units.get(unit, config.units["default"])
        if unit_config.enable:
            command = ["journalctl", "--priority", unit_config.priority, "--since", unit_config.since, "--unit", unit]
            lines = [
                line
                for line in subprocess.run(
                        command,
                        check=True,
                        capture_output=True,
                        text=True,
                ).stdout.split("\n")
                if line.strip() and not (line.startswith("--") and line.endswith("--")) and not any(re.search(filter, line) for filter in unit_config.filters_regex)
            ]
            if lines:
                command = " | ".join([
                    " ".join(map(shlex.quote, command)),
                    *[f"pcregrep --invert-match {shlex.quote(filter)}" for filter in unit_config.filters_regex],
                ])
                (config.logs_dir / unit.replace(".", "-")).write_text("\n".join(["$ " + command, *lines]))
            log_lines_guage.labels(unit).set(len(lines))


if __name__ == '__main__':
    prometheus_client.REGISTRY.unregister(prometheus_client.GC_COLLECTOR)
    prometheus_client.REGISTRY.unregister(prometheus_client.PLATFORM_COLLECTOR)
    prometheus_client.REGISTRY.unregister(prometheus_client.PROCESS_COLLECTOR)
    prometheus_client.start_http_server(config.port)
    print(f"Listening on {config.port}")
    print(repr(config))
    try:
        while True:
            loop()
            time.sleep(config.frequency.total_seconds())
    except KeyboardInterrupt:
        print("Keyboard interrupt caught; exiting")
