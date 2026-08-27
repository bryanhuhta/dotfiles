-- Prevent ts_ls from flagging or removing `import React` as unused: TypeScript
-- reports it as 6133 ("declared but its value is never read"), which drives
-- both the diagnostic and the quick-fix offered for it.
local function is_react_unused_import(d)
  return d.code == 6133 and d.message ~= nil and d.message:match("'React'") ~= nil
end

-- Code actions carry the diagnostics they resolve, so dropping any action tied
-- to the React 6133 diagnostic keeps that quick-fix out of the picker.
local function code_action_filter(action)
  for _, d in ipairs(action.diagnostics or {}) do
    if is_react_unused_import(d) then return false end
  end
  return true
end

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
    map("n", "<leader>ca", function()
      vim.lsp.buf.code_action({ filter = code_action_filter })
    end, "Code action")
    map("n", "<leader>e",  vim.diagnostic.open_float,  "Show line diagnostics")
    map("n", "[d",         function() vim.diagnostic.jump({ count = -1 }) end, "Previous diagnostic")
    map("n", "]d",         function() vim.diagnostic.jump({ count = 1 }) end,  "Next diagnostic")
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
  -- Only publishDiagnostics belongs here. Neovim 0.12 builds its own callbacks
  -- for textDocument/codeAction and codeAction/resolve (see the note above
  -- vim.lsp.buf.code_action in runtime/lua/vim/lsp/buf.lua), so a client
  -- handler for either is never consulted -- code actions are filtered at the
  -- keymap instead, via code_action_filter above.
  handlers = {
    ["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
      if result and result.diagnostics then
        result.diagnostics = vim.tbl_filter(function(d)
          return not is_react_unused_import(d)
        end, result.diagnostics)
      end
      vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx, config)
    end,
  },
})
vim.lsp.enable("ts_ls")

vim.lsp.config("clangd", {
  cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=iwyu" },
  filetypes = { "c", "cpp", "objc", "objcpp" },
  root_markers = {
    ".clangd",
    ".clang-tidy",
    ".clang-format",
    "compile_commands.json",
    "compile_flags.txt",
    "configure.ac",
    ".git",
  },
})
vim.lsp.enable("clangd")

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
      -- ST1000: "at least one file in a package should have a package comment"
      analyses = { unusedparams = true, ST1000 = false },
      staticcheck = true,
    },
  },
})
vim.lsp.enable("gopls")

vim.lsp.config("sourcekit", {
  cmd = { "xcrun", "sourcekit-lsp" },
  filetypes = { "swift" },
  -- root_markers are matched literally by vim.fs.find, so globs like "*.xcodeproj"
  -- never match. buildServer.json (from xcode-build-server) comes first so it wins
  -- over .git when both are present.
  root_markers = { "buildServer.json", "Package.swift", ".git" },
})
vim.lsp.enable("sourcekit")

vim.lsp.config("rust_analyzer", {
  cmd = { "rust-analyzer" },
  filetypes = { "rust" },
  root_markers = { "Cargo.toml", "rust-project.json", ".git" },
  settings = {
    ["rust-analyzer"] = {
      cargo = { allFeatures = true },
      check = { command = "clippy" },
      procMacro = { enable = true },
    },
  },
})
vim.lsp.enable("rust_analyzer")

local jdtls_cache = vim.fn.stdpath("cache") .. "/jdtls"
vim.lsp.config("jdtls", {
  cmd = {
    "jdtls",
    "-configuration", jdtls_cache .. "/config",
    "-data", jdtls_cache .. "/workspace",
  },
  filetypes = { "java" },
  root_markers = { "gradlew", "mvnw", "pom.xml", "build.gradle", "build.gradle.kts", ".git" },
})
vim.lsp.enable("jdtls")

vim.lsp.config("zls", {
  cmd = { "zls" },
  filetypes = { "zig", "zir" },
  root_markers = { "build.zig", "build.zig.zon", ".git" },
})
vim.lsp.enable("zls")
