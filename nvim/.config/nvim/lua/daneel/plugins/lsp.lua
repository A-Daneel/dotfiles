---@module "lazy"
---@type LazySpec[]
return {
  {
    {
      "neovim/nvim-lspconfig",
      cmd = "LspInfo",
      event = { "BufReadPre", "BufNewFile" },
      dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "hrsh7th/cmp-nvim-lsp",
        -- special ltex shizzle
        { "barreiroleo/ltex_extra.nvim", ft = "tex" },
        -- fancy updates, might be nice?
        { "j-hui/fidget.nvim", opts = {} },
      },
      config = function()
        -- `mason-lspconfig` (v2+) no longer exposes `setup_handlers`. On
        -- Neovim 0.11+ servers are configured with the built-in
        -- `vim.lsp.config` API and enabled automatically by
        -- `mason-lspconfig` (`automatic_enable`, on by default).
        local lsp_capabilities = require("cmp_nvim_lsp").default_capabilities()
        require("mason").setup()
        require("mason-lspconfig").setup({
          ensure_installed = {
            "gopls",
            "intelephense",
            "ltex",
            "pyright",
            "rust_analyzer",
          },
        })

        -- Shared config merged into every server (see `:h lsp-config`).
        vim.lsp.config("*", {
          capabilities = lsp_capabilities,
        })

        vim.lsp.config("ltex", {
          on_attach = function()
            require("ltex_extra").setup({
              load_langs = { "nl", "en-US" },
              init_check = true,
              path = vim.fn.expand("~") .. "/.dotfiles/nvim/spell",
            })
          end,
          settings = {
            ltex = {
              checkFrequency = "save",
            },
          },
        })

        vim.diagnostic.config({
          float = {
            source = true,
          },
        })
        vim.api.nvim_create_autocmd("LspAttach", {
          group = vim.api.nvim_create_augroup("UserLspConfig", {}),
          callback = function(ev)
            local opts = { buffer = ev.bufnr, remap = false }

            vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
            vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
            vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, opts)
            vim.keymap.set("n", "<leader>vca", vim.lsp.buf.code_action, opts)
            vim.keymap.set("n", "<leader>vrr", vim.lsp.buf.references, opts)
            vim.keymap.set("n", "<leader>vri", vim.lsp.buf.implementation, opts)
            vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename, opts)
            vim.keymap.set("n", "<leader>vh", vim.lsp.buf.signature_help, opts)
          end,
        })
      end,
    },
    {
      "hrsh7th/nvim-cmp",
      event = "InsertEnter",
      dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "micangl/cmp-vimtex",
        { "L3MON4D3/LuaSnip", build = "make install_jsregexp" },
        "saadparwaiz1/cmp_luasnip",
      },
      config = function()
        local cmp = require("cmp")

        cmp.setup({
          mapping = {
            ["<C-n>"] = cmp.mapping.select_next_item({
              behavior = cmp.SelectBehavior.Select,
            }),
            ["<C-p>"] = cmp.mapping.select_prev_item({
              behavior = cmp.SelectBehavior.Select,
            }),
            ["<C-y>"] = cmp.mapping.confirm({
              behavior = cmp.SelectBehavior.Select,
              select = true,
            }),
            ["<C-Space>"] = cmp.mapping.complete(),
          },

          sources = cmp.config.sources({
            { name = "luasnip" },
            { name = "nvim_lsp" },
            { name = "buffer" },
            { name = "path" },
          }),

          snippet = {
            expand = function(args)
              require("luasnip").lsp_expand(args.body)
            end,
          },
        })
        cmp.setup.filetype({ "tex" }, {
          sources = {
            { name = "luasnip" },
            { name = "nvim_lsp" },
            { name = "vimtex" },
            { name = "buffer" },
            { name = "path" },
          },
        })
        cmp.setup.filetype({ "sql" }, {
          sources = {
            { name = "vim-dadbod-completion" },
            { name = "buffer" },
          },
        })
        local ls = require("luasnip")
        ls.config.set_config({
          history = false,
          updateevents = "TextChanged,TextChangedI",
        })

        for _, ft_path in
          ipairs(
            vim.api.nvim_get_runtime_file("lua/daneel/snippets/*.lua", true)
          )
        do
          loadfile(ft_path)()
        end

        vim.keymap.set({ "i", "s" }, "<c-k>", function()
          if ls.expand_or_jumpable() then
            ls.expand_or_jump()
          end
        end, { silent = true })

        vim.keymap.set({ "i", "s" }, "<c-j>", function()
          if ls.jumpable(-1) then
            ls.jump(-1)
          end
        end, { silent = true })
      end,
    },
  },
  --  Formatting
  {
    "stevearc/conform.nvim",
    event = "InsertEnter",
    cmd = { "ConformInfo" },
    ---@module "conform"
    ---@type conform.setupOpts
    opts = {
      ---@type conform.FormatterConfigOverride
      formatters = {
        bibtex = {
          command = "bibtex-tidy",
          args = {
            "--curly",
            "--numeric",
            "--months",
            "--sort=key",
            "--duplicates=key,doi",
            "--no-escape",
            -- "--strip-enclosing-braces",
            "--sort-fields",
            "--trailing-commas",
            "--remove-empty-fields",
          },
        },
      },
      formatters_by_ft = {
        bib = { "bibtex" },
        go = { "gofmt" },
        lua = { "stylua" },
        php = { "php_cs_fixer" },
        python = { "black" },
        rust = { "rustfmt" },
        tex = { "latexindent" },
        ["_"] = { "trim_whitespace" },
      },
    },
    keys = {
      {
        "<leader>f",
        function()
          require("conform").format({
            async = true,
            lsp_format = "fallback",
          })
        end,
        desc = "Format buffer",
      },
    },
  },
  -- Linter
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        php = { "phpstan" },
      }
      local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
      vim.api.nvim_create_autocmd(
        { "BufEnter", "BufWritePost", "InsertLeave" },
        {
          group = lint_augroup,
          callback = function()
            require("lint").try_lint()
          end,
        }
      )
    end,
  },
}
