local F = {}

local A1, A2 = 727595, 798405  -- 5^17=D20*A1+A2
local D20, D40 = 1048576, 1099511627776  -- 2^20, 2^40
local X1 = 0
local X2 = 1

-- get a decimal value between [0, 1]
function F.value()
    local U = X2*A2
    local V = (X1*A2 + X2*A1) % D20
    V = (V*D20 + U) % D40
    X1 = math.floor(V/D20)
    X2 = V - X1*D20
    return V/D40
end

-- seed the generator
function F.seed(seed)
    X1 = (seed * 2 + 11111) % D20
    X2 = (seed * 4 + 1) % D20
    F.value()
    F.value()
    F.value()
end

-- get an integer value between [1, max]
function F.int(max)
    return math.floor(F.value()*max) + 1
end

-- get an integer value between [min, max]
function F.range(min, max)
    return min + F.int(max - min + 1) - 1
end

function F.float_range(min, max)
    return min + F.value() * (max - min)
end

-- shuffle a table
function F.shuffle(tbl)
    for i = #tbl, 2, -1 do
        local j = F.int(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
end

return F