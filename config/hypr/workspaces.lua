-- Associates workspaces with monitors by parity:
--   odd  (1, 3, 5, 7, 9)   -> DP-1      (ASUS VG32WQ3B, principal)
--   even (2, 4, 6, 8, 10)  -> HDMI-A-1  (CMT GA241, secundario en vertical)
--
-- monitor = "<name>" binds the workspace; persistent = true keeps it created and
-- re-homed on that monitor after reloads and replugs. default = true makes each
-- monitor start on its first assigned workspace.
--
-- Revert: delete this file and remove the `require("hypr.workspaces")` line
-- from ~/.config/hypr/hyprland.lua, then `hyprctl reload`.

local primary = "DP-1"
local secondary = "HDMI-A-1"
local last = 10

for id = 1, last do
  hl.workspace_rule({
    workspace = tostring(id),
    monitor = (id % 2 == 1) and primary or secondary,
    persistent = true,
    default = (id == 1 or id == 2),
  })
end
