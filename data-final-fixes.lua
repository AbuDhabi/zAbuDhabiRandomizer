local util = require "scripts.utilities"
local tech = require "scripts.technology"
local recipes = require "scripts.recipes"
local random = require "scripts.random"
local material = require "scripts.raw_materials"
local recipes_tests = require "scripts.recipes_tests"

random.seed(412)

local data_raw_working_copy = table.deepcopy(data.raw)

local original_filtered_recipes = recipes.filter_out_ignored_recipes(data_raw_working_copy.recipe)
local technologies = tech.get_technology_table(data_raw_working_copy.technology, data_raw_working_copy.recipe);
local starting_recipes = recipes.get_enabled_recipes(original_filtered_recipes)

util.logg(starting_recipes)

for recipe_name, recipe in pairs(starting_recipes) do
    recipes.randomize_recipe(data_raw_working_copy, recipe_name, starting_recipes, original_filtered_recipes)
end

recipes.balance_costs(data_raw_working_copy);

for tech_name, tech in pairs(technologies) do
    local recipes_unlocked = recipes.get_starting_and_unlocked_recipes(original_filtered_recipes, technologies, tech_name)
    local recipes_to_randomize = tech.recipes_unlocked


    --util.logg(recipes_to_randomize)
end

-- Assign new values to raws.
data.raw = data_raw_working_copy;

-- Recalculate all recycling recipes, as implemented by the developers.
if mods["quality"] then
    require("__quality__.data-updates")
end

recipes_tests.raw_materials_are_accurate(original_filtered_recipes)