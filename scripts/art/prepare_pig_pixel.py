"""Deterministically key the approved checkerboard previews and pack feet-aligned PNGs.
Run with Python + Pillow + numpy; source previews remain untouched.
"""
from pathlib import Path
from collections import deque
import json
import argparse
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT.parent / 'bigidea/02_pig'
parser = argparse.ArgumentParser()
parser.add_argument('--style', choices=['pixel', 'unified'], default='pixel')
STYLE = parser.parse_args().style
SUFFIX = '统一画风' if STYLE == 'unified' else '像素画风预览'
OUT = ROOT / 'assets/chapter2' / ('pig_unified' if STYLE == 'unified' else 'pig_pixel')
SIZE, FOOT = 320, 300
DIRECTIONS = ['down', 'left', 'up', 'right']

def key_background(path):
    a = np.array(Image.open(path).convert('RGB'))
    rgb = a.astype(np.int16)
    # Both grid colors are bright and neutral; pig colors and outlines are chromatic/dark.
    candidate = (rgb.max(2)-rgb.min(2) < 32) & (rgb.min(2) > 125)
    h,w = candidate.shape
    seen = np.zeros((h,w), bool)
    remove = np.zeros((h,w), bool)
    for sy,sx in zip(*np.where(candidate)):
        if seen[sy,sx]: continue
        q = deque([(int(sy),int(sx))]); seen[sy,sx] = True; component=[]
        while q:
            y,x = q.popleft(); component.append((y,x))
            for yy,xx in ((y-1,x),(y+1,x),(y,x-1),(y,x+1)):
                if 0 <= yy < h and 0 <= xx < w and candidate[yy,xx] and not seen[yy,xx]:
                    seen[yy,xx] = True; q.append((yy,xx))
        # Preserve tiny enclosed eye highlights; also key enclosed background gaps.
        if len(component) > 40:
            ys,xs = zip(*component); remove[ys,xs] = True
    rgba = np.dstack((a,np.where(remove,0,255).astype('uint8')))
    rgba[remove,:3]=0
    return Image.fromarray(rgba)

def frame(sheet, box, factor=1.0, min_component=18):
    crop=sheet.crop(box)
    # Discard isolated compression/grid fringes, preserving expression symbols.
    alpha=np.array(crop.getchannel('A')) > 0
    h,w=alpha.shape; seen=np.zeros_like(alpha); keep=np.zeros_like(alpha)
    for sy,sx in zip(*np.where(alpha)):
        if seen[sy,sx]: continue
        q=deque([(int(sy),int(sx))]); seen[sy,sx]=True; comp=[]
        while q:
            y,x=q.popleft(); comp.append((y,x))
            for yy,xx in ((y-1,x),(y+1,x),(y,x-1),(y,x+1)):
                if 0<=yy<h and 0<=xx<w and alpha[yy,xx] and not seen[yy,xx]:
                    seen[yy,xx]=True; q.append((yy,xx))
        if len(comp)>=min_component:
            yy,xx=zip(*comp); keep[yy,xx]=True
    crop.putalpha(Image.fromarray((keep*255).astype('uint8')))
    bounds=crop.getbbox(); assert bounds
    crop=crop.crop(bounds)
    if factor != 1:
        crop=crop.resize((round(crop.width*factor),round(crop.height*factor)),(Image.Resampling.LANCZOS if STYLE == 'unified' else Image.Resampling.NEAREST))
    assert crop.width < SIZE and crop.height < FOOT
    result=Image.new('RGBA',(SIZE,SIZE))
    result.alpha_composite(crop,((SIZE-crop.width)//2,FOOT-crop.height))
    return result

def pack(name, frames, cols):
    atlas=Image.new('RGBA',(cols*SIZE, ((len(frames)+cols-1)//cols)*SIZE))
    regions=[]
    for i,(label,im) in enumerate(frames):
        im.save(OUT/'frames'/f'{name}_{label}.png')
        x,y=(i%cols)*SIZE,(i//cols)*SIZE
        atlas.alpha_composite(im,(x,y)); regions.append([x,y,SIZE,SIZE])
    atlas.save(OUT/f'{name}.png')
    return regions

OUT.mkdir(parents=True,exist_ok=True); (OUT/'frames').mkdir(exist_ok=True)
cape=key_background(SOURCE/f'小呆猪披风-{SUFFIX}.png')
armed=key_background(SOURCE/f'小呆猪拿木棍-{SUFFIX}.png')
cape.save(OUT/'cape_source_transparent.png'); armed.save(OUT/'armed_source_transparent.png')
manifest={'frame_size':[SIZE,SIZE],'pivot':[SIZE//2,FOOT],'directions':DIRECTIONS,'source_files':[f'小呆猪披风-{SUFFIX}.png',f'小呆猪拿木棍-{SUFFIX}.png']}
frames=[]
xs=[0,260,520,770,1025]; ys=[0,260,485,710,945]
for row,d in enumerate(DIRECTIONS):
    for col in range(4):
        frames.append((f'{d}_{col:02}',frame(cape,(xs[col],ys[row],xs[col+1],ys[row+1]))))
manifest['cape']=pack('cape',frames,4)
frames=[]
xs=[0,440,815,1254]; ys=[0,333,627,929,1254]
for row,d in enumerate(DIRECTIONS):
    for col in range(3):
        frames.append((f'{d}_{col:02}',frame(armed,(xs[col],ys[row],xs[col+1],ys[row+1]),0.72)))
manifest['armed']=pack('armed',frames,3)
xs=[0,195,390,590,785,995,1215]
expressions=[]
for i,label in enumerate(['idle','happy','surprised','sad','sleep','hurt']):
    expressions.append((label,frame(cape,(xs[i],980,xs[i+1],1205),min_component=150 if label == 'sad' else 18)))
manifest['expressions']=pack('expressions',expressions,6)
# Authored poses only: a four-pose recovery, held over six existing timing steps.
manifest['wake']=pack('wake',[(str(i),expressions[j][1]) for i,j in enumerate([5,4,4,3,3,0])],6)
(OUT/'atlas.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
print('Prepared 34 unique poses; transparent atlases + 6 recovery timing frames:',OUT)
