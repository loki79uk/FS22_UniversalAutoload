UniversalAutoloadSetBaleCollectionModeEvent = {}
local UniversalAutoloadSetBaleCollectionModeEvent_mt = Class(UniversalAutoloadSetBaleCollectionModeEvent, Event)
InitEventClass(UniversalAutoloadSetBaleCollectionModeEvent, "UniversalAutoloadSetBaleCollectionModeEvent")
-- print("  UniversalAutoload - SetBaleCollectionModeEvent")

function UniversalAutoloadSetBaleCollectionModeEvent.emptyNew()
	local self = Event.new(UniversalAutoloadSetBaleCollectionModeEvent_mt)
	return self
end

function UniversalAutoloadSetBaleCollectionModeEvent.new(vehicle, baleCollectionMode)
	local self = UniversalAutoloadSetBaleCollectionModeEvent.emptyNew()
	self.vehicle = vehicle
	self.baleCollectionMode = baleCollectionMode
	return self
end

function UniversalAutoloadSetBaleCollectionModeEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.baleCollectionMode = streamReadBool(streamId)
	self:run(connection)
end

function UniversalAutoloadSetBaleCollectionModeEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteBool(streamId, self.baleCollectionMode)
end

function UniversalAutoloadSetBaleCollectionModeEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		UniversalAutoload.setBaleCollectionMode(self.vehicle, self.baleCollectionMode, true)
	end
end

function UniversalAutoloadSetBaleCollectionModeEvent.sendEvent(vehicle, baleCollectionMode, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			--print("server: Set BaleCollectionMode Event")
			g_server:broadcastEvent(UniversalAutoloadSetBaleCollectionModeEvent.new(vehicle, baleCollectionMode), nil, nil, object)
		else
			--print("client: Set BaleCollectionMode Event")
			g_client:getServerConnection():sendEvent(UniversalAutoloadSetBaleCollectionModeEvent.new(vehicle, baleCollectionMode))
		end
	end
end