--- Telescope extension for terrareg.nvim
-- @module telescope._extensions.terrareg

local telescope = require("telescope")
local terrareg_telescope = require("terrareg.telescope")

return telescope.register_extension({
  setup = function(ext_config)
    -- Extension setup if needed
  end,
  exports = {
    -- Main picker for all AWS resources and data sources
    aws_resources = terrareg_telescope.aws_resources_picker,

    -- Resources only picker
    resources = terrareg_telescope.resources_picker,

    -- Data sources only picker
    data_sources = terrareg_telescope.data_sources_picker,

    -- Search functionality
    search = terrareg_telescope.search_resources,
  },
})
