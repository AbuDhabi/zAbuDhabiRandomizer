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

return F