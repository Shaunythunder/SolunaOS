-- /assets/asset_tables.lua
-- This file maps asset names to their file paths.
-- do not edit the names of the files, only the references from
-- asset_tables.lua

local asset_tables = require("asset_tables")

local assets = {

TASKBAR = nil,
START_BUTTON_CLICKED = asset_tables.start_button_clicked,
START_BUTTON_UNCLICKED = asset_tables.start_button_unclicked,
}

return assets