local util = require "scripts.utilities"
local tech = require "scripts.technology"
local recipes = require "scripts.recipes"
local random = require "scripts.random"
local material = require "scripts.raw_materials"
local recipes_tests = require "scripts.recipes_tests"

random.seed(412)

local original_filtered_recipes = recipes.filter_out_ignored_recipes(data.raw.recipe)
local technologies = tech.get_technology_table(data.raw.technology, data.raw.recipe);
local starting_recipes = recipes.get_enabled_recipes(original_filtered_recipes)

util.logg(starting_recipes)

local original_recipe_cost_scores = {};
for recipe_name, recipe in pairs(starting_recipes) do
    local raw_recipe = data.raw.recipe[recipe_name]
    local recipe_raw_materials = recipes.get_recipe_raw_materials(original_filtered_recipes, raw_recipe.results[1].name, raw_recipe.results[1].amount)
    local recipe_cost_scores = material.get_raw_material_costs(data.raw.item, data.raw.fluid, recipe_raw_materials);
    original_recipe_cost_scores[recipe_name] = recipe_cost_scores
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
                    -- And if the candidate itself is not already being made from the this recipe, ie. not making gears from belts (made from gears).
                    if not recipes.is_recipe_made_of_this(data.raw.recipe, recipe_name, candidate_name) then
                        candidates_for_replacements[candidate_name] = candidate_scores
                    end
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

    for ingredient_index, ingredient in pairs(raw_recipe.ingredients) do
        if ingredient.type == "item" and amount_of_item_candidates > amount_of_item_ingredients then
            for item_candidate_name, _ in pairs(item_candidates) do
                ingredient.name = item_candidate_name
                item_candidates[item_candidate_name] = nil
                raw_recipe.modified = true
                break
            end
        elseif ingredient.type == "fluid" and amount_of_fluid_candidates > amount_of_fluid_ingredients then
            for fluid_candidate_name, _ in pairs(fluid_candidates) do
                ingredient.name = fluid_candidate_name
                fluid_candidates[fluid_candidate_name] = nil
                raw_recipe.modified = true
                break
            end
        end
    end
end

