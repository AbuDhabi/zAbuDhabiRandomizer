local F = {};

function F.find_initially_available_ingredients(technology_tree)
    local initial_ingredients = {}; -- string->bool dictionary
    -- Collect ingredients and results from recipes unlocked at start.
    for _, recipe in pairs(data.raw.recipe) do
        if (recipe.enabled == nil or recipe.enabled == true) and (recipe.hidden ~= true) and (recipe.category ~= "parameters") then
            if recipe.results then
                for _, result in pairs(recipe.results) do
                    initial_ingredients[result.name] = true
                end
            end
            if recipe.ingredients then
                for _, ingredient in pairs(recipe.ingredients) do
                    initial_ingredients[ingredient.name] = true
                end
            end
        end
    end

    return initial_ingredients
end

return F