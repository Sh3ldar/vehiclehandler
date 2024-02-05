local Progress = lib.load('data.progress')
local Settings = lib.load('data.vehicle')
local Handler = lib.class('vehiclehandler')

function Handler:init()
    if GetResourceState('ox_fuel') == 'started' then
        self.private.ox = true
    else
        self.private.ox = false
    end
end

function Handler:isActive() return self.private.active end

function Handler:isLimited() return self.private.limited end

function Handler:isFuelOx() return self.private.ox end

function Handler:isValid()
    if not cache.ped then return false end
    if cache.vehicle or IsPedInAnyPlane(cache.ped) then return true end

    return false
end

function Handler:setActive(state)
    if state ~= nil and type(state) == 'boolean' then
        self.private.state = state
    end
end

function Handler:setLimited(state)
    if state ~= nil and type(state) == 'boolean' then
        self.private.limited = state
    end
end

function Handler:adminfuel(newlevel)
    if not self:isValid() then return false end
    if not newlevel then return false end

    newlevel = tonumber(newlevel) + 0.0
    if newlevel < 0.0 then return false end
    if newlevel > 100.0 then newlevel = 100.0 end

    lib.callback('vehiclehandler:sync', -1, function()
        if self:isFuelOx() then
            Entity(cache.vehicle).state.fuel = newlevel
        else
            SetVehicleFuelLevel(cache.vehicle, newlevel)
            DecorSetFloat(cache.vehicle, '_FUEL_LEVEL', GetVehicleFuelLevel(cache.vehicle))
        end
    end)

    return true
end

function Handler:adminwash()
    if not self:isValid() then return false end

    lib.callback('vehiclehandler:sync', -1, function()
        SetVehicleDirtLevel(cache.vehicle, 0.0)
        WashDecalsFromVehicle(cache.vehicle, 1.0)
    end)

    return true
end

function Handler:adminfix()
    if not self:isValid() then return false end

    lib.callback('vehiclehandler:sync', -1, function()
        SetVehicleUndriveable(cache.vehicle, false)
        SetVehicleEngineHealth(cache.vehicle, 1000.0)
        SetVehiclePetrolTankHealth(cache.vehicle, 1000.0)
        SetVehicleBodyHealth(cache.vehicle, 1000.0)
        SetVehicleDirtLevel(vehicle, 0.0)
        ResetVehicleWheels(cache.vehicle, true)

        for i = 0, 5 do
            SetVehicleTyreFixed(cache.vehicle, i)
            SetVehicleWheelHealth(cache.vehicle, i, 1000.0)
        end

        SetVehicleFixed(cache.vehicle)

        if self:isFuelOx() then
            Entity(cache.vehicle).state.fuel = 100.0
        else
            SetVehicleFuelLevel(cache.vehicle, 100.0)
            DecorSetFloat(cache.vehicle, '_FUEL_LEVEL', GetVehicleFuelLevel(cache.vehicle))
        end
        
        SetVehicleEngineOn(cache.vehicle, true, true)
    end)

    return true
end

function Handler:basicwash()
    if not cache.ped then return false end

    local pos = GetEntityCoords(cache.ped)
    local vehicle,_ = lib.getClosestVehicle(pos, 3.0, false)
	if vehicle == nil or vehicle == 0 then return false end

    local vehpos = GetEntityCoords(vehicle)
    if #(pos - vehpos) > 3.0 or cache.vehicle then return false end

    local success = false
    LocalPlayer.state:set("inv_busy", true, true)
    TaskStartScenarioInPlace(cache.ped, "WORLD_HUMAN_MAID_CLEAN", 0, true)

    if lib.progressCircle(Progress['cleankit']) then
        lib.callback('vehiclehandler:sync', -1, function()
            SetVehicleDirtLevel(vehicle, 0.0)
            WashDecalsFromVehicle(vehicle, 1.0)
        end)
        success = true
    end

    ClearAllPedProps(cache.ped)
    ClearPedTasks(cache.ped)

    LocalPlayer.state:set("inv_busy", false, true)

    return success
end

function Handler:basicfix(fixtype)
    if not cache.ped then return false end

    local coords = GetEntityCoords(cache.ped)
    local vehicle,_ = lib.getClosestVehicle(coords, 3.0, false)
	if vehicle == nil or vehicle == 0 then return false end

    if GetVehicleEngineHealth(vehicle) < 500 then
        local offset = GetOffsetFromEntityInWorldCoords(vehicle, 0, 2.5, 0)
        local backengine = Settings.backengine[GetEntityModel(vehicle)]

        if backengine then
            offset = GetOffsetFromEntityInWorldCoords(vehicle, 0, -2.5, 0)
        end

        if #(coords - offset) < 2.0 then
            local success = false
            local hoodindex = backengine and 5 or 4

            LocalPlayer.state:set("inv_busy", true, true)
            SetVehicleDoorOpen(vehicle, hoodindex, false, false)

            if lib.progressCircle(Progress[fixtype]) then
                success = true

                lib.callback('vehiclehandler:sync', -1, function()
                    local newhealth = fixtype == 'bigfix' and 1000.0 or 500.0
            
                    SetVehicleUndriveable(vehicle, false)
                    SetVehicleEngineHealth(vehicle, newhealth)
            
                    if fixtype == 'bigfix' then
                        SetVehiclePetrolTankHealth(vehicle, newhealth)
                        SetVehicleBodyHealth(vehicle, newhealth)
            
                        for i = 0, 5 do
                            SetVehicleTyreFixed(vehicle, i)
                            SetVehicleWheelHealth(vehicle, i, newhealth)
                        end
                    end
                end)
            end

            SetVehicleDoorShut(vehicle, hoodindex, false)
            LocalPlayer.state:set("inv_busy", false, true)

            if success then
                CreateThread(function()
                    Wait(1000)
                    SetVehicleFixed(vehicle)
                end)
            end

            return success
        else
            if backengine then
                lib.notify({
                    title = 'Engine bay is in back',
                    type = 'error'
                })
            end
        end
    else
        lib.notify({
            title = 'Cannot repair any further',
            type = 'error'
        })
    end

    return false
end

return Handler