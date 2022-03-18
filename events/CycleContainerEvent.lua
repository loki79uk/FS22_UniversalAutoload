UniversalAutoloadCycleContainerEvent = {}
local UniversalAutoloadCycleContainerEvent_mt = Class(UniversalAutoloadCycleContainerEvent, Event)
InitEventClass(UniversalAutoloadCycleContainerEvent, "UniversalAutoloadCycleContainerEvent")
-- print("  UniversalAutoload - CycleContainerEvent")

function UniversalAutoloadCycleContainerEvent.emptyNew()
	local self = Event.new(UniversalAutoloadCycleContainerEvent_mt)
	return self
end

function UniversalAutoloadCycleContainerEvent.new(vehicle, direction)
	local self = UniversalAutoloadCycleContainerEvent.emptyNew()
	self.vehicle = vehicle
	self.direction = direction
	return self
end

function UniversalAutoloadCycleContainerEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.direction = streamReadUInt8(streamId)
	self:run(connection)
end

function UniversalAutoloadCycleContainerEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteUInt8(streamId, self.direction)
end

function UniversalAutoloadCycleContainerEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		UniversalAutoload.cycleContainerTypeIndex(self.vehicle, self.direction, true) 
	end
end

function UniversalAutoloadCycleContainerEvent.sendEvent(vehicle, direction, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			--print("server: Cycle Container Event")
			g_server:broadcastEvent(UniversalAutoloadCycleContainerEvent.new(vehicle, direction), nil, nil, object)
		else
			--print("client: Cycle Container Event")
			g_client:getServerConnection():sendEvent(UniversalAutoloadCycleContainerEvent.new(vehicle, direction))
		end
	end
end