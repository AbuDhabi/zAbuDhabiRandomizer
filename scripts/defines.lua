local F = {};

-- Barreling and unbarreling should be ignored, because these recipes loop losslessly.
F.ignored_recipe_subgroups = {
    ["fill-barrel"] = true,
    ["empty-barrel"] = true
};

F.ignored_recipe_categories = {
    ["parameters"] = true
}

F.types_of_items_and_fluid_for_randomizable_recipes = {
    "fluid",
    "item",
    "tool",
    "gun",
    "armor",
    "capsule",
    "projectile",
    "ammo",
    "space-platform-starter-pack",
    "module",
    "item-with-entity-data"
}

F.types_of_items_and_fluid_for_ingredient_candidates = {
    "fluid",
    "item",
    "gun",
    "armor",
    "capsule",
    "projectile",
    "ammo",
    "space-platform-starter-pack",
    "module",
    "item-with-entity-data"
}

F.maximum_item_amount = 65535

return F;