-- Bootstrap lazy.nvim (plugin manager)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugins
require("lazy").setup({
  {
    "fatih/vim-go",
    build = ":GoUpdateBinaries",
    ft = { "go" },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "typescript", "tsx", "go", "lua" },
        highlight = { enable = true },
      })
    end,
  },
})

-- General
vim.opt.ruler = true
vim.opt.relativenumber = true
vim.opt.updatetime = 100

-- Column rulers
vim.opt.colorcolumn = "81,121"
vim.api.nvim_set_hl(0, "ColorColumn", { ctermbg = 235, bg = "#262626" })

-- Display whitespace
vim.opt.list = true
vim.opt.listchars = { tab = ">-", trail = ".", multispace = "." }

-- Indentation
vim.opt.autoindent = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.cinoptions = "l1"

-- Folding (disabled by default, preserved via foldlevel)
vim.opt.foldmethod = "syntax"
vim.opt.foldenable = false
vim.opt.foldlevel = 99

-- Open new splits to the right and below
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Keymaps
vim.keymap.set("n", "<C-E>", ":Lexplore<CR>", { silent = true, desc = "Toggle file explorer" })
vim.keymap.set("n", "<leader>r", ":set relativenumber! number!<CR>", { desc = "Toggle relative/absolute line numbers" })
vim.keymap.set("n", "<Leader>w", ":%s/\\s\\+$//e<CR>", { desc = "Trim trailing whitespace" })
vim.keymap.set("v", "<Leader>W", "<Cmd>set textwidth=80<CR>gvgq", { desc = "Hard wrap selection to 80 columns" })
vim.keymap.set("n", "<Leader>z", ":set spell!<CR>", { desc = "Toggle spell checking" })
vim.keymap.set("n", "<C-j>", "i<CR><CR><Up><C-t>", { desc = "Insert newline with indentation (e.g. expand braces)" })

-- vim-go
vim.g.go_fmt_command = "goimports"
vim.g.go_auto_type_info = 1
vim.g.go_auto_sameids = 1
