vim.api.nvim_set_hl(0, "Normal", { fg = "#c0c0c0", ctermfg = 250 })
-- Make treesitter groups that default to white inherit the Normal fg
vim.api.nvim_set_hl(0, "@variable", { fg = "#f5c18a" })
vim.api.nvim_set_hl(0, "@punctuation.bracket", { link = "Normal" })
vim.api.nvim_set_hl(0, "@punctuation.delimiter", { link = "Normal" })
vim.api.nvim_set_hl(0, "@operator", { link = "Normal" })
vim.api.nvim_set_hl(0, "@keyword", { fg = "#f4b8c8" })
vim.api.nvim_set_hl(0, "@label", { fg = "#e8829a" })
vim.api.nvim_set_hl(0, "ColorColumn", { ctermbg = 235, bg = "#262626" })
vim.api.nvim_set_hl(0, "@variable.parameter", { fg = "#b39ddb" })
vim.api.nvim_set_hl(0, "@variable.receiver", { fg = "#80cbc4" })
-- Don't let LSP override treesitter variable highlights; gopls provides no
-- finer-grained variable info than treesitter already does.
vim.api.nvim_set_hl(0, "@lsp.type.variable", {})
