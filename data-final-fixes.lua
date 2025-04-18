local util = require "scripts.utilities"
local tech = require "scripts.technology"
local recipes = require "scripts.recipes"

local original_filtered_recipes = recipes.filter_out_ignored_recipes(data.raw.recipe)
local tech_tree = tech.get_technology_table(data.raw.technology, data.raw.recipe);

local recipes_unlocked = recipes.get_starting_and_unlocked_recipes(original_filtered_recipes, tech_tree, "automation-science-pack")

util.logg(recipes_unlocked)


-- Recalculate all recycling recipes, as implemented by the developers.
if mods["quality"] then
    require("__quality__.data-updates")
end