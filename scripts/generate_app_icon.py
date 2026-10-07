import os
from PIL import Image, ImageDraw, ImageFont

def create_mps_icon(size):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    scale = size / 512.0

    # 1. Background Rounded Squircle with Gradient
    # Create high-res supersampled canvas (2x)
    super_size = size * 2
    super_img = Image.new("RGBA", (super_size, super_size), (0, 0, 0, 0))
    super_draw = ImageDraw.Draw(super_img)

    r_corner = int(112 * scale * 2)
    # Background gradient from deep indigo (#312E81) to indigo (#4F46E5)
    for y in range(super_size):
        ratio = y / float(super_size)
        r = int(49 + (79 - 49) * ratio)
        g = int(46 + (70 - 46) * ratio)
        b = int(129 + (229 - 129) * ratio)
        super_draw.line([(0, y), (super_size, y)], fill=(r, g, b, 255))

    # Mask for rounded squircle
    mask = Image.new("L", (super_size, super_size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([0, 0, super_size, super_size], radius=r_corner, fill=255)
    
    super_img.putalpha(mask)

    # 2. Draw Shield Emblem
    shield_pts = [
        (256 * 2 * scale, 85 * 2 * scale),
        (395 * 2 * scale, 135 * 2 * scale),
        (370 * 2 * scale, 280 * 2 * scale),
        (256 * 2 * scale, 415 * 2 * scale),
        (142 * 2 * scale, 280 * 2 * scale),
        (117 * 2 * scale, 135 * 2 * scale),
    ]
    # Gold border
    super_draw.polygon(shield_pts, fill=(15, 23, 42, 235), outline=(245, 158, 11, 255), width=max(2, int(8 * scale * 2)))

    # 3. Graduation Cap Emblem
    cap_top = [
        (256 * 2 * scale, 135 * 2 * scale),
        (325 * 2 * scale, 160 * 2 * scale),
        (256 * 2 * scale, 185 * 2 * scale),
        (187 * 2 * scale, 160 * 2 * scale),
    ]
    super_draw.polygon(cap_top, fill=(251, 191, 36, 255))
    # Cap band
    cap_band = [
        (215 * 2 * scale, 172 * 2 * scale),
        (297 * 2 * scale, 172 * 2 * scale),
        (290 * 2 * scale, 200 * 2 * scale),
        (222 * 2 * scale, 200 * 2 * scale),
    ]
    super_draw.polygon(cap_band, fill=(245, 158, 11, 255))

    # 4. Bold Typography "MPS"
    # Try loading a bold font, fallback to default font scaled
    try:
        font_path = "C:/Windows/Fonts/arialbd.ttf"
        font = ImageFont.truetype(font_path, int(96 * scale * 2))
        sub_font = ImageFont.truetype(font_path, int(22 * scale * 2))
    except Exception:
        try:
            font_path = "C:/Windows/Fonts/segoeuib.ttf"
            font = ImageFont.truetype(font_path, int(96 * scale * 2))
            sub_font = ImageFont.truetype(font_path, int(22 * scale * 2))
        except Exception:
            font = ImageFont.load_default()
            sub_font = font

    # Draw "MPS" centered
    mps_text = "MPS"
    super_draw.text((256 * 2 * scale, 280 * 2 * scale), mps_text, font=font, fill=(255, 255, 255, 255), anchor="mm")
    
    # Subtitle "SCHOOL"
    super_draw.text((256 * 2 * scale, 345 * 2 * scale), "SCHOOL", font=sub_font, fill=(252, 211, 77, 240), anchor="mm")

    # Downsample with high-quality Lanczos resampling
    final_img = super_img.resize((size, size), Image.Resampling.LANCZOS)
    return final_img

def main():
    sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }

    base_res = "android/app/src/main/res"
    os.makedirs("assets/icons", exist_ok=True)

    # Also save 512x512 master app icon
    master_icon = create_mps_icon(512)
    master_icon.save("assets/icons/mps_app_icon.png")
    print("Saved assets/icons/mps_app_icon.png (512x512)")

    for folder, sz in sizes.items():
        out_dir = os.path.join(base_res, folder)
        os.makedirs(out_dir, exist_ok=True)
        out_path = os.path.join(out_dir, "ic_launcher.png")
        icon = create_mps_icon(sz)
        icon.save(out_path)
        print(f"Saved {out_path} ({sz}x{sz})")

if __name__ == "__main__":
    main()
