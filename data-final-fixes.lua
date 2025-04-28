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

-- Annonate every recipe with original analyses.
for tech_name, technology in pairs(technologies) do
    local current_filtered_recipes = recipes.filter_out_ignored_recipes(data_raw_working_copy.recipe)
    local recipes_unlocked = recipes.get_starting_and_unlocked_recipes(current_filtered_recipes, technologies, tech_name)
    local filtered_recipes_unlocked = recipes.filter_out_ignored_unlocked_recipes(current_filtered_recipes, recipes_unlocked)

    local recipes_to_randomize = technology.recipes_unlocked
    local filtered_recipes_to_randomize = recipes.filter_out_non_randomizable_recipes(data_raw_working_copy, recipes_to_randomize, current_filtered_recipes);

    for recipe_name, recipe in pairs(filtered_recipes_to_randomize) do
        if not data_raw_working_copy.recipe[recipe_name].modified then
            recipes.annotate_with_original_cost_scores(data_raw_working_copy, recipe_name, filtered_recipes_unlocked, current_filtered_recipes)
        end
    end
end

-- TODO: Thruster fluids are used in recipes.
-- TODO: Thruster fuel is randomized. It probably shouldn't be. Especially its fluids. Perhaps only its fluids shouldn't be.
-- TODO: Randomizing potentially obviates the need for planet-specific raws. Dunno what to do about that!
-- TODO: More appropriate recipes. Prebalancing. Try to pick ingredients that are roughly in line with the former raw materials cost in the given amount.

-- Randomize recipes unlocked by tech.
for tech_name, technology in pairs(technologies) do
    local current_filtered_recipes = recipes.filter_out_ignored_recipes(data_raw_working_copy.recipe)
    local recipes_unlocked = recipes.get_starting_and_unlocked_recipes(current_filtered_recipes, technologies, tech_name)
    local filtered_recipes_unlocked = recipes.filter_out_ignored_unlocked_recipes(current_filtered_recipes, recipes_unlocked)

    local recipes_to_randomize = technology.recipes_unlocked
    local filtered_recipes_to_randomize = recipes.filter_out_non_randomizable_recipes(data_raw_working_copy, recipes_to_randomize, current_filtered_recipes);

    for recipe_name, recipe in pairs(filtered_recipes_to_randomize) do
        if not data_raw_working_copy.recipe[recipe_name].modified then
            recipes.randomize_recipe(data_raw_working_copy, recipe_name, filtered_recipes_unlocked, current_filtered_recipes)
        end
    end
end

recipes.balance_costs(data_raw_working_copy);

-- Assign new values to raws.
data.raw = data_raw_working_copy;

-- Recalculate all recycling recipes, as implemented by the developers.
if mods["quality"] then
    require("__quality__.data-updates")
end

-- Unit tests, uncomment to run.
recipes_tests.raw_materials_are_accurate(original_filtered_recipes)