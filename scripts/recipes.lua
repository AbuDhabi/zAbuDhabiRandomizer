local utilities = require "scripts.utilities"

local F = {};

function F.get_recipe_raw_materials(data_raw_recipes, recipe_name, amount_demanded)
    local found_recipe = data_raw_recipes[recipe_name]
    if found_recipe then
        local found_raw_materials = {};
        if found_recipe.original.ingredients == nil then
            return {} -- No ingredients.
        end
        for _, ingredient in pairs(found_recipe.original.ingredients) do
            if recipe_name == ingredient.name then
                return recipe_name -- Recipe is a breeder, ie. produces something from itself. Need to avoid loop.
            end
            local amount_produced = found_recipe.original.results[1].amount -- TODO: Will fail if there's more results sometimes.
            local ingredient_raw_materials = F.get_recipe_raw_materials(data_raw_recipes, ingredient.name, ingredient.amount)
            if type(ingredient_raw_materials) == "table" then
                for raw_material_name, raw_material_amount in pairs(ingredient_raw_materials) do
                    local already_counted = found_raw_materials[raw_material_name] or 0
                    found_raw_materials[raw_material_name] = already_counted + (raw_material_amount * (amount_demanded / amount_produced))
                 end
            else
                found_raw_materials[ingredient_raw_materials] = ingredient.amount * (amount_demanded / amount_produced)
            end
        end
        return found_raw_materials
    else
        return recipe_name -- Doesn't have a recipe, it's a raw material.
    end
end


return F;