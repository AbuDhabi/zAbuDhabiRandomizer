local util = require "scripts.utilities"
local defines = require "scripts.defines"
local material = require "scripts.raw_materials"
local recipe_module = require "scripts.recipes"

local F = {};


---Balances costs in the raw dataset.
---@param data_raw table Wube-provided raw data, modified by randomization.
function F.balance_costs(data_raw)
    for recipe_name, recipe_raw in pairs(data_raw.recipe) do
        if recipe_raw.processed then
            local updated_filtered_recipes = recipe_module.filter_out_ignored_recipes(data_raw.recipe)
            local updated_recipe_raw_materials = material.get_recipe_raw_materials(updated_filtered_recipes, recipe_raw.results[1].name, recipe_raw.results[1].amount, true)
            local updated_recipe_cost_scores = material.get_raw_material_costs(data_raw.item, data_raw.fluid, updated_recipe_raw_materials);
            local old_recipe_cost_scores = recipe_raw.original_recipe_cost_scores
    
            -- Adjust costs if they're not sufficiently close to the original.
            local loop_breaker = 0;
            local acceptable_ratio = 1.1;
            local maximum_iterations = 100;
            -- Combined, both fluid and item raw materials.
            if updated_recipe_cost_scores.item > 0 and updated_recipe_cost_scores.fluid > 0 then
                -- Too expensive.
                loop_breaker = 0;
                local recipe_ratio = function (updated_recipe_cost_scores, old_recipe_cost_scores)
                    return (updated_recipe_cost_scores.item / old_recipe_cost_scores.item) * (updated_recipe_cost_scores.fluid / old_recipe_cost_scores.fluid);
                end
                while (recipe_ratio(updated_recipe_cost_scores, old_recipe_cost_scores)) > acceptable_ratio  do
                    util.logg(recipe_name .. " is too expensive " .. recipe_ratio(updated_recipe_cost_scores, old_recipe_cost_scores) .. " > " .. acceptable_ratio)
                    for ingredient_name, ingredient_raw in pairs(recipe_raw.ingredients) do
                        ingredient_raw.amount = math.floor(ingredient_raw.amount / acceptable_ratio) -- Always decrements by at least one.
                        if ingredient_raw.amount < 1 then
                            ingredient_raw.amount = 1
                        elseif ingredient_raw.amount > defines.maximum_item_amount then
                            ingredient_raw.amount = defines.maximum_item_amount
                        end
                    end
                    updated_filtered_recipes = recipe_module.filter_out_ignored_recipes(data_raw.recipe)
                    updated_recipe_raw_materials = material.get_recipe_raw_materials(updated_filtered_recipes, recipe_raw.results[1].name, recipe_raw.results[1].amount, true)
                    updated_recipe_cost_scores = material.get_raw_material_costs(data_raw.item, data_raw.fluid, updated_recipe_raw_materials);
                    loop_breaker = loop_breaker + 1;
                    if loop_breaker > maximum_iterations then
                        break;
                    end
                end
                -- Too cheap.
                loop_breaker = 0;
                recipe_ratio = function (old_recipe_cost_scores, updated_recipe_cost_scores)
                    return (old_recipe_cost_scores.item / updated_recipe_cost_scores.item) * (old_recipe_cost_scores.fluid / updated_recipe_cost_scores.fluid)
                end
                while (recipe_ratio(old_recipe_cost_scores, updated_recipe_cost_scores)) > acceptable_ratio  do
                    util.logg(recipe_name .. " is too cheap " .. recipe_ratio(old_recipe_cost_scores, updated_recipe_cost_scores) .. " > " .. acceptable_ratio)
                    for ingredient_name, ingredient_raw in pairs(recipe_raw.ingredients) do
                        ingredient_raw.amount = math.ceil(ingredient_raw.amount * acceptable_ratio) -- Always increments by at least one.
                        if ingredient_raw.amount < 1 then
                            ingredient_raw.amount = 1
                        elseif ingredient_raw.amount > defines.maximum_item_amount then
                            ingredient_raw.amount = defines.maximum_item_amount
                        end
                    end
                    updated_filtered_recipes = recipe_module.filter_out_ignored_recipes(data_raw.recipe)
                    updated_recipe_raw_materials = material.get_recipe_raw_materials(updated_filtered_recipes, recipe_raw.results[1].name, recipe_raw.results[1].amount, true)
                    updated_recipe_cost_scores = material.get_raw_material_costs(data_raw.item, data_raw.fluid, updated_recipe_raw_materials);
                    loop_breaker = loop_breaker + 1;
                    if loop_breaker > maximum_iterations then
                        break;
                    end
                end
            else
                -- Items
                while updated_recipe_cost_scores.item > 0 and (updated_recipe_cost_scores.item / old_recipe_cost_scores.item) > acceptable_ratio  do
                    util.logg(recipe_name .. " is too item expensive " .. updated_recipe_cost_scores.item .. " > " .. old_recipe_cost_scores.item)
                    for ingredient_name, ingredient_raw in pairs(recipe_raw.ingredients) do
                        if ingredient_raw.type == "item" then
                            ingredient_raw.amount = math.floor(ingredient_raw.amount / acceptable_ratio) -- Always decrements by at least one.
                            if ingredient_raw.amount < 1 then
                                ingredient_raw.amount = 1
                            elseif ingredient_raw.amount > defines.maximum_item_amount then
                                ingredient_raw.amount = defines.maximum_item_amount
                            end
                        end
                    end
                    updated_filtered_recipes = recipe_module.filter_out_ignored_recipes(data_raw.recipe)
                    updated_recipe_raw_materials = material.get_recipe_raw_materials(updated_filtered_recipes, recipe_raw.results[1].name, recipe_raw.results[1].amount, true)
                    updated_recipe_cost_scores = material.get_raw_material_costs(data_raw.item, data_raw.fluid, updated_recipe_raw_materials);
                    loop_breaker = loop_breaker + 1;
                    if loop_breaker > maximum_iterations then
                        break;
                    end
                end
                loop_breaker = 0;
                while updated_recipe_cost_scores.item > 0 and (old_recipe_cost_scores.item / updated_recipe_cost_scores.item) > acceptable_ratio do
                    util.logg(recipe_name .. " is too item cheap " .. updated_recipe_cost_scores.item .. " < " .. old_recipe_cost_scores.item)
                    for ingredient_name, ingredient_raw in pairs(recipe_raw.ingredients) do
                        if ingredient_raw.type == "item" then
                            ingredient_raw.amount = math.ceil(ingredient_raw.amount * acceptable_ratio) -- Always increments by at least one.
                            if ingredient_raw.amount < 1 then
                                ingredient_raw.amount = 1
                            elseif ingredient_raw.amount > defines.maximum_item_amount then
                                ingredient_raw.amount = defines.maximum_item_amount
                            end
                        end
                    end
                    updated_filtered_recipes = recipe_module.filter_out_ignored_recipes(data_raw.recipe)
                    updated_recipe_raw_materials = material.get_recipe_raw_materials(updated_filtered_recipes, recipe_raw.results[1].name, recipe_raw.results[1].amount, true)
                    updated_recipe_cost_scores = material.get_raw_material_costs(data_raw.item, data_raw.fluid, updated_recipe_raw_materials);
                    loop_breaker = loop_breaker + 1;
                    if loop_breaker > maximum_iterations then
                        break;
                    end
                end
                -- Fluids
                loop_breaker = 0;
                while updated_recipe_cost_scores.fluid > 0 and (updated_recipe_cost_scores.fluid / old_recipe_cost_scores.fluid) > acceptable_ratio  do
                    util.logg(recipe_name .. " is too fluid expensive " .. updated_recipe_cost_scores.fluid .. " > " .. old_recipe_cost_scores.fluid)
                    for ingredient_name, ingredient_raw in pairs(recipe_raw.ingredients) do
                        if ingredient_raw.type == "fluid" then
                            ingredient_raw.amount = math.floor(ingredient_raw.amount / acceptable_ratio) -- Always decrements by at least one.
                            if ingredient_raw.amount < 1 then
                                ingredient_raw.amount = 1
                            elseif ingredient_raw.amount > defines.maximum_item_amount then
                                ingredient_raw.amount = defines.maximum_item_amount
                            end
                        end
                    end
                    updated_filtered_recipes = recipe_module.filter_out_ignored_recipes(data_raw.recipe)
                    updated_recipe_raw_materials = material.get_recipe_raw_materials(updated_filtered_recipes, recipe_raw.results[1].name, recipe_raw.results[1].amount, true)
                    updated_recipe_cost_scores = material.get_raw_material_costs(data_raw.item, data_raw.fluid, updated_recipe_raw_materials);
                    loop_breaker = loop_breaker + 1;
                    if loop_breaker > maximum_iterations then
                        break;
                    end
                end
                loop_breaker = 0;
                while updated_recipe_cost_scores.fluid > 0 and (old_recipe_cost_scores.fluid / updated_recipe_cost_scores.fluid) > acceptable_ratio do
                    util.logg(recipe_name .. " is too fluid cheap " .. updated_recipe_cost_scores.fluid .. " < " .. old_recipe_cost_scores.fluid)
                    for ingredient_name, ingredient_raw in pairs(recipe_raw.ingredients) do
                        if ingredient_raw.type == "fluid" then
                            ingredient_raw.amount = math.ceil(ingredient_raw.amount * acceptable_ratio) -- Always increments by at least one.
                            if ingredient_raw.amount < 1 then
                                ingredient_raw.amount = 1
                            elseif ingredient_raw.amount > defines.maximum_item_amount then
                                ingredient_raw.amount = defines.maximum_item_amount
                            end
                        end
                    end
                    updated_filtered_recipes = recipe_module.filter_out_ignored_recipes(data_raw.recipe)
                    updated_recipe_raw_materials = material.get_recipe_raw_materials(updated_filtered_recipes, recipe_raw.results[1].name, recipe_raw.results[1].amount, true)
                    updated_recipe_cost_scores = material.get_raw_material_costs(data_raw.item, data_raw.fluid, updated_recipe_raw_materials);
                    loop_breaker = loop_breaker + 1;
                    if loop_breaker > maximum_iterations then
                        break;
                    end
                end
            end
        end
    end
end


return F