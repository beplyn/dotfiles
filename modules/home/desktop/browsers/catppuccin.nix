# Upstream Catppuccin Mocha files -> Stylix scheme; overrides get the same names via subst.
{ lib, subst, palette }:

let
  channels = hex: map (i: lib.fromHexString (builtins.substring i 2 (lib.removePrefix "#" hex))) [ 0 2 4 ];
  toHex = cs: "#" + lib.concatMapStrings (c: lib.fixedWidthString 2 "0" (lib.toLower (lib.toHexString c))) cs;

  # pct of a, rest of b, per channel
  mix = pct: a: b: toHex (lib.zipListsWith (x: y: (x * pct + y * (100 - pct)) / 100) (channels a) (channels b));

  p = palette;
  # base16 has nothing below background; mocha's own ratios
  colors = p //
  {
    shade = mix 80 p.background "#000000";
    crust = mix 57 p.background "#000000";
  };

  # every Mocha colour; ones base16 lacks are blends of their neighbours
  mocha = with colors;
  {
    "#f5e0dc" = bright; # rosewater
    "#f2cdcd" = brown; # flamingo
    "#f5c2e7" = mix 50 red purple; # pink
    "#cba6f7" = purple; # mauve
    "#f38ba8" = red;
    "#eba0ac" = mix 70 red bright; # maroon
    "#fab387" = orange; # peach
    "#f9e2af" = yellow;
    "#a6e3a1" = green;
    "#94e2d5" = cyan; # teal
    "#89dceb" = mix 50 cyan blue; # sky
    "#74c7ec" = mix 70 blue cyan; # sapphire
    "#89b4fa" = blue;
    "#b4befe" = brightest; # lavender
    "#cdd6f4" = foreground; # text
    "#bac2de" = mix 50 foreground subtext; # subtext1
    "#a6adc8" = subtext; # subtext0
    "#9399b2" = mix 67 subtext muted; # overlay2
    "#7f849c" = mix 33 subtext muted; # overlay1
    "#6c7086" = muted; # overlay0
    "#585b70" = mix 50 surface muted; # surface2
    "#45475a" = surface; # surface1
    "#313244" = mantle; # surface0
    "#1e1e2e" = background; # base
    "#181825" = shade; # mantle
    "#11111b" = crust;
  };
  from = lib.attrNames mocha ++ map lib.toUpper (lib.attrNames mocha);
  to = lib.attrValues mocha ++ lib.attrValues mocha;
in
{
  # upstream file, recoloured
  recolor = file: lib.replaceStrings from to (builtins.readFile file);
  # local overrides: @name@ placeholders from the palette (+ shade, crust)
  override = file: subst colors (builtins.readFile file);
}
