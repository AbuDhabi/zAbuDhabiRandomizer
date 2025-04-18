local util = require "scripts.utilities"

local F = {};

function F.get_technology_table(data_raw_technology, data_raw_recipe)
    -- technologies_with_prerequisites : string->object dictionary
    --      prerequisites : string->bool dictionary
    --      recipes_unlocked: string->bool dictionary
    --      results_unlocked: string->string dictionary
    --      ingredients_used: string->string dictionary
    local technologies_with_prerequisites = {};
    for tech_name, tech_raw in pairs(data_raw_technology) do
        local recipes_unlocked = {}
        local results_unlocked = {}
        local ingredients_used = {}
        if tech_raw.effects then
            for _, effect in pairs(tech_raw.effects) do
                if effect.type == "unlock-recipe" then
                    recipes_unlocked[effect.recipe] = true
                    local recipe = data_raw_recipe[effect.recipe]
                    for _, result in pairs(recipe.results) do
                        results_unlocked[result.name] = result.type
                    end
                    for _, ingredient in pairs(recipe.ingredients) do
                        ingredients_used[ingredient.name] = ingredient.type
                    end
                end
            end
        end

        local prerequisites = {}
        if tech_raw.prerequisites then
            for _, prerequisite in pairs(tech_raw.prerequisites) do
                prerequisites[prerequisite] = true
            end
        end

        technologies_with_prerequisites[tech_name] = {
            prerequisites = prerequisites,
            recipes_unlocked = recipes_unlocked,
            results_unlocked = results_unlocked,
            ingredients_used = ingredients_used
        }
    end

    return technologies_with_prerequisites
end

function F.get_unlocked_recipes(technology_tree, technology_name)
    local unlocked_recipes = {};
    for unlocked_recipe_name, _ in pairs(technology_tree[technology_name].recipes_unlocked) do
        unlocked_recipes[unlocked_recipe_name] = true
    end

    for prerequisite_name, _ in pairs(technology_tree[technology_name].prerequisites) do
        local recipes_unlocked_by_prerequisites = F.get_unlocked_recipes(technology_tree, prerequisite_name)
        for recipe_unlocked_by_prerequisite, _  in pairs(recipes_unlocked_by_prerequisites) do
            unlocked_recipes[recipe_unlocked_by_prerequisite] = true
        end
    end

    return unlocked_recipes
end


return F