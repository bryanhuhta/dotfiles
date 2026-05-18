return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").setup({
      ensure_installed = { "typescript", "tsx", "go", "lua", "markdown", "markdown_inline", "c", "cpp" },
    })
  end,
}
