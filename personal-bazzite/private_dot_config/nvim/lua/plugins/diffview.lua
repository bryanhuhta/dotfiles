local function detect_base_branch()
  local out = vim.fn.systemlist({ "git", "symbolic-ref", "--short", "refs/remotes/origin/HEAD" })
  if vim.v.shell_error == 0 and out[1] then
    return (out[1]:gsub("^origin/", ""))
  end
  for _, b in ipairs({ "main", "master" }) do
    vim.fn.system({ "git", "show-ref", "--verify", "--quiet", "refs/heads/" .. b })
    if vim.v.shell_error == 0 then return b end
  end
  return nil
end

local function diff_against_base()
  local base = detect_base_branch()
  if base then
    vim.cmd("DiffviewOpen " .. base .. "...HEAD")
    return
  end
  vim.ui.input({ prompt = "Base branch: " }, function(input)
    if input and input ~= "" then
      vim.cmd("DiffviewOpen " .. input .. "...HEAD")
    end
  end)
end

return {
  "sindrets/diffview.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles", "DiffviewRefresh" },
  keys = {
    { "<leader>gd", ":DiffviewOpen<CR>", silent = true, desc = "Diffview: working tree" },
    { "<leader>gb", diff_against_base, desc = "Diffview: branch vs base" },
    { "<leader>gh", ":DiffviewFileHistory %<CR>", silent = true, desc = "Diffview: current file history" },
    { "<leader>gH", ":DiffviewFileHistory<CR>", silent = true, desc = "Diffview: branch history" },
    { "<leader>gx", ":DiffviewClose<CR>", silent = true, desc = "Diffview: close" },
  },
}
