# File: png_to_svg_converter.py

import cv2
import numpy as np
import svgwrite
from pathlib import Path

def png_to_svg(png_path: str, svg_path: str, threshold: int = 127) -> None:
    # Load image in grayscale
    image = cv2.imread(png_path, cv2.IMREAD_GRAYSCALE)
    if image is None:
        raise FileNotFoundError(f"Cannot load image: {png_path}")

    # Threshold the image
    _, thresh = cv2.threshold(image, threshold, 255, cv2.THRESH_BINARY_INV)

    # Find contours
    contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    height, width = image.shape
    dwg = svgwrite.Drawing(svg_path, size=(f"{width}px", f"{height}px"))

    for contour in contours:
        if len(contour) < 3:
            continue  # Skip if not enough points to form a shape

        points = [(pt[0][0], pt[0][1]) for pt in contour]
        dwg.add(dwg.polygon(points=points, fill='black'))

    dwg.save()
    print(f"SVG saved to: {svg_path}")

if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description='Convert PNG to SVG')
    parser.add_argument('png', help='Input PNG file')
    parser.add_argument('svg', help='Output SVG file')
    parser.add_argument('--threshold', type=int, default=127, help='Threshold for binarization')
    args = parser.parse_args()

    png_to_svg(args.png, args.svg, args.threshold)
