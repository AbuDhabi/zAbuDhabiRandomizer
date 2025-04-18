local util = require "scripts.utilities"
local defines = require "scripts.defines"
local tech = require "scripts.technology"

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
        for _, ingredient in pairs(found_recipe.ingredients) do
            if item_or_fluid_name == ingredient.name then
                return item_or_fluid_name -- Recipe is a breeder, ie. produces something from itself. Need to avoid loop.
            end
            local amount_produced = 1;
            for _, result in pairs(found_recipe.results) do
                if result.name == found_recipe then
                    amount_produced = result.amount
                end
            end
            local ingredient_raw_materials = F.get_recipe_raw_materials(recipes, ingredient.name, ingredient.amount)
            if type(ingredient_raw_materials) == "table" then
                for raw_material_name, raw_material_amount in pairs(ingredient_raw_materials) do
                    local already_counted = found_raw_materials[raw_material_name] or 0
                    found_raw_materials[raw_material_name] = already_counted + raw_material_amount
                 end
                 for raw_material_name, raw_material_amount in pairs(ingredient_raw_materials) do
                    found_raw_materials[raw_material_name] = raw_material_amount * (amount_demanded / amount_produced) -- Multiply only once.
                 end
            else
                found_raw_materials[ingredient_raw_materials] = ingredient.amount * (amount_demanded / amount_produced)
            end
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


return F;