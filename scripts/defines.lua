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

F.categories_that_cannot_be_used_as_ingredients = {
    "rocket-building"
}

F.maximum_item_amount = 65535

--- Ie. how many fluid units are considered equivalent to one solid material item.
F.fluid_to_item_ratio = 10;

--- This is how many best candidates can be considered good.
F.number_of_good_candidates = 5;

--- Sometimes one needs a large number.
F.a_sufficiently_large_number = 65535

return F;