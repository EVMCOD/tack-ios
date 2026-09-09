#!/usr/bin/env python3
import time,json
from pathlib import Path
import jwt,requests
KEY_ID="R3842P859P"; ISSUER="d2764ec1-2cc4-4a91-87e7-273be34c5c0c"
KEY=Path.home()/".appstoreconnect/private_keys"/f"AuthKey_{KEY_ID}.p8"
BASE="https://api.appstoreconnect.apple.com"; APP="6809932513"
def H(): return {"Authorization":"Bearer "+jwt.encode({"iss":ISSUER,"exp":int(time.time())+1200,"aud":"appstoreconnect-v1"},KEY.read_text(),algorithm="ES256",headers={"kid":KEY_ID,"typ":"JWT"}),"Content-Type":"application/json"}
def g(p,**kw):
    r=requests.get(BASE+p,headers=H(),params=kw,timeout=60); return r.status_code,(r.json() if r.text else {})

c,d=g(f"/v1/apps/{APP}")
a=d["data"]["attributes"]
print("APP:",a.get("name"),"| bundle",a.get("bundleId"),"| contentRights:",a.get("contentRightsDeclaration"))

c,d=g(f"/v1/apps/{APP}/appStoreVersions",**{"limit":10})
for v in d.get("data",[]):
    va=v["attributes"]
    print(f"\nVERSION {va['versionString']} {va['platform']} state={va['appStoreState']} release={va.get('releaseType')} copyright={va.get('copyright')!r} id={v['id']}")
    VID=v["id"]
    c2,d2=g(f"/v1/appStoreVersions/{VID}/appStoreVersionLocalizations",**{"limit":50})
    for L in d2.get("data",[]):
        la=L["attributes"]
        print(f"   {la['locale']:6} desc={len(la.get('description') or '')}ch kw={len(la.get('keywords') or '')}ch whatsNew={'y' if la.get('whatsNew') else '-'} support={la.get('supportUrl')} mkt={la.get('marketingUrl')}")
        c3,d3=g(f"/v1/appStoreVersionLocalizations/{L['id']}/appScreenshotSets",**{"limit":20})
        for s in d3.get("data",[]):
            c4,d4=g(f"/v1/appScreenshotSets/{s['id']}/appScreenshots",**{"limit":20})
            print(f"      shots[{s['attributes']['screenshotDisplayType']}] = {len(d4.get('data',[]))}")
    c5,d5=g(f"/v1/appStoreVersions/{VID}/build")
    print("   build:",d5.get("data") and d5["data"]["id"] or None)

c,d=g(f"/v1/apps/{APP}/appInfos",**{"limit":5})
for ai in d.get("data",[]):
    print("\nAPPINFO",ai["id"],ai["attributes"].get("appStoreState"))
    c2,d2=g(f"/v1/appInfos/{ai['id']}/appInfoLocalizations",**{"limit":50})
    for L in d2.get("data",[]):
        la=L["attributes"]
        print(f"   {la['locale']:6} name={la.get('name')!r} sub={la.get('subtitle')!r} privacy={la.get('privacyPolicyUrl')}")

c,d=g(f"/v1/apps/{APP}/builds",**{"limit":10})
print("\nBUILDS:")
for b in d.get("data",[]):
    ba=b["attributes"]
    print("  ",b["id"],"v",ba.get("version"),ba.get("processingState"),"expired" if ba.get("expired") else "")
