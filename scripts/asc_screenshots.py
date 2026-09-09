#!/usr/bin/env python3
"""Upload App Store screenshots for one locale via the ASC API.

Flow per file: reserve (POST appScreenshots) → PUT bytes to each
uploadOperation → PATCH uploaded:true + md5. appScreenshots REQUIRES
sourceFileChecksum (unlike appScreenshotSets' sibling resources).
"""
import hashlib, json, sys, time
from pathlib import Path
import jwt, requests

KEY_ID="R3842P859P"; ISSUER="d2764ec1-2cc4-4a91-87e7-273be34c5c0c"
KEY=Path.home()/".appstoreconnect/private_keys"/f"AuthKey_{KEY_ID}.p8"
BASE="https://api.appstoreconnect.apple.com"; APP="6809932513"
DISPLAY="APP_IPHONE_67"          # 6.9" — 1320×2868

def H(ct=True):
    h={"Authorization":"Bearer "+jwt.encode({"iss":ISSUER,"exp":int(time.time())+1200,
        "aud":"appstoreconnect-v1"},KEY.read_text(),algorithm="ES256",
        headers={"kid":KEY_ID,"typ":"JWT"})}
    if ct: h["Content-Type"]="application/json"
    return h
def rq(m,p,**kw):
    r=requests.request(m,BASE+p,headers=H(),timeout=120,**kw)
    return r.status_code,(r.json() if r.text else {})

locale, folder = sys.argv[1], Path(sys.argv[2])
c,d=rq("GET",f"/v1/apps/{APP}/appStoreVersions",params={"limit":5})
VID=d["data"][0]["id"]
c,d=rq("GET",f"/v1/appStoreVersions/{VID}/appStoreVersionLocalizations",params={"limit":50})
LID=next(x["id"] for x in d["data"] if x["attributes"]["locale"]==locale)

# reuse or create the 6.9" set
c,d=rq("GET",f"/v1/appStoreVersionLocalizations/{LID}/appScreenshotSets",params={"limit":20})
SET=next((s["id"] for s in d.get("data",[])
          if s["attributes"]["screenshotDisplayType"]==DISPLAY), None)
if SET:
    c,d=rq("GET",f"/v1/appScreenshotSets/{SET}/appScreenshots",params={"limit":20})
    for old in d.get("data",[]):
        rq("DELETE",f"/v1/appScreenshots/{old['id']}")
    print(f"  reused set {SET} (cleared {len(d.get('data',[]))})")
else:
    c,d=rq("POST","/v1/appScreenshotSets",json={"data":{"type":"appScreenshotSets",
        "attributes":{"screenshotDisplayType":DISPLAY},
        "relationships":{"appStoreVersionLocalization":{"data":
            {"type":"appStoreVersionLocalizations","id":LID}}}}})
    if c not in (200,201): sys.exit(f"✗ set: {c} {json.dumps(d)[:300]}")
    SET=d["data"]["id"]; print(f"  created set {SET}")

for png in sorted(folder.glob("*.png")):
    blob=png.read_bytes()
    c,d=rq("POST","/v1/appScreenshots",json={"data":{"type":"appScreenshots",
        "attributes":{"fileSize":len(blob),"fileName":png.name},
        "relationships":{"appScreenshotSet":{"data":{"type":"appScreenshotSets","id":SET}}}}})
    if c not in (200,201): sys.exit(f"✗ reserve {png.name}: {c} {json.dumps(d)[:300]}")
    sid=d["data"]["id"]
    for op in d["data"]["attributes"]["uploadOperations"]:
        chunk=blob[op["offset"]:op["offset"]+op["length"]]
        hdrs={h["name"]:h["value"] for h in op["requestHeaders"]}
        r=requests.request(op["method"],op["url"],headers=hdrs,data=chunk,timeout=300)
        r.raise_for_status()
    c,d=rq("PATCH",f"/v1/appScreenshots/{sid}",json={"data":{"type":"appScreenshots","id":sid,
        "attributes":{"uploaded":True,"sourceFileChecksum":hashlib.md5(blob).hexdigest()}}})
    print(f"  {'✓' if c==200 else '✗'} {png.name} ({len(blob)//1024} KB)"
          + ("" if c==200 else f" {json.dumps(d)[:200]}"))
