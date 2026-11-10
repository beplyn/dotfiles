-- ReGreet's compositor; @name@ comes from default.nix.
-- Only the primary output: cage stretched the greeter over every monitor.
@monitors@

hl.config({
    input = {
        kb_layout = "@layout@",
    },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
        -- greetd starts Hyprland itself, not through start-hyprland
        disable_watchdog_warning = true,
        disable_autoreload = true,
    },
    ecosystem = {
        no_update_news = true,
        no_donation_nag = true,
    },
    animations = {
        enabled = false,
    },
    xwayland = {
        enabled = false,
    },
})

hl.on("hyprland.start", function()
    hl.exec_cmd("@regreet@; @hyprctl@ dispatch 'hl.dsp.exit()'")
end)
