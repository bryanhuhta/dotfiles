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
    "ibhagwan/fzf-lua",
    config = function()
      local fzf = require("fzf-lua")
      fzf.setup({
        winopts = {
          on_create = function()
            vim.keymap.set("t", "<C-r>", function()
              return '<C-\\><C-N>"' .. vim.fn.nr2char(vim.fn.getchar()) .. "pi"
            end, { expr = true, buffer = true })
          end,
        },
      })
      vim.keymap.set("n", "<leader>f", function() fzf.git_files({ prompt = "git > " }) end, { silent = true, desc = "Fuzzy find git files" })
      vim.keymap.set("n", "<leader>F", fzf.files, { silent = true, desc = "Fuzzy find files" })
      vim.keymap.set("n", "<leader>b", fzf.buffers, { silent = true, desc = "Fuzzy find buffers" })
    end,
  },
  { "tpope/vim-fugitive" },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({})
    end,
  },
  {
    "nmac427/guess-indent.nvim",
    config = function()
      require("guess-indent").setup({})
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({
        ensure_installed = { "typescript", "tsx", "go", "lua" },
      })
    end,
  },
})

-- LSP
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local buf = ev.buf
    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
    end
    map("n", "gd",         vim.lsp.buf.definition,     "Go to definition")
    map("n", "gD",         vim.lsp.buf.declaration,    "Go to declaration")
    map("n", "gr",         vim.lsp.buf.references,     "Go to references")
    map("n", "gi",         vim.lsp.buf.implementation, "Go to implementation")
    map("n", "K",          vim.lsp.buf.hover,          "Hover documentation")
    map("n", "<leader>rn", vim.lsp.buf.rename,         "Rename symbol")
    map("n", "<leader>ca", vim.lsp.buf.code_action,    "Code action")
    map("n", "<leader>e",  vim.diagnostic.open_float,  "Show line diagnostics")
    map("n", "[d",         vim.diagnostic.goto_prev,   "Previous diagnostic")
    map("n", "]d",         vim.diagnostic.goto_next,   "Next diagnostic")
  end,
})

vim.lsp.config("ts_ls", {
  cmd = { "typescript-language-server", "--stdio" },
  filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
})
vim.lsp.enable("ts_ls")

-- General
vim.opt.ruler = true
vim.opt.relativenumber = true
vim.opt.updatetime = 100
vim.opt.clipboard = "unnamedplus"
-- Column rulers
vim.opt.colorcolumn = "81,121"
vim.api.nvim_set_hl(0, "ColorColumn", { ctermbg = 235, bg = "#262626" })

-- Display whitespace
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "•", multispace = "•" }

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

-- Search with ag (Silver Searcher) via :grep, results in quickfix list
vim.opt.grepprg = "ag --vimgrep"
vim.opt.grepformat = "%f:%l:%c:%m"

-- Keymaps
vim.keymap.set("n", "<C-E>", ":Lexplore %:h<CR>", { silent = true, desc = "Toggle file explorer (buffer dir)" })
vim.keymap.set("n", "<C-S-E>", ":Lexplore<CR>", { silent = true, desc = "Toggle file explorer (cwd)" })
vim.keymap.set("n", "<leader>r", ":set relativenumber! number!<CR>", { desc = "Toggle relative/absolute line numbers" })
vim.keymap.set("n", "<Leader>w", ":%s/\\s\\+$//e<CR>", { desc = "Trim trailing whitespace" })

local function reflow_selection()
  local saved_tw = vim.bo.textwidth
  local saved_fe = vim.bo.formatexpr
  vim.bo.textwidth = 80
  vim.bo.formatexpr = ""

  local buf = vim.api.nvim_get_current_buf()
  local end_line = vim.fn.line("'>")  -- 1-indexed

  -- Insert a blank line after the selection as a paragraph boundary so gq
  -- does not pull in the following line. Track it with an extmark so we can
  -- find and remove it after reformatting regardless of how lines shift.
  vim.fn.append(end_line, "")
  local ns = vim.api.nvim_create_namespace("reflow_sentinel")
  local mark_id = vim.api.nvim_buf_set_extmark(buf, ns, end_line, 0, {})

  vim.cmd("normal! gvgq")

  local pos = vim.api.nvim_buf_get_extmark_by_id(buf, ns, mark_id, {})
  vim.api.nvim_buf_set_lines(buf, pos[1], pos[1] + 1, false, {})
  vim.api.nvim_buf_del_extmark(buf, ns, mark_id)

  vim.bo.textwidth = saved_tw
  vim.bo.formatexpr = saved_fe
end
vim.keymap.set("v", "<Leader>W", reflow_selection, { desc = "Hard wrap selection to 80 columns" })

vim.keymap.set("n", "<Leader>z", ":set spell!<CR>", { desc = "Toggle spell checking" })
vim.keymap.set("n", "<leader>q", ":copen<CR>", { silent = true, desc = "Open quickfix list" })
vim.keymap.set("v", "//", [[y/\V<C-R>=escape(@", '/\')<CR><CR>]], { desc = "Search for visual selection" })
vim.keymap.set("n", "<leader>yp", function() vim.fn.setreg("+", vim.fn.expand("%")) end, { desc = "Copy relative file path to clipboard" })
vim.keymap.set("n", "<leader>yP", function() vim.fn.setreg("+", vim.fn.expand("%:p")) end, { desc = "Copy absolute file path to clipboard" })
vim.keymap.set("n", "<leader>yn", function() vim.fn.setreg("+", vim.fn.expand("%:t")) end, { desc = "Copy file name to clipboard" })
vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { desc = 'show diagnostics' })

-- vim-go
vim.g.go_fmt_command = "goimports"
vim.g.go_auto_type_info = 1
vim.g.go_auto_sameids = 1
