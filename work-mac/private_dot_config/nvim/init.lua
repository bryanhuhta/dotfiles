require("theme")

vim.g.mapleader = " "
vim.g.maplocalleader = " "

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
require("lazy").setup("plugins")

require("lsp")

-- General
vim.opt.termguicolors = true
vim.opt.completeopt = { "menu", "menuone", "noinsert", "noselect" }
vim.opt.ruler = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.updatetime = 100
vim.opt.signcolumn = "yes"
vim.opt.clipboard = "unnamedplus"
-- Column rulers
vim.opt.colorcolumn = "81,121"

-- Display whitespace
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", multispace = "·" }

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
vim.keymap.set("n", "<C-E>", ":Lexplore %:h<CR>:vertical resize 40<CR>", { silent = true, desc = "Toggle file explorer (buffer dir)" })
vim.keymap.set("n", "<C-S-E>", ":Lexplore<CR>:vertical resize 40<CR>", { silent = true, desc = "Toggle file explorer (cwd)" })
vim.keymap.set("n", "<leader>r", ":set relativenumber!<CR>", { desc = "Toggle relative line numbers" })
vim.keymap.set("n", "<Leader>w", ":%s/\\s\\+$//e<CR>", { desc = "Trim trailing whitespace" })
vim.keymap.set("n", "<S-CR>", "m`o<Esc>``", { desc = "Insert blank line below cursor" })

-- Reflows a single paragraph (a list of non-blank lines) to fit within
-- `width` columns, preserving the first line's leading indent on every
-- wrapped line. Words wider than the available width are placed on their
-- own line rather than split.
local function wrap_paragraph(lines, width)
  local indent = lines[1]:match("^%s*") or ""
  local indent_width = vim.fn.strdisplaywidth(indent)

  local words = {}
  for _, line in ipairs(lines) do
    for word in line:gmatch("%S+") do
      table.insert(words, word)
    end
  end
  if #words == 0 then
    return { "" }
  end

  local wrapped = {}
  local current, current_width
  for _, word in ipairs(words) do
    local word_width = vim.fn.strdisplaywidth(word)
    if current == nil then
      current, current_width = indent .. word, indent_width + word_width
    elseif current_width + 1 + word_width <= width then
      current, current_width = current .. " " .. word, current_width + 1 + word_width
    else
      table.insert(wrapped, current)
      current, current_width = indent .. word, indent_width + word_width
    end
  end
  table.insert(wrapped, current)
  return wrapped
end

-- Hard-wraps the visually selected lines to 80 columns. Blank lines inside
-- the selection are treated as paragraph breaks and preserved; everything
-- else is reflowed as plain text, ignoring 'formatoptions'/'comments' so the
-- result doesn't depend on filetype settings. Always operates on the full
-- lines spanned by the selection, so it behaves the same for charwise,
-- linewise, and blockwise visual selections.
--
-- Reads the selection via getpos("v")/getpos(".") rather than the '</'>
-- marks: a Lua-function right-hand side of a Visual-mode mapping runs while
-- Visual mode is still active, before those marks are updated.
local function reflow_selection()
  local buf = vim.api.nvim_get_current_buf()
  local start_line = math.min(vim.fn.getpos("v")[2], vim.fn.getpos(".")[2])
  local end_line = math.max(vim.fn.getpos("v")[2], vim.fn.getpos(".")[2])
  local lines = vim.api.nvim_buf_get_lines(buf, start_line - 1, end_line, false)

  local result = {}
  local paragraph = {}
  local function flush()
    if #paragraph > 0 then
      vim.list_extend(result, wrap_paragraph(paragraph, 80))
      paragraph = {}
    end
  end

  for _, line in ipairs(lines) do
    if line:match("^%s*$") then
      flush()
      table.insert(result, line)
    else
      table.insert(paragraph, line)
    end
  end
  flush()

  vim.cmd("normal! \27") -- leave Visual mode before editing the buffer
  vim.api.nvim_buf_set_lines(buf, start_line - 1, end_line, false, result)
end
vim.keymap.set("v", "<Leader>W", reflow_selection, { desc = "Hard wrap selection to 80 columns" })

vim.keymap.set("n", "<Leader>z", ":set spell!<CR>", { desc = "Toggle spell checking" })
vim.keymap.set("n", "<leader>q", ":copen<CR>", { silent = true, desc = "Open quickfix list" })
vim.keymap.set("v", "//", [[y/\V<C-R>=escape(@", '/\')<CR><CR>]], { desc = "Search for visual selection" })
vim.keymap.set("n", "<leader>yp", function() vim.fn.setreg("+", vim.fn.expand("%")) end, { desc = "Copy relative file path to clipboard" })
vim.keymap.set("n", "<leader>yP", function() vim.fn.setreg("+", vim.fn.expand("%:p")) end, { desc = "Copy absolute file path to clipboard" })
vim.keymap.set("n", "<leader>yn", function() vim.fn.setreg("+", vim.fn.expand("%:t")) end, { desc = "Copy file name to clipboard" })
vim.keymap.set("n", "<leader>nf", ":e %:h/", { desc = "New file in current directory" })
vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { desc = 'show diagnostics' })
vim.keymap.set("n", "<leader><Tab>", ":bnext<CR>", { silent = true, desc = "Next buffer" })
vim.keymap.set("n", "<leader><S-Tab>", ":bprev<CR>", { silent = true, desc = "Previous buffer" })

-- Auto-open quickfix after :grep
vim.api.nvim_create_autocmd("QuickFixCmdPost", {
  pattern = { "grep", "vimgrep" },
  callback = function() vim.cmd("copen") end,
})

-- Start treesitter highlighting
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "go", "typescript", "typescriptreact", "lua", "markdown", "c", "cpp" },
  callback = function() pcall(vim.treesitter.start) end,
})

-- Display tabs as 2 columns in Go files
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "go", "gomod", "gowork", "gosum", "gotmpl" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = false
  end,
})

-- Treesitter-based folding for markdown
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.foldmethod = "expr"
    vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
  end,
})

-- Create missing parent directories on save (except for URIs like "scp://")
vim.api.nvim_create_autocmd({ "BufWritePre", "FileWritePre" }, {
  callback = function(ev)
    if ev.match:match("://") then
      return
    end
    vim.fn.mkdir(vim.fn.fnamemodify(ev.match, ":p:h"), "p")
  end,
})

-- Format with goimports on save via gopls
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function() vim.lsp.buf.format({ async = false }) end,
})
