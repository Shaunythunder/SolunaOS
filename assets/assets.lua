-- /assets/asset_tables.lua
-- This file maps asset names to their file paths.
-- do not edit the names of the files, only the references from
-- asset_tables.lua

local asset_tables = require("asset_tables")

local assets = {

taskbar = nil,
start_button_clicked = asset_tables.start_button_clicked,
start_button_unclicked = asset_tables.start_button_unclicked,
}

return assets