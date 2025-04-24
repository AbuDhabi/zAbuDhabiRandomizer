local util = require "scripts.utilities"
local defines = require "scripts.defines"
local tech = require "scripts.technology"
local material = require "scripts.raw_materials"
local random = require "scripts.random"

local F = {};

function F.filter_out_ignored_recipes(data_raw_recipes)
    local filtered_recipes = {}
    for recipe_name, recipe_raw in pairs(data_raw_recipes) do
        if defines.ignored_recipe_subgroups[recipe_raw.subgroup] then
            filtered_recipes[recipe_name] = nil
        elseif defines.ignored_recipe_categories[recipe_raw.category] then
            filtered_recipes[recipe_name] = nil
        elseif recipe_raw.hidden == true then
            filtered_recipes[recipe_name] = nil
        else
            filtered_recipes[recipe_name] = table.deepcopy(recipe_raw)
        end
    end
    return filtered_recipes
end

-- TODO: Fix and use in raw material calculation, or remove.
function F.try_to_find_a_non_obvious_recipe(recipes, item_or_fluid_name)
    local amount_of_recipes_producing_this = 0
    local production_recipe
    for _, recipe in pairs(recipes) do
        if recipe.results and #recipe.results == 1 and recipe.results[1].name == item_or_fluid_name then
            amount_of_recipes_producing_this = amount_of_recipes_producing_this + 1
            production_recipe = recipe
        end
    end
    if amount_of_recipes_producing_this == 1 then
        return production_recipe 
    end
    return nil
end

function F.get_enabled_recipes(recipes)
    local starting_recipes = {};
    for recipe_name, recipe in pairs(recipes) do
        if (recipe.enabled == nil or recipe.enabled == true) then
            starting_recipes[recipe_name] = true
        end
    end
    return starting_recipes
end

function F.get_starting_and_unlocked_recipes(recipes, tech_tree, tech_name)
    local starting_recipes = F.get_enabled_recipes(recipes)
    local recipes_unlocked_by_tech = tech.get_unlocked_recipes(tech_tree, tech_name)
    util.merge_tables(starting_recipes, recipes_unlocked_by_tech)
    return starting_recipes
end

function F.is_recipe_made_of_this(recipes, recipe_name, ingredient_name)
    local recipe = recipes[recipe_name];
    if not recipe or not recipe.ingredients then
        return false -- No recipe, raw material, end of the line.
    end
    for _, recipe_ingredient in pairs(recipe.ingredients) do
        if recipe_ingredient.name == ingredient_name then
            return true
        else
            if F.is_recipe_made_of_this(recipes, recipe_ingredient, ingredient_name) == true then
                return true
            end
        end
    end
    return false
end

