-- Final overrides: loaded last in hyprland.lua so they win over Omarchy
-- defaults, the current theme (e.g. Aether-generated), and other user files.

-- Steam scaling override (match 100% desktop scale)
hl.env("STEAM_FORCE_DESKTOPUI_SCALING", "1.0")

-- Blur on for windows and layers (Omarchy ships it disabled).
hl.config({
  decoration = {
    active_opacity = 1.0,
    inactive_opacity = 1.0,
    blur = { enabled = true },
  },
})

-- All windows at 90% opacity (10% transparent), active and inactive.
-- "override" sets the value absolutely instead of multiplying it with
-- global opacity settings, and this rule comes after every app-specific one.
o.window(".*", { opacity = "0.9 override 0.9 override", no_blur = false })

-- Bar flyouts (calendar, tray, media...) blur too: xdg-popups of the bar
-- and the standalone panel layers. Their 90% alpha lives in omarchy/shell.toml.
hl.layer_rule({ match = { namespace = "omarchy-bar" }, blur = true, blur_popups = true, ignore_alpha = 0.1 })
hl.layer_rule({ match = { namespace = "^(omarchy-keyboard-panel|omarchy-menu)$" }, blur = true, ignore_alpha = 0.1 })

-- World of Warcraft: pantalla completa fija, sin perder fullscreen por eventos o foco,
-- asignado al monitor principal (workspace 1), opacidad 100% y renderizado continuo.
o.window({ class = "^steam_app_battlenet$", title = ".*World of Warcraft.*" }, {
  fullscreen = true,
  workspace = "1",
  suppress_event = "fullscreen maximize",
  idle_inhibit = "always",
  render_unfocused = true,
  opacity = "1.0 override 1.0 override",
  no_blur = true,
  no_shadow = true,
})

-- Cyberpunk 2077: pantalla completa en el monitor principal (workspace 1), sin
-- transparencia. Sin esto la ventana del juego aparecía flotando fuera de pantalla.
o.window({ class = "^steam_app_1091500$", title = "^Cyberpunk 2077.*" }, {
  fullscreen = true,
  workspace = "1",
  suppress_event = "fullscreen maximize",
  idle_inhibit = "always",
  opacity = "1.0 override 1.0 override",
  no_blur = true,
})
