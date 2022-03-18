UniversalAutoloadCycleMaterialEvent = {}
local UniversalAutoloadCycleMaterialEvent_mt = Class(UniversalAutoloadCycleMaterialEvent, Event)
InitEventClass(UniversalAutoloadCycleMaterialEvent, "UniversalAutoloadCycleMaterialEvent")
-- print("  UniversalAutoload - CycleMaterialEvent")

function UniversalAutoloadCycleMaterialEvent.emptyNew()
	local self = Event.new(UniversalAutoloadCycleMaterialEvent_mt)
	return self
end

function UniversalAutoloadCycleMaterialEvent.new(vehicle, direction)
	local self = UniversalAutoloadCycleMaterialEvent.emptyNew()
	self.vehicle = vehicle
	self.direction = direction
	return self
end

function UniversalAutoloadCycleMaterialEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.direction = streamReadUInt8(streamId)
	self:run(connection)
end

function UniversalAutoloadCycleMaterialEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteUInt8(streamId, self.direction)
end

function UniversalAutoloadCycleMaterialEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		UniversalAutoload.cycleMaterialTypeIndex(self.vehicle, self.direction, true) 
	end
end

function UniversalAutoloadCycleMaterialEvent.sendEvent(vehicle, direction, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			--print("server: Cycle Material Event")
			g_server:broadcastEvent(UniversalAutoloadCycleMaterialEvent.new(vehicle, direction), nil, nil, object)
		else
			--print("client: Cycle Material Event")
			g_client:getServerConnection():sendEvent(UniversalAutoloadCycleMaterialEvent.new(vehicle, direction))
		end
	end
end