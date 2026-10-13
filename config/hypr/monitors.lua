-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Managed by im0001gt.screens (Screens bar panel).

local omarchy_gdk_scale = 1
hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- BEGIN im0001gt.screens
hl.monitor({ output = "desc:ASUSTek COMPUTER INC VG32WQ3B T1LMTF147439", mode = "2560x1440@180.00", position = "0x277", scale = 1, vrr = 3, bitdepth = 10, supports_hdr = 1 })
hl.monitor({ output = "desc:CMT GA241 CMI232000319", mode = "1920x1080@100.00", position = "2560x0", scale = 1, transform = 3, vrr = 0 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
hl.config({ misc = { vrr = 3 }, render = { cm_auto_hdr = 2 } })
hl.workspace_rule({ workspace = "1", monitor = "desc:ASUSTek COMPUTER INC VG32WQ3B T1LMTF147439", persistent = true, default = true })
hl.workspace_rule({ workspace = "3", monitor = "desc:ASUSTek COMPUTER INC VG32WQ3B T1LMTF147439", persistent = true })
hl.workspace_rule({ workspace = "5", monitor = "desc:ASUSTek COMPUTER INC VG32WQ3B T1LMTF147439", persistent = true })
hl.workspace_rule({ workspace = "7", monitor = "desc:ASUSTek COMPUTER INC VG32WQ3B T1LMTF147439", persistent = true })
hl.workspace_rule({ workspace = "9", monitor = "desc:ASUSTek COMPUTER INC VG32WQ3B T1LMTF147439", persistent = true })
hl.workspace_rule({ workspace = "2", monitor = "desc:CMT GA241 CMI232000319", persistent = true, default = true })
hl.workspace_rule({ workspace = "4", monitor = "desc:CMT GA241 CMI232000319", persistent = true })
hl.workspace_rule({ workspace = "6", monitor = "desc:CMT GA241 CMI232000319", persistent = true })
hl.workspace_rule({ workspace = "8", monitor = "desc:CMT GA241 CMI232000319", persistent = true })
hl.workspace_rule({ workspace = "10", monitor = "desc:CMT GA241 CMI232000319", persistent = true })
-- END im0001gt.screens
