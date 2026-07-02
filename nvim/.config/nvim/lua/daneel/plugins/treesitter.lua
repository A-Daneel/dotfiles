---@module "lazy"
---@type LazySpec[]
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    dependencies = { "mason-org/mason.nvim" },
    config = function()
      local ensure_installed = {
        "lua",
        "php",
        "rust",
        "markdown",
        "markdown_inline",
      }

      local path_sep = vim.fn.has("win32") == 1 and ";" or ":"
      local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
      if
        vim.fn.isdirectory(mason_bin) == 1
        and not string.find(
          path_sep .. (vim.env.PATH or "") .. path_sep,
          path_sep .. mason_bin .. path_sep,
          1,
          true
        )
      then
        vim.env.PATH = mason_bin .. path_sep .. (vim.env.PATH or "")
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

      if vim.fn.executable("tree-sitter") == 1 then
        install_parsers()
      else
        local ok, registry = pcall(require, "mason-registry")
        if not ok then
          manual_install_warning()
        else
          registry.refresh(function()
            vim.schedule(function()
              provision_from_registry(registry)
            end)
          end)
        end
      end

      local skip_filetypes = {
        tex = true,
        latex = true,
      }

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup(
          "daneel_treesitter",
          { clear = true }
        ),
        callback = function(args)
          local bufnr = args.buf
          if skip_filetypes[vim.bo[bufnr].filetype] then
            return
          end

          local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
          if not ok or not parser then
            return
          end

          pcall(vim.treesitter.start, bufnr)
          vim.bo[bufnr].indentexpr =
            "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile", "BufWritePre" },
  },
}
