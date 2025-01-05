#!/usr/bin/env python3
import sys
import hashlib

raw_hash = int(hashlib.md5(sys.argv[1].encode()).hexdigest()[:4], 16)

if raw_hash < 1000:
    raw_hash += 1000

print(raw_hash)
