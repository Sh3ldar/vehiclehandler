local Vehicle = lib.class('Vehicle')

-- Getters
function Vehicle:getEntity() return self.ref end

function Vehicle:getClass() return self.class end

function Vehicle:getSeat() return self.seat end

function Vehicle:isActive() return self.active end

-- Setters
function Vehicle:setEntity(entity)
    self.ref = entity
end

function Vehicle:updateData(seat, active)
    self.class = self.ref and GetVehicleClass(self.ref) or false
    self.seat = seat
    self.active = active
end

function Vehicle:resetData()
    self.ref = false
    self.class = false
    self.seat = false
    self.active = false
end

return Vehicle