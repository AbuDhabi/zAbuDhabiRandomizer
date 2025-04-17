local F = {};

function F.build_tech_tree()
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

    return technology_tree
end

return F