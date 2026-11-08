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
grub-mkfont -n Maple -s @px16@ -r "$range" -o maple-16.pf2 "$regular"
grub-mkfont -n Maple -s @px20@ -r "$range" -o maple-20.pf2 "$regular"
grub-mkfont -n Maple -s @px48@ -r "$range" -o maple-bold-48.pf2 "$bold"

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

# pill name colour: 8px bar centred in the 28px GRUB gives every progress bar (at 1080p)
pill() {
  magick -size @px28@x@px28@ xc:none -fill "$2" -draw "roundrectangle 0,@px10@ $((@px28@ - 1)),@px17@ @px4@,@px4@" pill.png
  slice pill.png "$1" @px28@ @px10@
}

# menu panel, selected entry, countdown bar, scrollbar
# the selected box is drawn outside the item by its corner size
box panel @px96@ @px22@ "@mantle@d9" "@surface@" 2 @px24@
box select @px40@ @px10@ "@accent@33" "@accent@" 2 @px10@
# invisible, same border as select so every row is laid out alike
box item @px40@ @px10@ none none 0 @px10@
pill track "@surface@"
pill fill "@accent@"
box thumb @px12@ @px3@ "@muted@" none 0 @px3@

# background at the boot screen's size: diagonal gradient, dot grid, two-tone glowing snowflake, rainbow foot
magick -size @width@x@height@ -define gradient:angle=135 gradient:"@mantle@"-"@background@" bg.png
magick -size 32x32 xc:none -fill "@surface@" -draw "circle 16,16 17.2,16" dot.png
magick -size @width@x@height@ tile:dot.png -channel A -evaluate multiply 0.55 +channel grid.png

magick -background none -density 600 "@snowflake@" -resize @px760@x@px760@ \
  -channel RGB -colorspace gray -auto-level +level-colors "@blue@","@accent@" +channel flake.png
magick flake.png -background none -gravity center -extent @px1000@x@px1000@ \
  -channel A -evaluate multiply 0.6 +channel -blur 0x@px60@ glow.png
magick flake.png -channel A -evaluate multiply 0.12 +channel dim.png
magick flake.png -channel A -morphology EdgeIn Disk:2.5 -evaluate multiply 0.9 +channel edge.png

stripe=()
for c in "@red@" "@orange@" "@yellow@" "@green@" "@cyan@" "@blue@" "@purple@"; do
  stripe+=(xc:"$c")
done
magick -size 275x5 "${stripe[@]}" +append -resize '@width@x5!' stripe.png

# -geometry sticks, so every layer gets its own
magick bg.png \
  grid.png -geometry +0+0 -composite \
  glow.png -geometry +@px900@+@px40@ -composite \
  dim.png -geometry +@px1020@+@px160@ -composite \
  edge.png -geometry +@px1020@+@px160@ -composite \
  stripe.png -geometry +0+$((@height@ - 5)) -composite \
  png24:background.png
rm bg.png dot.png grid.png flake.png glow.png dim.png edge.png stripe.png

# icon class glyph colour: Nerd Font glyph, trimmed and centred in the icon box
icon() {
  magick -background none -fill "$3" -font "$regular" -pointsize 96 label:"$2" \
    -trim +repage -resize @px30@x@px30@ -gravity center -extent @px36@x@px36@ "PNG32:icons/$1.png"
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
