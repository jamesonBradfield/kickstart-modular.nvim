-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set({ 'n', 'v' }, '<C-f>', function()
  local mf = require 'mini.files'
  -- Toggle logic: if it's open, close it. If closed, open to current buffer's directory.
  if not mf.close() then mf.open(vim.api.nvim_buf_get_name(0)) end
end, { desc = 'Toggle mini.files' })
vim.keymap.set({ 'n', 'v' }, '<leader>sh', function() require('mini.pick').builtin.help() end, { desc = 'Search Help' })
vim.keymap.set({ 'n', 'v' }, '<leader>sc', function() require('mini.files').open(vim.fn.stdpath 'config') end, { desc = 'Search Config' })
vim.keymap.set({ 'n', 'v' }, '<leader>sn', function() require('mini.files').open(vim.fn.expand '~/notes/') end, { desc = 'Search Notes' })
-- [[ Scratch Buffer for Notes ]]
vim.keymap.set('n', '<leader>bs', function()
  vim.cmd 'enew' -- Open a new empty buffer
  vim.bo.filetype = 'markdown' -- Set filetype so IWE/CodeCompanion engage immediately
  vim.bo.swapfile = false -- Don't create a swapfile for a temporary scratchpad
end, { desc = 'Open [B]uffer [S]cratch (Markdown)' })
vim.keymap.set({ 'n', 'v' }, '<leader>cc', function() require('codecompanion').toggle() end, { desc = 'Toggle CodeCompanion' })
vim.keymap.set({ 'n', 'v' }, '<leader>ca', '<cmd>CodeCompanionActions<CR>', { desc = 'CodeCompanion actions' })
-- Diagnostic Config & Keymaps
-- See :help vim.diagnostic.Opts
vim.diagnostic.config {
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = { min = vim.diagnostic.severity.WARN } },

  -- Can switch between these as you prefer
  virtual_text = true, -- Text shows up at the end of the line
  virtual_lines = false, -- Text shows up underneath the line, with virtual lines

  -- Auto open the float, so you can easily read the errors when jumping with `[d` and `]d`
  jump = { float = true },
}

vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- [[ Web Dev Server Keymaps ]]
-- Quickly start/restart a Vite dev server (React / vanilla JS/TS)
-- Opens a terminal split at the bottom running `npm run dev`
-- If one is already running, it will be toggled instead of duplicated.
--
-- Usage:
--   <leader>sv  — start Vite dev server
--   <leader>sa  — start Angular CLI dev server
--   <leader>sk  — kill any running dev server (sends SIGTERM)
--
local dev_server_buf = nil
local dev_server_win = nil

local function start_dev_server(cmd, name)
  -- If the terminal is already open, just focus it
  if dev_server_win and vim.api.nvim_win_is_valid(dev_server_win) then
    vim.api.nvim_set_current_win(dev_server_win)
    vim.notify('Dev server (' .. name .. ') is already running', vim.log.levels.INFO)
    return
  end

  -- Open a new terminal at the bottom (10 rows tall)
  vim.cmd 'botright 10 split'
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, buf)
  dev_server_win = vim.api.nvim_get_current_win()
  dev_server_buf = buf

  -- Start the terminal with the dev server command
  vim.fn.termopen(cmd, {
    on_exit = function()
      -- Clean up references when the terminal exits
      dev_server_buf = nil
      dev_server_win = nil
    end,
  })

  -- Start in insert mode so you see output immediately
  vim.cmd 'startinsert'
  vim.notify('Started ' .. name .. ' dev server', vim.log.levels.INFO)
end

vim.keymap.set('n', '<leader>sv', function()
  start_dev_server('npm run dev', 'Vite')
end, { desc = 'Start [V]ite dev server (npm run dev)' })

vim.keymap.set('n', '<leader>sa', function()
  start_dev_server('ng serve', 'Angular')
end, { desc = 'Start [A]ngular dev server (ng serve)' })

vim.keymap.set('n', '<leader>sk', function()
  if dev_server_buf and vim.api.nvim_buf_is_valid(dev_server_buf) then
    -- Send SIGTERM (Ctrl+C) to the running process
    vim.api.nvim_chan_send(vim.bo[dev_server_buf].channel, '\03')
    -- Close the terminal window after a short delay
    vim.defer_fn(function()
      if dev_server_win and vim.api.nvim_win_is_valid(dev_server_win) then
        vim.api.nvim_win_close(dev_server_win, true)
      end
      dev_server_buf = nil
      dev_server_win = nil
      vim.notify('Dev server stopped', vim.log.levels.INFO)
    end, 500)
  else
    vim.notify('No dev server is running', vim.log.levels.WARN)
  end
end, { desc = '[K]ill dev server (SIGTERM + close terminal)' })


-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
-- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
-- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
-- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
-- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

-- vim: ts=2 sts=2 sw=2 et
