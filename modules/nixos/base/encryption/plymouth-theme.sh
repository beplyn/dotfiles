# Plymouth theme images in $dir; @name@ comes from plymouth-theme.nix
set -eu
# $'\uXXXX' below needs a UTF-8 locale
export LC_ALL=C.UTF-8
dir="$out/share/plymouth/themes/palette"
mkdir -p "$dir"
cd "$dir"

# background: diagonal gradient, dot grid, rainbow foot (as in the GRUB theme)
magick -size 1920x1080 -define gradient:angle=135 gradient:"@mantle@"-"@background@" bg.png
magick -size 32x32 xc:none -fill "@surface@" -draw "circle 16,16 17.2,16" dot.png
stripe=()
for c in "@red@" "@orange@" "@yellow@" "@green@" "@cyan@" "@blue@" "@purple@"; do
  stripe+=(xc:"$c")
done
magick -size 275x5 "${stripe[@]}" +append -resize '1920x5!' stripe.png
magick bg.png \
  \( -size 1920x1080 tile:dot.png -channel A -evaluate multiply 0.55 +channel \) -geometry +0+0 -composite \
  stripe.png -geometry +0+1075 -composite \
  png24:background.png
rm bg.png dot.png stripe.png

# snowflake: two-tone fill with a bright edge, and a separate glow that pulses
magick -background none -density 600 "@snowflake@" -resize 300x300 \
  -channel RGB -colorspace gray -auto-level +level-colors "@blue@","@accent@" +channel flake.png
magick flake.png -background none -gravity center -extent 460x460 \
  -channel A -evaluate multiply 0.8 +channel -blur 0x28 PNG32:glow.png
magick flake.png \
  \( +clone -channel A -evaluate multiply 0.22 +channel \) \
  \( -clone 0 -channel A -morphology EdgeIn Disk:1.5 +channel \) \
  -delete 0 -compose over -composite PNG32:logo.png
rm flake.png

# one dot per palette colour: spinner and passphrase bullets
i=0
for c in "@red@" "@orange@" "@yellow@" "@green@" "@cyan@" "@blue@" "@purple@"; do
  magick -size 28x28 xc:none -fill "$c" -draw "circle 14,14 14,4" -resize 14x14 "PNG32:dot-$i.png"
  i=$((i + 1))
done

# passphrase box and lock
magick -size 520x60 xc:none -fill "@mantle@e6" -stroke "@surface@" -strokewidth 2 \
  -draw "roundrectangle 1,1 518,58 16,16" PNG32:box.png
magick -background none -fill "@accent@" -font "@fontFile@" -pointsize 160 label:$'' \
  -trim +repage -resize 40x40 PNG32:lock.png

cp "@script@" palette.script
cat > palette.plymouth <<EOF
[Plymouth Theme]
Name=palette
Description=Palette-built unlock screen
ModuleName=script

[script]
ImageDir=$dir
ScriptFile=$dir/palette.script
EOF
