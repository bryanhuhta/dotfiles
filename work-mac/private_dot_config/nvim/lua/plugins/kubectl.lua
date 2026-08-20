-- The plugin has no "default view" setting: on open it restores the last view
-- recorded for the current context in its session file (~/.local/share/nvim/
-- kubectl/kubectl.json), falling back to pods for a context it has not seen.
-- `:Kubectl view <resource>` inits the client and then routes to that view
-- regardless of what the session says, so open through it to pin namespaces.
local function toggle(tab)
  local kubectl = require("kubectl")
  if kubectl.is_open then
    kubectl.toggle({ tab = tab })
    return
  end
  if tab then
    vim.cmd("tabnew")
  end
  require("kubectl.splash").show()
  vim.cmd("Kubectl view namespaces")
end

return {
  "ramilito/kubectl.nvim",
  -- Release tag: downloads a pre-built binary via blink.download instead of
  -- building the Rust backend from source (which needs nightly).
  version = "2.*",
  dependencies = { "saghen/blink.download" },
  -- `:K` is the plugin's own shorthand for `:Kubectl`, mirroring fugitive's `:G`.
  cmd = { "K", "Kubectl", "Kubens", "Kubectx" },
  keys = {
    { "<leader>k", function() toggle(false) end, silent = true, desc = "Kubectl: toggle cluster view" },
    { "<leader>K", function() toggle(true) end, silent = true, desc = "Kubectl: toggle cluster view in new tab" },
  },
  opts = {},
}
