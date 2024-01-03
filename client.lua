if not lib.checkDependency('ox_lib', '3.14.0') then print('Update ox_lib to v3.14.0 or newer!') return end

local Utils = require 'modules.utils'
local Vehicle = require 'modules.class.vehicle'
local Settings = lib.load('data.vehicle')

local fuelscript = Utils.Detect.Fuel()
local speedunit = Settings.units == 'mph' and 2.23694 or 3.6
local listening = false

local function startThreads()
    listening = true
    local vehEntity = Vehicle:getEntity()
    local vehClass = Vehicle:getClass()
    local airborne, torqueReduction = false, false
    local speedBuffer, healthBuffer, bodyBuffer, roll = {0.0,0.0}, {0.0,0.0}, {0.0,0.0}, 0.0

    function startTorqueReduction()
        torqueReduction = true
        CreateThread(function()

            while Vehicle:getSeat() == -1 do

                -- Update vehicle torque
                if healthBuffer[1] < 500 then
                    local newtorque = (healthBuffer[1] + 500) / 1100
                    SetVehicleCheatPowerIncrease(vehEntity, newtorque)
                else
                    torqueReduction = false
                    break
                end
    
                Wait(1)
            end

            torqueReduction = false
        end)
    end

    CreateThread(function()
        while Vehicle:getSeat() == -1 do
            if Vehicle:getEntity() ~= vehEntity then
                vehEntity = Vehicle:getEntity()
            end

            bodyBuffer[1] = GetVehicleBodyHealth(vehEntity)
            healthBuffer[1] = GetVehicleEngineHealth(vehEntity)
            speedBuffer[1] = GetEntitySpeed(vehEntity) * speedunit

            -- Driveability handler (health, fuel)
            local fuelLevel = GetVehicleFuelLevel(vehEntity)
            if healthBuffer[1] <= 0 or fuelLevel <= 6.4 then
                if IsVehicleDriveable(vehEntity, true) then
                    SetVehicleUndriveable(vehEntity, true)
                end
            end

            -- Prevent rotation controls while flipped/airborne
            if Settings.regulated[vehClass] then
                if speedBuffer[1] < 2.0 then
                    if airborne then airborne = false end
                    roll = GetEntityRoll(vehEntity)
                else
                    airborne = IsEntityInAir(vehEntity)
                end

                if (roll > 75.0 or roll < -75.0) or airborne then
                    SetVehicleOutOfControl(vehEntity, false, false)
                end
            end

            -- Damage handler
            local bodyDiff = bodyBuffer[2] - bodyBuffer[1]
            if bodyDiff >= 1 then

                -- Calculate latest damage
                local bodyDamage = bodyDiff * Settings.globalmultiplier * Settings.classmultiplier[vehClass]
                local vehicleHealth = healthBuffer[1] - bodyDamage

                -- Engage torque reduction thread
                if vehicleHealth < 500 then
                    if not torqueReduction then
                        startTorqueReduction()
                    end
                end

                -- Update vehicle health
                if vehicleHealth ~= healthBuffer[1] and vehicleHealth > 0 then
                    SetVehicleEngineHealth(vehEntity, vehicleHealth)
                elseif vehicleHealth ~= 0 then
                    SetVehicleEngineHealth(vehEntity, 0.0) -- prevent negative engine health
                end

                -- Prevent negative body health
                if bodyBuffer[1] < 0 then
                    SetVehicleBodyHealth(vehEntity, 0.0)
                end

                -- Prevent negative tank health (explosion)
                if GetVehiclePetrolTankHealth(vehEntity) < 0 then
                    SetVehiclePetrolTankHealth(vehEntity, 0.0)
                end
            end

            -- Handle collision impact
            local speedDiff = speedBuffer[2] - speedBuffer[1]
            if speedDiff >= Settings.threshold.speed then

                -- Handle wheel loss
                if bodyDiff >= Settings.threshold.health then
                    local chance = math.random(0,1)
                    BreakOffVehicleWheel(vehEntity, chance, true, false, true, false)
                end

                -- Handle heavy impact
                if speedDiff >= Settings.threshold.heavy then
                    SetVehicleUndriveable(vehEntity, true)
                    SetVehicleEngineHealth(vehEntity, 0.0) -- Disable vehicle completely
                end
            end

            -- Store data for next cycle
            bodyBuffer[2] = bodyBuffer[1]
            healthBuffer[2] = healthBuffer[1]
            speedBuffer[2] = speedBuffer[1]

            Wait(100)
        end
        
        listening, airborne, torqueReduction = false, false, false
        speedBuffer, healthBuffer, bodyBuffer, roll = {0.0,0.0}, {0.0,0.0}, {0.0,0.0}, 0.0
    end)
end

lib.onCache('vehicle', function(newVeh)
    Vehicle:setEntity(newVeh)
end)

lib.onCache('seat', function(newSeat)
	Vehicle:updateData(newSeat, seated)
    if Utils.Player.Seated(newSeat) and newSeat == -1 then
        if not listening then
            startThreads()
        end
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    local veh, seat = Utils.Player.Data()

    Vehicle = Vehicle:new({
        ref = veh,
        class = veh and GetVehicleClass(veh) or false,
        seat = seat,
        active = Utils.Player.Seated(seat)
    })

    startThreads()
end)

RegisterNetEvent('vehiclehandler:playerlogout', function()
    Vehicle:resetData()
end)

RegisterNetEvent('vehiclehandler:client:adminfix', function()
    if not cache.ped then return end
    if Vehicle:isActive() or IsPedInAnyPlane(cache.ped) then
        Utils.Vehicle.Repair(Vehicle:getEntity(), fuelscript)
    end
end)