for recipe_name, recipe_raw in pairs(data.raw.recipe) do
    if recipe_raw.modified then
        local updated_filtered_recipes = recipes.filter_out_ignored_recipes(data.raw.recipe)
        local updated_recipe_raw_materials = recipes.get_recipe_raw_materials(updated_filtered_recipes, recipe_raw.results[1].name, recipe_raw.results[1].amount)
        local updated_recipe_cost_scores = material.get_raw_material_costs(data.raw.item, data.raw.fluid, updated_recipe_raw_materials);
        local old_recipe_cost_scores = original_recipe_cost_scores[recipe_name]

        -- Adjust costs if they're not sufficiently close to the original.
        local loop_breaker = 0;
        local acceptable_ratio = 1.1;
        local maximum_iterations = 100;
        -- Items
        while (updated_recipe_cost_scores.item / old_recipe_cost_scores.item) > acceptable_ratio  do
            util.logg(recipe_name .. " is too item expensive " .. updated_recipe_cost_scores.item .. " > " .. old_recipe_cost_scores.item)
            for ingredient_name, ingredient_raw in pairs(recipe_raw.ingredients) do
                if ingredient_raw.type == "item" then
                    ingredient_raw.amount = math.floor(ingredient_raw.amount / acceptable_ratio) -- Always decrements by at least one.
                    if ingredient_raw.amount < 1 then
                        ingredient_raw.amount = 1
                    end
                end
            end
            updated_filtered_recipes = recipes.filter_out_ignored_recipes(data.raw.recipe)
            updated_recipe_raw_materials = recipes.get_recipe_raw_materials(updated_filtered_recipes, recipe_raw.results[1].name, recipe_raw.results[1].amount)
            updated_recipe_cost_scores = material.get_raw_material_costs(data.raw.item, data.raw.fluid, updated_recipe_raw_materials);
            loop_breaker = loop_breaker + 1;
            if loop_breaker > maximum_iterations then
                break;
            end
        end
        loop_breaker = 0;
        while (old_recipe_cost_scores.item / updated_recipe_cost_scores.item) > acceptable_ratio do
            util.logg(recipe_name .. " is too item cheap " .. updated_recipe_cost_scores.item .. " < " .. old_recipe_cost_scores.item)
            for ingredient_name, ingredient_raw in pairs(recipe_raw.ingredients) do
                if ingredient_raw.type == "item" then
                    ingredient_raw.amount = math.ceil(ingredient_raw.amount * acceptable_ratio) -- Always increments by at least one.
                    if ingredient_raw.amount < 1 then
                        ingredient_raw.amount = 1
                    end
                end
            end
            updated_filtered_recipes = recipes.filter_out_ignored_recipes(data.raw.recipe)
            updated_recipe_raw_materials = recipes.get_recipe_raw_materials(updated_filtered_recipes, recipe_raw.results[1].name, recipe_raw.results[1].amount)
            updated_recipe_cost_scores = material.get_raw_material_costs(data.raw.item, data.raw.fluid, updated_recipe_raw_materials);
            loop_breaker = loop_breaker + 1;
            if loop_breaker > maximum_iterations then
                break;
            end
        end
        -- Fluids
        loop_breaker = 0;
        while (updated_recipe_cost_scores.fluid / old_recipe_cost_scores.fluid) > acceptable_ratio  do
            util.logg(recipe_name .. " is too fluid expensive " .. updated_recipe_cost_scores.fluid .. " > " .. old_recipe_cost_scores.fluid)
            for ingredient_name, ingredient_raw in pairs(recipe_raw.ingredients) do
                if ingredient_raw.type == "fluid" then
                    ingredient_raw.amount = math.floor(ingredient_raw.amount / acceptable_ratio) -- Always decrements by at least one.
                    if ingredient_raw.amount < 1 then
                        ingredient_raw.amount = 1
                    end
                end
            end
            updated_filtered_recipes = recipes.filter_out_ignored_recipes(data.raw.recipe)
            updated_recipe_raw_materials = recipes.get_recipe_raw_materials(updated_filtered_recipes, recipe_raw.results[1].name, recipe_raw.results[1].amount)
            updated_recipe_cost_scores = material.get_raw_material_costs(data.raw.item, data.raw.fluid, updated_recipe_raw_materials);
            loop_breaker = loop_breaker + 1;
            if loop_breaker > maximum_iterations then
                break;
            end
        end
        loop_breaker = 0;
        while (old_recipe_cost_scores.fluid / updated_recipe_cost_scores.fluid) > acceptable_ratio do
            util.logg(recipe_name .. " is too fluid cheap " .. updated_recipe_cost_scores.fluid .. " < " .. old_recipe_cost_scores.fluid)
            for ingredient_name, ingredient_raw in pairs(recipe_raw.ingredients) do
                if ingredient_raw.type == "fluid" then
                    ingredient_raw.amount = math.ceil(ingredient_raw.amount * acceptable_ratio) -- Always increments by at least one.
                    if ingredient_raw.amount < 1 then
                        ingredient_raw.amount = 1
                    end
                end
            end
            updated_filtered_recipes = recipes.filter_out_ignored_recipes(data.raw.recipe)
            updated_recipe_raw_materials = recipes.get_recipe_raw_materials(updated_filtered_recipes, recipe_raw.results[1].name, recipe_raw.results[1].amount)
            updated_recipe_cost_scores = material.get_raw_material_costs(data.raw.item, data.raw.fluid, updated_recipe_raw_materials);
            loop_breaker = loop_breaker + 1;
            if loop_breaker > maximum_iterations then
                break;
            end
        end
    end
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

recipes_tests.raw_materials_are_accurate(original_filtered_recipes)