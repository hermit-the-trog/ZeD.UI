#!/usr/bin/env python3
import os
import subprocess
from pathlib import Path
from PIL import Image, ImageOps

SRC_DIR = Path(r"C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\icon_matcher\uicons-solid-straight\svg")
OUT_DIR = Path(r"C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\icon_matcher\uicons-solid-straight\png")

OUT_DIR.mkdir(parents=True, exist_ok=True)

print("SVG → PNG Conversion")
print(f"Source: {SRC_DIR}")
print(f"Output: {OUT_DIR}")
print("")

# Try to find convert or magick
convert_cmd = None
for cmd in ["magick", "convert"]:
    result = subprocess.run(["where", cmd], capture_output=True, text=True)
    if result.returncode == 0:
        convert_cmd = cmd
        print(f"✓ Found: {cmd}")
        break

if not convert_cmd:
    print("✗ ImageMagick not in PATH. Searching...")
    for root, dirs, files in os.walk(r"C:\Program Files"):
        if "magick.exe" in files:
            convert_cmd = os.path.join(root, "magick.exe")
            print(f"✓ Found: {convert_cmd}")
            break
        if "convert.exe" in files:
            convert_cmd = os.path.join(root, "convert.exe")
            print(f"✓ Found: {convert_cmd}")
            break

if not convert_cmd:
    print("✗ ImageMagick not found!")
    print("Please install ImageMagick from https://imagemagick.org/")
    exit(1)

print("")

converted = 0
flipped = 0

for svg_path in sorted(SRC_DIR.glob("*.svg")):
    filename = svg_path.name
    basename_no_ext = svg_path.stem
    png_out = OUT_DIR / f"{basename_no_ext}.png"

    try:
        # Use simple ImageMagick command
        cmd = [
            convert_cmd,
            str(svg_path),
            "-negate",
            "-resize", "64x64!",
            "-background", "none",
            "-gravity", "center",
            "-extent", "64x64",
            str(png_out)
        ]

        result = subprocess.run(cmd, capture_output=True, text=True, timeout=5)

        if result.returncode == 0:
            print(f"✓ {filename}")
            converted += 1

            # Flip hand images
            if 'hand' in filename.lower():
                try:
                    img = Image.open(str(png_out))
                    flipped = ImageOps.mirror(img)

                    if 'left' in filename.lower():
                        flipped_name = basename_no_ext.replace('left', 'right') + '.png'
                    elif 'right' in filename.lower():
                        flipped_name = basename_no_ext.replace('right', 'left') + '.png'
                    else:
                        flipped_name = basename_no_ext + '_flipped.png'

                    flipped_path = OUT_DIR / flipped_name
                    flipped.save(str(flipped_path))
                    print(f"  → {flipped_name}")
                    flipped += 1
                except:
                    pass
        else:
            print(f"✗ {filename}")
            if result.stderr:
                print(f"  {result.stderr[:100]}")
    except Exception as e:
        print(f"✗ {filename}: {e}")

print(f"\nDone: {converted} converted, {flipped} flipped")
