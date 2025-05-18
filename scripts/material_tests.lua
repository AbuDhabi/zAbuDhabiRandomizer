local material = require "scripts.material"
local util = require "scripts.util"

local F = {};

function F.raw_materials_are_accurate(data_raw, recipes)
    local expected = {};
    local actual = {};
    local item = "";
    local amount = 0;

    amount = 1;
    item = "copper-plate";
    expected = { ["copper-ore"] = 1 }
    actual = F.test_raw_material(data_raw, recipes, item, amount)
    if not util.equals(actual, expected, false) then
        util.logg("Raw materials test failed for " .. amount .. " " .. item)
        util.logg(actual)
        util.logg(expected)
    end

    amount = 10;
    item = "copper-plate";
    expected = { ["copper-ore"] = 10 }
    actual = F.test_raw_material(data_raw, recipes, item, amount)
    if not util.equals(actual, expected, false) then
        util.logg("Raw materials test failed for " .. amount .. " " .. item)
        util.logg(actual)
        util.logg(expected)
    end

    amount = 1;
    item = "copper-cable";
    expected = { ["copper-ore"] = 0.5 }
    actual = F.test_raw_material(data_raw, recipes, item, amount)
    if not util.equals(actual, expected, false) then
        util.logg("Raw materials test failed for " .. amount .. " " .. item)
        util.logg(actual)
        util.logg(expected)
    end

    amount = 2;
    item = "copper-cable";
    expected = { ["copper-ore"] = 1 }
    actual = F.test_raw_material(data_raw, recipes, item, amount)
    if not util.equals(actual, expected, false) then
        util.logg("Raw materials test failed for " .. amount .. " " .. item)
        util.logg(actual)
        util.logg(expected)
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
    actual = F.test_raw_material(data_raw, recipes, item, amount)
    if not util.equals(actual, expected, false) then
        util.logg("Raw materials test failed for " .. amount .. " " .. item)
        util.logg(actual)
        util.logg(expected)
    end

    amount = 1;
    item = "iron-gear-wheel";
    expected = {
        ["iron-ore"] = 2
      }
    actual = F.test_raw_material(data_raw, recipes, item, amount)
    if not util.equals(actual, expected, false) then
        util.logg("Raw materials test failed for " .. amount .. " " .. item)
        util.logg(actual)
        util.logg(expected)
    end

    amount = 1;
    item = "transport-belt";
    expected = {
        ["iron-ore"] = 1.5
      }
    actual = F.test_raw_material(data_raw, recipes, item, amount)
    if not util.equals(actual, expected, false) then
        util.logg("Raw materials test failed for " .. amount .. " " .. item)
        util.logg(actual)
        util.logg(expected)
    end

    amount = 1;
    item = "pentapod-egg";
    expected = {
        nutrients = 15,
        ["pentapod-egg"] = 0.5,
        water = 30
      }
    actual = F.test_raw_material(data_raw, recipes, item, amount)
    if not util.equals(actual, expected, false) then
        util.logg("Raw materials test failed for " .. amount .. " " .. item)
        util.logg(actual)
        util.logg(expected)
    end

    amount = 1;
    item = "agricultural-science-pack";
    expected = {
        jelly = 3,
        ["pentapod-egg"] = 1,
        ["yumako-mash"] = 3.75
      }
    actual = F.test_raw_material(data_raw, recipes, item, amount)
    if not util.equals(actual, expected, false) then
        util.logg("Raw materials test failed for " .. amount .. " " .. item)
        util.logg(actual)
        util.logg(expected)
    end

    amount = 1;
    item = "holmium-plate";
    expected = {
        ["holmium-ore"] = 0.4,
        stone = 0.2,
        water = 2
      }
    actual = F.test_raw_material(data_raw, recipes, item, amount)
    if not util.equals(actual, expected, false) then
        util.logg("Raw materials test failed for " .. amount .. " " .. item)
        util.logg(actual)
        util.logg(expected)
    end

    amount = 1;
    item = "electromagnetic-plant";
    expected = {
        coal = 100,
        ["copper-ore"] = 2000,
        ["holmium-ore"] = 60,
        ["iron-ore"] = 1510,
        ["petroleum-gas"] = 2375,
        stone = 130,
        water = 1300
      }
    actual = F.test_raw_material(data_raw, recipes, item, amount)
    if not util.equals(actual, expected, false) then
        util.logg("Raw materials test failed for " .. amount .. " " .. item)
        util.logg(actual)
        util.logg(expected)
    end
end

---Run unit test.
---@param data_raw table Wube-provided raw data.
---@param recipes table
---@param item_or_fluid_name string
---@param amount_demanded number
---@return table
function F.test_raw_material(data_raw, recipes, item_or_fluid_name, amount_demanded)
    return material.get_recipe_raw_materials(data_raw, recipes, item_or_fluid_name, amount_demanded, true)
end

function F.resources_check_works(data_raw)
    local expected = nil;
    local actual = nil;
    local item = "";

    item = "lol";
    expected = false;
    actual = F.test_resource(data_raw, item)
    if not util.equals(actual, expected, false) then
        util.logg("Resource check test failed for " .. item)
        util.logg(actual)
        util.logg(expected)
    end

    item = "coal";
    expected = true;
    actual = F.test_resource(data_raw, item)
    if not util.equals(actual, expected, false) then
        util.logg("Resource check test failed for " .. item)
        util.logg(actual)
        util.logg(expected)
    end

    item = "crude-oil";
    expected = true;
    actual = F.test_resource(data_raw, item)
    if not util.equals(actual, expected, false) then
        util.logg("Resource check test failed for " .. item)
        util.logg(actual)
        util.logg(expected)
    end

    item = "petroleum-gas";
    expected = false;
    actual = F.test_resource(data_raw, item)
    if not util.equals(actual, expected, false) then
        util.logg("Resource check test failed for " .. item)
        util.logg(actual)
        util.logg(expected)
    end

    item = "iron-plate";
    expected = false;
    actual = F.test_resource(data_raw, item)
    if not util.equals(actual, expected, false) then
        util.logg("Resource check test failed for " .. item)
        util.logg(actual)
        util.logg(expected)
    end

    item = "tungsten-ore";
    expected = true;
    actual = F.test_resource(data_raw, item)
    if not util.equals(actual, expected, false) then
        util.logg("Resource check test failed for " .. item)
        util.logg(actual)
        util.logg(expected)
    end

    item = "fluorine";
    expected = true;
    actual = F.test_resource(data_raw, item)
    if not util.equals(actual, expected, false) then
        util.logg("Resource check test failed for " .. item)
        util.logg(actual)
        util.logg(expected)
    end
end

---Run test for resource check.
---@param data_raw table Wube-provided raw data.
---@param name string
---@return boolean
function F.test_resource(data_raw, name)
    return material.is_resource(data_raw, name);
end

return F;