---Balances costs in the raw dataset.
---@param data_raw table Wube-provided raw data, modified by randomization.
function F.balance_costs(data_raw)
    for recipe_name, recipe_raw in pairs(data_raw.recipe) do
        if recipe_raw.modified then
            local updated_filtered_recipes = F.filter_out_ignored_recipes(data_raw.recipe)
            local updated_recipe_raw_materials = material.get_recipe_raw_materials(updated_filtered_recipes, recipe_raw.results[1].name, recipe_raw.results[1].amount)
            local updated_recipe_cost_scores = material.get_raw_material_costs(data_raw.item, data_raw.fluid, updated_recipe_raw_materials);
            local old_recipe_cost_scores = recipe_raw.original_recipe_cost_scores
    
            -- Adjust costs if they're not sufficiently close to the original.
            local loop_breaker = 0;
            local acceptable_ratio = 1.1;
            local maximum_iterations = 100;
            -- Items
            while updated_recipe_cost_scores.item > 0 and (updated_recipe_cost_scores.item / old_recipe_cost_scores.item) > acceptable_ratio  do
                util.logg(recipe_name .. " is too item expensive " .. updated_recipe_cost_scores.item .. " > " .. old_recipe_cost_scores.item)
                for ingredient_name, ingredient_raw in pairs(recipe_raw.ingredients) do
                    if ingredient_raw.type == "item" then
                        ingredient_raw.amount = math.floor(ingredient_raw.amount / acceptable_ratio) -- Always decrements by at least one.
                        if ingredient_raw.amount < 1 then
                            ingredient_raw.amount = 1
                        end
                    end
                end
                updated_filtered_recipes = F.filter_out_ignored_recipes(data_raw.recipe)
                updated_recipe_raw_materials = material.get_recipe_raw_materials(updated_filtered_recipes, recipe_raw.results[1].name, recipe_raw.results[1].amount)
                updated_recipe_cost_scores = material.get_raw_material_costs(data_raw.item, data_raw.fluid, updated_recipe_raw_materials);
                loop_breaker = loop_breaker + 1;
                if loop_breaker > maximum_iterations then
                    break;
                end
            end
            loop_breaker = 0;
            while updated_recipe_cost_scores.item > 0 and (old_recipe_cost_scores.item / updated_recipe_cost_scores.item) > acceptable_ratio do
                util.logg(recipe_name .. " is too item cheap " .. updated_recipe_cost_scores.item .. " < " .. old_recipe_cost_scores.item)
                for ingredient_name, ingredient_raw in pairs(recipe_raw.ingredients) do
                    if ingredient_raw.type == "item" then
                        ingredient_raw.amount = math.ceil(ingredient_raw.amount * acceptable_ratio) -- Always increments by at least one.
                        if ingredient_raw.amount < 1 then
                            ingredient_raw.amount = 1
                        end
                    end
                end
                updated_filtered_recipes = F.filter_out_ignored_recipes(data_raw.recipe)
                updated_recipe_raw_materials = material.get_recipe_raw_materials(updated_filtered_recipes, recipe_raw.results[1].name, recipe_raw.results[1].amount)
                updated_recipe_cost_scores = material.get_raw_material_costs(data_raw.item, data_raw.fluid, updated_recipe_raw_materials);
                loop_breaker = loop_breaker + 1;
                if loop_breaker > maximum_iterations then
                    break;
                end
            end
            -- Fluids
            loop_breaker = 0;
            while updated_recipe_cost_scores.fluid > 0 and (updated_recipe_cost_scores.fluid / old_recipe_cost_scores.fluid) > acceptable_ratio  do
                util.logg(recipe_name .. " is too fluid expensive " .. updated_recipe_cost_scores.fluid .. " > " .. old_recipe_cost_scores.fluid)
                for ingredient_name, ingredient_raw in pairs(recipe_raw.ingredients) do
                    if ingredient_raw.type == "fluid" then
                        ingredient_raw.amount = math.floor(ingredient_raw.amount / acceptable_ratio) -- Always decrements by at least one.
                        if ingredient_raw.amount < 1 then
                            ingredient_raw.amount = 1
                        end
                    end
                end
                updated_filtered_recipes = F.filter_out_ignored_recipes(data_raw.recipe)
                updated_recipe_raw_materials = material.get_recipe_raw_materials(updated_filtered_recipes, recipe_raw.results[1].name, recipe_raw.results[1].amount)
                updated_recipe_cost_scores = material.get_raw_material_costs(data_raw.item, data_raw.fluid, updated_recipe_raw_materials);
                loop_breaker = loop_breaker + 1;
                if loop_breaker > maximum_iterations then
                    break;
                end
            end
            loop_breaker = 0;
            while updated_recipe_cost_scores.fluid > 0 and (old_recipe_cost_scores.fluid / updated_recipe_cost_scores.fluid) > acceptable_ratio do
                util.logg(recipe_name .. " is too fluid cheap " .. updated_recipe_cost_scores.fluid .. " < " .. old_recipe_cost_scores.fluid)
                for ingredient_name, ingredient_raw in pairs(recipe_raw.ingredients) do
                    if ingredient_raw.type == "fluid" then
                        ingredient_raw.amount = math.ceil(ingredient_raw.amount * acceptable_ratio) -- Always increments by at least one.
                        if ingredient_raw.amount < 1 then
                            ingredient_raw.amount = 1
                        end
                    end
                end
                updated_filtered_recipes = F.filter_out_ignored_recipes(data_raw.recipe)
                updated_recipe_raw_materials = material.get_recipe_raw_materials(updated_filtered_recipes, recipe_raw.results[1].name, recipe_raw.results[1].amount)
                updated_recipe_cost_scores = material.get_raw_material_costs(data_raw.item, data_raw.fluid, updated_recipe_raw_materials);
                loop_breaker = loop_breaker + 1;
                if loop_breaker > maximum_iterations then
                    break;
                end
            end
        end
    end
