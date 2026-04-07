vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local buf = ev.buf
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
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
  init_options = {
    preferences = {
      includeCompletionsForModuleExports = true,
      includeCompletionsWithInsertText = true,
      importModuleSpecifierPreference = "shortest",
    },
  },
})
vim.lsp.enable("ts_ls")

vim.lsp.config("gopls", {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork" },
  root_markers = { "go.work", "go.mod", ".git" },
  capabilities = {
    workspace = {
      didChangeWatchedFiles = { dynamicRegistration = false },
    },
  },
  settings = {
    gopls = {
      semanticTokens = true,
      completeUnimported = true,
      analyses = { unusedparams = true },
      staticcheck = true,
    },
  },
})
vim.lsp.enable("gopls")
