#!/usr/bin/env python3
"""Set supportUrl/marketingUrl on every version localization and
privacyPolicyUrl on every app-info localization.

Note the split Apple makes: supportUrl lives on appStoreVersionLocalizations,
privacyPolicyUrl on appInfoLocalizations. Looking for the latter on the version
is a reliable way to lose half an hour.
"""
import time, json
from pathlib import Path
import jwt, requests
KEY_ID="R3842P859P"; ISSUER="d2764ec1-2cc4-4a91-87e7-273be34c5c0c"
KEY=Path.home()/".appstoreconnect/private_keys"/f"AuthKey_{KEY_ID}.p8"
BASE="https://api.appstoreconnect.apple.com"; APP="6809932513"
PRIVACY="https://games.clawstud.com/tack/privacy/"
SUPPORT="https://games.clawstud.com/tack/support/"
def H(): return {"Authorization":"Bearer "+jwt.encode({"iss":ISSUER,"exp":int(time.time())+1200,
    "aud":"appstoreconnect-v1"},KEY.read_text(),algorithm="ES256",headers={"kid":KEY_ID,"typ":"JWT"}),
    "Content-Type":"application/json"}
def rq(m,p,**kw):
    r=requests.request(m,BASE+p,headers=H(),timeout=60,**kw); return r.status_code,(r.json() if r.text else {})

c,d=rq("GET",f"/v1/apps/{APP}/appStoreVersions",params={"limit":5}); VID=d["data"][0]["id"]
c,d=rq("GET",f"/v1/appStoreVersions/{VID}/appStoreVersionLocalizations",params={"limit":50})
for L in d["data"]:
    c2,d2=rq("PATCH",f"/v1/appStoreVersionLocalizations/{L['id']}",
        json={"data":{"type":"appStoreVersionLocalizations","id":L["id"],
              "attributes":{"supportUrl":SUPPORT,"marketingUrl":SUPPORT}}})
    print(f"  support {L['attributes']['locale']:6} -> {c2}" + ("" if c2==200 else " "+json.dumps(d2)[:200]))

c,d=rq("GET",f"/v1/apps/{APP}/appInfos",params={"limit":5}); AI=d["data"][0]["id"]
c,d=rq("GET",f"/v1/appInfos/{AI}/appInfoLocalizations",params={"limit":50})
for L in d["data"]:
    c2,d2=rq("PATCH",f"/v1/appInfoLocalizations/{L['id']}",
        json={"data":{"type":"appInfoLocalizations","id":L["id"],
              "attributes":{"privacyPolicyUrl":PRIVACY}}})
    print(f"  privacy {L['attributes']['locale']:6} -> {c2}" + ("" if c2==200 else " "+json.dumps(d2)[:200]))
