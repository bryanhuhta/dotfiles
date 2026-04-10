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

-- Prevent ts_ls from flagging or removing `import React` as unused.
-- Covers the diagnostic hint (6133) and code actions like "Remove all unused imports".
local function is_react_import_line(line)
  return line:match("import.*React.*from%s+['\"]react['\"]") ~= nil
end

local function filter_react_import_edits(edit, bufnr)
  local uri = vim.uri_from_bufnr(bufnr)
  local function keep_edit(text_edit)
    local lines = vim.api.nvim_buf_get_lines(
      bufnr, text_edit.range.start.line, text_edit.range["end"].line + 1, false
    )
    for _, line in ipairs(lines) do
      if is_react_import_line(line) then return false end
    end
    return true
  end
  if edit.changes and edit.changes[uri] then
    edit.changes[uri] = vim.tbl_filter(keep_edit, edit.changes[uri])
  end
  if edit.documentChanges then
    for _, change in ipairs(edit.documentChanges) do
      if change.textDocument and change.textDocument.uri == uri and change.edits then
        change.edits = vim.tbl_filter(keep_edit, change.edits)
      end
    end
  end
end

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
  handlers = {
    ["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
      if result and result.diagnostics then
        result.diagnostics = vim.tbl_filter(function(d)
          return not (d.code == 6133 and d.message:match("'React'"))
        end, result.diagnostics)
      end
      vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx, config)
    end,
    ["textDocument/codeAction"] = function(err, result, ctx)
      if result then
        for i = #result, 1, -1 do
          local action = result[i]
          -- Drop individual quick-fixes tied to the React 6133 diagnostic
          if action.diagnostics then
            for _, d in ipairs(action.diagnostics) do
              if d.code == 6133 and d.message:match("'React'") then
                table.remove(result, i)
                goto next_action
              end
            end
          end
          -- Strip React-import edits from bulk actions (e.g. "Remove all unused imports")
          if action.edit then
            filter_react_import_edits(action.edit, ctx.bufnr)
          end
          ::next_action::
        end
      end
      vim.lsp.handlers["textDocument/codeAction"](err, result, ctx)
    end,
    ["codeAction/resolve"] = function(err, result, ctx)
      if result and result.edit then
        filter_react_import_edits(result.edit, ctx.bufnr)
      end
      vim.lsp.handlers["codeAction/resolve"](err, result, ctx)
    end,
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
