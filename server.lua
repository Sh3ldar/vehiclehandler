if not lib.checkDependency('ox_lib', '3.16.2') then error('ox_lib v3.16.2 or newer required!') end
lib.versionCheck("QuantumMalice/vehiclehandler")

if GetResourceState('ox_inventory') == 'started' then
    if not lib.checkDependency('ox_inventory', '2.38.1') then error('ox_inventory v2.38.1 or newer required!') end

    exports('cleaningkit', function(event, item, inventory, slot, data)
        if event == 'usingItem' then
            local src = inventory.id
            if not src then return false end

            local success = lib.callback.await('vehiclehandler:wash', src)
            if success then return end

            return false
        end
    end)

    exports('tirekit', function(event, item, inventory, slot, data)
        if event == 'usingItem' then
            local src = inventory.id
            if not src then return false end

            local success = lib.callback.await('vehiclehandler:basicfix', src, 'tirekit')
            if success then return end

            return false
        end
    end)

    exports('repairkit', function(event, item, inventory, slot, data)
        if event == 'usingItem' then
            local src = inventory.id
            if not src then return false end

            local success = lib.callback.await('vehiclehandler:basicfix', src, 'smallkit')
            if success then return end

            return false
        end
    end)

    exports('advancedrepairkit', function(event, item, inventory, slot, data)
        if event == 'usingItem' then
            local src = inventory.id
            if not src then return false end

            local success = lib.callback.await('vehiclehandler:basicfix', src, 'bigkit')
            if success then return end

            return false
        end
    end)
end

lib.callback.register('vehiclehandler:sync', function(source)
    return true
end)

lib.addCommand('fix', {
    help = 'Repair current vehicle',
    restricted = 'group.admin'
}, function(source, args, raw)
    lib.callback('vehiclehandler:adminfix', source)
end)

lib.addCommand('wash', {
    help = 'Clean current vehicle',
    restricted = 'group.admin'
}, function(source, args, raw)
    lib.callback('vehiclehandler:adminwash', source)
end)

lib.addCommand('setfuel', {
    help = 'Set vehicle fuel level',
    params = {
        {
            name = 'level',
            type = 'number',
            help = 'Amount of fuel to set',
        },
    },
    restricted = 'group.admin'
}, function(source, args, raw)
    local level = args.level

    if level then
        lib.callback('vehiclehandler:adminfuel', source, false, level)
    end
end)