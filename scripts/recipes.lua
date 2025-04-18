local utilities = require "scripts.utilities"

local F = {};

function F.get_recipe_raw_materials(data_raw_recipes, recipe_name)
    utilities.logg("getting raw for " .. recipe_name)
    local found_recipe = data_raw_recipes[recipe_name]
    if found_recipe then
        local found_raw_materials = {};
        for _, ingredient in pairs(found_recipe.original.ingredients) do
            local ingredient_raw_materials = F.get_recipe_raw_materials(data_raw_recipes, ingredient.name)
            utilities.logg(ingredient_raw_materials)
            if type(ingredient_raw_materials) == "table" then
                for raw_material_name, _ in pairs(ingredient_raw_materials) do
                    found_raw_materials[raw_material_name] = true
                 end
            else
                found_raw_materials[ingredient_raw_materials] = true
            end
        end
        return found_raw_materials
    else
        return recipe_name -- Doesn't have a recipe, it's a raw material.
    end
end


return F;