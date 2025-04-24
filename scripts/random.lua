local util = require "scripts.utilities"

local F = {}

local A1, A2 = 727595, 798405  -- 5^17=D20*A1+A2
local D20, D40 = 1048576, 1099511627776  -- 2^20, 2^40
local X1 = 0
local X2 = 1

---@return number Result Floating point value between [0, 1]
function F.value()
    local U = X2*A2
    local V = (X1*A2 + X2*A1) % D20
    V = (V*D20 + U) % D40
    X1 = math.floor(V/D20)
    X2 = V - X1*D20
    return V/D40
end

---@param seed number Seed for pseudo-random number generator
function F.seed(seed)
    X1 = (seed * 2 + 11111) % D20
    X2 = (seed * 4 + 1) % D20
    F.value()
    F.value()
    F.value()
end

---@param max number Maximum integer
---@return number Result Integer between [1, max]
function F.int(max)
    return math.floor(F.value()*max) + 1
end

---@param min number Minimum integer
---@param max number Maximum integer
---@return number Result Integer between [min, max]
function F.range(min, max)
    return min + F.int(max - min + 1) - 1
end

---@param min number Minimum float
---@param max number Maximum float
---@return number Result Floating point value between [min, max]
function F.float_range(min, max)
    return min + F.value() * (max - min)
end

---Shuffles an array
---@param tbl table Array; trying to shuffle a dictionary probably won't work well
function F.shuffle(tbl)
    for i = #tbl, 2, -1 do
        local j = F.int(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
end

---Picks a random key from the dictionary where the value of said key is true.
---@param dictionary table A string->boolean dictionary
---@return string
function F.pick_any_true(dictionary)
    local true_values = {};
    for key, value in pairs(dictionary) do
        if value == true then
            table.insert(true_values, key)
        end
    end
    F.shuffle(true_values);
    return true_values[1]
end

return F