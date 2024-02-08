if not lib.checkDependency('ox_lib', '3.14.0') then error('ox_lib v3.14 or newer required!') end

local Handler = require 'modules.handler'
local Settings = lib.load('data.vehicle')

local speedUnit = Settings.units == 'mph' and 2.23694 or 3.6

local function startThreads(vehicle)
    if not vehicle then return end
    if Handler:isActive() then return end

    Handler:setActive(true)

    local class = GetVehicleClass(vehicle) or false
    local speedBuffer, healthBuffer, bodyBuffer, roll, airborne = {0.0,0.0}, {0.0,0.0}, {0.0,0.0}, 0.0, false
    
    CreateThread(function()
        while cache.vehicle and cache.seat == -1 do

            -- Retrieve latest vehicle data
            bodyBuffer[1] = GetVehicleBodyHealth(vehicle)
            healthBuffer[1] = GetVehicleEngineHealth(vehicle)
            speedBuffer[1] = GetEntitySpeed(vehicle) * speedUnit

            -- Driveability handler (health, fuel)
            local fuelLevel = GetVehicleFuelLevel(vehicle)
            if healthBuffer[1] <= 0 or fuelLevel <= 6.4 then
                if IsVehicleDriveable(vehicle, true) then
                    SetVehicleUndriveable(vehicle, true)
                end
            end

            -- Reduce torque after half-life
            if not Handler:isLimited() then
                if healthBuffer[1] < 500 then
                    Handler:setLimited(true)
                    
                    CreateThread(function()
                        while cache.vehicle and healthBuffer[1] < 500 do
                            local newtorque = (healthBuffer[1] + 500) / 1100
                            SetVehicleCheatPowerIncrease(vehicle, newtorque)
                            Wait(1)
                        end
            
                        Handler:setLimited(false)
                    end)
                end
            end

            -- Prevent rotation controls while flipped/airborne
            if Settings.regulated[class] then
                if speedBuffer[1] < 2.0 then
                    if airborne then airborne = false end
                    roll = GetEntityRoll(vehicle)
                else
                    airborne = IsEntityInAir(vehicle)
                end

                if (roll > 75.0 or roll < -75.0) or airborne then
                    SetVehicleOutOfControl(vehicle, false, false)
                end
            end

            -- Damage handler
            local bodyDiff = bodyBuffer[2] - bodyBuffer[1]
            if bodyDiff >= 1 then

                -- Calculate latest damage
                local bodyDamage = bodyDiff * Settings.globalmultiplier * Settings.classmultiplier[class]
                local vehicleHealth = healthBuffer[1] - bodyDamage

                -- Update engine health
                if vehicleHealth ~= healthBuffer[1] and vehicleHealth > 0 then
                    SetVehicleEngineHealth(vehicle, vehicleHealth)
                elseif vehicleHealth ~= 0 then
                    SetVehicleEngineHealth(vehicle, 0.0) -- prevent negative engine health
                end

                -- Prevent negative body health
                if bodyBuffer[1] < 0 then
                    SetVehicleBodyHealth(vehicle, 0.0)
                end

                -- Prevent negative tank health (explosion)
                if GetVehiclePetrolTankHealth(vehicle) < 0 then
                    SetVehiclePetrolTankHealth(vehicle, 0.0)
                end
            end

            -- Impact handler
            local speedDiff = speedBuffer[2] - speedBuffer[1]
            if speedDiff >= Settings.threshold.speed then

                -- Handle wheel loss
                if bodyDiff >= Settings.threshold.health then
                    local chance = math.random(0,1)
                    SetVehicleTyreBurst(vehicle, chance, true, 1000.0)
                    BreakOffVehicleWheel(vehicle, chance, true, true, true, false)
                end

                -- Handle heavy impact
                if speedDiff >= Settings.threshold.heavy then
                    SetVehicleUndriveable(vehicle, true)
                    SetVehicleEngineHealth(vehicle, 0.0) -- Disable vehicle completely
                end
            end

            -- Store data for next cycle
            bodyBuffer[2] = bodyBuffer[1]
            healthBuffer[2] = healthBuffer[1]
            speedBuffer[2] = speedBuffer[1]

            Wait(100)
        end

        Handler:setActive(false)
    end)
end

lib.onCache('seat', function(seat)
    if seat == -1 then
        startThreads(cache.vehicle)
    end
end)

lib.callback.register('vehiclehandler:adminfuel', function(newlevel)
    return Handler:adminfuel(newlevel)
end)

lib.callback.register('vehiclehandler:adminwash', function()
    return Handler:adminwash()
end)

lib.callback.register('vehiclehandler:adminfix', function()
    return Handler:adminfix()
end)

lib.callback.register('vehiclehandler:wash', function()
    return Handler:basicwash()
end)

lib.callback.register('vehiclehandler:basicfix', function(fixtype)
    return Handler:basicfix(fixtype)
end)

CreateThread(function()
    Handler = Handler:new({ 
        private = {
            active = false,
            limited = false,
            ox = GetResourceState('ox_fuel') == 'started' and true or false
        } 
    })
    startThreads(cache.vehicle)
end)