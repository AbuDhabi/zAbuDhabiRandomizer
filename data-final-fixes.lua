local util = require "scripts.utilities"
local tech = require "scripts.technology"

-- Get all technologies.
-- Create an ancestor graph from them. The technology plus its ancestors.
-- For each technology, randomize its recipe ingredients allowing stuff already unlocked in its ancestors and itself (except the item in question).


local ignored_recipe_subgroups = {
    ["fill-barrel"] = true,
    ["empty-barrel"] = true
};

-- Save a copy of each recipe's original version in the game data.
for recipe_name, recipe_raw in pairs(data.raw.recipe) do
    local copy = table.deepcopy(data.raw.recipe[recipe_name])
    data.raw.recipe[recipe_name].original = copy
end

local technology_tree = tech.build_tech_tree();