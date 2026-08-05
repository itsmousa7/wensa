#!/usr/bin/env python3
"""Remove the studio background from the Wensa character renders.

Uses ML segmentation (rembg / U^2-Net) rather than a color-distance
technique. The source renders' garments (white T-shirt, white dress shirt)
sit in the same warm-grey color family as the studio background gradient —
verified by direct pixel sampling — so no flood-fill or threshold tolerance
can separate them by color alone. Segmentation classifies by learned object
structure instead, which is unaffected by the color overlap.

Usage:  python3 tools/cutout.py <input.png> <output.png>
"""
import sys
from rembg import remove
from PIL import Image


def cutout(src_path, dst_path):
    im = Image.open(src_path)
    out = remove(im)

    bbox = out.getbbox()
    if bbox:
        out = out.crop(bbox)
    out.save(dst_path)
    print(f"{src_path} -> {dst_path}  {out.size}  transparent")


if __name__ == "__main__":
    cutout(sys.argv[1], sys.argv[2])
