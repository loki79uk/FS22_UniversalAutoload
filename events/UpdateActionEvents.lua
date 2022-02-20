UniversalAutoloadUpdateActionEvents = {}
local UniversalAutoloadUpdateActionEvents_mt = Class(UniversalAutoloadUpdateActionEvents, Event)
InitEventClass(UniversalAutoloadUpdateActionEvents, "UniversalAutoloadUpdateActionEvents")
-- print("  UniversalAutoload - UpdateActionEvents")

function UniversalAutoloadUpdateActionEvents.emptyNew()
	local self = Event.new(UniversalAutoloadUpdateActionEvents_mt)
	return self
end

function UniversalAutoloadUpdateActionEvents.new(vehicle, loadCount, unloadCount)
	local self = UniversalAutoloadUpdateActionEvents.emptyNew()
	self.vehicle = vehicle
	self.loadCount = loadCount
	self.unloadCount = unloadCount
	return self
end

function UniversalAutoloadUpdateActionEvents:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	--if connection:getIsServer() then
		self.loadCount = streamReadInt32(streamId)
		self.unloadCount = streamReadInt32(streamId)
	--end
	self:run(connection)
end

function UniversalAutoloadUpdateActionEvents:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	--if not connection:getIsServer() then
		streamWriteInt32(streamId, self.loadCount)
		streamWriteInt32(streamId, self.unloadCount)
	--end
end

function UniversalAutoloadUpdateActionEvents:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		UniversalAutoload.updateActionEventText(self.vehicle, self.loadCount, self.unloadCount, true)
	end
end

function UniversalAutoloadUpdateActionEvents.sendEvent(vehicle, loadCount, unloadCount, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			--print("server: Update Action Events")
			g_server:broadcastEvent(UniversalAutoloadUpdateActionEvents.new(vehicle, loadCount, unloadCount), nil, nil, object)
		else
			--print("client: Update Action Events")
			g_client:getServerConnection():sendEvent(UniversalAutoloadUpdateActionEvents.new(vehicle))
		end
	end
end