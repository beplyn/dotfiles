# GRUB theme assets in $out; @name@ comes from grub-theme.nix
# GRUB only reads 8-bit RGB(A) PNGs: slices and icons are forced to PNG32
set -eu
# $'\uXXXX' below needs a UTF-8 locale
export LC_ALL=C.UTF-8
mkdir -p "$out/icons"
cd "$out"

font() {
  find "@fontDir@" -name "*-$1.ttf" | sort | head -n1
}
regular="$(font Regular)"
bold="$(font Bold)"
bold="${bold:-$regular}"

# ascii, latin-1, arrows, bullets: the whole font would take seconds to load
range=0x20-0x7E,0xA0-0xFF,0x2190-0x21FF,0x2022-0x2022
grub-mkfont -n Maple -s 16 -r "$range" -o maple-16.pf2 "$regular"
grub-mkfont -n Maple -s 20 -r "$range" -o maple-20.pf2 "$regular"
grub-mkfont -n Maple -s 48 -r "$range" -o maple-bold-48.pf2 "$bold"

# slice file name size corner: cut a square image into GRUB's nine styled-box parts
slice() {
  local f=$1 name=$2 s=$3 c=$4
  local m=$((s - 2 * c)) far=$((s - c))
  magick "$f" -crop "${c}x${c}+0+0" +repage "PNG32:${name}_nw.png"
  magick "$f" -crop "${m}x${c}+${c}+0" +repage "PNG32:${name}_n.png"
  magick "$f" -crop "${c}x${c}+${far}+0" +repage "PNG32:${name}_ne.png"
  magick "$f" -crop "${c}x${m}+0+${c}" +repage "PNG32:${name}_w.png"
  magick "$f" -crop "${m}x${m}+${c}+${c}" +repage "PNG32:${name}_c.png"
  magick "$f" -crop "${c}x${m}+${far}+${c}" +repage "PNG32:${name}_e.png"
  magick "$f" -crop "${c}x${c}+0+${far}" +repage "PNG32:${name}_sw.png"
  magick "$f" -crop "${m}x${c}+${c}+${far}" +repage "PNG32:${name}_s.png"
  magick "$f" -crop "${c}x${c}+${far}+${far}" +repage "PNG32:${name}_se.png"
  rm "$f"
}

# box name size radius fill stroke strokewidth corner: rounded rect, sliced
box() {
  local name=$1 s=$2 r=$3 fill=$4 stroke=$5 w=$6 c=$7
  local lo=$((w / 2)) hi=$((s - 1 - w / 2))
  magick -size "${s}x${s}" xc:none -fill "$fill" -stroke "$stroke" -strokewidth "$w" \
    -draw "roundrectangle $lo,$lo $hi,$hi $r,$r" box.png
  slice box.png "$name" "$s" "$c"
}

# pill name colour: 8px bar centred in the 28px GRUB gives every progress bar
pill() {
  magick -size 28x28 xc:none -fill "$2" -draw "roundrectangle 0,10 27,17 4,4" pill.png
  slice pill.png "$1" 28 10
}

# menu panel, selected entry, countdown bar, scrollbar
# the selected box is drawn outside the item by its corner size
box panel 96 22 "@mantle@d9" "@surface@" 2 24
box select 40 10 "@accent@33" "@accent@" 2 10
# invisible, same border as select so every row is laid out alike
box item 40 10 none none 0 10
pill track "@surface@"
pill fill "@accent@"
box thumb 12 3 "@muted@" none 0 3

# background: diagonal gradient, dot grid, two-tone glowing snowflake, rainbow foot
magick -size 1920x1080 -define gradient:angle=135 gradient:"@mantle@"-"@background@" bg.png
magick -size 32x32 xc:none -fill "@surface@" -draw "circle 16,16 17.2,16" dot.png
magick -size 1920x1080 tile:dot.png -channel A -evaluate multiply 0.55 +channel grid.png

magick -background none -density 600 "@snowflake@" -resize 760x760 \
  -channel RGB -colorspace gray -auto-level +level-colors "@blue@","@accent@" +channel flake.png
magick flake.png -background none -gravity center -extent 1000x1000 \
  -channel A -evaluate multiply 0.6 +channel -blur 0x60 glow.png
magick flake.png -channel A -evaluate multiply 0.12 +channel dim.png
magick flake.png -channel A -morphology EdgeIn Disk:2.5 -evaluate multiply 0.9 +channel edge.png

stripe=()
for c in "@red@" "@orange@" "@yellow@" "@green@" "@cyan@" "@blue@" "@purple@"; do
  stripe+=(xc:"$c")
done
magick -size 275x5 "${stripe[@]}" +append -resize '1920x5!' stripe.png

# -geometry sticks, so every layer gets its own
magick bg.png \
  grid.png -geometry +0+0 -composite \
  glow.png -geometry +900+40 -composite \
  dim.png -geometry +1020+160 -composite \
  edge.png -geometry +1020+160 -composite \
  stripe.png -geometry +0+1075 -composite \
  png24:background.png
rm bg.png dot.png grid.png flake.png glow.png dim.png edge.png stripe.png

# icon class glyph colour: Nerd Font glyph, trimmed and centred in 36px
icon() {
  magick -background none -fill "$3" -font "$regular" -pointsize 96 label:"$2" \
    -trim +repage -resize 30x30 -gravity center -extent 36x36 "PNG32:icons/$1.png"
}
icon nixos      $'\uf313' "@blue@"
icon submenu    $'\uf1da' "@muted@"
icon efi        $'\uf287' "@green@"
icon windows    $'\uf17a' "@cyan@"
icon gnu-linux  $'\uf31a' "@yellow@"
icon linux      $'\uf31a' "@yellow@"
icon os         $'\uf31a' "@yellow@"
icon arch       $'\uf303' "@blue@"
icon debian     $'\uf306' "@red@"
icon ubuntu     $'\uf31b' "@orange@"
icon fedora     $'\uf30a' "@blue@"
icon manjaro    $'\uf312' "@green@"
icon opensuse   $'\uf314' "@green@"
icon gentoo     $'\uf30d' "@purple@"
icon macosx     $'\uf179' "@foreground@"

cp "@themeTxt@" theme.txt
