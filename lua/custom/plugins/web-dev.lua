return {
  --[[
    peek.nvim — Live markdown preview in your browser.
    Great for previewing READMEs, documentation, or any Markdown file
    while you edit it. Opens in your default browser and auto-updates
    as you type (on BufWrite).
  ]]
  {
    'toppair/peek.nvim',
    event = { 'VeryLazy' },
    build = 'deno task --quiet build',
    ---@type PeekConfig
    opts = {
      filetype = { 'markdown' },
      theme = 'dark',
      update_on_change = true,
      auto_close = false,
    },
    keys = {
      {
        '<leader>P',
        function()
          local peek = require 'peek'
          if peek.is_open() then peek.close() else peek.open() end
        end,
        desc = '[P]eek: toggle markdown preview',
      },
    },
    -- Also set up convenient defaults for web-dev filetypes
    init = function()
      local group = vim.api.nvim_create_augroup('WebDevHelpers', { clear = true })
      vim.api.nvim_create_autocmd('FileType', {
        group = group,
        pattern = {
          'javascript', 'typescript',
          'javascriptreact', 'typescriptreact',
          'css', 'scss', 'html',
        },
        callback = function(args)
          vim.bo[args.buf].shiftwidth = 2
          vim.bo[args.buf].tabstop = 2
          vim.bo[args.buf].softtabstop = 2
          vim.bo[args.buf].expandtab = true
        end,
      })
    end,
  },
}
