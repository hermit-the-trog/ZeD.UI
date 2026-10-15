"""Pull named sprites out of a Project Zomboid texture pack (.pack).
   python pz_unpack.py "<PZ>/media/texturepacks/UI2.pack" Item_Wrench Item_Hammer_Forged Item_Pocketwatch
   Writes ref/icons/<name>.png (full 32x32 frame with the offset applied). Names may end in * as a prefix match."""
import struct, io, sys
from PIL import Image
def rd_int(f): return struct.unpack("<i", f.read(4))[0]
def rd_str(f):
    n=rd_int(f); return f.read(n).decode("utf-8","replace")
def pages(path):
    f=open(path,"rb"); magic=f.read(4)
    if magic==b"PZPK": ver=rd_int(f); npages=rd_int(f)
    else: f.seek(0); ver=0; npages=rd_int(f)
    for _ in range(npages):
        name=rd_str(f); n=rd_int(f); mask=rd_int(f)
        ents=[]
        for _ in range(n):
            en=rd_str(f); vals=struct.unpack("<8i",f.read(32)); ents.append((en,vals))
        if ver>=1:
            ln=rd_int(f); data=f.read(ln)
        else:
            buf=bytearray()
            while True:
                b=f.read(4)
                if b==b"\xef\xbe\xad\xde" or not b: break
                buf+=b[:1]; f.seek(-3,1)
            data=bytes(buf)
        yield name,ents,data
want=set(sys.argv[2:])
import os
os.makedirs(os.path.join("ref","icons"),exist_ok=True)
allnames=[]
for pname,ents,data in pages(sys.argv[1]):
    hit=[e for e in ents if e[0] in want or any(w.endswith("*") and e[0].startswith(w[:-1]) for w in want)]
    allnames+= [e[0] for e in ents]
    if not hit: continue
    page=Image.open(io.BytesIO(data)).convert("RGBA")
    for en,(x,y,w,h,ox,oy,tw,th) in hit:
        im=Image.new("RGBA",(tw,th)); im.paste(page.crop((x,y,x+w,y+h)),(ox,oy)); im.save(os.path.join("ref","icons",f"{en}.png")); print(en,(tw,th),"crop",(w,h))

