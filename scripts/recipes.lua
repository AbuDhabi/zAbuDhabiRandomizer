local util = require "scripts.utilities"
local defines = require "scripts.defines"
local tech = require "scripts.technology"
local material = require "scripts.raw_materials"
local random = require "scripts.random"

local F = {};

---Filters out recipes which should be ignored based on defines. Stuff like parameter placeholders, barreling/unbarreling, and hidden recipes.
---@param data_raw_recipes table Raw recipes from Wube.
---@return table Recipes Filtered and deep-copied.
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

---Gets enabled recipes (ie. non-disabled).
---@param recipes table Recipes in Wube-provided data structures.
---@return table Recipes string->bool dictionary.
function F.get_enabled_recipes(recipes)
    local starting_recipes = {};
    for recipe_name, recipe in pairs(recipes) do
        if (recipe.enabled == nil or recipe.enabled == true) then
            starting_recipes[recipe_name] = true
        end
    end
    return starting_recipes
end

---Gets starting recipes and those unlocked by technology and its prerequisites.
---@param recipes table Filtered recipes.
---@param tech_tree table
---@param tech_name string
---@return table
function F.get_starting_and_unlocked_recipes(recipes, tech_tree, tech_name)
    local starting_recipes = F.get_enabled_recipes(recipes)
    local recipes_unlocked_by_tech = tech.get_unlocked_recipes(tech_tree, tech_name)
    util.merge_tables(starting_recipes, recipes_unlocked_by_tech)
    return starting_recipes
end

