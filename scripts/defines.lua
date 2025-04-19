local F = {};

-- Barreling and unbarreling should be ignored, because these recipes loop losslessly.
F.ignored_recipe_subgroups = {
    ["fill-barrel"] = true,
    ["empty-barrel"] = true
};

F.ignored_recipe_categories = {
    ["parameters"] = true,
    ["smelting"] = true
}

return F;