local defines = require "scripts.defines"
local util = require "scripts.utilities"

local F = {};

---Calculates raw material "costs", ie. sums of fluid and item raw materials.
---@param data_raw_item table Wube-provided data.raw.item
---@param data_raw_fluid table Wube-provided data.raw.fluid
---@param raw_materials table Keys: item names, values: amounts needed to produce one unit
---@return table Scores { item: number, fluid: number }
function F.get_raw_material_costs(data_raw_item, data_raw_fluid, raw_materials)
    local scores = { item = 0, fluid = 0};
    for material_name, material_amount in pairs(raw_materials) do
        if data_raw_item[material_name] then
            scores.item = scores.item + material_amount
        elseif data_raw_fluid[material_name] then
            scores.fluid = scores.fluid + material_amount
        end
    end
    return scores
end

---@param recipes table
---@param item_or_fluid_name string
---@param amount_demanded number Integer
---@param top_level boolean True when calling from somewhere else, false when recursing within.
---@return any When top_level = true, then table. Otherwise table or string.
function F.get_recipe_raw_materials(recipes, item_or_fluid_name, amount_demanded, top_level)
    local found_recipe = recipes[item_or_fluid_name] -- Naively try a recipe with the exact same name.
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
            if item_or_fluid_name == ingredient.name then -- Recipe is a breeder, ie. produces something from itself. Need to avoid loop.
                if not top_level then
                    return item_or_fluid_name
                end
                local already_counted = found_raw_materials[item_or_fluid_name] or 0
                found_raw_materials[item_or_fluid_name] = already_counted + ingredient.amount
            else
                local ingredient_raw_materials = F.get_recipe_raw_materials(recipes, ingredient.name, ingredient.amount, false)
                if type(ingredient_raw_materials) == "table" then
                    for raw_material_name, raw_material_amount in pairs(ingredient_raw_materials) do
                        local already_counted = found_raw_materials[raw_material_name] or 0
                        found_raw_materials[raw_material_name] = already_counted + raw_material_amount
                     end
                else
                    found_raw_materials[ingredient_raw_materials] = ingredient.amount
                end
            end
        end
        -- Multiply by demanded-to-produced ratio.
        for found_raw_material_name, found_raw_material_amount in pairs(found_raw_materials) do
            found_raw_materials[found_raw_material_name] = found_raw_material_amount * (amount_demanded / amount_produced)
        end
        return found_raw_materials
    else
        -- Doesn't have a recipe, it's a raw material.
        if not top_level then
            return item_or_fluid_name; -- Found in recursion.
        else
            local return_value = {};
            return_value[item_or_fluid_name] = amount_demanded;
            return return_value -- The raw material itself.
        end
    end
end

---Calculates the difference between the raw material amounts of recipes/items/fluids.
---@param data_raw table Wube-provided raw data.
---@param recipes table
---@param original_ingredient string
---@param candidate_ingredient string
---@return number Result Difference between adjusted ingredient counts.
function F.compare_raw_material_difference(data_raw, recipes, original_ingredient, candidate_ingredient)
    -- Original costs should be considered for ingredients, because that's what we're balancing for.
    local original_cost_scores = nil
    if data_raw.recipe[original_ingredient] then
        original_cost_scores = table.deepcopy(data_raw.recipe[original_ingredient].original_recipe_cost_scores)
    end
    if original_cost_scores then
        if data_raw.recipe[original_ingredient].results[1].amount > 1 then
            original_cost_scores.item = original_cost_scores.item / data_raw.recipe[original_ingredient].results[1].amount
            original_cost_scores.fluid = original_cost_scores.fluid / data_raw.recipe[original_ingredient].results[1].amount
        end
    else
        -- Sometimes the cost scores may be missing, eg. for raw materials themselves.
        local original_raw_materials = F.get_recipe_raw_materials(recipes, original_ingredient, 1, true);
        original_cost_scores = F.get_raw_material_costs(data_raw.item, data_raw.fluid, original_raw_materials);
    end
    original_cost_scores.fluid = original_cost_scores.fluid / defines.fluid_to_item_ratio

    -- Candidates have to be calculated according to current knowledge.
    local candidate_raw_materials = F.get_recipe_raw_materials(recipes, candidate_ingredient, 1, true);
    local candidate_cost_scores = F.get_raw_material_costs(data_raw.item, data_raw.fluid, candidate_raw_materials);
    candidate_cost_scores.fluid = candidate_cost_scores.fluid / defines.fluid_to_item_ratio;

    local original_count = original_cost_scores.item + original_cost_scores.fluid;
    local candidate_count = candidate_cost_scores.item + candidate_cost_scores.fluid;

    if original_count > candidate_count then
        return original_count - candidate_count
    else
        return candidate_count - original_count
    end
end

---Gets the defined amount of best candidates.
---@param data_raw table Wube-provided raw data.
---@param recipes table Current filtered recipes.
---@param candidates table string->bool
---@param original_ingredient_name string
---@return table
function F.get_good_candidates(data_raw, recipes, candidates, original_ingredient_name)
    local candidate_differences = {};
    for candidate_name, _ in pairs(candidates) do
        local difference = F.compare_raw_material_difference(data_raw, recipes, original_ingredient_name, candidate_name)
        candidate_differences[candidate_name] = difference
    end
    local best_candidates = {};
    for i=1,defines.number_of_good_candidates,1 do
        local best_candidate = util.get_lowest_value_key(candidate_differences)
        if best_candidate == nil then
            return best_candidates
        end
        best_candidates[best_candidate] = true
        candidate_differences[best_candidate] = nil
    end
    return best_candidates
end

return F;