---Determines if recipe is made of an ingredient.
---@param recipes table Filtered recipes.
---@param recipe_name string
---@param ingredient_name string
---@return boolean
function F.is_recipe_made_of_this(recipes, recipe_name, ingredient_name)
    local recipe = recipes[recipe_name];
    if not recipe or not recipe.ingredients then
        return false -- No recipe, raw material, end of the line.
    end
    for _, recipe_ingredient in pairs(recipe.ingredients) do
        if recipe_ingredient.name == ingredient_name then
            return true
        else
            if F.is_recipe_made_of_this(recipes, recipe_ingredient.name, ingredient_name) == true then
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
            local updated_recipe_raw_materials = material.get_recipe_raw_materials(updated_filtered_recipes, recipe_raw.results[1].name, recipe_raw.results[1].amount, true)
            local updated_recipe_cost_scores = material.get_raw_material_costs(data_raw.item, data_raw.fluid, updated_recipe_raw_materials);
            local old_recipe_cost_scores = recipe_raw.original_recipe_cost_scores -- TODO: Calculate this for originals, not originals based in randomized prerequisites.
    
            -- Adjust costs if they're not sufficiently close to the original.
            local loop_breaker = 0;
            local acceptable_ratio = 1.1;
            local maximum_iterations = 100;
            -- Combined, both fluid and item raw materials.
            if updated_recipe_cost_scores.item > 0 and updated_recipe_cost_scores.fluid > 0 then
                -- Too expensive.
                loop_breaker = 0;
                while ((updated_recipe_cost_scores.item / old_recipe_cost_scores.item) * (updated_recipe_cost_scores.fluid / old_recipe_cost_scores.fluid)) > acceptable_ratio  do
                    -- TODO: Fix the log.
                    util.logg(recipe_name .. " is too expensive " .. updated_recipe_cost_scores.item * updated_recipe_cost_scores.fluid .. " > " .. old_recipe_cost_scores.item * old_recipe_cost_scores.fluid)
                    for ingredient_name, ingredient_raw in pairs(recipe_raw.ingredients) do
                        ingredient_raw.amount = math.floor(ingredient_raw.amount / acceptable_ratio) -- Always decrements by at least one.
                        if ingredient_raw.amount < 1 then
                            ingredient_raw.amount = 1
                        elseif ingredient_raw.amount > defines.maximum_item_amount then
                            ingredient_raw.amount = defines.maximum_item_amount
                        end
                    end
                    updated_filtered_recipes = F.filter_out_ignored_recipes(data_raw.recipe)
                    updated_recipe_raw_materials = material.get_recipe_raw_materials(updated_filtered_recipes, recipe_raw.results[1].name, recipe_raw.results[1].amount, true)
                    updated_recipe_cost_scores = material.get_raw_material_costs(data_raw.item, data_raw.fluid, updated_recipe_raw_materials);
                    loop_breaker = loop_breaker + 1;
                    if loop_breaker > maximum_iterations then
                        break;
                    end
                end
                -- Too cheap.
                loop_breaker = 0;
                while ((old_recipe_cost_scores.item / updated_recipe_cost_scores.item) * (old_recipe_cost_scores.fluid / updated_recipe_cost_scores.fluid)) > acceptable_ratio  do
                    -- TODO: Fix the log.
                    util.logg(recipe_name .. " is too cheap " .. updated_recipe_cost_scores.item * updated_recipe_cost_scores.fluid .. " < " .. old_recipe_cost_scores.item * old_recipe_cost_scores.fluid)
                    for ingredient_name, ingredient_raw in pairs(recipe_raw.ingredients) do
                        ingredient_raw.amount = math.ceil(ingredient_raw.amount * acceptable_ratio) -- Always increments by at least one.
                        if ingredient_raw.amount < 1 then
                            ingredient_raw.amount = 1
                        elseif ingredient_raw.amount > defines.maximum_item_amount then
                            ingredient_raw.amount = defines.maximum_item_amount
                        end
                    end
                    updated_filtered_recipes = F.filter_out_ignored_recipes(data_raw.recipe)
                    updated_recipe_raw_materials = material.get_recipe_raw_materials(updated_filtered_recipes, recipe_raw.results[1].name, recipe_raw.results[1].amount, true)
                    updated_recipe_cost_scores = material.get_raw_material_costs(data_raw.item, data_raw.fluid, updated_recipe_raw_materials);
                    loop_breaker = loop_breaker + 1;
                    if loop_breaker > maximum_iterations then
                        break;
                    end
                end
            else
                -- Items
                while updated_recipe_cost_scores.item > 0 and (updated_recipe_cost_scores.item / old_recipe_cost_scores.item) > acceptable_ratio  do
                    util.logg(recipe_name .. " is too item expensive " .. updated_recipe_cost_scores.item .. " > " .. old_recipe_cost_scores.item)
                    for ingredient_name, ingredient_raw in pairs(recipe_raw.ingredients) do
                        if ingredient_raw.type == "item" then
                            ingredient_raw.amount = math.floor(ingredient_raw.amount / acceptable_ratio) -- Always decrements by at least one.
                            if ingredient_raw.amount < 1 then
                                ingredient_raw.amount = 1
                            elseif ingredient_raw.amount > defines.maximum_item_amount then
                                ingredient_raw.amount = defines.maximum_item_amount
                            end
                        end
                    end
                    updated_filtered_recipes = F.filter_out_ignored_recipes(data_raw.recipe)
                    updated_recipe_raw_materials = material.get_recipe_raw_materials(updated_filtered_recipes, recipe_raw.results[1].name, recipe_raw.results[1].amount, true)
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
                            elseif ingredient_raw.amount > defines.maximum_item_amount then
                                ingredient_raw.amount = defines.maximum_item_amount
                            end
                        end
                    end
                    updated_filtered_recipes = F.filter_out_ignored_recipes(data_raw.recipe)
                    updated_recipe_raw_materials = material.get_recipe_raw_materials(updated_filtered_recipes, recipe_raw.results[1].name, recipe_raw.results[1].amount, true)
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
                            elseif ingredient_raw.amount > defines.maximum_item_amount then
                                ingredient_raw.amount = defines.maximum_item_amount
                            end
                        end
                    end
                    updated_filtered_recipes = F.filter_out_ignored_recipes(data_raw.recipe)
                    updated_recipe_raw_materials = material.get_recipe_raw_materials(updated_filtered_recipes, recipe_raw.results[1].name, recipe_raw.results[1].amount, true)
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
                            elseif ingredient_raw.amount > defines.maximum_item_amount then
                                ingredient_raw.amount = defines.maximum_item_amount
                            end
                        end
                    end
                    updated_filtered_recipes = F.filter_out_ignored_recipes(data_raw.recipe)
                    updated_recipe_raw_materials = material.get_recipe_raw_materials(updated_filtered_recipes, recipe_raw.results[1].name, recipe_raw.results[1].amount, true)
                    updated_recipe_cost_scores = material.get_raw_material_costs(data_raw.item, data_raw.fluid, updated_recipe_raw_materials);
                    loop_breaker = loop_breaker + 1;
                    if loop_breaker > maximum_iterations then
                        break;
                    end
                end
            end
        end
    end
end

