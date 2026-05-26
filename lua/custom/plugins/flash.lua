return {
  -- Flash
  'folke/flash.nvim',
  event = 'VeryLazy',
  opts = {
    modes = {
      search = {
        enabled = false,
      },
    },
  },
  config = function(_, opts)
    require('flash').setup(opts)
    -- Prevent flash from attaching to mini.files or checkhealth
    vim.api.nvim_create_autocmd('FileType', {
      pattern = { 'minifiles', 'checkhealth' },
      callback = function() vim.b.flash_enabled = false end,
    })
  end,
  keys = {
    { 's', mode = { 'n', 'x', 'o' }, function() require('flash').jump() end, desc = 'Flash' },
    { 'S', mode = { 'n', 'x', 'o' }, function() require('flash').treesitter() end, desc = 'Flash Treesitter' },
    { 'r', mode = 'o', function() require('flash').remote() end, desc = 'Remote Flash' },
    { 'R', mode = { 'o', 'x' }, function() require('flash').treesitter_search() end, desc = 'Treesitter Search' },
    { '<c-s>', mode = { 'c' }, function() require('flash').toggle() end, desc = 'Toggle Flash Search' },
  },
}
