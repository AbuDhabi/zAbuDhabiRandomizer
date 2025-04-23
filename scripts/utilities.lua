local F = {};


function F.logg(input) 
    log(serpent.block(input))
end

function F.merge_tables(table1, table2)
    for key, value in pairs(table2) do
       table1[key] = value
    end
    return table1
end

---@param smaller_table table Table with less or equal amount of elements
---@param larger_table table Table with more or the same amount of elements
function F.table_keys_subset(smaller_table, larger_table)
    local smaller_table_length = 0;
    for key, _ in pairs(smaller_table) do
        smaller_table_length = smaller_table_length + 1
    end
    local keys_found = 0;
    for key, _ in pairs(larger_table) do
        if smaller_table[key] then
            keys_found = keys_found + 1
        end
    end
    return keys_found == smaller_table_length
end

---@param o1 any|table First object to compare
---@param o2 any|table Second object to compare
---@param ignore_mt boolean True to ignore metatables (a recursive function to tests tables inside tables)
function F.equals(o1, o2, ignore_mt)
    if o1 == o2 then return true end
    local o1Type = type(o1)
    local o2Type = type(o2)
    if o1Type ~= o2Type then return false end
    if o1Type ~= 'table' then return false end

    if not ignore_mt then
        local mt1 = getmetatable(o1)
        if mt1 and mt1.__eq then
            --compare using built in method
            return o1 == o2
        end
    end

    local keySet = {}

    for key1, value1 in pairs(o1) do
        local value2 = o2[key1]
        if value2 == nil or F.equals(value1, value2, ignore_mt) == false then
            return false
        end
        keySet[key1] = true
    end

    for key2, _ in pairs(o2) do
        if not keySet[key2] then return false end
    end
    return true
end

return F