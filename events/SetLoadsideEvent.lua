UniversalAutoloadSetLoadsideEvent = {}
local UniversalAutoloadSetLoadsideEvent_mt = Class(UniversalAutoloadSetLoadsideEvent, Event)
InitEventClass(UniversalAutoloadSetLoadsideEvent, "UniversalAutoloadSetLoadsideEvent")
-- print("  UniversalAutoload - SetLoadsideEvent")

function UniversalAutoloadSetLoadsideEvent.emptyNew()
	local self = Event.new(UniversalAutoloadSetLoadsideEvent_mt)
	return self
end

function UniversalAutoloadSetLoadsideEvent.new(vehicle, loadside)
	local self = UniversalAutoloadSetLoadsideEvent.emptyNew()
	self.vehicle = vehicle
	self.loadside = loadside
	return self
end

function UniversalAutoloadSetLoadsideEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.loadside = streamReadString(streamId)
	self:run(connection)
end

function UniversalAutoloadSetLoadsideEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteString(streamId, self.loadside)
end

function UniversalAutoloadSetLoadsideEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		UniversalAutoload.setCurrentLoadside(self.vehicle, self.loadside, true)
	end
end

function UniversalAutoloadSetLoadsideEvent.sendEvent(vehicle, loadside, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			--print("server: Set Loadside Event")
			g_server:broadcastEvent(UniversalAutoloadSetLoadsideEvent.new(vehicle, loadside), nil, nil, object)
		else
			--print("client: Set Loadside Event")
			g_client:getServerConnection():sendEvent(UniversalAutoloadSetLoadsideEvent.new(vehicle, loadside))
		end
	end
end