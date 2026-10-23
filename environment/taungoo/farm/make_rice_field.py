import numpy as np, sys, os
from PIL import Image, ImageDraw
from scipy import ndimage as ndi
OUT=sys.argv[1]; SC=float(sys.argv[2]); os.makedirs(OUT,exist_ok=True)
src=np.array(Image.open('ca87a583-isometric_rice_paddy_field_16/isometric_rice_paddy_field_16/rotations/isometric_rice_paddy_field_16.png').convert('RGBA'))
T=np.array([128,11]); vR=np.array([124,59]); vL=np.array([-124,66])
N=2
offs=[(i,j) for i in range(N) for j in range(N)]
pos=[T*0+i*vR+j*vL for i,j in offs]
minx=min(p[0] for p in pos); miny=min(p[1] for p in pos)
W=256+max(p[0] for p in pos)-minx; H=256+max(p[1] for p in pos)-miny
can=np.zeros((H,W,4),np.uint8)
for (i,j),p in sorted(zip(offs,pos),key=lambda q:q[0][0]+q[0][1]):
    x0,y0=p[0]-minx,p[1]-miny
    sub=can[y0:y0+256,x0:x0+256]; sel=src[...,3]>0
    # this (nearer) block owns its columns from its top outline down: clear what's behind
    for x in range(256):
        ys=np.where(sel[:,x])[0]
        if len(ys): sub[ys.min()+6:ys.max()+1,x]=0
    sub[sel]=src[sel]
# smooth away the block-corner outline columns where two front walls meet
for k in range(1,N):
    for c in (T+k*vL+N*vR-[minx,miny], T+N*vL+k*vR-[minx,miny]):
        xj=int(round(c[0])); yj=int(round(c[1]))
        for y in range(yj-4,min(H,yj+125)):
            l=can[y,xj-4].astype(float); r=can[y,xj+5].astype(float)
            if l[3]==0 or r[3]==0: continue
            for x in range(xj-3,xj+5):
                t=(x-(xj-4))/9.0
                can[y,x]=((1-t)*l+t*r).astype(np.uint8)
# top face of the whole field (big diamond) for the water mask
Tc=T-[minx,miny]; Rc=Tc+N*vR; Lc=Tc+N*vL; Bc=Tc+N*vR+N*vL
face=Image.new('L',(W,H),0); ImageDraw.Draw(face).polygon([tuple(Tc),tuple(Rc),tuple(Bc),tuple(Lc)],fill=255)
face=np.array(face)>0
a=can.astype(int); r,g,b=a[...,0],a[...,1],a[...,2]; lum=(r+g+b)/3
sat=np.maximum(np.maximum(r,g),b)-np.minimum(np.minimum(r,g),b)
wat=(a[...,3]>250)&(b>=r-2)&(g>=r)&(lum>95)&(sat<70)&face
wat=ndi.binary_closing(wat,np.ones((5,5)))&face&(a[...,3]>250)
wat=ndi.binary_opening(wat,np.ones((3,3)))
img=Image.fromarray(can,'RGBA'); wm=np.zeros((H,W,4),np.uint8); wm[...,0]=40; wm[...,3]=wat*255
w2,h2=int(W*SC),int(H*SC)
img.resize((w2,h2),Image.NEAREST).save(OUT+'rice_field.png')
Image.fromarray(wm,'RGBA').resize((w2,h2),Image.NEAREST).save(OUT+'rice_field_water.png')
print(w2,h2,'corners',(Tc*SC).tolist(),(Rc*SC).tolist(),(Bc*SC).tolist(),(Lc*SC).tolist())
bg=Image.new('RGBA',(W,H),(80,120,60,255)); bg.alpha_composite(img); bg.save('/tmp/claude-0/-home-claude/8ae01d0c-0749-5644-8e70-45ed2287eac8/scratchpad/iso.png')
