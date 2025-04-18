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

return F