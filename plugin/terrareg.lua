--- Terrareg plugin loader
-- @script plugin.terrareg

if vim.g.loaded_terrareg == 1 then
  return
end
vim.g.loaded_terrareg = 1

-- Create user commands
vim.api.nvim_create_user_command("TerraregResources", function(opts)
  require("terrareg").aws_resources(opts.args and { default_text = opts.args } or {})
end, {
  desc = "Open Terraform AWS resources picker",
  nargs = "?",
})

vim.api.nvim_create_user_command("TerraregResourcesOnly", function(opts)
  require("terrareg").aws_resources_only(opts.args and { default_text = opts.args } or {})
end, {
  desc = "Open Terraform AWS resources picker (resources only)",
  nargs = "?",
})

vim.api.nvim_create_user_command("TerraregDataSources", function(opts)
  require("terrareg").aws_data_sources(opts.args and { default_text = opts.args } or {})
end, {
  desc = "Open Terraform AWS data sources picker",
  nargs = "?",
})

vim.api.nvim_create_user_command("TerraregSearch", function(opts)
  local query = opts.args and opts.args ~= "" and opts.args or nil
  require("terrareg").search(query)
end, {
  desc = "Search Terraform AWS resources",
  nargs = "?",
})

vim.api.nvim_create_user_command("TerraregDocs", function(opts)
  local args = vim.split(opts.args or "", "%s+")
  if #args < 2 then
    vim.notify("Usage: TerraregDocs <resource|data> <resource_name>", vim.log.levels.ERROR)
    return
  end
  require("terrareg").show_docs(args[1], args[2])
end, {
  desc = "Show documentation for a specific resource",
  nargs = "*",
})

vim.api.nvim_create_user_command("TerraregInsert", function(opts)
  local args = vim.split(opts.args or "", "%s+")
  if #args < 2 then
    vim.notify("Usage: TerraregInsert <resource|data> <resource_name>", vim.log.levels.ERROR)
    return
  end
  require("terrareg").insert_example(args[1], args[2])
end, {
  desc = "Insert example code for a resource at cursor",
  nargs = "*",
})

-- Plugin initialization (only auto-setup if explicitly enabled)
-- Users should call require('terrareg').setup() in their config
-- To enable auto-setup: vim.g.terrareg_auto_setup = true
if vim.g.terrareg_auto_setup then
  require("terrareg").setup()
end
