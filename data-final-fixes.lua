local util = require "scripts.utilities"
local tech = require "scripts.technology"
local recipes = require "scripts.recipes"
local random = require "scripts.random"
local material = require "scripts.raw_materials"

local original_filtered_recipes = recipes.filter_out_ignored_recipes(data.raw.recipe)
local technologies = tech.get_technology_table(data.raw.technology, data.raw.recipe);
local starting_recipes = recipes.get_enabled_recipes(original_filtered_recipes)

for recipe_name, recipe in pairs(starting_recipes) do
    local raw_recipe = data.raw.recipe[recipe_name]
    local recipe_raw_materials = recipes.get_recipe_raw_materials(original_filtered_recipes, raw_recipe.results[1].name, raw_recipe.results[1].amount)
    local recipe_cost_scores = material.get_raw_material_costs(data.raw.item, data.raw.fluid, recipe_raw_materials);
    local candidates_for_replacements = {};
    for candidate_name, candidate in pairs(starting_recipes) do
        local candidate_raw_materials = recipes.get_recipe_raw_materials(original_filtered_recipes, candidate_name, 1)
        local candidate_scores = material.get_raw_material_costs(data.raw.item, data.raw.fluid, candidate_raw_materials);
        if candidate_scores.item <= recipe_cost_scores.item and candidate_scores.fluid <= recipe_cost_scores.fluid then
            candidates_for_replacements[candidate_name] = candidate_scores
        end
    end
    util.logg(recipe_cost_scores)
    util.logg(candidates_for_replacements)
    -- TODO: actual candidates are from a subset of the raw materials the recipe is normally made from
    -- TODO: so I need to know the raw mats of the recipe and the raw mats of everything else here
    for ingredient_index, ingredient in pairs(raw_recipe.ingredients) do
        if ingredient.type == "item" then

        elseif ingredient.type == "fluid" then

        end
       ingredient.amount = random.int(20) 
    end
end


for tech_name, tech in pairs(technologies) do
    local recipes_unlocked = recipes.get_starting_and_unlocked_recipes(original_filtered_recipes, technologies, tech_name)
    local recipes_to_randomize = tech.recipes_unlocked


    util.logg(recipes_to_randomize)
end


-- Recalculate all recycling recipes, as implemented by the developers.
if mods["quality"] then
    require("__quality__.data-updates")
end