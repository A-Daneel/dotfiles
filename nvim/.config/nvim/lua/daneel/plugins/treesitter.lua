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
    -- mason provides the `tree-sitter` CLI that the `main` branch uses to
    -- compile parsers, and prepends its `bin/` directory to Neovim's PATH.
    dependencies = { "williamboman/mason.nvim" },
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

      -- Make sure mason's bin directory (where the mason-managed `tree-sitter`
      -- CLI lives) is on PATH, even if mason.setup() has not run yet.
      local sep = vim.fn.has("win32") == 1 and ";" or ":"
      local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
      if
        vim.fn.isdirectory(mason_bin) == 1
        and not string.find(sep .. (vim.env.PATH or "") .. sep, sep .. mason_bin .. sep, 1, true)
      then
        vim.env.PATH = mason_bin .. sep .. (vim.env.PATH or "")
      end

      local function install_parsers()
        require("nvim-treesitter").install(ensure_installed)
      end

      -- The `main` branch compiles parsers with the external `tree-sitter` CLI.
      -- If it is missing, self-provision it via mason (which is already used
      -- for LSP tooling); fall back to a helpful message otherwise.
      if vim.fn.executable("tree-sitter") == 1 then
        install_parsers()
      else
        local ok, registry = pcall(require, "mason-registry")
        local pkg
        if ok then
          local pkg_ok, result = pcall(registry.get_package, "tree-sitter-cli")
          pkg = pkg_ok and result or nil
        end

        if pkg and pkg:is_installed() then
          install_parsers()
        elseif pkg then
          vim.notify(
            "nvim-treesitter (main): installing the `tree-sitter` CLI via mason to compile parsers…",
            vim.log.levels.INFO
          )
          pkg:install(nil, function(success)
            if success then
              vim.schedule(install_parsers)
            else
              vim.schedule(function()
                vim.notify(
                  "Failed to install the `tree-sitter` CLI via mason. Install it manually "
                    .. "(e.g. `cargo install tree-sitter-cli` or your package manager) and run `:TSUpdate`.",
                  vim.log.levels.ERROR
                )
              end)
            end
          end)
        else
          vim.notify(
            "nvim-treesitter (main) requires the `tree-sitter` CLI to compile parsers. "
              .. "Install it (e.g. `:MasonInstall tree-sitter-cli`, `cargo install tree-sitter-cli`, "
              .. "or your package manager) and run `:TSUpdate`.",
            vim.log.levels.WARN
          )
        end
      end

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
