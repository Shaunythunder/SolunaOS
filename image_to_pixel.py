from PIL import Image

# In order to use this put the relative path of the image into the image.open()
# and then run with python3 image_to_pixel.py  in your shell.
# Afterwards, rename the file and put it where you would like.
# you also must have a virtual environment with pillow installed.  
# run python3 -m venv venv -> source venv/bin/activate -> pip install pillow in your shell

def rgb_to_hex(rgb):
    return (rgb[0] << 16) + (rgb[1] << 8) + rgb[2]

img = Image.open("non_oc_assets/starcraft-terran.jpg").resize((160, 100))
pixels = img.load()

with open("test_oc_assets/output_pixels.lua", "w") as file:
    file.write("return {\n")
    for y in range(0, img.height, 2):
        for x in range(img.width):
           top = pixels[x, y]
           bottom = pixels[x, y + 1] if y + 1 < img.height else (0, 0, 0)
           file.write(f'{{{x + 1}, {y // 2 + 1}, 0x{rgb_to_hex(top):06X}, 0x{rgb_to_hex(bottom):06X}}},\n')
    file.write("}\n")


