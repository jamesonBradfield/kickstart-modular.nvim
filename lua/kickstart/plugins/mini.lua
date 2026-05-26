---@module 'lazy'
---@type LazySpec
return {
  { -- Collection of various small independent plugins/modules
    'nvim-mini/mini.nvim',
    init = function()
      if vim.fn.argc() > 0 then
        local arg = vim.fn.argv(0)
        if vim.fn.isdirectory(arg) == 1 then require('lazy').load { plugins = { 'mini.nvim' } } end
      end
    end,
    config = function()
      -- Custom filter to hide Godot sidecar files
      local filter_hide_godot = function(fs_entry) return not vim.endswith(fs_entry.name, '.uid') and not vim.endswith(fs_entry.name, '.import') end

      require('mini.files').setup {
        content = {
          filter = filter_hide_godot,
        },
        windows = {
          preview = true,
          width_focus = 30,
          width_preview = 50,
        },
        options = {
          use_as_default_explorer = true,
        },
      }

      -- Automatically attach Grapple keymap when mini.files opens
      vim.api.nvim_create_autocmd('User', {
        pattern = 'MiniFilesBufferCreate',
        callback = function(args)
          local buf_id = args.data.buf_id

          -- Use <leader>m to match your global Grapple toggle key
          vim.keymap.set('n', '<leader>m', function()
            local entry = MiniFiles.get_fs_entry()

            -- Only toggle tags for actual files, not directories
            if entry and entry.fs_type == 'file' then
              require('grapple').toggle { path = entry.path }
              vim.notify('Toggled Grapple tag: ' .. entry.name)
            end
          end, { buffer = buf_id, desc = 'Grapple toggle tag (mini.files)' })
        end,
      })
      -- Better Around/Inside textobjects
      --
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yiiq - [Y]ank [I]nside [I]+1 [Q]uote
      --  - ci'  - [C]hange [I]nside [']quote
      require('mini.ai').setup {
        -- NOTE: Avoid conflicts with the built-in incremental selection mappings on Neovim>=0.12 (see `:help treesitter-incremental-selection`)
        mappings = {
          around_next = 'aa',
          inside_next = 'ii',
        },
        n_lines = 500,
      }

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      --
      -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      -- - sd'   - [S]urround [D]elete [']quotes
      -- - sr)'  - [S]urround [R]eplace [)] [']
      require('mini.surround').setup()
      require('mini.pick').setup {
        mappings = {
          -- Alternate navigation keys (like Telescope/fzf-lua style)
          move_down_j = {
            char = '<C-j>',
            func = function()
              local pick = require 'mini.pick'
              local matches = pick.get_picker_matches()
              if not matches or not matches.all_inds then return end
              local n = #matches.all_inds
              if n == 0 then return end
              local cur = matches.current_ind or 1
              local next = cur + 1
              if next > n then next = 1 end
              pick.set_picker_match_inds({ matches.all_inds[next] }, 'current')
            end,
          },
          move_up_k = {
            char = '<C-k>',
            func = function()
              local pick = require 'mini.pick'
              local matches = pick.get_picker_matches()
              if not matches or not matches.all_inds then return end
              local n = #matches.all_inds
              if n == 0 then return end
              local cur = matches.current_ind or 1
              local prev = cur - 1
              if prev < 1 then prev = n end
              pick.set_picker_match_inds({ matches.all_inds[prev] }, 'current')
            end,
          },
        },

        window = {
          -- VSCode-style centered picker (command palette look)
          config = function()
            local width = math.floor(0.55 * vim.o.columns)
            local height = math.floor(0.35 * vim.o.lines)
            return {
              relative = 'editor',
              anchor = 'NW',
              width = width,
              height = height,
              row = 2,
              col = math.floor(0.5 * (vim.o.columns - width)),
              border = 'rounded',
            }
          end,
        },
      }
      -- Simple and easy statusline.
      --  You could remove this setup call if you don't like it,
      --  and try some other statusline plugin
      local statusline = require 'mini.statusline'
      -- set use_icons to true if you have a Nerd Font
      statusline.setup { use_icons = vim.g.have_nerd_font }

      -- You can configure sections in the statusline by overriding their
      -- default behavior. For example, here we set the section for
      -- cursor location to LINE:COLUMN
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function() return '%2l:%-2v' end

      -- ... and there is more!
      --  Check out: https://github.com/nvim-mini/mini.nvim
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
