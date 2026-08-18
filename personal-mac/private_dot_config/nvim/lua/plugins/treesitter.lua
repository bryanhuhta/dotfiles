return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    -- On the main branch, setup() no longer takes ensure_installed;
    -- grammars are installed with install(), which skips ones already
    -- present. Compiling requires the tree-sitter CLI (Brewfile).
    require("nvim-treesitter").install({
      "typescript", "tsx", "go", "lua", "markdown", "markdown_inline", "c", "cpp",
    })
  end,
}
