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

      local function manual_install_warning(level)
        vim.notify(
          "nvim-treesitter (main) requires the `tree-sitter` CLI to compile parsers. "
            .. "Install it (e.g. `:MasonInstall tree-sitter-cli`, `cargo install tree-sitter-cli`, "
            .. "or your package manager) and run `:TSUpdate`.",
          level or vim.log.levels.WARN
        )
      end

      -- Look up and, if needed, install the mason `tree-sitter-cli` package,
      -- then compile the parsers. Assumes the mason registry has been refreshed
      -- so that `get_package` can resolve the package.
      local function provision_from_registry(registry)
        local pkg_ok, pkg = pcall(registry.get_package, "tree-sitter-cli")
        if not pkg_ok or not pkg then
          manual_install_warning()
          return
        end

        if pkg:is_installed() then
          install_parsers()
          return
        end

        vim.notify(
          "nvim-treesitter (main): installing the `tree-sitter` CLI via mason to compile parsers…",
          vim.log.levels.INFO
        )
        pkg:install(nil, function(success)
          vim.schedule(function()
            if success then
              install_parsers()
            else
              manual_install_warning(vim.log.levels.ERROR)
            end
          end)
        end)
      end

      -- The `main` branch compiles parsers with the external `tree-sitter` CLI.
      -- If it is missing, self-provision it via mason (which is already used
      -- for LSP tooling); fall back to a helpful message otherwise.
      if vim.fn.executable("tree-sitter") == 1 then
        install_parsers()
      else
        local ok, registry = pcall(require, "mason-registry")
        if not ok then
          manual_install_warning()
        else
          -- On a fresh install the mason registry has not been downloaded yet,
          -- so `get_package` would fail. Refresh it first, then provision.
          registry.refresh(function()
            vim.schedule(function()
              provision_from_registry(registry)
            end)
          end)
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
          local bufnr = args.buf
          if skip_filetypes[vim.bo[bufnr].filetype] then
            return
          end

          -- Follow tj devries' `main`-branch config: let Neovim resolve the
          -- parser for the buffer and start treesitter highlighting. Both
          -- calls are wrapped in `pcall` so buffers without an installed
          -- parser simply fall back to Vim's default syntax highlighting
          -- instead of throwing (parsers install asynchronously, so the
          -- first buffer of a language may open before its parser is ready).
          local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
          if not ok or not parser then
            return
          end

          pcall(vim.treesitter.start, bufnr)
          vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile", "BufWritePre" },
  },
}
