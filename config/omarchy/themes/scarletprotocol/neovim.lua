return {
  {
    "bjarneo/aether.nvim",
    branch = "v3",
    name = "aether",
    priority = 1000,
    opts = {
      on_highlights = function(hl, c)
        -- Visual selection highlight in deep cyan with pure white text
        hl.Visual = { bg = c.selection, fg = c.selection_foreground, bold = true }
        hl.VisualNOS = { bg = c.selection, fg = c.selection_foreground, bold = true }

        -- Neo-tree directory colors in vibrant neon scarlet
        hl.NeoTreeDirectoryIcon = { fg = c.red }
        hl.NeoTreeDirectoryName = { fg = c.red, bold = true }
        hl.NeoTreeRootName = { fg = c.bright_red, bold = true }

        -- Line numbers and active cursor line in electric cyan
        hl.CursorLineNr = { fg = c.cyan, bold = true }
        hl.LineNr = { fg = c.muted }
      end,
      colors = {
        bg = "#2e0612",
        dark_bg = "#20040c",
        darker_bg = "#140208",
        lighter_bg = "#440a1c",

        fg = "#ffffff",
        dark_fg = "#966f80",
        light_fg = "#ffeaee",
        bright_fg = "#ffffff",
        muted = "#7a5868",

        red = "#ff2a6d",
        yellow = "#ffd700",
        orange = "#ff6238",
        green = "#00ff9c",
        cyan = "#00f0ff",
        blue = "#00a2ff",
        magenta = "#e580e5",
        brown = "#8b1e3f",

        bright_red = "#ff4d88",
        bright_yellow = "#ffff00",
        bright_green = "#00ffc8",
        bright_cyan = "#00f0ff",
        bright_blue = "#38bdf8",
        bright_magenta = "#f5a0ff",

        accent = "#00f0ff",
        cursor = "#00f0ff",
        foreground = "#ffffff",
        background = "#2e0612",
        selection = "#005968",
        selection_foreground = "#ffffff",
        selection_background = "#005968",
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "aether",
    },
  },
}
