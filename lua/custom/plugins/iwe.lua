return {
  {
    'iwe-org/iwe.nvim',
    dependencies = {
      -- At least one picker recommended (any of these):
      -- 'nvim-telescope/telescope.nvim',
      -- 'ibhagwan/fzf-lua',
      -- 'folke/snacks.nvim',
      'echasnovski/mini.pick',
    },
    config = function()
      require('iwe').setup {
        lsp = {
          cmd = { 'iwes.exe' },
          -- Force the LSP to treat ~/notes as the workspace root
          root_dir = function() return vim.fn.expand 'C:/Users/mcraf/notes' end,
        },

        telescope = {
          enabled = false,
          setup_config = false,
          load_extensions = { 'ui-select', 'emoji' },
        },
        preview = {
          output_dir = 'C:/Users/mcraf/notes/.preview', -- Tell it exactly where to go
        },
      }
    end,
  },
}
