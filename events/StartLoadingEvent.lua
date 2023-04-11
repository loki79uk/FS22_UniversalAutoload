UniversalAutoloadStartLoadingEvent = {}
local UniversalAutoloadStartLoadingEvent_mt = Class(UniversalAutoloadStartLoadingEvent, Event)
InitEventClass(UniversalAutoloadStartLoadingEvent, "UniversalAutoloadStartLoadingEvent")
-- print("  UniversalAutoload - StartLoadingEvent")

function UniversalAutoloadStartLoadingEvent.emptyNew()
	local self = Event.new(UniversalAutoloadStartLoadingEvent_mt)
	return self
end

function UniversalAutoloadStartLoadingEvent.new(vehicle, force)
	local self = UniversalAutoloadStartLoadingEvent.emptyNew()
	self.vehicle = vehicle
	self.force = force or false
	return self
end

function UniversalAutoloadStartLoadingEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.force = streamReadBool(streamId)
	self:run(connection)
end

function UniversalAutoloadStartLoadingEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteBool(streamId, self.force)
end

function UniversalAutoloadStartLoadingEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		UniversalAutoload.startLoading(self.vehicle, self.force, true)
	end
end

function UniversalAutoloadStartLoadingEvent.sendEvent(vehicle, force, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			--print("server: Start Loading Event")
			g_server:broadcastEvent(UniversalAutoloadStartLoadingEvent.new(vehicle, force), nil, nil, object)
		else
			--print("client: Start Loading Event")
			g_client:getServerConnection():sendEvent(UniversalAutoloadStartLoadingEvent.new(vehicle, force))
		end
	end
end