"""Rounded, part-aware normal maps for pixel-art characters.
Each body part (separated by the dark outline lines) gets its own rounded bulge,
so lights roll across arms, legs, head and clothes as the animation plays."""
import numpy as np, sys, glob, os
from PIL import Image
from scipy import ndimage as ndi

def normal_map(rgba, R=6.0, strength=1.0, detail=1.6):
    a = rgba.astype(float); al = a[..., 3] > 20
    lum = (0.3*a[...,0] + 0.59*a[...,1] + 0.11*a[...,2]) / 255.0
    lum = np.where(al, lum, 0)
    cnt = ndi.uniform_filter(al.astype(float), 5) + 1e-4
    local = ndi.uniform_filter(lum, 5) / cnt
    outline = al & (lum < 0.30) & (lum < local * 0.72)
    inner = al & ~outline
    d = ndi.distance_transform_edt(inner)
    t = np.clip(d / R, 0, 1)
    h = np.sqrt(1 - (1 - t) ** 2) * R * 0.9           # round (cylinder-like) profile per part
    # whole-silhouette bulge, so the body as a whole is round too
    D = ndi.distance_transform_edt(al)
    T = np.clip(D / (R * 2.2), 0, 1)
    h += np.sqrt(1 - (1 - T) ** 2) * R * 0.9
    h += ndi.gaussian_filter(lum, 0.7) * detail * R * 0.25
    h = ndi.gaussian_filter(h, 0.9)
    gx = ndi.sobel(h, 1) / 8.0; gy = ndi.sobel(h, 0) / 8.0
    nn = np.dstack([-gx * strength, gy * strength, np.ones_like(gx)])
    nn /= np.linalg.norm(nn, axis=2, keepdims=True)
    out = ((nn * 0.5 + 0.5) * 255).round().astype(np.uint8)
    out[~al] = [128, 128, 255]
    return np.dstack([out, (al * 255).astype(np.uint8)])

def shade_preview(rgba, n, L):
    N = n[..., :3].astype(float) / 127.5 - 1; N[..., 1] *= -1   # Godot normal maps: y down = green low
    L = np.array(L, float); L /= np.linalg.norm(L)
    d = np.clip((N * L).sum(2), 0, 1)
    c = rgba[..., :3].astype(float) * (0.35 + 0.9 * d[..., None])
    return np.dstack([np.clip(c, 0, 255).astype(np.uint8), rgba[..., 3]])

if __name__ == '__main__':
    for src in sys.argv[1:]:
        im = np.array(Image.open(src).convert('RGBA'))
        n = normal_map(im)
        dst = src[:-4] + '_n.png'
        Image.fromarray(n, 'RGBA').save(dst)
        print('wrote', dst)
