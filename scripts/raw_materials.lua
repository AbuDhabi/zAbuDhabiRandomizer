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
                    return item_or_fluid_name;
                end
                -- TODO: Verify this amount works
                local breeder_ingredients = {};
                for _, breeder_ingredient in pairs(found_recipe.ingredients) do
                    breeder_ingredients[breeder_ingredient.name] = breeder_ingredient.amount
                end
                return breeder_ingredients
            end
        end
        for _, ingredient in pairs(found_recipe.ingredients) do
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
        -- Multiply by demanded-to-produced ratio.
        for found_raw_material_name, found_raw_material_amount in pairs(found_raw_materials) do
            found_raw_materials[found_raw_material_name] = found_raw_material_amount * (amount_demanded / amount_produced)
        end
        return found_raw_materials
    else
        return item_or_fluid_name -- Doesn't have a recipe, it's a raw material.
    end
end

return F;