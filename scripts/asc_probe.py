#!/usr/bin/env python3
"""Read-only probe: does app.tack.ios exist as bundle ID / app record / profile?"""
import json, time, sys
from pathlib import Path
import jwt, requests

KEY_ID = "R3842P859P"
ISSUER_ID = "d2764ec1-2cc4-4a91-87e7-273be34c5c0c"
KEY_PATH = Path.home() / ".appstoreconnect/private_keys" / f"AuthKey_{KEY_ID}.p8"
BASE = "https://api.appstoreconnect.apple.com"

def token():
    return jwt.encode(
        {"iss": ISSUER_ID, "exp": int(time.time()) + 1200, "aud": "appstoreconnect-v1"},
        KEY_PATH.read_text(), algorithm="ES256", headers={"kid": KEY_ID, "typ": "JWT"})

H = {"Authorization": f"Bearer {token()}"}

def get(path, **params):
    r = requests.get(BASE + path, headers=H, params=params, timeout=30)
    return r.status_code, (r.json() if r.text else {})

print("== bundleIds matching 'tack' ==")
c, d = get("/v1/bundleIds", **{"filter[platform]": "IOS", "limit": 200})
print("status", c)
for b in d.get("data", []):
    ident = b["attributes"]["identifier"]
    if "tack" in ident.lower():
        print(" ", b["id"], ident, "|", b["attributes"]["name"])

print("\n== apps matching 'tack' ==")
c, d = get("/v1/apps", limit=200)
print("status", c)
for a in d.get("data", []):
    at = a["attributes"]
    if "tack" in (at.get("bundleId") or "").lower() or "tack" in (at.get("name") or "").lower():
        print(" ", a["id"], at.get("bundleId"), "|", at.get("name"), "|", at.get("sku"))

print("\n== profiles matching 'tack' ==")
c, d = get("/v1/profiles", limit=200)
print("status", c)
for p in d.get("data", []):
    if "tack" in p["attributes"]["name"].lower():
        print(" ", p["id"], p["attributes"]["name"], p["attributes"]["profileState"], p["attributes"]["profileType"])

print("\n== distribution certs ==")
c, d = get("/v1/certificates", limit=200)
print("status", c)
for x in d.get("data", []):
    at = x["attributes"]
    if "DISTRIBUTION" in at["certificateType"]:
        print(" ", x["id"], at["certificateType"], at["name"], "exp", at["expirationDate"])
