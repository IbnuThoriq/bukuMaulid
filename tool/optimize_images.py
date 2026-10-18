# Tool sekali-pakai (bisa dipakai ulang): optimasi screenshot di assets/img/.
# - PNG teks/screenshot -> JPG max lebar 1600px, quality 80 (jauh lebih kecil,
#   masih tajam untuk dibaca + pinch-zoom di DetailScreen).
# - Update referensi "gambar" di assets/sholawat/*.json dari .png -> .jpg.
# - Hapus PNG lama HANYA jika JPG terverifikasi (bisa dibuka + ukuran > 0).
# - Dilewati: icon.png (sumber launcher icon, bukan konten), assets/img/grup/.
#
# Cara pakai:
#   python tool/optimize_images.py
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
IMG_DIR = ROOT / "assets" / "img"
JSON_DIR = ROOT / "assets" / "sholawat"
SKIP = {"icon.png"}
MAX_W = 1600
QUALITY = 80


def main() -> int:
    try:
        from PIL import Image
    except ImportError:
        print("ERROR: Pillow belum terinstal. Jalankan: pip install Pillow")
        return 1

    pngs = sorted(
        p for p in IMG_DIR.glob("*.png") if p.name not in SKIP and p.is_file()
    )
    if not pngs:
        print("Tidak ada PNG untuk dioptimasi.")
        return 0

    total_before = 0
    total_after = 0
    converted: dict[str, str] = {}  # nama.png -> nama.jpg

    for png in pngs:
        before = png.stat().st_size
        total_before += before
        jpg = png.with_suffix(".jpg")
        try:
            with Image.open(png) as im:
                if im.mode in ("RGBA", "LA", "PA"):
                    bg = Image.new("RGB", im.size, (255, 255, 255))
                    bg.paste(im, mask=im.split()[-1])
                    im = bg
                elif im.mode != "RGB":
                    im = im.convert("RGB")
                if im.width > MAX_W:
                    h = round(im.height * MAX_W / im.width)
                    im = im.resize((MAX_W, h), Image.LANCZOS)
                im.save(jpg, "JPEG", quality=QUALITY, optimize=True)
            # Verifikasi JPG hasil.
            with Image.open(jpg) as check:
                check.verify()
            after = jpg.stat().st_size
            assert after > 0
        except Exception as e:  # noqa: BLE001 - tool manual, tampilkan saja
            print(f"GAGAL {png.name}: {e}")
            if jpg.exists():
                jpg.unlink()
            continue
        total_after += after
        converted[png.name] = jpg.name
        print(
            f"OK {png.name} {before / 1e6:.2f}MB -> "
            f"{jpg.name} {after / 1e6:.2f}MB"
        )

    # Update JSON yang merujuk PNG yang berhasil dikonversi.
    updated = 0
    for jf in sorted(JSON_DIR.glob("*.json")):
        if jf.name == "index.json":
            continue
        try:
            text = jf.read_text(encoding="utf-8")
            data = json.loads(text)
        except Exception as e:  # noqa: BLE001
            print(f"SKIP {jf.name}: JSON rusak ({e})")
            continue
        gambar = str(data.get("gambar", ""))
        changed = False
        for old, new in converted.items():
            ref_old = f"assets/img/{old}"
            if gambar == ref_old:
                data["gambar"] = f"assets/img/{new}"
                changed = True
        if changed:
            jf.write_text(
                json.dumps(data, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
            updated += 1

    # Hapus PNG lama yang sudah ada JPG terverifikasi.
    freed = 0
    for old, new in converted.items():
        png = IMG_DIR / old
        jpg = IMG_DIR / new
        if jpg.exists() and jpg.stat().st_size > 0:
            freed += png.stat().st_size
            png.unlink()

    print(f"\nGambar: {len(converted)} dikonversi, {updated} JSON diupdate.")
    print(
        f"Ukuran gambar: {total_before / 1e6:.1f}MB -> "
        f"{total_after / 1e6:.1f}MB "
        f"(hemat ~{(total_before - total_after) / 1e6:.1f}MB)."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
