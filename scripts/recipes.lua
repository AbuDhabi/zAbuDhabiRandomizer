local util = require "scripts.utilities"
local defines = require "scripts.defines"
local tech = require "scripts.technology"
local material = require "scripts.raw_materials"

local F = {};

function F.get_recipe_raw_materials(recipes, item_or_fluid_name, amount_demanded)
    local found_recipe = recipes[item_or_fluid_name] -- Naively try a recipe with the exact same name.
    if found_recipe == nil and false then -- TODO: Currently this finds coal-synthesis and breaks.
        found_recipe = F.try_to_find_a_non_obvious_recipe(recipes, item_or_fluid_name)
    end
    if found_recipe then
        local found_raw_materials = {};
        if found_recipe.ingredients == nil then
            return {} -- No ingredients.
        end
        local amount_produced = 1;
        for _, result in pairs(found_recipe.results) do
            if result.name == found_recipe.name then
                amount_produced = result.amount
            end
        end
        for _, ingredient in pairs(found_recipe.ingredients) do
            if item_or_fluid_name == ingredient.name then
                return item_or_fluid_name -- Recipe is a breeder, ie. produces something from itself. Need to avoid loop.
            end
            local ingredient_raw_materials = F.get_recipe_raw_materials(recipes, ingredient.name, ingredient.amount)
            if type(ingredient_raw_materials) == "table" then
                for raw_material_name, raw_material_amount in pairs(ingredient_raw_materials) do
                    local already_counted = found_raw_materials[raw_material_name] or 0
                    found_raw_materials[raw_material_name] = already_counted + raw_material_amount
                 end
            else
                found_raw_materials[ingredient_raw_materials] = ingredient.amount
            end
        end
        -- Multiply by demanded-to-produced ratio.
        for found_raw_material_name, found_raw_material_amount in pairs(found_raw_materials) do
            found_raw_materials[found_raw_material_name] = found_raw_material_amount * (amount_demanded / amount_produced)
        end
        return found_raw_materials
    else
        return item_or_fluid_name -- Doesn't have a recipe, it's a raw material.
    end
end

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

function F.balance_costs(data_raw, original_recipe_cost_scores)
    for recipe_name, recipe_raw in pairs(data_raw.recipe) do
        if recipe_raw.modified then
            local updated_filtered_recipes = F.filter_out_ignored_recipes(data_raw.recipe)
            local updated_recipe_raw_materials = F.get_recipe_raw_materials(updated_filtered_recipes, recipe_raw.results[1].name, recipe_raw.results[1].amount)
            local updated_recipe_cost_scores = material.get_raw_material_costs(data_raw.item, data_raw.fluid, updated_recipe_raw_materials);
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
                updated_filtered_recipes = F.filter_out_ignored_recipes(data_raw.recipe)
                updated_recipe_raw_materials = F.get_recipe_raw_materials(updated_filtered_recipes, recipe_raw.results[1].name, recipe_raw.results[1].amount)
                updated_recipe_cost_scores = material.get_raw_material_costs(data_raw.item, data_raw.fluid, updated_recipe_raw_materials);
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
                updated_filtered_recipes = F.filter_out_ignored_recipes(data_raw.recipe)
                updated_recipe_raw_materials = F.get_recipe_raw_materials(updated_filtered_recipes, recipe_raw.results[1].name, recipe_raw.results[1].amount)
                updated_recipe_cost_scores = material.get_raw_material_costs(data_raw.item, data_raw.fluid, updated_recipe_raw_materials);
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
                updated_filtered_recipes = F.filter_out_ignored_recipes(data_raw.recipe)
                updated_recipe_raw_materials = F.get_recipe_raw_materials(updated_filtered_recipes, recipe_raw.results[1].name, recipe_raw.results[1].amount)
                updated_recipe_cost_scores = material.get_raw_material_costs(data_raw.item, data_raw.fluid, updated_recipe_raw_materials);
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
                updated_filtered_recipes = F.filter_out_ignored_recipes(data_raw.recipe)
                updated_recipe_raw_materials = F.get_recipe_raw_materials(updated_filtered_recipes, recipe_raw.results[1].name, recipe_raw.results[1].amount)
                updated_recipe_cost_scores = material.get_raw_material_costs(data_raw.item, data_raw.fluid, updated_recipe_raw_materials);
                loop_breaker = loop_breaker + 1;
                if loop_breaker > maximum_iterations then
                    break;
                end
            end
        end
    end
end


return F;