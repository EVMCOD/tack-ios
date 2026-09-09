#!/usr/bin/env python3
"""Fill the age-rating declaration for a "nothing objectionable / 4+" app.

Apple's questionnaire mixes types (most fields are enums, a few are booleans)
and keeps adding required fields, so rather than hardcode the 2026 shape this
reads the error pointers back and repairs itself: REQUIRED adds the field,
ATTRIBUTE.TYPE flips enum <-> boolean.
"""
import sys, time, json
from pathlib import Path
import jwt, requests
KEY_ID="R3842P859P"; ISSUER="d2764ec1-2cc4-4a91-87e7-273be34c5c0c"
KEY=Path.home()/".appstoreconnect/private_keys"/f"AuthKey_{KEY_ID}.p8"
BASE="https://api.appstoreconnect.apple.com"
def H(): return {"Authorization":"Bearer "+jwt.encode({"iss":ISSUER,"exp":int(time.time())+1200,
    "aud":"appstoreconnect-v1"},KEY.read_text(),algorithm="ES256",headers={"kid":KEY_ID,"typ":"JWT"}),
    "Content-Type":"application/json"}
AID=sys.argv[1]
attrs={k:"NONE" for k in ["alcoholTobaccoOrDrugUseOrReferences","contests","gamblingSimulated",
    "medicalOrTreatmentInformation","profanityOrCrudeHumor","sexualContentOrNudity",
    "horrorOrFearThemes","matureOrSuggestiveThemes","violenceCartoonOrFantasy",
    "violenceRealisticProlongedGraphicOrSadistic","violenceRealistic","sexualContentGraphicAndNudity"]}
attrs.update({"gambling":False,"unrestrictedWebAccess":False,"kidsAgeBand":None})
for attempt in range(25):
    r=requests.patch(BASE+f"/v1/ageRatingDeclarations/{AID}",headers=H(),timeout=60,
        json={"data":{"type":"ageRatingDeclarations","id":AID,"attributes":attrs}})
    if r.status_code==200:
        print(f"✅ age rating set in {attempt+1} passes")
        print("   ", json.dumps(r.json()["data"]["attributes"], indent=1)[:900]); break
    errs=r.json().get("errors",[]); changed=False
    for e in errs:
        f=((e.get("source") or {}).get("pointer","")).split("/")[-1]
        code=e.get("code","")
        if not f: continue
        if code.endswith("ATTRIBUTE.REQUIRED") and f not in attrs:
            attrs[f]="NONE"; changed=True; print(f"  + {f}")
        elif code.endswith("ATTRIBUTE.TYPE") and f in attrs:
            attrs[f]=False if attrs[f]=="NONE" else "NONE"; changed=True; print(f"  ~ {f} -> {attrs[f]}")
        elif code.endswith("ATTRIBUTE.INVALID") and f in attrs:
            attrs.pop(f); changed=True; print(f"  - {f}")
    if not changed:
        print("stuck:",r.status_code,json.dumps(errs)[:600]); break
