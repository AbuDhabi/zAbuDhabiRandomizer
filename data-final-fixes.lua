local util = require "scripts.utilities"

-- Get all technologies.
-- Create an ancestor graph from them. The technology plus its ancestors.
-- For each technology, randomize its recipe ingredients allowing stuff already unlocked in its ancestors and itself (except the item in question).

-- technologies_with_prerequisites : string->object dictionary
--      prerequisites : string array
--      recipes_unlocked: string array
--      results_unlocked: string->string dictionary
--      ingredients_used: string->string dictionary
local technologies_with_prerequisites = {};
for tech_name, tech_raw in pairs(data.raw.technology) do
    local recipes_unlocked = {}
    local results_unlocked = {}
    local ingredients_used = {}
    if tech_raw.effects then
        for _, effect in pairs(tech_raw.effects) do
            if effect.type == "unlock-recipe" then
                table.insert(recipes_unlocked, effect.recipe)
                local recipe = data.raw.recipe[effect.recipe]
                for _, result in pairs(recipe.results) do
                    results_unlocked[result.name] = result.type
                end
                for _, ingredient in pairs(recipe.ingredients) do
                    ingredients_used[ingredient.name] = ingredient.type
                end
            end
        end
    end
    
    technologies_with_prerequisites[tech_name] = {
        prerequisites = tech_raw.prerequisites,
        recipes_unlocked = recipes_unlocked,
        results_unlocked = results_unlocked,
        ingredients_used = ingredients_used
    }
end

-- technologies_with_prerequisites : string->object dictionary
--      prerequisites : string->object dictionary
--      recipes_unlocked: string array
--      results_unlocked: string->string dictionary
--      ingredients_used: string->string dictionary
for _, tech_with_prereqs in pairs(technologies_with_prerequisites) do
    local prerequisite_references = {}
    if tech_with_prereqs.prerequisites then
        for _, prereq_name in pairs(tech_with_prereqs.prerequisites) do
            prerequisite_references[prereq_name] = technologies_with_prerequisites[prereq_name]
        end
        tech_with_prereqs.prerequisites = prerequisite_references
    end
end

util.logg(technologies_with_prerequisites)