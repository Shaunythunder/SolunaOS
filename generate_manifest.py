# This script generates an install manifest for the LorielleOS Mod project.

import os
excluded_files = {'README.txt', 
           'generate_manifest.py', 
           'install_manifest.txt',
           'disk_imager.lua',
           'license.txt',
           '.gitignore',}

excluded_directories = {'.git',}

def checksum(path):
    with open(path, 'rb') as f:
        return sum(f.read()) % (2**32)

with open('install_manifest.lua', 'w') as manifest:
    manifest.write("return {\n")
    for root, dirs, files in os.walk('.'):
        dirs[:] = [d for d in dirs if d not in excluded_directories]
        # Exclude files in excluded_directories
        for file in files:
            if file not in excluded_files:
                relpath = os.path.relpath(os.path.join(root, file))
                if relpath.startswith('.' + os.sep):
                    relpath = relpath[2:]
                abspath = os.path.join(root, file)
                size = os.path.getsize(abspath)
                cksum = checksum(abspath)
                manifest.write(f"{{filename = '{relpath}', size = {size}, checksum = {cksum}}},\n")
    manifest.write("}\n")