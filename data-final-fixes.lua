local util = require "scripts.utilities"
local tech = require "scripts.technology"
local recipes = require "scripts.recipes"

-- Save a copy of each recipe's original version in the game data.
for recipe_name, recipe_raw in pairs(data.raw.recipe) do
    local copy = table.deepcopy(data.raw.recipe[recipe_name])
    data.raw.recipe[recipe_name].original = copy
end

for recipe_name, recipe_raw in pairs(data.raw.recipe) do
    util.logg(recipe_name)
    util.logg(recipes.get_recipe_raw_materials(data.raw.recipe, recipe_name, 1))
end




-- Recalculate all recycling recipes, as implemented by the developers.
if mods["quality"] then
    require("__quality__.data-updates")
end