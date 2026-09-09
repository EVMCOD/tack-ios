#!/usr/bin/env python3
"""Register app.tack.ios + widget bundle IDs, APP_GROUPS capability, and
IOS_APP_STORE provisioning profiles. Idempotent."""
import base64, json, time, sys
from pathlib import Path
import jwt, requests

KEY_ID="R3842P859P"; ISSUER="d2764ec1-2cc4-4a91-87e7-273be34c5c0c"
KEY=Path.home()/".appstoreconnect/private_keys"/f"AuthKey_{KEY_ID}.p8"
BASE="https://api.appstoreconnect.apple.com"
CERT_ID="TFMJSM5P56"   # Apple Distribution: ENRIQUE VALEROS MURIANA
PROFILE_DIR=Path.home()/"Library/MobileDevice/Provisioning Profiles"

TARGETS=[("app.tack.ios","Tack iOS","Tack App Store"),
         ("app.tack.ios.widget","Tack Widget","Tack Widget App Store")]

def hdr():
    t=jwt.encode({"iss":ISSUER,"exp":int(time.time())+1200,"aud":"appstoreconnect-v1"},
                 KEY.read_text(),algorithm="ES256",headers={"kid":KEY_ID,"typ":"JWT"})
    return {"Authorization":f"Bearer {t}","Content-Type":"application/json"}

def req(m,p,**kw):
    r=requests.request(m,BASE+p,headers=hdr(),timeout=60,**kw)
    return r.status_code,(r.json() if r.text else {})

def find_bundle(ident):
    c,d=req("GET","/v1/bundleIds",params={"filter[identifier]":ident,"limit":10})
    for b in d.get("data",[]):
        if b["attributes"]["identifier"]==ident: return b["id"]
    return None

def find_profile(name):
    c,d=req("GET","/v1/profiles",params={"filter[name]":name,"limit":10})
    for p in d.get("data",[]):
        if p["attributes"]["name"]==name: return p
    return None

for ident,name,profname in TARGETS:
    bid=find_bundle(ident)
    if bid:
        print(f"= bundleId {ident} exists ({bid})")
    else:
        c,d=req("POST","/v1/bundleIds",json={"data":{"type":"bundleIds","attributes":{
            "identifier":ident,"name":name,"platform":"IOS"}}})
        if c not in (200,201): print(f"✗ create bundleId {ident}: {c} {json.dumps(d)[:400]}"); sys.exit(1)
        bid=d["data"]["id"]; print(f"+ bundleId {ident} created ({bid})")

    # APP_GROUPS capability
    c,d=req("GET",f"/v1/bundleIds/{bid}/bundleIdCapabilities",params={"limit":50})
    have={x["attributes"]["capabilityType"] for x in d.get("data",[])}
    if "APP_GROUPS" in have:
        print(f"  = APP_GROUPS already on {ident}")
    else:
        c,d=req("POST","/v1/bundleIdCapabilities",json={"data":{"type":"bundleIdCapabilities",
            "attributes":{"capabilityType":"APP_GROUPS","settings":None},
            "relationships":{"bundleId":{"data":{"type":"bundleIds","id":bid}}}}})
        print(f"  {'+' if c in (200,201) else '✗'} APP_GROUPS {c} {'' if c in (200,201) else json.dumps(d)[:400]}")

    # profile
    p=find_profile(profname)
    if p and p["attributes"]["profileState"]=="ACTIVE":
        print(f"  = profile '{profname}' exists")
    else:
        if p:
            req("DELETE",f"/v1/profiles/{p['id']}")
            print(f"  - deleted stale profile '{profname}'")
        c,d=req("POST","/v1/profiles",json={"data":{"type":"profiles",
            "attributes":{"name":profname,"profileType":"IOS_APP_STORE"},
            "relationships":{"bundleId":{"data":{"type":"bundleIds","id":bid}},
                             "certificates":{"data":[{"type":"certificates","id":CERT_ID}]}}}})
        if c not in (200,201): print(f"  ✗ create profile: {c} {json.dumps(d)[:500]}"); sys.exit(1)
        p=d["data"]; print(f"  + profile '{profname}' created")

    content=p["attributes"].get("profileContent")
    if not content:
        c,d=req("GET",f"/v1/profiles/{p['id']}")
        content=d["data"]["attributes"]["profileContent"]; p=d["data"]
    uuid=p["attributes"]["uuid"]
    PROFILE_DIR.mkdir(parents=True,exist_ok=True)
    out=PROFILE_DIR/f"{uuid}.mobileprovision"
    out.write_bytes(base64.b64decode(content))
    print(f"  ↓ installed {out}")
print("\ndone")
