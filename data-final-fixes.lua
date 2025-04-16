local util = require "scripts.utilities"

-- Get all technologies.
-- Create an ancestor graph from them. The technology plus its ancestors.
-- For each technology, randomize its recipe ingredients allowing stuff already unlocked in its ancestors and itself (except the item in question).

-- technologies_with_prerequisites : string->object dictionary
--      prerequisites : string array
--      recipes_unlocked: string array
--      ingredients_unlocked: string->string dictionary
local technologies_with_prerequisites = {};
for tech_name, tech_raw in pairs(data.raw.technology) do
    local recipes_unlocked = {}
    local ingredients_unlocked = {}
    if tech_raw.effects then
        for _, effect in pairs(tech_raw.effects) do
            if effect.type == "unlock-recipe" then
                table.insert(recipes_unlocked, effect.recipe)
                local recipe = data.raw.recipe[effect.recipe]
                for _, result in pairs(recipe.results) do
                    ingredients_unlocked[result.name] = result.type
                end
            end
        end
    end
    
    technologies_with_prerequisites[tech_name] = {
        prerequisites = tech_raw.prerequisites,
        recipes_unlocked = recipes_unlocked,
        ingredients_unlocked = ingredients_unlocked
    }
end
util.logg(technologies_with_prerequisites)

