import argparse
import collections.abc
import json
import pathlib
import typing
import namecheap
import namecheap.models


parser = argparse.ArgumentParser()
parser.add_argument("config_json")
args = parser.parse_args()


class Domain(typing.TypedDict):
    type: str
    name: str
    address: str
    ttl: int | None
    mx_priority: int | None

cfg = json.loads(pathlib.Path(args.config_json).read_bytes())
api_key_file: str = cfg["authentication"]["api-key-file"]
username: str = cfg["authentication"]["username"]
api_user: str = cfg["authentication"]["api-user"]
sandbox: bool = cfg["authentication"]["sandbox"]
delete_other_records: bool = cfg["delete-other-records"]
domains: collections.abc.Mapping[str, Domain] = cfg["domains"]


with namecheap.Namecheap(
    api_key=pathlib.Path(api_key_file).read_text(),
    username=username,
    api_user=api_user,
    sandbox=sandbox,
) as namecheap_client:
    ip_status = namecheap_client.check_ip()
    assert ip_status["configured_ip"] == ip_status["actual_ip"]
    for domain_name, domain_cfg in domains.items():
        wanted_records = [
            namecheap.models.DNSRecord.model_validate({
                "@Name": domain_cfg["name"],
                "@Type": domain_cfg["type"],
                "@Address": domain_cfg["address"],
                **({
                    "@TTL": domain_cfg["ttl"]
                } if "ttl" in domain_cfg else {}),
                "@MXPref": domain_cfg["mx_priority"],
            })
        ]
        existing_records = namecheap_client.dns.get(domain_name)
        if delete_other_records:
            if set(existing_records) != set(wanted_records):
                namecheap_client.dns.set(domain_name, wanted_records)
        else:
            existing_records_set = set(existing_records)
            new_records = [
                record
                for record in wanted_records
                if record not in existing_records_set
            ]
            # One call to .set is better than N calls to .add
            namecheap_client.dns.set(domain_name, existing_records + new_records)