---@param raw_recipe table Wube-provided recipe structure.
---@param candidates_and_counts table Output of get_candidates_and_counts().
function F.pick_new_ingredients(raw_recipe, candidates_and_counts)
    for ingredient_index, ingredient in pairs(raw_recipe.ingredients) do
        if ingredient.type == "item" and candidates_and_counts.amount_of_item_candidates > candidates_and_counts.amount_of_item_ingredients then
            local picked_item = random.pick_any_true(candidates_and_counts.item_candidates)
            ingredient.name = picked_item
            candidates_and_counts.item_candidates[picked_item] = nil
            raw_recipe.modified = true
        elseif ingredient.type == "fluid" and candidates_and_counts.amount_of_fluid_candidates > candidates_and_counts.amount_of_fluid_ingredients then
            local picked_fluid = random.pick_any_true(candidates_and_counts.fluid_candidates)
            ingredient.name = picked_fluid
            candidates_and_counts.fluid_candidates[picked_fluid] = nil
            raw_recipe.modified = true
        end
    end
end

---@param data_raw table Wub-provided raw data.
---@param recipe_name string
---@param candidates_for_replacements table
---@return table Result item_candidates, fluid_candidates, amount_of_item_candidates, amount_of_fluid_candidates, amount_of_item_ingredients, amount_of_fluid_ingredients
function F.get_candidates_and_counts(data_raw, recipe_name, candidates_for_replacements)
    local raw_recipe = data_raw.recipe[recipe_name]
    local fluid_candidates = {};
    local amount_of_fluid_candidates = 0;
    local item_candidates = {};
    local amount_of_item_candidates = 0;
    for candidate_name, candidate in pairs(candidates_for_replacements) do
        if F.is_acceptable_type(data_raw, candidate_name, defines.types_of_items_and_fluid_for_ingredient_candidates) then
            if (data_raw.fluid[candidate_name]) then
                amount_of_fluid_candidates = amount_of_fluid_candidates + 1
                fluid_candidates[candidate_name] = true
            else
                amount_of_item_candidates = amount_of_item_candidates + 1
                item_candidates[candidate_name] = true
            end
        end
    end

    local amount_of_fluid_ingredients = 0;
    local amount_of_item_ingredients = 0;
    for ingredient_index, ingredient in pairs(raw_recipe.ingredients) do
        if ingredient.type == "item" then
            amount_of_item_ingredients = amount_of_item_ingredients + 1
        elseif ingredient.type == "fluid" then
            amount_of_fluid_ingredients = amount_of_fluid_ingredients + 1
        end
    end

    return {
        item_candidates = item_candidates,
        fluid_candidates = fluid_candidates,
        amount_of_item_candidates = amount_of_item_candidates,
        amount_of_fluid_candidates = amount_of_fluid_candidates,
        amount_of_item_ingredients = amount_of_item_ingredients,
        amount_of_fluid_ingredients = amount_of_fluid_ingredients
    }
end

--- Calculates original raw materials and cost scores of the recipe, and writes them to the raws.
---@param data_raw table Wube-provided raw data copy.
---@param recipe_name string
---@param available_recipes table
---@param filtered_recipes table
function F.annotate_with_original_cost_scores(data_raw, recipe_name, available_recipes, filtered_recipes)
    local raw_recipe = data_raw.recipe[recipe_name]
    local recipe_raw_materials = material.get_recipe_raw_materials(filtered_recipes, raw_recipe.results[1].name, raw_recipe.results[1].amount, true)
    local recipe_cost_scores = material.get_raw_material_costs(data_raw.item, data_raw.fluid, recipe_raw_materials);
    raw_recipe.original_raw_materials = recipe_raw_materials;
    raw_recipe.original_recipe_cost_scores = recipe_cost_scores;
end


