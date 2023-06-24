UniversalAutoloadStopLoadingEvent = {}
local UniversalAutoloadStopLoadingEvent_mt = Class(UniversalAutoloadStopLoadingEvent, Event)
InitEventClass(UniversalAutoloadStopLoadingEvent, "UniversalAutoloadStopLoadingEvent")
-- print("  UniversalAutoload - StopLoadingEvent")

function UniversalAutoloadStopLoadingEvent.emptyNew()
	local self = Event.new(UniversalAutoloadStopLoadingEvent_mt)
	return self
end

function UniversalAutoloadStopLoadingEvent.new(vehicle, force)
	local self = UniversalAutoloadStopLoadingEvent.emptyNew()
	self.vehicle = vehicle
	self.force = force or false
	return self
end

function UniversalAutoloadStopLoadingEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.force = streamReadBool(streamId)
	self:run(connection)
end

function UniversalAutoloadStopLoadingEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteBool(streamId, self.force)
end

function UniversalAutoloadStopLoadingEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		UniversalAutoload.stopLoading(self.vehicle, self.force, true)
	end
end

function UniversalAutoloadStopLoadingEvent.sendEvent(vehicle, force, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			--print("server: Stop Loading Event")
			g_server:broadcastEvent(UniversalAutoloadStopLoadingEvent.new(vehicle, force), nil, nil, object)
		else
			--print("client: Stop Loading Event")
			g_client:getServerConnection():sendEvent(UniversalAutoloadStopLoadingEvent.new(vehicle, force))
		end
	end
end