#!/usr/bin/env bash
# Converts the app's generated images/videos into small web assets in website/public/media.
# Needs: cwebp, ffmpeg. Run from anywhere: website/tools/optimize-assets.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/website/public/media"
mkdir -p "$OUT/halloween" "$OUT/christmas" "$OUT/trends" "$OUT/screens" "$OUT/video"

webp() { # src dst width quality
  cwebp -quiet -q "${4:-72}" -resize "$3" 0 -metadata none "$1" -o "$2"
}
slug() { basename "$1" | sed -E 's/\.[a-z]+$//; s/[^A-Za-z0-9]+/_/g' | tr 'A-Z' 'a-z'; }

for dir in image-to-image text-to-image; do
  for f in "$ROOT"/assets/images/haloween/$dir/*; do
    case "$(slug "$f")" in ngvd*) continue;; esac
    webp "$f" "$OUT/halloween/$(slug "$f").webp" 420
  done
  for f in "$ROOT"/assets/images/christmas/$dir/*; do
    webp "$f" "$OUT/christmas/$(slug "$f").webp" 420
  done
done
for f in "$ROOT"/store_screenshots/trends_src/*.jpg; do
  webp "$f" "$OUT/trends/$(slug "$f").webp" 560 74
done
i=1; for f in "$ROOT"/store_screenshots/ios_1242x2688_v2/*.png; do
  webp "$f" "$OUT/screens/$(slug "$f").webp" 420 76; i=$((i+1))
done

# Photo-to-video: still (before) + silent looping clip (after)
for n in blackcat telephone; do
  src="$ROOT/assets/images/haloween/image-to-video/$n"
  webp "$src.jpg" "$OUT/video/$n.webp" 560 76
  ffmpeg -loglevel error -y -i "$src.mp4" -an -vf scale=560:-2 -c:v libx264 -profile:v high -crf 27 -preset slow -pix_fmt yuv420p -movflags +faststart "$OUT/video/$n.mp4"
  ffmpeg -loglevel error -y -i "$src.mp4" -an -vf scale=560:-2 -c:v libvpx-vp9 -crf 38 -b:v 0 -row-mt 1 "$OUT/video/$n.webm"
done

# Icons
cwebp -quiet -q 85 -resize 256 0 "$ROOT/assets/icons/app_icon.png" -o "$OUT/icon.webp"
cwebp -quiet -q 85 -resize 256 0 "$ROOT/assets/icons/app_icon_christmas.png" -o "$OUT/icon_christmas.webp"
sips -s format png -z 180 180 "$ROOT/assets/icons/app_icon.png" --out "$ROOT/website/public/apple-touch-icon.png" >/dev/null
sips -s format png -z 48 48 "$ROOT/assets/icons/app_icon.png" --out "$ROOT/website/public/favicon.png" >/dev/null

# Open Graph card 1200x630 from the store header art
ffmpeg -loglevel error -y -i "$ROOT/store_screenshots/header/spookyai_header_3840x1646.png" \
  -vf "scale=1200:-2,pad=1200:630:0:(oh-ih)/2:color=0x0F0B1A" -q:v 4 "$ROOT/website/public/og-image.jpg"
du -sh "$OUT" "$ROOT/website/public/og-image.jpg"

# Before/after: the selfie used as input for two image-to-image styles, all cropped to 4:5
mkdir -p "$OUT/compare"; TMP="$(mktemp -d)"
ffmpeg -loglevel error -y -i "$ROOT/assets/images/boy.jpeg" -vf "crop=720:900:0:(ih-900)/3,scale=600:750" "$TMP/selfie.png"
ffmpeg -loglevel error -y -i "$ROOT/assets/images/haloween/image-to-image/vampire_noble.png" -vf "crop=720:900:0:(ih-900)/3,scale=600:750" "$TMP/vampire.png"
ffmpeg -loglevel error -y -i "$ROOT/assets/images/christmas/image-to-image/winter_royalty.jpg" -vf "crop=652:816:(iw-652)/2:0,scale=600:750" "$TMP/winter.png"
for n in selfie vampire winter; do cwebp -quiet -q 76 "$TMP/$n.png" -o "$OUT/compare/$n.webp"; done
rm -rf "$TMP"
