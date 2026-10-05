"""Zip an extension's src/ folder with forward-slash paths: make_zip.py <extension_dir> <out.zip>"""
import os, sys, zipfile


def build(extension_dir, output):
    with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as archive:
        for root, _, files in os.walk(os.path.join(extension_dir, "src")):
            for name in sorted(files):
                full = os.path.join(root, name)
                archive.write(full, os.path.relpath(full, extension_dir).replace(os.sep, "/"))


if __name__ == "__main__":
    build(sys.argv[1], sys.argv[2])