---@param data_raw table Wube-provided raw data copy.
---@param recipe_name string
---@param available_recipes table
---@param filtered_recipes table
function F.randomize_recipe(data_raw, recipe_name, available_recipes, filtered_recipes)
    local raw_recipe = data_raw.recipe[recipe_name]
    local recipe_raw_materials = raw_recipe.original_raw_materials
    local recipe_cost_scores = raw_recipe.original_recipe_cost_scores;

    -- Since these are recipes, find the results they produce.
    local available_results = {};
    for available_recipe_name, available_recipe in pairs(available_recipes) do
        local recipe_raw = data_raw.recipe[available_recipe_name]
        if recipe_raw.results then
            for _, result in pairs(recipe_raw.results) do
                -- Deliberately excluding tools, ie. science packs.
                if data_raw.item[result.name] or data_raw.fluid[result.name] then
                    available_results[result.name] = true
                end
            end
        end
    end
    local candidates_for_replacements = {};
    for candidate_name, candidate in pairs(available_results) do
        local candidate_raw_materials = material.get_recipe_raw_materials(filtered_recipes, candidate_name, 1, true)
        local candidate_scores = material.get_raw_material_costs(data_raw.item, data_raw.fluid, candidate_raw_materials);
        -- Only items considered if they cost less than the total raw of the recipe to be randomized, in both fluids and items.
        if (candidate_scores.item < recipe_cost_scores.item or (candidate_scores.item == recipe_cost_scores.item and candidate_scores.item == 0)) and (candidate_scores.fluid < recipe_cost_scores.fluid or (candidate_scores.fluid == recipe_cost_scores.fluid and candidate_scores.fluid == 0)) then
            -- And only if their raw material list is a subset of the raw material list of the recipe to be randomized.
            if util.table_keys_subset(candidate_raw_materials, recipe_raw_materials) then
                -- And if it's not the same item. No breeding!
                if candidate_name ~= recipe_name then
                    -- And if the candidate itself is not already being made from the this recipe, ie. not making gears from belts (made from gears).
                    if not F.is_recipe_made_of_this(data_raw.recipe, candidate_name, recipe_name) then
                        candidates_for_replacements[candidate_name] = candidate_scores
                    end
                end
            end
        end
    end

    local candidates_and_counts = F.get_candidates_and_counts(data_raw, recipe_name, candidates_for_replacements);
    F.pick_new_ingredients(raw_recipe, candidates_and_counts)
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

---@param data_raw table Wube-provided raw data.
---@param recipe_name string
---@param acceptable_types table Array of defined types, see defines.lua.
---@return boolean
function F.is_acceptable_type(data_raw, recipe_name, acceptable_types)
    for _, type_of_thing in pairs(acceptable_types) do
       if data_raw[type_of_thing][recipe_name] then
        return true
       end
    end
    return false
end

---@param data_raw table An instance of data.raw as provided by Wube
---@param recipes_to_randomize table
---@param current_filtered_recipes table
function F.filter_out_non_randomizable_recipes(data_raw, recipes_to_randomize, current_filtered_recipes)
    local filtered_recipes_to_randomize = table.deepcopy(recipes_to_randomize);
    for recipe_to_randomize_name, recipe_to_randomize in pairs(recipes_to_randomize) do
        -- Only recipes that aren't ignored and exist as items (or subtypes of item) or fluids.
        if not current_filtered_recipes[recipe_to_randomize_name] or (not F.is_acceptable_type(data_raw, recipe_to_randomize_name, defines.types_of_items_and_fluid_for_randomizable_recipes)) then
            filtered_recipes_to_randomize[recipe_to_randomize_name] = nil
        end
        -- No breeders (recipes with a result in ingredients).
        local raw_recipe = data_raw.recipe[recipe_to_randomize_name]
        local is_breeder = false;
        for _, ingredient in pairs(raw_recipe.ingredients) do
            if ingredient.name == recipe_to_randomize_name then
                is_breeder = true;
            end
        end
        if is_breeder == true then
            filtered_recipes_to_randomize[recipe_to_randomize_name] = nil
        end
        -- If a recipe is made solely from raw materials, don't randomize it.
        local raw_materials = material.get_recipe_raw_materials(current_filtered_recipes, recipe_to_randomize_name, 1, true)
        local has_non_raw_ingredient = false;
        for _, ingredient in pairs(raw_recipe.ingredients) do
            if not raw_materials[ingredient.name] then
                has_non_raw_ingredient = true;
            end
        end
        if has_non_raw_ingredient == false then
            filtered_recipes_to_randomize[recipe_to_randomize_name] = nil
        end
        -- If recipe has surface conditions, don't randomize it.
        -- TODO: Maybe there is a better method.
        -- IDEA: If recipe has surface conditions, its new raw materials must match old raw materials.
        if raw_recipe.surface_conditions and next(raw_recipe.surface_conditions) ~= nil then
            filtered_recipes_to_randomize[recipe_to_randomize_name] = nil
        end
    end

    return filtered_recipes_to_randomize
end


return F;