local recipes_module = require "scripts.recipes"
local utilities = require "scripts.utilities"

local F = {};

function F.raw_materials_are_accurate(recipes)
    local expected = {};
    local actual = {};
    local item = "";
    local amount = 0;

    amount = 1;
    item = "copper-plate";
    expected = { ["copper-ore"] = 1 }
    actual = F.test_raw_material(recipes, item, amount)
    if not utilities.equals(actual, expected, false) then
        utilities.logg("Raw materials test failed for " .. amount .. " " .. item)
        utilities.logg(actual)
        utilities.logg(expected)
    end

    amount = 10;
    item = "copper-plate";
    expected = { ["copper-ore"] = 10 }
    actual = F.test_raw_material(recipes, item, amount)
    if not utilities.equals(actual, expected, false) then
        utilities.logg("Raw materials test failed for " .. amount .. " " .. item)
        utilities.logg(actual)
        utilities.logg(expected)
    end

    amount = 1;
    item = "copper-cable";
    expected = { ["copper-ore"] = 0.5 }
    actual = F.test_raw_material(recipes, item, amount)
    if not utilities.equals(actual, expected, false) then
        utilities.logg("Raw materials test failed for " .. amount .. " " .. item)
        utilities.logg(actual)
        utilities.logg(expected)
    end

    amount = 2;
    item = "copper-cable";
    expected = { ["copper-ore"] = 1 }
    actual = F.test_raw_material(recipes, item, amount)
    if not utilities.equals(actual, expected, false) then
        utilities.logg("Raw materials test failed for " .. amount .. " " .. item)
        utilities.logg(actual)
        utilities.logg(expected)
    end

    amount = 1;
    item = "fusion-generator";
    expected = {
        ammonia = 1000,
        calcite = 2,
        coal = 337.5,
        ["copper-ore"] = 2075,
        ["fluoroketone-cold"] = 500,
        ["holmium-ore"] = 38,
        ["iron-ore"] = 1355,
        ["light-oil"] = 375,
        ["lithium-brine"] = 1000,
        ["petroleum-gas"] = 6875,
        stone = 19,
        ["tungsten-ore"] = 500,
        water = 5690,
        ["yumako-mash"] = 500
      }
    actual = F.test_raw_material(recipes, item, amount)
    if not utilities.equals(actual, expected, false) then
        utilities.logg("Raw materials test failed for " .. amount .. " " .. item)
        utilities.logg(actual)
        utilities.logg(expected)
    end
end

function F.test_raw_material(recipes, item_or_fluid_name, amount_demanded)
    return recipes_module.get_recipe_raw_materials(recipes, item_or_fluid_name, amount_demanded)
end

return F;
