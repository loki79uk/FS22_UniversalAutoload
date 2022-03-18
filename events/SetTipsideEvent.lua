UniversalAutoloadSetTipsideEvent = {}
local UniversalAutoloadSetTipsideEvent_mt = Class(UniversalAutoloadSetTipsideEvent, Event)
InitEventClass(UniversalAutoloadSetTipsideEvent, "UniversalAutoloadSetTipsideEvent")
-- print("  UniversalAutoload - SetTipsideEvent")

function UniversalAutoloadSetTipsideEvent.emptyNew()
	local self = Event.new(UniversalAutoloadSetTipsideEvent_mt)
	return self
end

function UniversalAutoloadSetTipsideEvent.new(vehicle, tipside)
	local self = UniversalAutoloadSetTipsideEvent.emptyNew()
	self.vehicle = vehicle
	self.tipside = tipside
	return self
end

function UniversalAutoloadSetTipsideEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.tipside = streamReadString(streamId)
	self:run(connection)
end

function UniversalAutoloadSetTipsideEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteString(streamId, self.tipside)
end

function UniversalAutoloadSetTipsideEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		UniversalAutoload.setCurrentTipside(self.vehicle, self.tipside, true)
	end
end

function UniversalAutoloadSetTipsideEvent.sendEvent(vehicle, tipside, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			--print("server: Set Tipside Event")
			g_server:broadcastEvent(UniversalAutoloadSetTipsideEvent.new(vehicle, tipside), nil, nil, object)
		else
			--print("client: Set Tipside Event")
			g_client:getServerConnection():sendEvent(UniversalAutoloadSetTipsideEvent.new(vehicle, tipside))
		end
	end
end