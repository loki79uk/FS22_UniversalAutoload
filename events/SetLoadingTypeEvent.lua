UniversalAutoloadSetLoadingTypeEvent = {}
local UniversalAutoloadSetLoadingTypeEvent_mt = Class(UniversalAutoloadSetLoadingTypeEvent, Event)

InitEventClass(UniversalAutoloadSetLoadingTypeEvent, "UniversalAutoloadSetLoadingTypeEvent")
print("  UniversalAutoload - SetLoadingTypeEvent")

function UniversalAutoloadSetLoadingTypeEvent.emptyNew()
	local self = Event.new(UniversalAutoloadSetLoadingTypeEvent_mt)
	return self
end

function UniversalAutoloadSetLoadingTypeEvent.new(vehicle, typeIndex)
	local self = UniversalAutoloadSetLoadingTypeEvent.emptyNew()
	self.vehicle = vehicle
	self.typeIndex = typeIndex
	return self
end

function UniversalAutoloadSetLoadingTypeEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.typeIndex = streamReadUInt8(streamId)
	self:run(connection)
end

function UniversalAutoloadSetLoadingTypeEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteUInt8(streamId, self.typeIndex)
end

function UniversalAutoloadSetLoadingTypeEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		self.vehicle:setLoadingTypeIndex(self.typeIndex, true) 
	end
end

function UniversalAutoloadSetLoadingTypeEvent.sendEvent(vehicle, typeIndex, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			--print("server: Set Loading Type Event")
			g_server:broadcastEvent(UniversalAutoloadSetLoadingTypeEvent.new(vehicle, typeIndex), nil, nil, object)
		else
			--print("client: Set Loading Type Event")
			g_client:getServerConnection():sendEvent(UniversalAutoloadSetLoadingTypeEvent.new(vehicle, typeIndex))
		end
	end
end