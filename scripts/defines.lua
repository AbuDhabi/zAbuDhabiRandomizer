local F = {};

-- Barreling and unbarreling should be ignored, because these recipes loop losslessly.
F.ignored_recipe_subgroups = {
    ["fill-barrel"] = true,
    ["empty-barrel"] = true
};

F.ignored_recipe_categories = {
    ["parameters"] = true
}

F.types_of_items_and_fluid = {
    "fluid",
    "item",
    "tool",
    "gun",
    "armor",
    "capsule",
    "projectile"
}

return F;