UniversalAutoloadRaiseActiveEvent = {}
local UniversalAutoloadRaiseActiveEvent_mt = Class(UniversalAutoloadRaiseActiveEvent, Event)
InitEventClass(UniversalAutoloadRaiseActiveEvent, "UniversalAutoloadRaiseActiveEvent")
-- print("  UniversalAutoload - RaiseActiveEvent")

function UniversalAutoloadRaiseActiveEvent.emptyNew()
	local self = Event.new(UniversalAutoloadRaiseActiveEvent_mt)
	return self
end

function UniversalAutoloadRaiseActiveEvent.new(vehicle, state)
	local self = UniversalAutoloadRaiseActiveEvent.emptyNew()
	self.vehicle = vehicle
	self.state = state
	return self
end

function UniversalAutoloadRaiseActiveEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	if streamReadBool(streamId) then
		self.state = streamReadBool(streamId)
	end
	self:run(connection)
end

function UniversalAutoloadRaiseActiveEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	if self.state ~= nil then
		streamWriteBool(streamId, true)
		streamWriteBool(streamId, self.state)
	else
		streamWriteBool(streamId, false)
	end
end

function UniversalAutoloadRaiseActiveEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		--print("RAISE ACTIVE "..tostring(self.inTrigger))
		UniversalAutoload.forceRaiseActive(self.vehicle, self.state, true)
	end
end

function UniversalAutoloadRaiseActiveEvent.sendEvent(vehicle, state, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			--print("server: Raise Active Event")
			g_server:broadcastEvent(UniversalAutoloadRaiseActiveEvent.new(vehicle, state), nil, nil, vehicle)
		else
			--print("client: Raise Active Event")
			g_client:getServerConnection():sendEvent(UniversalAutoloadRaiseActiveEvent.new(vehicle, state))
		end
	end
end