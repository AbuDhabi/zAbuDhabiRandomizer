local util = require "scripts.utilities"
local tech = require "scripts.technology"
local recipes = require "scripts.recipes"
local random = require "scripts.random"
local material = require "scripts.raw_materials"

random.seed(42)

local original_filtered_recipes = recipes.filter_out_ignored_recipes(data.raw.recipe)
local technologies = tech.get_technology_table(data.raw.technology, data.raw.recipe);
local starting_recipes = recipes.get_enabled_recipes(original_filtered_recipes)

util.logg(starting_recipes)

for recipe_name, recipe in pairs(starting_recipes) do
    local raw_recipe = data.raw.recipe[recipe_name]
    local recipe_raw_materials = recipes.get_recipe_raw_materials(original_filtered_recipes, raw_recipe.results[1].name, raw_recipe.results[1].amount)
    local recipe_cost_scores = material.get_raw_material_costs(data.raw.item, data.raw.fluid, recipe_raw_materials);
    local candidates_for_replacements = {};
    for candidate_name, candidate in pairs(starting_recipes) do
        local candidate_raw_materials = recipes.get_recipe_raw_materials(original_filtered_recipes, candidate_name, 1)
        local candidate_scores = material.get_raw_material_costs(data.raw.item, data.raw.fluid, candidate_raw_materials);
        -- Only items considered if they cost less than the total raw of the recipe to be randomized, in both fluids and items.
        if (candidate_scores.item < recipe_cost_scores.item or (candidate_scores.item == recipe_cost_scores.item and candidate_scores.item == 0)) and (candidate_scores.fluid < recipe_cost_scores.fluid or (candidate_scores.fluid == recipe_cost_scores.fluid and candidate_scores.fluid == 0)) then
            -- And only if their raw material list is a subset of the raw material list of the recipe to be randomized.
            if util.table_keys_subset(candidate_raw_materials, recipe_raw_materials) then
                -- And if it's not the same item. No breeding!
                if candidate_name ~= recipe_name then
                    candidates_for_replacements[candidate_name] = candidate_scores
                end
            end
        end
    end

    local fluid_candidates = {};
    local amount_of_fluid_candidates = 0;
    local item_candidates = {};
    local amount_of_item_candidates = 0;
    for candidate_name, candidate in pairs(candidates_for_replacements) do
        if (data.raw.item[candidate_name]) then
            amount_of_item_candidates = amount_of_item_candidates + 1
            item_candidates[candidate_name] = true
        elseif (data.raw.fluid[candidate_name]) then
            amount_of_fluid_candidates = amount_of_fluid_candidates + 1
            fluid_candidates[candidate_name] = true
        end
    end

    util.logg(recipe_name)
    util.logg(candidates_for_replacements)
    random.shuffle(fluid_candidates)
    random.shuffle(item_candidates)
    local amount_of_fluid_ingredients = 0;
    local amount_of_item_ingredients = 0;
    for ingredient_index, ingredient in pairs(raw_recipe.ingredients) do
        if ingredient.type == "item" then
            amount_of_item_ingredients = amount_of_item_ingredients + 1
        elseif ingredient.type == "fluid" then
            amount_of_fluid_ingredients = amount_of_fluid_ingredients + 1
        end
    end
    util.logg(#item_candidates)
    util.logg(#fluid_candidates)
    for ingredient_index, ingredient in pairs(raw_recipe.ingredients) do
        if ingredient.type == "item" and amount_of_item_candidates > amount_of_item_ingredients then
            for item_candidate_name, _ in pairs(item_candidates) do
                ingredient.name = item_candidate_name
                item_candidates[item_candidate_name] = nil
                break
            end
        elseif ingredient.type == "fluid" and amount_of_fluid_candidates > amount_of_fluid_ingredients then
            for fluid_candidate_name, _ in pairs(fluid_candidates) do
                ingredient.name = fluid_candidate_name
                fluid_candidates[fluid_candidate_name] = nil
                break
            end
        end
    end
    -- TODO: Merge duplicates. That breaks things.
    -- TODO: Handle cost approximation.
end


for tech_name, tech in pairs(technologies) do
    local recipes_unlocked = recipes.get_starting_and_unlocked_recipes(original_filtered_recipes, technologies, tech_name)
    local recipes_to_randomize = tech.recipes_unlocked


    --util.logg(recipes_to_randomize)
end


-- Recalculate all recycling recipes, as implemented by the developers.
if mods["quality"] then
    require("__quality__.data-updates")
end