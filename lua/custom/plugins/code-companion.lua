return {
  'olimorris/codecompanion.nvim',
  branch = 'main',
  enabled = true,
  lazy = false,
  dependencies = { 'nvim-lua/plenary.nvim', 'nvim-treesitter/nvim-treesitter', 'ravitemer/codecompanion-history.nvim' },
  opts = {
    log_level = 'ERROR',
    adapters = {
      deepseek = function()
        return require('codecompanion.adapters').extend('deepseek', {
          env = {
            api_key = "cmd:printenv DEEPSEEK_API_KEY | tr -d '\\r\\n '",
          },
        })
      end,
    },
    interactions = {
      chat = { adapter = { name = 'deepseek', model = 'deepseek-chat' } },
      inline = { adapter = { name = 'deepseek', model = 'deepseek-chat' } },
    },
    mcp = {
      servers = {
        iwe = {
          cmd = { 'iwec' },
        },
      },
      opts = {
        default_servers = { 'iwe' },
      },
    },
    display = { action_palette = { provider = 'default' } }, -- or remove the line
    extensions = {
      history = {
        enabled = true,
        opts = {
          dir_to_save = vim.fn.stdpath 'data' .. '/codecompanion_chats.json',
        },
      },
    },
  },
}
