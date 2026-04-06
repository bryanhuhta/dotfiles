return {
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
    vim.keymap.set("n", "<leader>f", function() fzf.git_files({ prompt = "git > ", cmd = "git ls-files --cached --others --exclude-standard" }) end, { silent = true, desc = "Fuzzy find git files" })
    vim.keymap.set("n", "<leader>F", fzf.files, { silent = true, desc = "Fuzzy find files" })
    vim.keymap.set("n", "<leader>b", fzf.buffers, { silent = true, desc = "Fuzzy find buffers" })
  end,
}
