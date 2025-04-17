local util = require "scripts.utilities"
local tech = require "scripts.technology"
local ingredients = require "scripts.ingredients"

-- Get all technologies.
-- Create an ancestor graph from them. The technology plus its ancestors.
-- For each technology, randomize its recipe ingredients allowing stuff already unlocked in its ancestors and itself (except the item in question).



local technology_tree = tech.build_tech_tree();
local initial_ingredients_available = ingredients.find_initially_available_ingredients(technology_tree);

util.logg(initial_ingredients_available)