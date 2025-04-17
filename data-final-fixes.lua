local util = require "scripts.utilities"
local tech = require "scripts.technology"

-- Get all technologies.
-- Create an ancestor graph from them. The technology plus its ancestors.
-- For each technology, randomize its recipe ingredients allowing stuff already unlocked in its ancestors and itself (except the item in question).



local technology_tree = tech.build_tech_tree();

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
