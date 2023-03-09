UniversalAutoloadStartUnloadingEvent = {}
local UniversalAutoloadStartUnloadingEvent_mt = Class(UniversalAutoloadStartUnloadingEvent, Event)
InitEventClass(UniversalAutoloadStartUnloadingEvent, "UniversalAutoloadStartUnloadingEvent")
-- print("  UniversalAutoload - StartUnloadingEvent")

function UniversalAutoloadStartUnloadingEvent.emptyNew()
	local self = Event.new(UniversalAutoloadStartUnloadingEvent_mt)
	return self
end

function UniversalAutoloadStartUnloadingEvent.new(vehicle, force)
	local self = UniversalAutoloadStartUnloadingEvent.emptyNew()
	self.vehicle = vehicle
	self.force = force
	return self
end

function UniversalAutoloadStartUnloadingEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.force = streamReadBool(streamId)
	self:run(connection)
end

function UniversalAutoloadStartUnloadingEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteBool(streamId, self.force)
end

function UniversalAutoloadStartUnloadingEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		UniversalAutoload.startUnloading(self.vehicle, self.force, true)
	end
end

function UniversalAutoloadStartUnloadingEvent.sendEvent(vehicle, force, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			--print("server: Start Unloading Event")
			g_server:broadcastEvent(UniversalAutoloadStartUnloadingEvent.new(vehicle, force), nil, nil, object)
		else
			--print("client: Start Unloading Event")
			g_client:getServerConnection():sendEvent(UniversalAutoloadStartUnloadingEvent.new(vehicle, force))
		end
	end
end