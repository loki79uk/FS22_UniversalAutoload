UniversalAutoloadSetMaterialTypeEvent = {}
local UniversalAutoloadSetMaterialTypeEvent_mt = Class(UniversalAutoloadSetMaterialTypeEvent, Event)
InitEventClass(UniversalAutoloadSetMaterialTypeEvent, "UniversalAutoloadSetMaterialTypeEvent")
-- print("  UniversalAutoload - SetMaterialTypeEvent")

function UniversalAutoloadSetMaterialTypeEvent.emptyNew()
	local self = Event.new(UniversalAutoloadSetMaterialTypeEvent_mt)
	return self
end

function UniversalAutoloadSetMaterialTypeEvent.new(vehicle, typeIndex)
	local self = UniversalAutoloadSetMaterialTypeEvent.emptyNew()
	self.vehicle = vehicle
	self.typeIndex = typeIndex
	return self
end

function UniversalAutoloadSetMaterialTypeEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.typeIndex = streamReadUInt8(streamId)
	self:run(connection)
end

function UniversalAutoloadSetMaterialTypeEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteUInt8(streamId, self.typeIndex)
end

function UniversalAutoloadSetMaterialTypeEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		UniversalAutoload.setMaterialTypeIndex(self.vehicle, self.typeIndex, true) 
	end
end

function UniversalAutoloadSetMaterialTypeEvent.sendEvent(vehicle, typeIndex, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			--print("server: Set Material Type Event")
			g_server:broadcastEvent(UniversalAutoloadSetMaterialTypeEvent.new(vehicle, typeIndex), nil, nil, object)
		else
			--print("client: Set Material Type Event")
			g_client:getServerConnection():sendEvent(UniversalAutoloadSetMaterialTypeEvent.new(vehicle, typeIndex))
		end
	end
end