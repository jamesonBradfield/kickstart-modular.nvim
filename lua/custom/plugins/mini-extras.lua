return {
  {
    'echasnovski/mini.nvim',
    -- Optional: If you want to change loading behavior or dependencies
    -- Otherwise, just use the config function to initialize new modules
    config = function(_, opts)
      -- WARNING: ME NO LIKEY mini.jump2d!
      --
      -- The original kickstart config will run its own setups first (or alongside).
      -- You can safely initialize your extra modules here:
      -- require('mini.jump2d').setup {
      --   -- Out-of-the-box mappings:
      --   -- <Leader>j followed by a character to jump anywhere
      --   mappings = {
      --     start_jumping = '<leader>j',
      --   },
      -- }
      require('mini.icons').setup()
      require('mini.sessions').setup {
        autowrite = true,
        directory = vim.fn.stdpath 'data' .. '/sessions',
      }
      require('mini.surround').setup {
        mappings = {
          add = 'gza', -- Add surrounding in Normal and Visual modes
          delete = 'gzd', -- Delete surrounding
          find = 'gzf', -- Find surrounding (to the right)
          find_left = 'gzF', -- Find surrounding (to the left)
          highlight = 'gzh', -- Highlight surrounding
          replace = 'gzr', -- Replace surrounding
          update_n_lines = 'gzn', -- Update `n_lines`
        },
      }
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
      -- 1. Add this helper function somewhere before your autocommand
      local map_split = function(buf_id, lhs, direction)
        local rhs = function()
          -- Get the window that mini.files is currently targeting
          local cur_target = MiniFiles.get_explorer_state().target_window

          -- Create a new window in the specified direction from that target
          local new_target = vim.api.nvim_win_call(cur_target, function()
            vim.cmd(direction .. ' split')
            return vim.api.nvim_get_current_win()
          end)

          -- Set the new window as the destination and open the file
          MiniFiles.set_target_window(new_target)
          MiniFiles.go_in()
        end

        vim.keymap.set('n', lhs, rhs, { buffer = buf_id, desc = 'Split ' .. direction })
      end

      -- Automatically attach Grapple keymap when mini.files opens
      vim.api.nvim_create_autocmd('User', {
        pattern = 'MiniFilesBufferCreate',
        callback = function(args)
          local buf_id = args.data.buf_id

          -- Add the split keymaps (change <C-v> and <C-x> to whatever you prefer)
          map_split(buf_id, '<C-v>', 'belowright vertical')
          map_split(buf_id, '<C-x>', 'belowright horizontal')
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
      -- Force clean UTF-8 + LF for IWE notes, regardless of how the file gets written
      vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
        pattern = '*.md',
        callback = function(args)
          local name = vim.api.nvim_buf_get_name(args.buf):gsub('\\', '/')
          if name:match '/notes/' then
            vim.bo[args.buf].fileencoding = 'utf-8'
            vim.bo[args.buf].fileformat = 'unix'
          end
        end,
      })

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
    end,
  },
}
