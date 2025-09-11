import os
from PIL import Image

# This script converts images to pixel data for use in OpenComputers.
# Converts pictures to 160x100 resolution with RGB values for top and bottom pixels.
# Keeps original resolution if smaller than 160x100.
# All assets must be placed in assetprocessing/raw_assets
# and then run with python3 image_to_pixel.py  in your shell.
# You also must have a virtual environment with pillow installed.
# run python3 -m venv venv -> source venv/bin/activate -> pip install pillow in your shell
# 160 x 100 is full screen resolution for OC monitors using unicode pixel lines.

def rgb_to_hex(rgb):
    return (rgb[0] << 16) + (rgb[1] << 8) + rgb[2]

input_dir = "asset_processing/raw_assets"
output_dir = "assets/asset_tables"
os.makedirs(output_dir, exist_ok=True)

for f in os.listdir(output_dir):
    file_path = os.path.join(output_dir, f)
    if os.path.isfile(file_path):
        os.remove(file_path)

for filename in os.listdir(input_dir):
    if filename.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp', '.gif')):
        base_filename = os.path.splitext(filename)[0].strip()
        base_filename = "_".join(base_filename.split())
        base_filename = base_filename.lower()
        image_path = os.path.join(input_dir, filename)
        image = Image.open(image_path)
        image_width, image_height = image.size
        if image_width > 160 or image_height > 100:
            image = image.resize((160, 100))
            image_width = 160
            image_height = 100
        pixels = image.load()
        output_path = os.path.join(output_dir, f"{base_filename}.lua")
        with open(output_path, 'w') as file:
            file.write("return {\n")
            for y in range(0, image_height, 2):
                for x in range(image_width):
                    top = pixels[x, y]
                    bottom = pixels[x, y + 1] if y + 1 < image_height else (0, 0, 0)
                    file.write(f'{{{x + 1}, {y // 2 + 1}, 0x{rgb_to_hex(top):06X}, 0x{rgb_to_hex(bottom):06X}}},\n')
            file.write("}\n")

os.system("python3 generate_manifest.py")