end


function F.randomize_recipe(data_raw, recipe_name, available_recipes, filtered_recipes)
    local raw_recipe = data_raw.recipe[recipe_name]
    local recipe_raw_materials = material.get_recipe_raw_materials(filtered_recipes, raw_recipe.results[1].name, raw_recipe.results[1].amount)
    local recipe_cost_scores = material.get_raw_material_costs(data_raw.item, data_raw.fluid, recipe_raw_materials);
    local candidates_for_replacements = {};
    for candidate_name, candidate in pairs(available_recipes) do
        local candidate_raw_materials = material.get_recipe_raw_materials(filtered_recipes, candidate_name, 1)
        local candidate_scores = material.get_raw_material_costs(data_raw.item, data_raw.fluid, candidate_raw_materials);
        -- Only items considered if they cost less than the total raw of the recipe to be randomized, in both fluids and items.
        if (candidate_scores.item < recipe_cost_scores.item or (candidate_scores.item == recipe_cost_scores.item and candidate_scores.item == 0)) and (candidate_scores.fluid < recipe_cost_scores.fluid or (candidate_scores.fluid == recipe_cost_scores.fluid and candidate_scores.fluid == 0)) then
            -- And only if their raw material list is a subset of the raw material list of the recipe to be randomized.
            if util.table_keys_subset(candidate_raw_materials, recipe_raw_materials) then
                -- And if it's not the same item. No breeding!
                if candidate_name ~= recipe_name then
                    -- And if the candidate itself is not already being made from the this recipe, ie. not making gears from belts (made from gears).
                    if not F.is_recipe_made_of_this(data_raw.recipe, recipe_name, candidate_name) then
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
        if (data_raw.item[candidate_name]) then
            amount_of_item_candidates = amount_of_item_candidates + 1
            item_candidates[candidate_name] = true
        elseif (data_raw.fluid[candidate_name]) then
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
    if raw_recipe.modified == true then
        raw_recipe.original_recipe_cost_scores = recipe_cost_scores
    end
end

---@param filtered_recipes table
---@param recipes_unlocked table
---@return table filtered_recipes_unlocked Unlocked recipes that are in the pre-filtered recipes
function F.filter_out_ignored_unlocked_recipes(filtered_recipes, recipes_unlocked)
    local filtered_recipes_unlocked = {};
    for unlocked_recipe_name, unlocked_recipe in pairs(recipes_unlocked) do
        if filtered_recipes[unlocked_recipe_name] then
            filtered_recipes_unlocked[unlocked_recipe_name] = unlocked_recipe
        end
    end
    return filtered_recipes_unlocked
end

---@param data_raw table An instance of data.raw as provided by Wube
---@param recipes_to_randomize table
---@param current_filtered_recipes table
function F.filter_out_non_randomizable_recipes(data_raw, recipes_to_randomize, current_filtered_recipes)
    -- First pass: Only recipes that aren't ignored and exist as items or fluids (recipe name == item or fluid name).
    local filtered_recipes_to_randomize_first_pass = {};
    for recipe_to_randomize_name, recipe_to_randomize in pairs(recipes_to_randomize) do
        if current_filtered_recipes[recipe_to_randomize_name] and (data_raw.item[recipe_to_randomize_name] or data_raw.fluid[recipe_to_randomize_name]) then
            filtered_recipes_to_randomize_first_pass[recipe_to_randomize_name] = recipe_to_randomize
        end
    end
    -- Second pass: No breeders (recipes with a result in ingredients).
    local filtered_recipes_to_randomize_second_pass = {};
    for recipe_to_randomize_name, recipe_to_randomize in pairs(filtered_recipes_to_randomize_first_pass) do
        local raw_recipe = data_raw.recipe[recipe_to_randomize_name]
        local is_breeder = false;
        for _, ingredient in pairs(raw_recipe.ingredients) do
            if ingredient.name == recipe_to_randomize_name then
                is_breeder = true;
            end
        end
        if is_breeder == false then
            filtered_recipes_to_randomize_second_pass[recipe_to_randomize_name] = recipe_to_randomize
        end
    end
    return filtered_recipes_to_randomize_second_pass
end


return F;