local util = require "scripts.utilities"
local tech = require "scripts.technology"
local recipes = require "scripts.recipes"

local original_filtered_recipes = recipes.filter_out_ignored_recipes(data.raw.recipe)
for recipe_name, recipe_raw in pairs(original_filtered_recipes) do
    util.logg(recipe_name)
    util.logg(recipes.get_recipe_raw_materials(original_filtered_recipes, recipe_name, 1))
end




-- Recalculate all recycling recipes, as implemented by the developers.
if mods["quality"] then
    require("__quality__.data-updates")
end