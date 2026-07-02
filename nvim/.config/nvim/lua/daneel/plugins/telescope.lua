---@module "lazy"
---@type LazySpec[]
return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)

      local extensions = { "fzf" }
      for _, extension in ipairs(extensions) do
        telescope.load_extension(extension)
      end
    end,
    keys = function()
      local builtin = require("telescope.builtin")
      return {
        {
          "<leader>pf",
          builtin.find_files,
        },
        {
          "<C-p>",
          builtin.git_files,
        },
        {
          "<leader>ps",
          builtin.live_grep,
        },
        {
          "<leader>vh",
          builtin.help_tags,
        },
      }
    end,
  },
}
