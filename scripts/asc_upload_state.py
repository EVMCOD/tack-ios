#!/usr/bin/env python3
"""Poll a buildUpload until it leaves PROCESSING.

App Store processing can FAIL silently: the build never appears in App Store
Connect and nothing surfaces in `altool`, which reports UPLOAD SUCCEEDED all
the same. /v1/buildUploads/<delivery-uuid> is where the real verdict lives.
"""
import sys, time
from pathlib import Path
import jwt, requests
KEY_ID="R3842P859P"; ISSUER="d2764ec1-2cc4-4a91-87e7-273be34c5c0c"
KEY=Path.home()/".appstoreconnect/private_keys"/f"AuthKey_{KEY_ID}.p8"
BASE="https://api.appstoreconnect.apple.com"
def H(): return {"Authorization":"Bearer "+jwt.encode({"iss":ISSUER,"exp":int(time.time())+1200,
    "aud":"appstoreconnect-v1"},KEY.read_text(),algorithm="ES256",headers={"kid":KEY_ID,"typ":"JWT"})}
uid=sys.argv[1]; tries=int(sys.argv[2]) if len(sys.argv)>2 else 20
for i in range(tries):
    r=requests.get(BASE+f"/v1/buildUploads/{uid}",headers=H(),timeout=60)
    st=r.json()["data"]["attributes"]["state"]
    print(f"[{i+1}] {st['state']}", flush=True)
    for e in st.get("errors",[]):   print(f"   ✗ {e['code']}: {e['description']}")
    for w in st.get("warnings",[]): print(f"   ! {w.get('code')}: {w.get('description')}")
    if st["state"]!="PROCESSING": break
    time.sleep(30)
