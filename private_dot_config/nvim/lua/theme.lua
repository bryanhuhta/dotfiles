vim.api.nvim_set_hl(0, "ColorColumn", { ctermbg = 235, bg = "#262626" })
vim.api.nvim_set_hl(0, "@variable.parameter", { fg = "#b39ddb" })
vim.api.nvim_set_hl(0, "@variable.receiver", { fg = "#80cbc4" })
-- Don't let LSP override treesitter variable highlights; gopls provides no
-- finer-grained variable info than treesitter already does.
vim.api.nvim_set_hl(0, "@lsp.type.variable", {})
