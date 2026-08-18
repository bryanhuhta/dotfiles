-- The bundled Swift ftplugin turns on 'smartindent', which hardcodes the C
-- convention of yanking a '#' typed as the first character of a line to
-- column 0. Swift's '#' tokens (#if, #available, #selector, #Preview) are
-- ordinary indented code, so insert '#' literally to bypass that rule while
-- keeping smartindent's brace handling.
vim.keymap.set("i", "#", "<C-v>#", { buffer = true, desc = "Insert # without smartindent clamping to column 0" })

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or "") .. "\n execute 'iunmap <buffer> #'"
