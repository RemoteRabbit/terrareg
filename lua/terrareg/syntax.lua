--- Advanced syntax highlighting for terrareg.nvim
-- @module terrareg.syntax

local M = {}

--- Setup enhanced syntax highlighting for documentation
-- @param bufnr number Buffer number
function M.setup_documentation_syntax(bufnr)
  -- Set custom filetype
  vim.api.nvim_buf_set_option(bufnr, "filetype", "terrareg-docs")

  -- Define syntax highlighting
  vim.cmd([[
    " Clear existing syntax
    syntax clear

    " Headers and sections
    syntax match TerraregDocsTitle "📖 TERRAFORM DOCUMENTATION"
    syntax match TerraregDocsSection "📝 Description:\|⚙️  Arguments:\|💡 Example Usage:"
    syntax match TerraregDocsBorder "═\+\|─\+"

    " Table elements
    syntax match TerraregDocsTableBorder "[┌┐└┘├┤┬┴┼│]"
    syntax match TerraregDocsTableHeader "│.*Argument Name.*│.*Required.*│.*Default.*│.*Description.*│"
    syntax match TerraregDocsRequired "\* Req"
    syntax match TerraregDocsOptional "  Opt"
    syntax match TerraregDocsForceNew "(!)"
    syntax match TerraregDocsDefault "`[^`]*`" contained

    " Resource information
    syntax match TerraregDocsResource "Resource: .*"
    syntax match TerraregDocsSource "Source: .*"
    syntax match TerraregDocsUrl "https\?://[^ ]*"

    " Navigation and metadata
    syntax match TerraregDocsNavigation "Navigation: .*"
    syntax match TerraregDocsLegend "Legend: .*"
    syntax match TerraregDocsTotal "Total arguments: .*"

    " Terraform code blocks
    syntax region TerraregDocsTerraform start="resource\|data\|variable\|output" end="^$" contains=TerraregTfKeyword,TerraregTfString,TerraregTfComment
    syntax keyword TerraregTfKeyword resource data variable output locals terraform
    syntax match TerraregTfString '"[^"]*"'
    syntax match TerraregTfComment "#.*$"
    syntax match TerraregTfOperator "=\|{\|}"
    syntax match TerraregTfArgument "^\s*[a-zA-Z_][a-zA-Z0-9_]*\s*="

    " Highlight groups
    highlight link TerraregDocsTitle Title
    highlight link TerraregDocsSection Function
    highlight link TerraregDocsBorder Comment
    highlight link TerraregDocsTableBorder Comment
    highlight link TerraregDocsTableHeader Statement
    highlight link TerraregDocsRequired DiffAdd
    highlight link TerraregDocsOptional DiffChange
    highlight link TerraregDocsForceNew WarningMsg
    highlight link TerraregDocsDefault String
    highlight link TerraregDocsResource Identifier
    highlight link TerraregDocsSource Comment
    highlight link TerraregDocsUrl Underlined
    highlight link TerraregDocsNavigation Comment
    highlight link TerraregDocsLegend Comment
    highlight link TerraregDocsTotal Special

    " Terraform syntax
    highlight link TerraregTfKeyword Keyword
    highlight link TerraregTfString String
    highlight link TerraregTfComment Comment
    highlight link TerraregTfOperator Operator
    highlight link TerraregTfArgument Identifier
    highlight link TerraregDocsTerraform Normal
  ]])
end

--- Setup folding for documentation
-- @param bufnr number Buffer number
function M.setup_folding(bufnr)
  vim.api.nvim_buf_set_option(bufnr, "foldmethod", "expr")
  vim.api.nvim_buf_set_option(
    bufnr,
    "foldexpr",
    'v:lua.require("terrareg.syntax").fold_expression()'
  )
  vim.api.nvim_buf_set_option(bufnr, "foldtext", 'v:lua.require("terrareg.syntax").fold_text()')
  vim.api.nvim_buf_set_option(bufnr, "foldenable", true)
  vim.api.nvim_buf_set_option(bufnr, "foldlevel", 1) -- Start with main sections open
end

--- Folding expression for documentation
-- @return string Fold level
function M.fold_expression()
  local line = vim.fn.getline(vim.v.lnum)

  -- Main headers (level 0)
  if line:match("^📖") or line:match("^═+$") then
    return "0"
  end

  -- Section headers (level 1)
  if line:match("^📝") or line:match("^⚙️") or line:match("^💡") then
    return "1"
  end

  -- Table content (level 2)
  if line:match("^┌") or line:match("^│") or line:match("^├") or line:match("^└") then
    return "2"
  end

  -- Code blocks (level 2)
  if line:match("^%s%s%s%sresource") or line:match("^%s%s%s%sdata") then
    return "2"
  end

  return "="
end

--- Custom fold text
-- @return string Fold text display
function M.fold_text()
  local line = vim.fn.getline(vim.v.foldstart)
  local lines_count = vim.v.foldend - vim.v.foldstart + 1

  -- Clean up the line for display
  local clean_line = line:gsub("^%s*", ""):gsub("%s*$", "")

  return string.format("%s (%d lines)", clean_line, lines_count)
end

--- Theme definitions
M.themes = {
  default = {
    title = "Title",
    section = "Function",
    border = "Comment",
    required = "DiffAdd",
    optional = "DiffChange",
    force_new = "WarningMsg",
  },

  dark = {
    title = "DraculaOrange",
    section = "DraculaPurple",
    border = "DraculaComment",
    required = "DraculaGreen",
    optional = "DraculaYellow",
    force_new = "DraculaRed",
  },

  light = {
    title = "Blue",
    section = "DarkBlue",
    border = "Gray",
    required = "DarkGreen",
    optional = "DarkYellow",
    force_new = "Red",
  },
}

--- Apply theme to documentation buffer
-- @param bufnr number Buffer number
-- @param theme_name string Theme name
function M.apply_theme(bufnr, theme_name)
  local theme = M.themes[theme_name]
  if not theme then
    vim.notify("Theme not found: " .. theme_name, vim.log.levels.WARN)
    return
  end

  -- Apply theme colors
  for element, highlight in pairs(theme) do
    local cmd = string.format(
      "highlight link TerraregDocs%s %s",
      element:gsub("^%l", string.upper),
      highlight
    )
    vim.cmd(cmd)
  end

  vim.notify("Applied theme: " .. theme_name, vim.log.levels.INFO)
end

--- Toggle syntax highlighting
-- @param bufnr number Buffer number
function M.toggle_syntax(bufnr)
  local syntax_enabled = vim.api.nvim_buf_get_option(bufnr, "syntax") ~= ""

  if syntax_enabled then
    vim.cmd("syntax off")
    vim.notify("Syntax highlighting disabled", vim.log.levels.INFO)
  else
    M.setup_documentation_syntax(bufnr)
    vim.notify("Syntax highlighting enabled", vim.log.levels.INFO)
  end
end

return M
