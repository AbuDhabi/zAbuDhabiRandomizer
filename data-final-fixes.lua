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
local technology_tree = table.deepcopy(technologies_with_prerequisites);
for _, tech_with_prereqs in pairs(technology_tree) do
    local prerequisite_references = {}
    if tech_with_prereqs.prerequisites then
        for _, prereq_name in pairs(tech_with_prereqs.prerequisites) do
            prerequisite_references[prereq_name] = technology_tree[prereq_name]
        end
        tech_with_prereqs.prerequisites = prerequisite_references
    end
end

local all_raw_materials = {}; -- string->bool dictionary
local advanced_raw_materials = {}; -- string->bool dictionary
local results_in_technologies = {}; -- string->bool dictionary
local ingredients_in_technologies = {}; -- string->bool dictionary
for _, tech in pairs(technology_tree) do
    for result_name, _ in pairs(tech.results_unlocked) do
        results_in_technologies[result_name] = true
    end
    for ingredient_name, _ in pairs(tech.ingredients_used) do
        ingredients_in_technologies[ingredient_name] = true
    end
end
for ingredient_name, _ in pairs(ingredients_in_technologies) do
    if not results_in_technologies[ingredient_name] then
        advanced_raw_materials[ingredient_name] = true
    end
end

local initial_raw_materials = {}; -- string->bool dictionary
local initial_results = {}; -- string->bool dictionary
local initial_ingredients = {}; -- string->bool dictionary
for recipe_name, recipe in pairs(data.raw.recipe) do
    if (recipe.enabled == nil or recipe.enabled == true) and (recipe.hidden ~= true) and (recipe.category ~= "parameters") then
        util.logg(recipe_name)
        if recipe.results then
            for _, result in pairs(recipe.results) do
                initial_results[result.name] = true
            end
        end
        if recipe.ingredients then
            for _, ingredient in pairs(recipe.ingredients) do
                initial_ingredients[ingredient.name] = true
            end
        end
    end
end

for ingredient_name, _ in pairs(initial_ingredients) do
    if not initial_results[ingredient_name] then
        initial_raw_materials[ingredient_name] = true
    end
end

for key, _ in pairs(advanced_raw_materials) do
    all_raw_materials[key] = true
end
for key, _ in pairs(initial_raw_materials) do
    all_raw_materials[key] = true
end

util.logg(all_raw_materials)
