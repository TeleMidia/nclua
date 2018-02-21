
local event = event
_ENV = nil

local function receive_finished (e)
    print("PROGRAM UDP", e) 
--[=====[     
    local co = ESTABLISHED_REV[e.connection]
    if co == nil then
       return false              -- nothing to do
    end
    if e.error == nil then
       resume (co, e.value)
    else
       resume (co, false, e.error)
    end
    return true                  -- consume event
--]=====]

 end
 event.register (receive_finished, {class='udp', type='bind'})