local F = {};

function F.get_raw_material_costs(data_raw_item, data_raw_fluid, raw_materials)
    local scores = { item = 0, fluid = 0};
    for material_name, material_amount in pairs(raw_materials) do
        if data_raw_item[material_name] then
            scores.item = scores.item + material_amount
        elseif data_raw_fluid[material_name] then
            scores.fluid = scores.fluid + material_amount
        end
    end
    return scores
end

return F;