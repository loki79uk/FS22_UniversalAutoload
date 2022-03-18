UniversalAutoloadSetContainerTypeEvent = {}
local UniversalAutoloadSetContainerTypeEvent_mt = Class(UniversalAutoloadSetContainerTypeEvent, Event)
InitEventClass(UniversalAutoloadSetContainerTypeEvent, "UniversalAutoloadSetContainerTypeEvent")
-- print("  UniversalAutoload - SetContainerTypeEvent")

function UniversalAutoloadSetContainerTypeEvent.emptyNew()
	local self = Event.new(UniversalAutoloadSetContainerTypeEvent_mt)
	return self
end

function UniversalAutoloadSetContainerTypeEvent.new(vehicle, typeIndex)
	local self = UniversalAutoloadSetContainerTypeEvent.emptyNew()
	self.vehicle = vehicle
	self.typeIndex = typeIndex
	return self
end

function UniversalAutoloadSetContainerTypeEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.typeIndex = streamReadUInt8(streamId)
	self:run(connection)
end

function UniversalAutoloadSetContainerTypeEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteUInt8(streamId, self.typeIndex)
end

function UniversalAutoloadSetContainerTypeEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		UniversalAutoload.setContainerTypeIndex(self.vehicle, self.typeIndex, true) 
	end
end

function UniversalAutoloadSetContainerTypeEvent.sendEvent(vehicle, typeIndex, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			--print("server: Set Container Type Event")
			g_server:broadcastEvent(UniversalAutoloadSetContainerTypeEvent.new(vehicle, typeIndex), nil, nil, object)
		else
			--print("client: Set Container Type Event")
			g_client:getServerConnection():sendEvent(UniversalAutoloadSetContainerTypeEvent.new(vehicle, typeIndex))
		end
	end
end