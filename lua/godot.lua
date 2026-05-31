-- ~/AppData/Local/nvim/lua/godot.lua
--
-- Everything about "a file just came in from Godot" lives here. The PowerShell
-- stub only ever calls _G.GodotOpen(path, line, col) -- so this is the only
-- file you tweak. Add `require("godot")` near the top of your init.lua.

local M = {}

-- The GlazeWM workspace your editor WezTerm lives on (see the config.yaml rule).
M.workspace = '9'

-- Bring the editor to the front. Neovim 0.10+ has vim.system; on older versions
-- replace the body with: vim.fn.jobstart({ "glazewm", "command", "focus", "--workspace", M.workspace })
local function focus_editor()
  -- pcall(vim.system, { 'glazewm', 'command', 'focus', '--workspace', M.workspace })
end

function _G.GodotOpen(path, line, col)
  line = tonumber(line) or 0
  col = tonumber(col) or 1

  -- Open the file (or switch to it if it's already a buffer). Forward slashes
  -- from Godot are fine for nvim on Windows. fnameescape handles spaces.
  vim.cmd('edit ' .. vim.fn.fnameescape(path))

  -- Godot 4.6.x sometimes fires a second call with line = -1; ignore the jump then.
  if line > 0 then
    pcall(vim.api.nvim_win_set_cursor, 0, { line, math.max(col - 1, 0) })
    vim.cmd 'normal! zz' -- center the cursor line; delete if unwanted
  end

  focus_editor() -- comment out to stop focus-stealing
end

return M
