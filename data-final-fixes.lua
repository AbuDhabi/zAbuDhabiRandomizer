local util = require "scripts.util"
local tech = require "scripts.technology"
local recipes = require "scripts.recipes"
local random = require "scripts.random"
local material = require "scripts.material"
local material_tests = require "scripts.material_tests"
local balance = require "scripts.balance"

random.seed(42)

local data_raw_working_copy = table.deepcopy(data.raw)

local original_filtered_recipes = recipes.filter_out_ignored_recipes(data_raw_working_copy.recipe)
local technologies = tech.get_technology_table(data_raw_working_copy.technology, data_raw_working_copy.recipe);

-- Annonate every recipe with original analyses.
for tech_name, technology in pairs(technologies) do
    local current_filtered_recipes = recipes.filter_out_ignored_recipes(data_raw_working_copy.recipe)
    local recipes_unlocked = recipes.get_starting_and_unlocked_recipes(current_filtered_recipes, technologies, tech_name)
    local filtered_recipes_unlocked = recipes.filter_out_ignored_unlocked_recipes(current_filtered_recipes, recipes_unlocked)

    local recipes_to_randomize = technology.recipes_unlocked
    local filtered_recipes_to_randomize = recipes.filter_out_non_randomizable_recipes(data_raw_working_copy, recipes_to_randomize, current_filtered_recipes);

    for recipe_name, recipe in pairs(filtered_recipes_to_randomize) do
        recipes.annotate_with_original_cost_scores(data_raw_working_copy, recipe_name, filtered_recipes_unlocked, current_filtered_recipes)
    end
end

-- TODO: Randomizing potentially obviates the need for planet-specific raws. Dunno what to do about that!
-- TODO: Get rid of hardcoded `results[1]` and similar.
-- TODO: What is a raw material? Everything gatherable, via machine or not. Raw materials can also be produced. Asteroids - not raw materials, they're more like resource patches.

-- Randomize recipes unlocked by tech.
for tech_name, technology in pairs(technologies) do
    local current_filtered_recipes = recipes.filter_out_ignored_recipes(data_raw_working_copy.recipe)
    local recipes_unlocked = recipes.get_starting_and_unlocked_recipes(current_filtered_recipes, technologies, tech_name)
    local filtered_recipes_unlocked = recipes.filter_out_ignored_unlocked_recipes(current_filtered_recipes, recipes_unlocked)

    local recipes_to_randomize = technology.recipes_unlocked
    local filtered_recipes_to_randomize = recipes.filter_out_non_randomizable_recipes(data_raw_working_copy, recipes_to_randomize, current_filtered_recipes);

    for recipe_name, recipe in pairs(filtered_recipes_to_randomize) do
        if not data_raw_working_copy.recipe[recipe_name].processed then
            recipes.randomize_recipe(data_raw_working_copy, recipe_name, filtered_recipes_unlocked, current_filtered_recipes)
        end
    end
end

balance.balance_costs(data_raw_working_copy);

-- Assign new values to raws.
data.raw = data_raw_working_copy;

-- Recalculate all recycling recipes, as implemented by the developers.
if mods["quality"] then
    require("__quality__.data-updates")
end

-- Unit tests, uncomment to run.
material_tests.raw_materials_are_accurate(data_raw_working_copy, original_filtered_recipes)
material_tests.resources_check_works(data_raw_working_copy);

