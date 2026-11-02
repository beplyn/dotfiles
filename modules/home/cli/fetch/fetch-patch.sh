# labels: no colon, no forced colour
sed -i 's/"\\033\[1;%sm%s\\033\[0m: %s"/"%.0s%s  %s"/g' fetch.c

# drop the title and separator
substituteInPlace fetch.c \
  --replace 'static void gather_title(void) {' \
            'static void gather_title(void) { return;'

# user@host above OS
substituteInPlace fetch.c \
  --replace 'add_info("OS", "%s %s", pretty, u.machine);' \
            'char u_n[64] = ""; char *l = getlogin(); if (l) strncpy(u_n, l, 63); else { char *e = getenv("USER"); if (e) strncpy(u_n, e, 63); } char h_n[64] = ""; gethostname(h_n, sizeof(h_n)); add_info("@purple@╭─@reset@", "%s@%s", u_n, h_n); add_info("OS", "%s %s", pretty, u.machine);'

# disk: glyph instead of "Disk (/)"
substituteInPlace fetch.c \
  --replace 'snprintf(label, sizeof(label), "Disk (%s)", path);' \
            'snprintf(label, sizeof(label), "%s", "@yellow@├─@reset@");'

# glyph labels
substituteInPlace fetch.c \
  --replace 'add_info("Host"'      'add_info("@blue@╭─󰌢@reset@"' \
  --replace 'add_info("CPU"'       'add_info("@cyan@├─󰻠@reset@"' \
  --replace 'add_info("GPU"'       'add_info("@green@├─󰍛@reset@"' \
  --replace 'add_info("Memory"'    'add_info("@orange@╰─󰑭@reset@"' \
  --replace 'add_info("Shell"'     'add_info("@green@╭─@reset@"' \
  --replace 'add_info("Terminal"'  'add_info("@cyan@├─@reset@"' \
  --replace 'add_info("WM"'        'add_info("@brown@╰─@reset@"' \
  --replace 'add_info("OS"'        'add_info("@blue@├─@reset@"' \
  --replace 'add_info("Kernel"'    'add_info("@cyan@├─@reset@"' \
  --replace 'add_info("Packages"'  'add_info("@green@├─󰏖@reset@"' \
  --replace 'add_info("Uptime"'    'add_info("@orange@╰─󰅐@reset@"'
