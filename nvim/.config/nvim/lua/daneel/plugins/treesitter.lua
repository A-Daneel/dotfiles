---@module "lazy"
---@type LazySpec[]
return {
  {
    "nvim-treesitter/nvim-treesitter",
    -- The `master` branch is locked to Neovim 0.11 and crashes on 0.12+
    -- (e.g. the `conceal_line` decoration provider error when rendering
    -- markdown in the LSP hover float). The `main` branch is the supported
    -- rewrite for Neovim 0.12+.
    branch = "main",
    -- `main` does not support lazy-loading.
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local ensure_installed = {
        "lua",
        "php",
        "rust",
        -- Needed so LSP hover/documentation floats (filetype markdown) are
        -- highlighted with parsers/queries compatible with the running Neovim.
        "markdown",
        "markdown_inline",
      }
      require("nvim-treesitter").install(ensure_installed)

      -- Filetypes whose highlighting/indentation is handled elsewhere
      -- (latex is handled by vimtex).
      local skip_filetypes = {
        tex = true,
        latex = true,
      }

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("daneel_treesitter", { clear = true }),
        callback = function(args)
          local ft = vim.bo[args.buf].filetype
          if skip_filetypes[ft] then
            return
          end

          local lang = vim.treesitter.language.get_lang(ft)
          if not lang then
            return
          end

          local ok, added = pcall(vim.treesitter.language.add, lang)
          if not ok or not added then
            return
          end

          pcall(vim.treesitter.start, args.buf, lang)
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile", "BufWritePre" },
  },
}
