vim.opt_local.spell = true
vim.opt_local.spelllang = "nl"

vim.bo.shiftwidth = 2
vim.bo.softtabstop = 2
vim.bo.tabstop = 2

vim.g.tex_conceal = "abdmg"
vim.opt_local.conceallevel = 2

vim.g.vimtex_syntax_conceal = {
  accents = 1,
  ligatures = 1,
  cites = 1,
  fancy = 1,
  spacing = 0,
  greek = 1,
  math_bounds = 1,
  math_delimiters = 1,
  math_fracs = 1,
  math_super_sub = 1,
  math_symbols = 1,
  sections = 0,
  styles = 0,
}

-- Autocommands to change conceal level based on mode
vim.api.nvim_create_augroup("ConcealOnInsert", { clear = true })

vim.api.nvim_create_autocmd("InsertEnter", {
  group = "ConcealOnInsert",
  pattern = "*.tex",
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
  group = "ConcealOnInsert",
  pattern = "*.tex",
  callback = function()
    vim.opt_local.conceallevel = 2
  end,
})
