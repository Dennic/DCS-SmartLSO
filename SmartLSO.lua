lso = {}
lso.debug = false -- **用于调试，请勿修改**
lso.dumpTrackData = false -- **DO NOT MODIFY**


-- 航母单位名称
lso.carrierName = "Mother"
-- 使用真实无线电频率 true/false
lso.useRadioFrequency = true
-- 航母无线电单位名称
lso.carrierRadioName = "Mother Radio"
-- 启用航母自动航行 true/false
lso.carrierSailing = true
-- 航母航行区域名称
lso.carrierSailArea = "Sail Area"
-- 航母航行速度（节）
lso.carrierSpeed = 25
-- 使用无线电F10二级菜单
lso.useSubMenu = false
-- 二级菜单名称
lso.subMenuName = "Carrier"


-- 音频库
lso.Sound = {
	RADIO			= {"l10n/DEFAULT/radio_on.ogg",				1	},
	BOLTER 			= {"l10n/DEFAULT/bolter.ogg",				1.7	},
	CALL_THE_BALL	= {"l10n/DEFAULT/call_the_ball.ogg",		1.5	},
	LEFT 			= {"l10n/DEFAULT/come_left.ogg", 			1.1	},
	CUT 			= {"l10n/DEFAULT/cut.ogg", 					0.6	},
	CLIMB 			= {"l10n/DEFAULT/dont_climb.ogg", 			1.1	},
	SETTLE 			= {"l10n/DEFAULT/dont_settle.ogg", 			1.1	},
	EASY 			= {"l10n/DEFAULT/easy_with_it.ogg",			1.5	},
	FAIR 			= {"l10n/DEFAULT/fair.ogg", 				0.6	},
	FOUR_WIRES 		= {"l10n/DEFAULT/four_wires.ogg", 			1	},
	KEEP_TURN 		= {"l10n/DEFAULT/keep_your_turn_in.ogg",	1.4	},
	LIG 			= {"l10n/DEFAULT/long_in_the_groove.ogg",	3.1	},
	NO_GRADE 		= {"l10n/DEFAULT/no_grade.ogg", 			0.7	},
	OK				= {"l10n/DEFAULT/ok.ogg", 					0.6	},
	ONE_WIRE 		= {"l10n/DEFAULT/one_wire.ogg", 			0.8	},
	PADDLES_CONTACT	= {"l10n/DEFAULT/paddles_contact.ogg",		1.5	},
	LOW 			= {"l10n/DEFAULT/power.ogg", 				1.1	},
	TOO_LOW 		= {"l10n/DEFAULT/power2.ogg", 				1.1	},
	RIGHT 			= {"l10n/DEFAULT/right_for_lineup.ogg", 	1.4	}, 
	ROGER_BALL 		= {"l10n/DEFAULT/roger_ball.ogg", 			0.9	}, 
	THREE_WIRES		= {"l10n/DEFAULT/three_wires.ogg", 			0.8	},
	TWO_WIRES 		= {"l10n/DEFAULT/two_wires.ogg", 			0.8	},
	WAVEOFF 		= {"l10n/DEFAULT/waveoff.ogg",				1.7	}, 
	FOUL_DECK 		= {"l10n/DEFAULT/waveoff_foul_deck.ogg",	1.8	}, 
	FAST 			= {"l10n/DEFAULT/youre_fast.ogg",			1.1	}, 
	HIGH 			= {"l10n/DEFAULT/youre_high.ogg",			1.1	}, 
	SLOW 			= {"l10n/DEFAULT/youre_slow.ogg",			1.3	}, 
}


-- 数据库模块
-- 包含了所需的固定数据
lso.data = {}
lso.data.carriers = {
	["Stennis"] = {
		offset = {
			x = -44.54,
			y = 19.06,
			z = -10.49,
		},
		deck = 9.0,
		gs = 3.5,
		runway = {
			length = 240.0,
			width = 25.0,
		},
	},
}
lso.data.aircrafts = {
	["FA-18C_hornet"] = {
		name = "hornet",
		aoa = 8.1,
	},
	["Su-33"] = {
		name = "falcon",
		aoa = 9.0,
	},
}
lso.data.coalitions = {
	[0] = "neutrals",
	[1] = "red",
	[2] = "blue",
}
function lso.data.getAircraft(unit)
	if (unit) then
		local typeName = unit:getTypeName()
		for name, data in pairs(lso.data.aircrafts) do
			if (name == typeName) then
				return data
			end
		end
	end
	return nil
end


function lso.print(msg, duration, useMist, name)
	if lso.debug == true then
		if (mist and useMist and lso.useRadioFrequency) then
			mist.message.add({
					text =	msg,
					displayTime = duration,
					msgFor = {coa = {"all"}},
					name = name,
				})
		else
			trigger.action.outText(msg, duration)
		end
	end
end


-- 创建枚举表
EnumObj = {
	new=function(self, value)
		local obj = {value=value}
		setmetatable(obj, {__index=self, __eq=self.equal, __tostring=self.toString, __add=self.add, __lt=self.lt})
		return obj
	end,
	addParam=function(self, params)
		for k, v in pairs(params) do
			assert(self[k] == nil, string.format("invalid Enum parameter \"%s\"", k))
			self[k] = v
		end
		return self
	end,
	add=function(self, another)
		if another == nil or self:equal(another) then
			return self
		else
			return EnumObj:new(self.value + another.value)
		end
	end,
	equal=function(self, another)
		return EnumObj.band(self.value, another.value) > 0
	end,
	lt=function(self, another)
		return self.value < another.value
	end,
	toString=function(self)
		return self.value
	end,
	band=function(n1, n2)
		local t1 = 0
		local t2 = 0
		while 2 ^ t1 < n1 do t1 = t1 + 1; end
		while 2 ^ t2 < n2 do t2 = t2 + 1; end
		local rlt = 0
		for i = math.max(t1, t2), 0, -1 do
			local ex = 2 ^ i
			local b1 = 0
			local b2 = 0
			if (n1 >= ex) then
				b1 = 1
				n1 = n1 % ex
			end
			if (n2 >= ex) then
				b2 = 1
				n2 = n2 % ex
			end
			if (b1 == 1 and b2 == 1) then
				rlt = rlt + ex
			end
		end
		return rlt
	end
}
function Enum(...)
	local items = {...}
	if (#items == 1 and type(items[1]) == "table") then
		items = items[1]
	end
	local enum = {}
	local index = 1
	for i, v in ipairs(items) do
		local val = 2 ^ (index - 1)
		local obj = EnumObj:new(val)
		if type(items[i+1]) == "table" then
			local params = items[i+1]
			obj:addParam(params)
		else
			index = index + 1
		end
		enum[v] = obj
	end
	return enum
end

-- 模拟 switch 语句块
function switch(value, ...)
	local cases = {...}
	local matched = false
	for i, case in ipairs(cases) do
		if (matched or (case[1] == value and type(case[2]) == "function") or (#case == 1 and type(case[1]) == "function")) then
			matched = true
			local code = (#case == 1 and type(case[1]) == "function") and case[1] or case[2]
			if (code()) then
				break
			end
		end
	end
end


-- 检测帧实现模块
lso.frameId = 1
lso.checkFrames = {}
lso.lastCheckTime = nil
function lso.addCheckFrame(frame)
	assert(type(frame) == "table", "argument expected table, got " .. type(frame))
	assert(frame.onFrame ~= nil and type(frame.onFrame) == "function", "didn't implement function 'onFrame'")
	local id = lso.frameId
	table.insert(lso.checkFrames, {frame = frame, id = id})
	lso.frameId = lso.frameId + 1
	return id
end
function lso.removeCheckFrame(id)
	for k, v in pairs(lso.checkFrames) do
		if (v.id == id) then
			lso.checkFrames[k] = nil
		end
	end
end
function lso.doFrame(arg, frameTime)
	lso.lastCheckTime = timer.getTime()
	lso.print("检查帧工作中", 5, true, "CheckFrameWorking")
	local i = 1
	while i <= #lso.checkFrames do
		if lso.checkFrames[i] ~= nil then
			local status, err = pcall(function()
					lso.checkFrames[i].frame:onFrame(frameTime)
					return true
				end)
			if (not status) then
				lso.print(err, 5, true, "checkFrameError")
				env.error(err)
				return nil
			end
		end
		i = i + 1
	end
	return timer.getTime() + 2
end
lso.resetTime = nil
function lso.autoReset(arg, frameTime)
	if (lso.resetTime == nil) then
		if (timer.getTime() - lso.lastCheckTime > 10) then
			lso.resetTime = 5
			trigger.action.outText(string.format("Smart-LSO script stop working, auto-reset in %d sec.", lso.resetTime), 5)
		end
	else
		if (lso.resetTime > 0) then
			lso.resetTime = lso.resetTime - 1
		else
			-- 遍历初始化所有飞机状态
			for unitName, plane in pairs(lso.DB.planes) do
				if (plane:updateData()) then
					lso.process.initPlane(plane.unit)
				end
			end
			timer.scheduleFunction(lso.doFrame, nil, timer.getTime() + 1)
			lso.resetTime = nil
			trigger.action.outText("Smart-LSO script auto-reset.", 2)
		end
	end
	return timer.getTime() + 1
end
function lso.start()
	timer.scheduleFunction(lso.doFrame, nil, timer.getTime() + 1)
	timer.scheduleFunction(lso.autoReset, nil, timer.getTime() + 1)
end


-- 事件广播模块
lso.Broadcast = {}
lso.Broadcast.count = 0
lso.Broadcast.event = Enum(
	"INIT_PLANE", -- plane
	"REMOVE_PLANE", -- plane
	"INIT_MENU", -- unit
	"CHECK_IN", -- plane
	"IN_SIGHT", -- plane
	"INITIAL", -- plane
	"BREAK", -- plane
	"PADDLES_CONTACT", -- plane
	"ABORT", -- plane
	"DEPART", -- plane
	"TURNING_START", -- nil
	"TURNING_STOP", -- nil
	"RECOVERY_START", -- nil
	"RECOVERY_STOP", -- nil
	"EMERGENCY", -- plane
	"TRACK_FINISH" -- trackData, result, cause, wire
)
lso.Broadcast.listeners = {}
lso.Broadcast.queue = {}
function lso.Broadcast:send(event, ...)
	if event then
		table.insert(self.queue, {
			event = event,
			data = {...},
			timestamp = timer.getTime()
		})
	end
end
function lso.Broadcast:remove(funcOrId)
	local removed = false
	if funcOrId then
		if (type(funcOrId) == "number") then
			for i, listener in ipairs(self.listeners) do
				if listener.id == funcOrId then
					table.remove(self.listeners, i)
					removed = true
				end
			end
		else
			for i, listener in ipairs(self.listeners) do
				if listener.callback == funcOrId then
					table.remove(self.listeners, i)
					removed = true
				end
			end
		end
	end
	return removed
end
function lso.Broadcast:receive(events, func)
	if (events and type(func) == "function") then
		self.count = self.count + 1
		local listenerId = self.count
		table.insert(self.listeners, {
			id = listenerId,
			events = events,
			callback = func
		})
		return listenerId
	end
end
function lso.Broadcast.loop(args, timestamp)
	while #lso.Broadcast.queue > 0 do
		local item = table.remove(lso.Broadcast.queue, 1)
		for i, listener in ipairs(lso.Broadcast.listeners) do
			if (listener.events == item.event) then
				listener.callback(item.event, item.timestamp, unpack(item.data))
			end
		end
	end
	return timer.getTime() + 0.01
end
timer.scheduleFunction(lso.Broadcast.loop, nil, timer.getTime() + 1)



-- 数据库模块
lso.DB = {}
-- 飞机集合
lso.DB.planes = {}
function lso.DB.init()
	local coalition = lso.data.coalitions[lso.Carrier.unit:getCoalition()]
	for coaName, coaData in pairs(env.mission.coalition) do
		if (coaName == coalition) then
			if (coaData.country) then
				for countryID, countryData in pairs(coaData.country) do
					for categoryName, categoryData in pairs(countryData) do
						if (categoryName == "ship") then
							if (categoryData.group and type(categoryData.group) == 'table' and #categoryData.group > 0) then
								for groupID, groupData in pairs(categoryData.group) do
									if (groupData.units and type(groupData.units) == 'table' and #groupData.units > 0) then
										for unitID, unitData in pairs(groupData.units) do
											local unitName
											if env.mission.version > 7 then
												unitName = env.getValueDictByKey(unitData.name)
											else
												unitName = unitData.name
											end
											if (unitName == lso.Carrier.unit:getName()) then
												lso.Carrier:loadTasks(groupData)
											end
										end
									end
								end
							end
						elseif (categoryName == "plane") then
							if (categoryData.group and type(categoryData.group) == 'table' and #categoryData.group > 0) then
								for groupID, groupData in pairs(categoryData.group) do
									if (groupData.units and type(groupData.units) == 'table' and #groupData.units > 0) then
										for unitID, unitData in pairs(groupData.units) do
											if (unitData.skill == "Player" or unitData.skill == "Client") then
												if (lso.data.aircrafts[unitData.type]) then
													local unitName
													if env.mission.version > 7 then
														unitName = env.getValueDictByKey(unitData.name)
													else
														unitName = unitData.name
													end
													local aircraftData = lso.data.aircrafts[unitData.type]
													local onboardNumber = unitData.onboard_num
													local plane = lso.Plane:new(unitName, aircraftData, onboardNumber)
													if (plane) then
														lso.DB.planes[unitName] = plane
													end
												end
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
end


-- 航母模块
lso.Carrier = {
	recovery = false, -- 是否正在回收作业
	case = 1, -- 回收作业 Case 1-3
	unit, -- 航母单位
	radio, -- 航母无线电单位
	data, -- 航母信息
	foulDeck = false,
	initPoint, -- 航母初始位置 vec2
	nextPoint, -- 最后一个路径点 vec2
	lastHeadding, -- 最近一次记录的航向
	needToTurn = false, -- 是否需要转向
	turning = false,
	turningTime = 0,
	pointCount = 0,
	inProcess = {}, -- 等待回收中的飞机
	recoveryStop, -- 结束回收计划
	backToCruise = false, -- 正在返回巡航区域
	foulTime = {}, -- 进入 foul lines 的时间
}
function lso.Carrier:addPlane(plane)
	local recoveryStarted = false
	if not (lso.utils.listContains(self.inProcess, plane)) then
		plane.case = self.case
		table.insert(self.inProcess, plane)
		if (lso.carrierSailing and #self.inProcess == 1 and self.recovery == false and self.backToCruise == false) then
			local eat = lso.Carrier:getEAT()
			if (eat and (eat - timer.getTime() > 15 * 60)) then
				-- lso.print(string.format("Charlie %d", (eat - timer.getTime()) / 60), 5, true, "charlieTime")
				self:addRoute(true)
				recoveryStarted = true
			end
		elseif (lso.carrierSailing == false or self.recovery == true) then
			recoveryStarted = true
		end
		if (self.recoveryStop ~= nil) then
			timer.removeFunction(self.recoveryStop)
			self.recoveryStop = nil
		end
		return true, recoveryStarted
	else
		return false, recoveryStarted
	end
end
function lso.Carrier:removePlane(plane)
	if (lso.utils.listContains(self.inProcess, plane)) then
		lso.utils.listRemove(self.inProcess, plane)
		if (lso.carrierSailing and #self.inProcess == 0) then
			local stopRecovery = function(args, timestamp)
				if (self.recovery == true) then
					self:addRoute(true)
					self.recovery = false
					self.recoveryStop = nil
				end
			end
			-- 3分钟内没有新飞机加入回收队列则结束回收作业
			self.recoveryStop = timer.scheduleFunction(stopRecovery, nil, timer.getTime() + 180)
		end
		return true
	else
		return false
	end
end
function lso.Carrier:emergency(event)
	if (lso.carrierSailing and #self.inProcess > 0 and self.recovery == false) then
		self:addRoute(true)
	end
end
function lso.Carrier:init()
	lso.Broadcast:receive(lso.Broadcast.event.EMERGENCY, function(event)
			self:emergency(event)
		end)
	local unit = Unit.getByName(lso.carrierName)
	local radioUnit = lso.carrierRadioName and Unit.getByName(lso.carrierRadioName) or nil
	local radio = (lso.useRadioFrequency and radioUnit) and radioUnit or unit
	if (
		unit ~= nil and radio ~= nil
		and unit:isExist() and radio:isExist()
		) then
		self.unit = unit
		self.radio = radio
		self.initPoint = {x=unit:getPoint().x, y=unit:getPoint().z}
		self.nextPoint = {x=unit:getPoint().x, y=unit:getPoint().z}
		local typeName = unit:getTypeName()
		for name, data in pairs(lso.data.carriers) do
			if (name == typeName) then
				self.data = data
				break
			end
		end
		if (self.data ~= nil) then
			if (not lso.carrierSailing) then
				self.recovery = true
			end
			self.frameID = lso.addCheckFrame(self) -- 添加 Carrier 检测帧程序
			return true
		end
	end
	return false
end
function lso.Carrier:loadTasks(groupData)
	if (lso.carrierSailing) then
		local group = self.unit:getGroup()
		if group then
			local groupCon = group:getController()
			if groupCon then
				local route = groupData.route
				if (#route.points > 0) then
					local point = route.points[1]
					if (type(point.task) == "table" and type(point.task.params) == "table" and type(point.task.params.tasks) == "table") then
						for i, task in pairs(point.task.params.tasks) do
							if (task.id == "WrappedAction") then
								local action = task.params.action
								if (action.id == "Option") then
									groupCon:setOption(action.params.name, action.params.value)
								else
									groupCon:setCommand(action)
								end
							end
						end
					end
				end
				local tasks = groupData.tasks
				for i, task in pairs(tasks) do
					if (task.id == "WrappedAction") then
						local action = task.params.action
						if (action.id == "Option") then
							groupCon:setOption(action.params.name, action.params.value)
						else
							groupCon:setCommand(action)
						end
					end
				end
			end
		end
		self.needToTurn = true
	end
end
function lso.Carrier:addRoute(clearAll)
	local nowPoint = self.unit:getPoint()
	local nextPoint = nil
	local zone = trigger.misc.getZone(lso.carrierSailArea)
	local center, radius
	if type(zone) == "table" then
		center = zone.point
		radius = zone.radius
	else
		center = self.initPoint
		radius = lso.Converter.NM_M(10)
	end
	self.backToCruise = false
	if (#self.inProcess > 0 and self.recovery == false) then
		local dir, speed = lso.utils.getWindInfo(nowPoint, self.data.offset.y + 20) -- 甲板上方 20 米风
		for dist = 20, 1, -1 do
			local y, x = lso.math.getOffsetPoint(nowPoint.z, nowPoint.x, (math.deg(dir) + self.data.deck) % 360, lso.Converter.NM_M(dist))
			local point = {x=x, y=y}
			if not (lso.utils.checkLand(point, {x=nowPoint.x, y=nowPoint.z})) then
				nextPoint = point
				self.recovery = true
				-- lso.Broadcast:send(lso.Broadcast.event.RECOVERY_START)
				break
			end
		end
		if nextPoint == nil then
			return false
		end
	else
		if (self.recovery == true) then
			self.recovery = false
			self.backToCruise = true
			lso.Broadcast:send(lso.Broadcast.event.RECOVERY_STOP)
		end
	end

	-- 在航行区域内随机选择下一个路径点
	if (nextPoint == nil) then
		local tried = 0
		repeat
			if (tried > 1000) then
				return false
			end
			local point = lso.utils.getRandPointInCircle(center, radius)
			local dist = lso.utils.getDistance(point.x, point.y, nowPoint.x, nowPoint.z)
			if (dist > radius * math.max(0.3, math.min(6000 / radius, 0.8))) then
				if not (lso.utils.checkLand(point, {x=nowPoint.x, y=nowPoint.z})) then
					nextPoint = point
				end
			end
			tried = tried + 1
		until (nextPoint ~= nil)
	end

	local waypoint = {}
	waypoint.x = nextPoint.x
	waypoint.y = nextPoint.y
	waypoint.x = nextPoint.x
	waypoint.alt = 0
	waypoint.type = "Turning Point"
	waypoint.speed = lso.Converter.KNOT_MS(lso.carrierSpeed)
	waypoint.action = "Turning Point"
	waypoint.task = {
		id = 'WrappedAction',
		params = {
			action = {
				id = 'Script',
				params = {
					command = "lso.Carrier:reachPoint()",
				},
			},
		},
	}

	local misTask = {
		id = 'Mission',
		params = {
			route = {
				points = {waypoint},
			},
		},
	}

	local group = self.unit:getGroup()
	if group then
		local groupCon = group:getController()
		if groupCon then
			if (clearAll) then
				groupCon:setTask(misTask)
			else
				groupCon:pushTask(misTask)
			end
		end
	end

	self.nextPoint = nextPoint
	self.pointCount = self.pointCount + 1
	lso.Broadcast:send(lso.Broadcast.event.TURNING_START)
	-- trigger.action.markToAll(self.pointCount, string.format("%d", self.pointCount), {x=self.nextPoint.x, y=0, z=self.nextPoint.y})
	return true
end
function lso.Carrier:reachPoint()
	self.needToTurn = true
end
function lso.Carrier:getRecoveryCase()
	if (self.case == 1) then
		return "Case I"
	elseif (self.case == 2) then
		return "Case II"
	elseif (self.case == 3) then
		return "Case III"
	else
		return ""
	end
end
-- 获取到达下一路径点的预计时间
function lso.Carrier:getEAT()
	local speed = lso.Carrier:getSpeed(self.unit)
	if speed > 0 then
		local point = self.unit:getPoint()
		local dist = lso.utils.getDistance(point.x, point.z, self.nextPoint.x, self.nextPoint.y)
		local timeInSec = dist / speed
		return timer.getTime() + timeInSec
	end
end
function lso.Carrier:getBRC(current)
	if (current or not lso.carrierSailing) then
		return lso.Carrier:getHeadding(true) or 0
	else
		local cPoint = self.unit:getPoint()
		local nextBRC = lso.math.round(lso.math.getAzimuth(cPoint.z, cPoint.x, lso.Carrier.nextPoint.y, lso.Carrier.nextPoint.x, true))
		return nextBRC
	end
	
end
function lso.Carrier:getTemperatureAndPressure()
	local point = self.unit:getPoint()
	point.y = 0
	local temperature, pressure = atmosphere.getTemperatureAndPressure(point)
	return lso.Converter.K_C(temperature), lso.Converter.PA_INHG(pressure)
end
-- 计算当前航母的接地点坐标
-- 返回值 bx, by: 接地点 vec2 坐标
function lso.Carrier:getLandingPoint()
	local carrierPoint = self.unit:getPoint()
	local carrierHeadding = lso.Carrier:getHeadding(true) or 0
	local landingPoint = lso.math.rotateOffsetPoint(self.data.offset, carrierHeadding)
	return carrierPoint.z + landingPoint.z, carrierPoint.x + landingPoint.x
end
-- 根据距离和高度，计算出当前所处下滑道角度
-- distance: 距离
-- altitude: 高度
-- 返回值: 下滑道角度
function lso.Carrier:getGlideSlope(distance, altitude)
	return math.deg(math.atan((altitude - self.data.offset.y)/distance))
end
-- 获取航母航向
-- degrees: 是否返回角度值
-- 返回值: 航母航向
function lso.Carrier:getHeadding(degrees)
	local heading = lso.utils.getHeading(self.unit, true)
	if degrees then
		heading = math.deg(heading)
	end
	return heading
end
-- 计算当前进近角相对于当前着陆甲板朝向的角度偏差
-- angle: 当前进近角
-- degrees: 是否返回角度值
-- 返回值: 角度偏差
function lso.Carrier:getAngleError(angle, degrees)
	local carrierHeadding = lso.Carrier:getHeadding(true)
	local stdAngle = (carrierHeadding - self.data.deck) % 360
	local offset = lso.math.getAzimuthError(angle, stdAngle, true)
	if (degrees) then
		return offset
	else
		return math.rad(offset)
	end
end
function lso.Carrier:getSpeed()
	return lso.utils.getGroundSpeed(self.unit)
end
function lso.Carrier:getCharlie()
	return (not self.turning) and self.recovery and math.abs(lso.Carrier:getBRC() - (lso.Carrier:getHeadding(true) or lso.Carrier:getBRC())) < 10
end
function lso.Carrier:checkOnRunway(unit)
	if (unit.__class == "Plane") then
		unit = plane.unit
	end
	local lx, ly = lso.Carrier:getLandingPoint()
	local unitPoint = unit:getPoint()
	local angle = lso.math.getAzimuth(unitPoint.z, unitPoint.x, lx, ly, true)
	local angleError = lso.Carrier:getAngleError(angle, true)
	local unitHeading = math.deg(lso.utils.getHeading(unit, true) or 0)
	local checkPoint
	if (unit:getDesc().box) then
		local box = unit:getDesc().box
		local parts = {
			nose = lso.math.rotateOffsetPoint({x=box.max.x, y=0, z=0}, unitHeading),
			tail = lso.math.rotateOffsetPoint({x=box.min.x, y=0, z=0}, unitHeading),
			left = lso.math.rotateOffsetPoint({x=0, y=0, z=box.min.z}, unitHeading),
			right = lso.math.rotateOffsetPoint({x=0, y=0, z=box.max.z}, unitHeading),
		}
		checkPoints = {
			{
				x = unitPoint.x + parts.nose.x,
				y = unitPoint.y,
				z = unitPoint.z + parts.nose.z,
			},
			{
				x = unitPoint.x + parts.tail.x,
				y = unitPoint.y,
				z = unitPoint.z + parts.tail.z,
			},
			{
				x = unitPoint.x + parts.left.x,
				y = unitPoint.y,
				z = unitPoint.z + parts.left.z,
			},
			{
				x = unitPoint.x + parts.right.x,
				y = unitPoint.y,
				z = unitPoint.z + parts.right.z,
			},
		}
	else
		checkPoints = {unitPoint}
	end
	local part = 0
	for i, point in ipairs(checkPoints) do
		local distance = lso.utils.getDistance(point.z, point.x, lx, ly)
		local angle = lso.math.getAzimuth(point.z, point.x, lx, ly, true)
		local angleError = lso.Carrier:getAngleError(angle, true)
		local rtg = distance * math.cos(math.rad(angleError))
		local offset = distance * math.sin(math.rad(angleError))
		if (math.abs(rtg) < self.data.runway.length / 2) and (math.abs(offset) < self.data.runway.width / 2) and (point.y - lso.Carrier.data.offset.y < 5) then
			if (part == 0) then
				part = i
			else
				part = 5
			end
		end
	end
	return part ~= 0, part
end
function lso.Carrier:onFrame()
	-- lso.print(string.format("Case %d\ninProcess %d\nrecovery %s\nbackToCruise %s", self.case, #self.inProcess, self.recovery and "true" or "false", self.backToCruise and "true" or "false"), 1, true, "carrierFrame")
	if (self.needToTurn) then
		if (#lso.process.getUnitsInStatus(lso.process.Status.INITIAL + lso.process.Status.BREAK + lso.process.Status.PADDLES) == 0) then
			if (self:addRoute(true)) then
				self.needToTurn = false
			end
		end
	end
	
	-- 检测航母是否在转向
	local heading = lso.Carrier:getHeadding(true)
	if (self.lastHeadding and math.abs(lso.math.getAzimuthError(heading, self.lastHeadding, true)) > 0.1) then
	-- if (self.lastHeadding and heading ~= self.lastHeadding) then
		if (not self.turning) then
			self.turningTime = timer.getTime()
		end
		-- 转向超过 5 分钟重置路径防卡死
		if (lso.carrierSailing and self.turningTime ~= nil and timer.getTime() - self.turningTime > 60 * 5) then
			local group = self.unit:getGroup()
			if group then
				local groupCon = group:getController()
				if groupCon then
					groupCon:popTask()
					self:addRoute()
				end
			end
		end
		self.turning = true
	else
		if (self.turning) then
			self.turningTime = nil
			if (math.abs(lso.Carrier:getBRC() - (lso.Carrier:getHeadding(true) or lso.Carrier:getBRC())) < 10) then
				lso.Broadcast:send(lso.Broadcast.event.TURNING_STOP)
				if (self.recovery) then
					lso.Broadcast:send(lso.Broadcast.event.RECOVERY_START)
				end
			end
		end
		self.turning = false
	end
	self.lastHeadding = heading
	
	-- 判断当前回收状况 Case 1-3
	local case = 0
	local now = lso.utils.getTime()
	local ceiling = lso.Converter.M_FT(env.mission.weather.clouds.base)
	local visibility = 10
	if (env.mission.weather.enable_fog or env.mission.weather.fog.thickness > 0) then
		visibility = lso.Converter.M_NM(env.mission.weather.fog.visibility)
	end
	if (now.h > 7 and now.h < 18) then
		if (visibility >= 5) then
			if (ceiling >= 3000) then
				case = 1
			elseif (ceiling >= 1000) then
				case = 2
			else
				case = 3
			end
		else
			case = 3
		end
	else
		case = 3
	end
	if (case ~= 0) then
		self.case = case
	end
	
	-- 检查飞机状态
	for i, plane in ipairs(self.inProcess) do
		if (not plane.unit:isExist()) then
			self:removePlane(plane)
		end
	end
	for i, unit in ipairs(
		lso.process.getUnitsInStatus(
			lso.process.Status.NONE
			+ lso.process.Status.CHECK_IN 
			+ lso.process.Status.IN_SIGHT
			+ lso.process.Status.INITIAL
			+ lso.process.Status.BREAK
			+ lso.process.Status.ABORT
		)
	) do
		local plane = lso.Plane.get(unit)
		if plane and (not plane.unit:inAir()) and (plane.groundSpeed - lso.Carrier:getSpeed()) < lso.Converter.KNOT_MS(20) then
			lso.process.removePlane(plane)
		end
	end
	
	-- 检查跑道入侵
	local foulDeck = false
	local side = self.unit:getCoalition()
	for i, group in ipairs(lso.utils.listConcat(coalition.getGroups(side, Group.Category.AIRPLANE), coalition.getGroups(side, Group.Category.HELICOPTER))) do
		for j, unit in ipairs(group:getUnits()) do
			if unit:isExist() then
				local carrierPoint = lso.Carrier.unit:getPoint()
				local unitPoint = unit:getPoint()
				if (lso.utils.getDistance(unitPoint.z, unitPoint.x, carrierPoint.z, carrierPoint.x) < 300) then
					local onRunway, part = lso.Carrier:checkOnRunway(unit)
					local plane = lso.Plane.get(unit)
					if plane then
						if (plane.onRunway == true and onRunway == true) then -- 在跑道
							if ((self.foulTime[unit:getName()] == nil or timer.getTime() - self.foulTime[unit:getName()] > 10)
								and lso.Carrier.recovery 
								and #lso.process.getUnitsInStatus(lso.process.Status.PADDLES) == 0
							) then
								self.foulTime[unit:getName()] = timer.getTime()
								local partName = "plane"
								switch(part,
									{1, function()
										partName = "nose"
										return true
									end},
									{2, function()
										partName = "tail"
										return true
									end},
									{3, function()
										partName = "left wing"
										return true
									end},
									{4, function()
										partName = "right wing"
										return true
									end},
									{5, function()
										partName = "plane"
										return true
									end}
								)
								lso.RadioCommand:new(string.format("%s.onRunway", plane.number), "Air Boss", string.format("%s, Move your %s out of the foul lines.", plane.number, partName), nil, 2, lso.RadioCommand.Priority.NORMAL):send()
							end
						elseif (plane.onRunway == true and onRunway == false) then -- 出跑道
							self.foulTime[unit:getName()] = nil
						end
						plane.onRunway = onRunway
					end
					if (onRunway) then
						foulDeck = true
					end
				end
			end
		end
	end
	self.foulDeck = foulDeck
end


-- 飞机类
-- 包含了所需的飞行参数
lso.Plane = {__class="Plane",
	case, -- 飞机正在执行的回收状况
	onRunway, -- 是否在跑道上
	unit, -- 飞机单位
	name, -- 飞机单位名称
	model, -- 飞机型号
	number, -- 机身编号
	point, -- 飞机位置
	altitude, -- 飞机高度（米）
	heading, -- 飞机航向（角度）
	azimuth, -- 飞机位于航母的方位角（角度）
	angle, -- 飞机到着陆点角度（角度）
	angleError, -- 相对着陆甲板角度误差（角度）
	distance, -- 到着陆点的平面距离（米）
	rtg, -- Range-to-go 到着陆点的下滑道剩余距离（米）
	gs, -- 当前下滑道角度（角度）
	gsError, -- 当前下滑道相对标准下滑道误差（角度）
	aoa, -- 攻角（角度）
	roll, -- 侧倾角
	pitch, -- 俯仰角
	speed, -- 示空速（m/s）
	groundSpeed, -- 地速 (m/s)
	vs, -- 垂直速度（m/s）
	fuel, -- 剩余油量（kg）
	fuelLow, -- 油量告竭
	fuelMassMax, -- 最大油量
	updateTime, -- 上次更新数据的时间
}
function lso.Plane:new(unitName, aircraftData, onboardNumber)
	if (unitName == nil) then
		return nil
	end
	local unit = Unit.getByName(unitName)
	local obj = {
		unit = unit,
		name = unitName,
		model = aircraftData,
		number = onboardNumber,
		fuelLow = false,
		fuelMassMax = unit and unit:getDesc().fuelMassMax or nil
	}
	setmetatable(obj, {__index = self, __eq = self.equalTo, __tostring = self.toString})
	return obj
end
function lso.Plane:updateData()
	if (self.unit and self.unit:isExist()) then
		local status, err = pcall(function()
			self.point = self.unit:getPoint()
			self.altitude = self.point.y
			self.heading = math.deg(lso.utils.getHeading(self.unit, true) or 0)
			local lx, ly = lso.Carrier:getLandingPoint()
			self.angle = lso.math.getAzimuth(self.point.z, self.point.x, lx, ly, true)
			self.angleError = lso.Carrier:getAngleError(self.angle, true)
			self.azimuth = (self.angle + 180 - lso.Carrier:getHeadding(true)) % 360
			self.distance = lso.utils.getDistance(self.point.z, self.point.x, lx, ly)
			self.rtg = self.distance * math.cos(math.rad(self.angleError))
			self.gs = lso.Carrier:getGlideSlope(self.distance, self.point.y)
			self.gsError = self.gs - (lso.Carrier.data.gs - lso.utils.getPitch(lso.Carrier.unit))
			self.aoa = math.deg(lso.utils.getAoA(self.unit) or 0)
			self.roll = math.deg(lso.utils.getRoll(self.unit) or 0)
			self.pitch = math.deg(lso.utils.getPitch(self.unit) or 0)
			self.speed = lso.utils.getIndicatedAirSpeed(self.unit) or 0
			self.groundSpeed = lso.utils.getGroundSpeed(self.unit) or 0
			self.vs = lso.utils.getVerticalSpeed(self.unit)
			self.fuel = self.fuelMassMax * self.unit:getFuel()
			self.updateTime = timer.getTime()
		end)
		return status
	else
		return false
	end
end
function lso.Plane.equalTo(self, another)
	local selfName, anotherName
	if (type(self) == "table") then
		selfName = self.name
	else
		selfName = self
	end
	if (type(another) == "table") then
		anotherName = another.name
	else
		anotherName = another
	end
	return selfName ~= nil and anotherName ~= nil and selfName == anotherName
end
function lso.Plane.toString(self)
	return string.format("<Plane: %s>", self.name)
end
function lso.Plane:inAir()
	return self.unit ~= nil and self.unit:isExist() and self.unit:inAir()
end
function lso.Plane:getFuel()
	return self.fuelMassMax * self.unit:getFuel()
end
function lso.Plane.get(unitName)
	if (type(unitName) == "table") then
		unitName = unitName:getName()
	end
	local unit = Unit.getByName(unitName)
	local plane = lso.DB.planes[unitName]
	if (unit and plane) then
		plane.unit = unit
		plane.fuelMassMax = unit:getDesc().fuelMassMax
		if (plane:updateData()) then
			return plane
		end
	end
	return nil
end


-- RadioCommand 类
-- 创建和发送无线电指令
lso.radioSoundQueue = nil
lso.RadioCommand = {__class="RadioCommand", id, sent, tag, speaker, msg, sound, duration, priority, showTime, callback}
lso.RadioCommand.count = 0
lso.RadioCommand.Priority = Enum(
	"LOW",
	"NORMAL",
	"HIGH",
	"IMMEDIATELY"
)
function lso.RadioCommand:new(tag, speaker, msg, sound, duration, priority, showTime)
	assert(msg ~= nil, "RadioCommand: msg cannot be nil");
	self.count = self.count + 1
	local soundList
	if (type(sound) == "table" and #sound > 0) then
		if (type(sound[1]) == "table") then
			soundList = sound
		else
			soundList = {sound}
		end
	else
		soundList = {lso.Sound.RADIO}
	end
	local obj = {
		id = self.count,
		sent = false,
		tag = tag or ("RadioCommand"..self.count),
		speaker = speaker,
		msg = msg,
		sound = soundList,
		duration = duration or 1,
		priority = priority or lso.RadioCommand.Priority.NORMAL,
		showTime = showTime or 5,
	}
	setmetatable(obj, {__index=self, __eq=self.equalTo, __tostring=self.toString, __add=self.concat, __concat=self.concat})
	return obj
end
function lso.RadioCommand.concat(self, another)
	if (type(another) == "table") then
		local group
		if (another.__class == "RadioCommand") then
			group = lso.RadioCommandGroup:new({self, another})
		elseif (another.__class == "RadioCommandGroup") then
			group = another
			group:add(self, 1)
		end
		return group
	end
end
function lso.RadioCommand.equalTo(self, another)
	local selfObj, anotherObj
	if (type(self) == "table") then
		selfObj = self.tag
	else
		selfObj = self
	end
	if (type(another) == "table") then
		anotherObj = another.tag
	else
		anotherObj = another
	end
	return selfObj == anotherObj
end
function lso.RadioCommand.toString(self)
	return self.tag
end
function lso.RadioCommand:onFinish(callback)
	self.callback = callback
	return self
end
function lso.RadioCommand:getDuration()
	return self.duration
end
function lso.RadioCommand:prepare(speaker, data)
	if type(speaker) == "table" and data == nil then
		data = speaker
		speaker = nil
	end
	self.speaker = speaker or self.speaker
	self.data = data or self.data
	return self
end
function lso.RadioCommand:send(speaker, data)
	self:prepare(speaker, data)
	local unit = lso.useRadioFrequency and lso.Carrier.radio or lso.Carrier.unit
	local content = self.msg:format(unpack(self.data or {}))
	local msg = string.format("%s: %s", self.speaker or "Unknown", content)
	local soundDuration = 0
	for i, sound in ipairs(self.sound) do
		soundDuration = soundDuration + sound[2]
	end
	if (unit and unit:isExist()) then
		self.sent = true
		if (lso.useRadioFrequency) then
			local controller = unit:getController()
			if (controller) then
				local command = { 
					id = 'TransmitMessage',
					params = {
						duration = math.max(self.showTime, soundDuration),
						subtitle = msg,
						loop = false,
						file = self.sound[1][1],
					}
				}
				controller:setCommand(command)
			end
		else
			trigger.action.outTextForCoalition(unit:getCoalition(), msg, math.max(self.showTime, soundDuration))
		end
		if (lso.radioSoundQueue ~= nil) then
			pcall(function()
				timer.removeFunction(lso.radioSoundQueue)
			end)
			lso.radioSoundQueue = nil
		end
		local soundIndex = 2
		local radioSound = function()
			trigger.action.outSoundForCoalition(unit:getCoalition(), self.sound[soundIndex][1])
			soundIndex = soundIndex + 1
			if (soundIndex <= #self.sound) then
				return timer.getTime() + self.sound[soundIndex][2]
			end
		end
		trigger.action.outSoundForCoalition(unit:getCoalition(), self.sound[1][1])
		if (#self.sound > 1) then
			lso.radioSoundQueue = timer.scheduleFunction(radioSound, nil, timer.getTime() + self.sound[1][2])
		end
		if (self.callback) then
			timer.scheduleFunction(self.callback, self, timer.getTime() + math.max(self.duration, soundDuration))
		end
	end
end


-- RadioCommandGroup 类
-- 创建和发送无线电指令组
lso.RadioCommandGroup = {__class="RadioCommandGroup", id, sent, msgQueue, callback, sendTask, 
	tag, duration, priority}
lso.RadioCommandGroup.count = 0
function lso.RadioCommandGroup:new(msgQueue)
	msgQueue = type(msgQueue) == "table" and msgQueue or {}
	self.count = self.count + 1
	local obj = {
		id = self.count,
		sent = false,
		msgQueue = msgQueue,
	}
	setmetatable(obj, {__index = self, __eq = self.equalTo, __add=self.concat, __concat=self.concat})
	obj:update()
	obj:updatePriority()
	return obj
end
function lso.RadioCommandGroup:update()
	if (#self.msgQueue > 0) then
		local tags = {}
		for i, msg in ipairs(self.msgQueue) do
			table.insert(tags, msg.tag)
		end
		self.tag = table.concat(tags, "+")
		
		local duration = 0
		for i, msg in ipairs(self.msgQueue) do
			duration = duration + msg.duration
		end
		self.duration = duration
	end
end
function lso.RadioCommandGroup:updatePriority()
	if (#self.msgQueue > 0) then
		local priority = lso.RadioCommand.Priority.LOW
		for i, msg in ipairs(self.msgQueue) do
			if (msg.priority > priority) then
				priority = msg.priority
			end
		end
		self.priority = priority
	end
end
function lso.RadioCommandGroup:add(msg, index)
	local i = index or #self.msgQueue + 1
	if (type(msg) == "table") then
		if (msg.__class == "RadioCommand") then
			msg = {msg}
		elseif (msg.__class == "RadioCommandGroup") then
			msg = msg.msgQueue
		end
		for __i, v in ipairs(msg) do
			table.insert(self.msgQueue, i, v)
			i = i + 1
		end
		self:update()
		self:updatePriority()
	end
end
function lso.RadioCommandGroup.concat(self, another)
	if (type(another) == "table") then
		if (another.__class == "RadioCommand") then
			self:add(another)
		elseif (another.__class == "RadioCommandGroup") then
			self:add(another)
		end
		return self
	end
end
function lso.RadioCommandGroup.equalTo(self, another)
	if (
		type(self) == "table" and type(another) == "table"
		and self.__class == "RadioCommandGroup" and another.__class == "RadioCommandGroup"
		) then
		return self.id == another.id
	else
		return false
	end
end
function lso.RadioCommandGroup:onFinish(callback)
	self.callback = callback
	return self
end
function lso.RadioCommandGroup:getDuration()
	return self.duration
end
function lso.RadioCommandGroup:send()
	local sendQueue = function(args, timestamp)
		local msg = table.remove(self.msgQueue, 1)
		self:updatePriority()
		if msg then
			msg:send()
			return timer.getTime() + msg.duration
		else
			if self.callback then
				self.callback(self)
			end
			return nil
		end
	end
	self.sendTask = timer.scheduleFunction(sendQueue, nil, sendQueue() or timer.getTime() + 0.01)
	self.sent = true
end


-- 单位转换器
lso.Converter = {
	KG_LB = function(src)
		return src * 2.204623
	end,
	LB_KG = function(src)
		return src / 2.204623
	end,
	M_MI = function(src)
		return src * 0.000621
	end,
	MI_M = function(src)
		return src / 0.000621
	end,
	M_NM = function(src)
		return src * 0.00054
	end,
	NM_M = function(src)
		return src / 0.00054
	end,
	M_FT = function(src)
		return src * 3.28084
	end,
	FT_M = function(src)
		return src / 3.28084
	end,
	PA_INHG = function(src)
		return src * 0.007502 * 0.03937
	end,
	INHG_PA = function(src)
		return src / 0.007502 / 0.03937
	end,
	K_C = function(src)
		return src - 273.15
	end,
	C_K = function(src)
		return src + 273.15
	end,
	MS_KNOT = function(src)
		return src * 1.944012
	end,
	KNOT_MS = function(src)
		return src / 1.944012
	end,
}


-- 工具模块
lso.utils = {}

function lso.utils.deepCopy(object)
	local lookup_table = {}
	local function _copy(object)
		if type(object) ~= "table" then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end
		local new_table = {}
		lookup_table[object] = new_table
		for index, value in pairs(object) do
			new_table[_copy(index)] = _copy(value)
		end
		return setmetatable(new_table, getmetatable(object))
	end
	return _copy(object)
end

function lso.utils.tableSize(t)
	local count = 0
	for k, v in pairs(t) do
		count = count + 1
	end
	return count
end

function lso.utils.listContains(t, v)
	for key, val in ipairs(t) do
		if (val == v) then
			return true, key
		end
	end
	return false, -1
end

function lso.utils.listRemove(t, v)
	local contains, key = lso.utils.listContains(t, v)
	if (contains) then
		table.remove(t, key)
		return true
	else
		return false
	end
end

function lso.utils.listConcat(t1, t2)
	local newTable = {}
	for i, v in ipairs(t1) do
		if not lso.utils.listContains(newTable, v) then
			table.insert(newTable, v)
		end
	end
	for i, v in ipairs(t2) do
		if not lso.utils.listContains(newTable, v) then
			table.insert(newTable, v)
		end
	end
	return newTable
end

-- 来自 MIST 的代码，用于debug输出table
function lso.utils.basicSerialize(var)
	if var == nil then
		return "\"\""
	else
		if ((type(var) == 'number') or
			(type(var) == 'boolean') or
			(type(var) == 'function') or
			(type(var) == 'table') or
			(type(var) == 'userdata') ) then
			return tostring(var)
		elseif type(var) == 'string' then
			var = string.format('%q', var)
			return var
		end
	end
end
function lso.utils.tableShow(tbl, loc, indent, tableshow_tbls) --based on serialize_slmod, this is a _G serialization
	tableshow_tbls = tableshow_tbls or {} --create table of tables
	loc = loc or ""
	indent = indent or ""
	if type(tbl) == 'table' then --function only works for tables!
		tableshow_tbls[tbl] = loc

		local tbl_str = {}

		tbl_str[#tbl_str + 1] = indent .. '{\n'

		for ind,val in pairs(tbl) do -- serialize its fields
			if type(ind) == "number" then
				tbl_str[#tbl_str + 1] = indent
				tbl_str[#tbl_str + 1] = loc .. '['
				tbl_str[#tbl_str + 1] = tostring(ind)
				tbl_str[#tbl_str + 1] = '] = '
			else
				tbl_str[#tbl_str + 1] = indent
				tbl_str[#tbl_str + 1] = loc .. '['
				tbl_str[#tbl_str + 1] = lso.utils.basicSerialize(ind)
				tbl_str[#tbl_str + 1] = '] = '
			end

			if ((type(val) == 'number') or (type(val) == 'boolean')) then
				tbl_str[#tbl_str + 1] = tostring(val)
				tbl_str[#tbl_str + 1] = ',\n'
			elseif type(val) == 'string' then
				tbl_str[#tbl_str + 1] = lso.utils.basicSerialize(val)
				tbl_str[#tbl_str + 1] = ',\n'
			elseif type(val) == 'nil' then -- won't ever happen, right?
				tbl_str[#tbl_str + 1] = 'nil,\n'
			elseif type(val) == 'table' then
				if tableshow_tbls[val] then
					tbl_str[#tbl_str + 1] = tostring(val) .. ' already defined: ' .. tableshow_tbls[val] .. ',\n'
				else
					tableshow_tbls[val] = loc ..	'[' .. lso.utils.basicSerialize(ind) .. ']'
					tbl_str[#tbl_str + 1] = tostring(val) .. ' '
					tbl_str[#tbl_str + 1] = lso.utils.tableShow(val,	loc .. '[' .. lso.utils.basicSerialize(ind).. ']', indent .. '		', tableshow_tbls)
					tbl_str[#tbl_str + 1] = ',\n'
				end
			elseif type(val) == 'function' then
				if debug and debug.getinfo then
					local fcnname = tostring(val)
					local info = debug.getinfo(val, "S")
					if info.what == "C" then
						tbl_str[#tbl_str + 1] = string.format('%q', fcnname .. ', C function') .. ',\n'
					else
						if (string.sub(info.source, 1, 2) == [[./]]) then
							tbl_str[#tbl_str + 1] = string.format('%q', fcnname .. ', defined in (' .. info.linedefined .. '-' .. info.lastlinedefined .. ')' .. info.source) ..',\n'
						else
							tbl_str[#tbl_str + 1] = string.format('%q', fcnname .. ', defined in (' .. info.linedefined .. '-' .. info.lastlinedefined .. ')') ..',\n'
						end
					end

				else
					tbl_str[#tbl_str + 1] = 'a function,\n'
				end
			else
				tbl_str[#tbl_str + 1] = 'unable to serialize value type ' .. lso.utils.basicSerialize(type(val)) .. ' at index ' .. tostring(ind)
			end
		end

		tbl_str[#tbl_str + 1] = indent .. '}'
		return table.concat(tbl_str)
	end
end

-- 获取当前游戏中时间
function lso.utils.getTime(t)
	local timeInSec = 0
	if t and type(t) == 'number' then
		timeInSec = t
	else
		timeInSec = lso.math.round(timer.getAbsTime() + env.mission.start_time)
	end
	local timeData = {h=0, m=0, s=0}
	timeInSec = timeInSec % 86400
	while timeInSec >= 3600 do
		timeData.h = timeData.h + 1
		timeInSec = timeInSec - 3600
	end
	while timeInSec >= 60 do
		timeData.m = timeData.m + 1
		timeInSec = timeInSec - 60
	end
	timeData.s = timeInSec
	return timeData
end

-- 计算两点欧氏距离
function lso.utils.getDistance(x1, y1, x2, y2)
	return math.sqrt(math.pow(x1 - x2, 2) + math.pow(y1 - y2, 2))
end

-- 获取指定坐标点风数据 (风向，风速)
function lso.utils.getWindInfo(gPoint, alt)
	local point = lso.utils.deepCopy(gPoint)
	if not point.z then --convert vec2 to Vec3
		point.z = point.y
		point.y = 1
	else
		if point.y < 1 then
			point.y = 1
		end
	end
	if alt ~= nil then
		point.y = alt
	end
	local wind = atmosphere.getWind(point)
	local heading = math.atan2(wind.z, wind.x)
	heading = heading + lso.utils.getNorthCorrection(point)
	if heading < 0 then
		heading = heading + 2*math.pi
	end
	heading = (heading + math.pi) % (2 * math.pi)
	local speed = lso.math.getMag(wind) or 0
	return heading, speed
end

-- 获取单位航向 MIST
function lso.utils.getHeading(unit, rawHeading)
	local unitpos = unit:getPosition()
	if unitpos then
		local heading = math.atan2(unitpos.x.z, unitpos.x.x)
		if not rawHeading then
			heading = heading + lso.utils.getNorthCorrection(unitpos.p)
		end
		if heading < 0 then
			heading = heading + 2*math.pi	-- put heading in range of 0 to 2*pi
		end
		return heading
	end
end

-- 获取单位攻角 MIST
function lso.utils.getAoA(unit)
	local unitpos = unit:getPosition()
	if unitpos then
		local unitvel = unit:getVelocity()
		if lso.math.getMag(unitvel) ~= 0 then --must have non-zero velocity!
			local AxialVel = {}	--unit velocity transformed into aircraft axes directions
			--transform velocity components in direction of aircraft axes.
			AxialVel.x = lso.math.getDP(unitpos.x, unitvel)
			AxialVel.y = lso.math.getDP(unitpos.y, unitvel)
			AxialVel.z = lso.math.getDP(unitpos.z, unitvel)
			-- AoA is angle between unitpos.x and the x and y velocities
			local AoA = math.acos(lso.math.getDP({x = 1, y = 0, z = 0}, {x = AxialVel.x, y = AxialVel.y, z = 0})/lso.math.getMag({x = AxialVel.x, y = AxialVel.y, z = 0}))
			--now set correct direction:
			if AxialVel.y > 0 then
				AoA = -AoA
			end
			return AoA
		end
	end
end

-- 获取单位俯仰角 MIST
function lso.utils.getPitch(unit)
	local unitpos = unit:getPosition()
	if unitpos then
		return math.asin(unitpos.x.y)
	end
end

-- 获取单位侧倾角 MIST
function lso.utils.getRoll(unit)
	local unitpos = unit:getPosition()
	if unitpos then
		-- now get roll:
		--maybe not the best way to do it, but it works.
		--first, make a vector that is perpendicular to y and unitpos.x with cross product
		local cp = lso.math.getCP(unitpos.x, {x = 0, y = 1, z = 0})
		--now, get dot product of of this cross product with unitpos.z
		local dp = lso.math.getDP(cp, unitpos.z)
		--now get the magnitude of the roll (magnitude of the angle between two vectors is acos(vec1.vec2/|vec1||vec2|)
		local Roll = math.acos(dp/(lso.math.getMag(cp)*lso.math.getMag(unitpos.z)))
		--now, have to get sign of roll.
		-- by convention, making right roll positive
		-- to get sign of roll, use the y component of unitpos.z.	For right roll, y component is negative.
		if unitpos.z.y < 0 then -- right roll, flip the sign of the roll
			Roll = -Roll
		end
		return Roll
	end
end

-- 获取单位偏航角 MIST
function lso.utils.getYaw(unit)
	local unitpos = unit:getPosition()
	if unitpos then
		-- get unit velocity
		local unitvel = unit:getVelocity()
		if lso.math.getMag(unitvel) ~= 0 then --must have non-zero velocity!
			local AxialVel = {}	--unit velocity transformed into aircraft axes directions
			--transform velocity components in direction of aircraft axes.
			AxialVel.x = lso.math.getDP(unitpos.x, unitvel)
			AxialVel.y = lso.math.getDP(unitpos.y, unitvel)
			AxialVel.z = lso.math.getDP(unitpos.z, unitvel)
			--Yaw is the angle between unitpos.x and the x and z velocities
			--define right yaw as positive
			local Yaw = math.acos(lso.math.getDP({x = 1, y = 0, z = 0}, {x = AxialVel.x, y = 0, z = AxialVel.z})/lso.math.getMag({x = AxialVel.x, y = 0, z = AxialVel.z}))
			--now set correct direction:
			if AxialVel.z > 0 then
				Yaw = -Yaw
			end
			return Yaw
		end
	end
end

-- 获取单位垂直速度 m/s
function lso.utils.getVerticalSpeed(unit)
	if (type(unit) == "string") then
		unit = Unit.getByName(unit)
	end
	return unit:getVelocity().y
end

-- 获取单位真空速 m/s
function lso.utils.getAirSpeed(unit)
	if (type(unit) == "string") then
		unit = Unit.getByName(unit)
	end
	return lso.math.getMag(unit:getVelocity()) or 0
end

-- 获取单位地速 m/s
function lso.utils.getGroundSpeed(unit)
	if (type(unit) == "string") then
		unit = Unit.getByName(unit)
	end
	local vel = unit:getVelocity()
	return lso.math.getMag(vel.x, vel.z) or 0
end

-- 获取单位示空速 m/s
function lso.utils.getIndicatedAirSpeed(unit)
	if (type(unit) == "string") then
		unit = Unit.getByName(unit)
	end
	local wind = atmosphere.getWind(unit:getPoint())
	local velocity = unit:getVelocity()
	local windSpeed = lso.math.getDP(wind, velocity) / lso.math.getMag(velocity)
	local tas = lso.utils.getAirSpeed(unit)
	local point = unit:getPoint()
	local t, p = atmosphere.getTemperatureAndPressure(point)
	local t0 = 288.15 -- 15℃标准气温（开尔文）
	point.y = 0
	local tsl, p0 = atmosphere.getTemperatureAndPressure(point)
	-- EAS = √((TAS^2)/(p0/p)/(T/T0))
	local eas = math.sqrt(math.pow(tas, 2) / (p0/p) / (t/t0))
	eas = eas - windSpeed
	return math.abs(eas)
end

-- 获取单位气压高度 m （实验）
function lso.utils.getBaroAltitude(unit)
	if (type(unit) == "string") then
		unit = Unit.getByName(unit)
	end
	local point = unit:getPoint()
	local t, p = atmosphere.getTemperatureAndPressure(point)
	point.y = 0
	local t0, p0 = atmosphere.getTemperatureAndPressure(point)
	local alt = (1 - math.pow(p/p0, 1/5.256)) / 0.00002257
	return alt
end

-- 获取圈中随机点 MIST
function lso.utils.getRandPointInCircle(point, radius, innerRadius)
	local theta = 2*math.pi*math.random()
	local rad = math.random() + math.random()
	if rad > 1 then
		rad = 2 - rad
	end

	local radMult
	if innerRadius and innerRadius <= radius then
		radMult = (radius - innerRadius)*rad + innerRadius
	else
		radMult = radius*rad
	end

	if not point.z then --might as well work with vec2/3
		point.z = point.y
	end

	local rndCoord
	if radius > 0 then
		rndCoord = {x = math.cos(theta)*radMult + point.x, y = math.sin(theta)*radMult + point.z}
	else
		rndCoord = {x = point.x, y = point.z}
	end
	return rndCoord
end

-- 获取指定坐标点的北修正量
function lso.utils.getNorthCorrection(gPoint)
	local point = lso.utils.deepCopy(gPoint)
	if not point.z then --convert vec2 to Vec3
		point.z = point.y
		point.y = 0
	end
	local lat, lon = coord.LOtoLL(point)
	local north_posit = coord.LLtoLO(lat + 1, lon)
	return math.atan2(north_posit.z - point.z, north_posit.x - point.x)
end

-- 检查两点之间是否存在陆地 Vec2
function lso.utils.checkLand(point1, point2)
	local dist = lso.utils.getDistance(point1.x, point1.y, point2.x, point2.y)
	local dx = point1.x - point2.x
	local dy = point1.y - point2.y

	local hasLand = false
	for delta = 1, dist do
		local x = point2.x + (dx * (delta / dist))
		local y = point2.y + (dy * (delta / dist))
		if (land.getSurfaceType({x=x, y=y}) ~= land.SurfaceType.WATER) then
			hasLand = true
			break
		end
	end
	return hasLand
end

-- 数学计算工具模块
lso.math ={}

function lso.math.round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

function lso.math.random(low, high, decimal)
	if (low == nil and high == nil) then
		decimal = true
	end
	low = low or 1
	if high == nil then
		high = low
		low = 0
	end
	local value = math.random()
	for i=1,50 do
		value = math.random()
	end
	value = value * (high - low) + low
	if not decimal then
		value = lso.math.round(value)
	end
	return value
end

function lso.math.dirToAngle(direction, degrees)
	local dir
	if (degrees) then
		dir = direction
	else
		dir = math.deg(direction)
	end
	local diff = 450 - dir
	local angle
	if (dir > 90 and dir < 270) then
		angle = -(360 % diff)
	else
		angle = diff % 360
	end
	if (degrees) then
		return angle
	else
		return math.rad(angle)
	end
end
function lso.math.angleToDir(angle, degrees)
	local agl
	if (degrees) then
		agl = angle
	else
		agl = math.deg(angle)
	end
	local diff = agl - 90
	local dir
	if (diff > 0) then
		dir = 450 - agl
	else
		dir = math.abs(diff)
	end
	if (degrees) then
		return dir
	else
		return math.rad(dir)
	end
end

function lso.math.getOffsetPoint(x, y, dir, dist)
	local angle = math.rad(lso.math.dirToAngle(dir, true))
	local dx = math.cos(angle) * dist
	local dy = math.sin(angle) * dist
	return x + dx, y + dy
end

function lso.math.rotateOffsetPoint(point, angle)
	local rPoint = {y = point.y}
	rPoint.z = point.z * math.cos(math.rad(angle)) + point.x * math.sin(math.rad(angle))
	rPoint.x = point.x * math.cos(math.rad(angle)) - point.z * math.sin(math.rad(angle))
	return rPoint
end

-- 计算相对方位角
-- 根据给定的坐标，计算出两点的相对方位角
-- xs,ys:基准点坐标
-- xt,yt:目标点坐标
-- degrees:布尔值，是否返回角度（默认返回弧度）
function lso.math.getAzimuth(xs, ys, xt, yt, degrees)
	local dx = xt - xs
	local dy = yt - ys
	local azimuth
	if (dx == 0) then
		if (dy >= 0) then
			azimuth = 0
		else
			azimuth = math.pi
		end
	else
		azimuth = lso.math.angleToDir(math.atan(dy/dx))
		if (xt < xs) then
			azimuth = azimuth + math.pi
		end
	end
	azimuth = (azimuth + lso.utils.getNorthCorrection({x=xs, y=ys})) % (2 * math.pi)
	if (degrees) then
		return math.deg(azimuth)
	else
		return azimuth
	end
end

function lso.math.getAzimuthError(a1, a2, degrees)
	local diff
	if (degrees) then
		diff = a1 - a2
	else
		diff = math.deg(a1-a2)
	end
	local angleDiff
	if (diff <= 180 and diff >= - 180) then
		angleDiff = diff
	elseif (diff > 180) then
		angleDiff = diff - 360
	elseif (diff < -180) then
		angleDiff = diff + 360
	end
	if (degrees) then
		return angleDiff
	else
		return math.rad(angleDiff)
	end
end

-- 计算平均值
-- 计算一组数据的平均值
-- data:数据 table
function lso.math.getAverage(data)
	if (#data == 0) then
		return 0
	end
	local avg = 0	-- 平均值
	for i, v in ipairs(data) do
		avg = avg + v
	end
	avg = avg / #data
	return avg
end

-- 计算方差
-- 计算一组数据的方差
-- data:数据 table
function lso.math.getVariance(data)
	if (#data < 2) then
		return 0
	end
	local avg = lso.math.getAverage(data)
	local sum = 0
	for i, v in ipairs(data) do
		sum = sum + math.pow(v - avg, 2)
	end

	return sum / #data
end

-- 计算向量合
function lso.math.getMag(...)
	local vec = {...}
	local sum = 0
	if (#vec == 0) then
		return sum
	end
	if (type(vec[1]) == "table") then
		vec = vec[1]
	end
	for i, v in pairs(vec) do
		sum = sum + math.pow(v, 2)
	end
	return math.sqrt(sum)
end

-- 计算向量点积
function lso.math.getDP(vec1, vec2)
	return vec1.x*vec2.x + vec1.y*vec2.y + vec1.z*vec2.z
end

-- 计算向量交叉乘积
function lso.math.getCP(vec1, vec2)
	return { x = vec1.y*vec2.z - vec1.z*vec2.y, y = vec1.z*vec2.x - vec1.x*vec2.z, z = vec1.x*vec2.y - vec1.y*vec2.x}
end


lso.process = {}
lso.process.currentStatus = {}
lso.process.Status = Enum(
	"NONE",
	"CHECK_IN",
	"IN_SIGHT",
	"INITIAL",
	"BREAK",
	"PADDLES",
	"ABORT"
)
function lso.process.changeStatus(unit, newStatus)
	lso.process.currentStatus[unit:getName()] = newStatus
end
function lso.process.getStatus(unit)
	if (type(unit) == "table" and unit.__class == "Plane") then
		unit = unit.unit
	end
	return lso.process.currentStatus[unit:getName()]
end
function lso.process.initPlane(unit)
	if (type(unit) == "table" and unit.__class == "Plane") then
		unit = unit.unit
	end
	local plane = lso.Plane.get(unit)
	if plane then
		plane.fuelLow = false
		lso.Carrier:removePlane(plane)
		lso.Broadcast:send(lso.Broadcast.event.INIT_PLANE, plane)
	end
	lso.process.changeStatus(unit, lso.process.Status.NONE)
	lso.Menu:initMenu(unit)
end
function lso.process.removePlane(unit)
	if (type(unit) == "table" and unit.__class == "Plane") then
		unit = unit.unit
	end
	local plane = lso.Plane.get(unit)
	if plane then
		plane.fuelLow = false
		lso.Carrier:removePlane(plane)
		lso.Broadcast:send(lso.Broadcast.event.REMOVE_PLANE, plane)
	end
	lso.process.changeStatus(unit, lso.process.Status.NONE)
	lso.Menu:clearMenu(unit, true)
end
function lso.process.getUnitsInStatus(status)
	local units = {}
	local insert = function(unit)
		local exist = false
		for i, value in ipairs(units) do
			if (value:getName() == unit:getName()) then
				exist = true
				break
			end
		end
		if not exist then
			table.insert(units, unit)
		end
	end
	for unitName, currStatus in pairs(lso.process.currentStatus) do
		if (status == currStatus) then
			local unit = Unit.getByName(unitName)
			if (unit and unit:isExist()) then
				insert(unit)
			end
		end
	end
	return units
end


lso.Menu = {}
-- 默认菜单
lso.Menu.defaultMenu = {
	[1] = {tag="CHECK_IN", 	text="Check in", 		handler="checkIn"},
	[2] = {tag="IN_SIGHT", 	text="In Sight", 		handler="inSight"},
	[3] = {tag="INFO", 		text="Information", 	handler="information"},
	[4] = {tag="EMERGENCY", text="Emergency", 		handler="emergency"},
	[5] = {tag="ABORT", 	text="Abort Landing", 	handler="abort"},
	[6] = {tag="DEPART", 	text="Depart", 			handler="depart"},
}
lso.Menu.Command = {} -- 所有菜单
lso.Menu.order = {} -- 菜单顺序
lso.Menu.path = {} -- 菜单路径
function lso.Menu:registerMenu(tag, text, handler, order)
	assert(type(tag) == "string", string.format("bad argument #1 (tag) to 'lso.Menu:registerMenu' (string expected, got %s)", type(tag)))
	assert(type(text) == "string", string.format("bad argument #2 (text) to 'lso.Menu:registerMenu' (string expected, got %s)", type(text)))
	assert(type(handler) == "function", string.format("bad argument #3 (handler) to 'lso.Menu:registerMenu' (function expected, got %s)", type(handler)))
	assert(order == nil or type(order) == "number", string.format("bad argument #4 (order) to 'lso.Menu:registerMenu' (number expected, got %s)", type(order)))
	assert(self.Command[tag] == nil, string.format("Fail to register menu (Tag \"%s\"already exist).", tag))
	self.Command[tag] = {text=text, handler=handler}
	table.insert(self.order, order or (#self.order + 1), self.Command[tag])
	return self.Command[tag]
end
function lso.Menu:init()
	for i, menu in ipairs(self.defaultMenu) do
		local handler = type(menu.handler) == "string" and self.handler[menu.handler] or menu.handler
		lso.Menu:registerMenu(menu.tag, menu.text, handler, i)
	end
end
function lso.Menu:addMenu(unit, menu, handler)
	if (unit.__class == "Plane") then
		unit = unit.unit
	end
	if (lso.Menu.path[unit:getName()][menu.text] == nil) then
		if not (handler) then
			if type(menu.handler) == "string" then
				handler = lso.Menu.handler[menu.handler]
			elseif type(menu.handler) == "function" then
				handler = menu.handler
			end
		end
		if type(handler) == "function" then
			lso.Menu:clearMenu(unit)
			for i, m in ipairs(lso.Menu.order) do
				if (lso.Menu:hasMenu(unit, m)) then
					local mData = lso.Menu:getMenu(unit, m)
					lso.Menu.path[unit:getName()][m.text].path = missionCommands.addCommandForGroup(unit:getGroup():getID(), m.text, lso.Menu.path[unit:getName()].root, mData.handler, unit:getName())
				elseif (m == menu) then
					lso.Menu.path[unit:getName()][menu.text] = {
						path = missionCommands.addCommandForGroup(unit:getGroup():getID(), menu.text, lso.Menu.path[unit:getName()].root, handler, unit:getName()),
						handler = handler,
					}
				end
			end
			return true
		end
	end
	return false
end
function lso.Menu:removeMenu(unit, menu)
	if (unit.__class == "Plane") then
		unit = unit.unit
	end
	if (lso.Menu.path[unit:getName()][menu.text] ~= nil) then
		missionCommands.removeItemForGroup(unit:getGroup():getID(), lso.Menu.path[unit:getName()][menu.text].path)
		lso.Menu.path[unit:getName()][menu.text] = nil
		return true
	else
		return false
	end
end
function lso.Menu:getMenu(unit, menu)
	if (unit.__class == "Plane") then
		unit = unit.unit
	end
	return lso.Menu.path[unit:getName()][menu.text]
end
function lso.Menu:hasMenu(unit, menu)
	if (unit.__class == "Plane") then
		unit = unit.unit
	end
	return lso.Menu.path[unit:getName()][menu.text] ~= nil
end
function lso.Menu:initMenu(unit)
	if (unit.__class == "Plane") then
		unit = unit.unit
	end
	lso.Menu:clearMenu(unit)
	lso.Menu.path[unit:getName()] = {}
	if lso.useSubMenu then
		lso.Menu.path[unit:getName()].root = missionCommands.addSubMenuForGroup(unit:getGroup():getID(), lso.subMenuName)
	end
	lso.Menu:addMenu(unit, lso.Menu.Command.CHECK_IN, lso.Menu.handler.checkIn)
	lso.Broadcast:send(lso.Broadcast.event.INIT_MENU, unit)
end
function lso.Menu:clearMenu(unit, removePath)
	if (unit.__class == "Plane") then
		unit = unit.unit
	end
	local unitName = unit:getName()
	if lso.Menu.path[unitName] ~= nil then
		for tag, menu in pairs(lso.Menu.Command) do
			if lso.Menu.path[unitName][menu.text] ~= nil then
				missionCommands.removeItemForGroup(unit:getGroup():getID(), lso.Menu.path[unitName][menu.text].path)
				if removePath then
					lso.Menu.path[unitName][menu.text] = nil
				end
			end
		end
	end
end

-- 默认菜单处理器
lso.Menu.handler = {}
function lso.Menu.handler.checkIn(unitName)
	local unit = Unit.getByName(unitName)
	if (not lso.Menu:hasMenu(unit, lso.Menu.Command.CHECK_IN)) then
		return
	end
	-- local plane = lso.Plane.get(unit)
	-- if plane then
		-- lso.LSO:track(plane)
	-- end
	if (lso.process.getStatus(unit) == lso.process.Status.NONE) then
		local plane = lso.Plane.get(unit)
		if (plane and plane.unit:inAir()) then
			local fuelMess = lso.Converter.KG_LB(plane.fuel) / 1000 -- 千磅
			local angel = lso.math.round(lso.Converter.M_FT(plane.altitude) / 1000) -- 千英尺
			local distance = lso.math.round(lso.Converter.M_NM(plane.distance)) -- 海里
			
			lso.RadioCommand:new(string.format("%s.check_in", plane.name), plane.number, string.format("Marshal, %s, %03d for %d, Angels %d, State %.1f.", plane.number, (plane.angle + 180) % 360, distance, angel, fuelMess), nil, 4, lso.RadioCommand.Priority.NORMAL)
				:onFinish(function()
					lso.Marshal:checkIn(unit)
				end)
				:send()
		end
	end
end
function lso.Menu.handler.inSight(unitName)
	local unit = Unit.getByName(unitName)
	if (not lso.Menu:hasMenu(unit, lso.Menu.Command.IN_SIGHT)) then
		return
	end
	if (lso.process.getStatus(unit) == lso.process.Status.CHECK_IN) then
		local plane = lso.Plane.get(unit)
		if (plane) then
			local distance = lso.math.round(lso.Converter.M_NM(plane.distance)) -- 海里
			
			lso.RadioCommand:new(string.format("%s.see_you", plane.name), plane.number, string.format("Marshal, %s, See you at %d.", plane.number, distance), nil, 2, lso.RadioCommand.Priority.NORMAL)
				:onFinish(function()
					lso.Marshal:inSight(unit)
				end)
				:send()
		end
	end
end
function lso.Menu.handler.information(unitName)
	local unit = Unit.getByName(unitName)
	if (not lso.Menu:hasMenu(unit, lso.Menu.Command.INFO)) then
		return
	end
	local plane = lso.Plane.get(unit)
	if (plane) then
		lso.Marshal:offerInformation()
	end
end
function lso.Menu.handler.emergency(unitName)
	local unit = Unit.getByName(unitName)
	if (not lso.Menu:hasMenu(unit, lso.Menu.Command.EMERGENCY)) then
		return
	end
	local plane = lso.Plane.get(unit)
	if (plane) then
		local radio = (
			lso.RadioCommand:new(string.format("%s.emergency", plane.name), plane.number, string.format("Marshal, %s, Declare emergency.", plane.number), nil, 2, lso.RadioCommand.Priority.NORMAL)
				:prepare()
			+ lso.RadioCommand:new(string.format("%s.emergency_roger", plane.name), "Marshal", string.format("%s, Roger, Wait for Charlie.", plane.number), nil, 3, lso.RadioCommand.Priority.NORMAL)
				:prepare()
		):onFinish(function()
			lso.Broadcast:send(lso.Broadcast.event.EMERGENCY, plane)
		end)
		radio:send()
	end
end
function lso.Menu.handler.depart(unitName)
	local unit = Unit.getByName(unitName)
	if (not lso.Menu:hasMenu(unit, lso.Menu.Command.DEPART)) then
		return
	end
	local plane = lso.Plane.get(unit)
	if (plane) then
		lso.Carrier:removePlane(plane)
		lso.process.initPlane(unit)
		lso.RadioCommand:new(string.format("%s.depart", plane.number), plane.number, string.format("%s, Depart.", plane.number), nil, 2, lso.RadioCommand.Priority.NORMAL)
			:send()
	end
end
function lso.Menu.handler.abort(unitName)
	local unit = Unit.getByName(unitName)
	if (not lso.Menu:hasMenu(unit, lso.Menu.Command.ABORT)) then
		return
	end
	local plane = lso.Plane.get(unit)
	if (plane) then
		local status = lso.process.getStatus(unit)
		if (
			status == lso.process.Status.INITIAL
			or status == lso.process.Status.BREAK
			or status == lso.process.Status.PADDLES
		) then
			lso.RadioCommand:new(string.format("%s.abort", plane.number), plane.number, string.format("%s, Abort landing.", plane.number), nil, 2, lso.RadioCommand.Priority.NORMAL)
				:onFinish(function()
					lso.Broadcast:send(lso.Broadcast.event.ABORT, plane)
				end)
				:send()
		end
	end
end



-- Marshal 雷达控制员模块

lso.Marshal = {}
lso.Marshal.check = {} -- 等待Check In的单位
lso.Marshal.visual = {} -- 报告See Me的单位
lso.Marshal.coolDownTime = 0 -- 冷却时间
lso.Marshal.needInformation = false -- 需要播报航母信息
lso.Marshal.queue = {} -- 待处理事项队列
lso.Marshal.lowFuel = lso.math.random(1, 2, true)
function lso.Marshal:coolDown(cdTime)
	self.coolDownTime = timer.getTime() + cdTime
end
function lso.Marshal:isCoolDown()
	return timer.getTime() > self.coolDownTime
end
function lso.Marshal:checkIn(unit)
	local unitName = unit:getName()
	if (lso.utils.listContains(self.check, unitName)) then
		return false
	else
		table.insert(self.check, unitName)
		return true
	end
end

function lso.Marshal:inSight(unit)
	local unitName = unit:getName()
	if (lso.utils.listContains(self.visual, unitName)) then
		return false
	else
		table.insert(self.visual, unitName)
		return true
	end
end

function lso.Marshal:offerInformation()
	if (self.needInformation == false) then
		self.needInformation = true
		table.insert(self.queue, function(timestamp)
				local eat = lso.Carrier:getEAT()
				local charlieTime = (lso.Carrier.recovery == true or eat == nil) and "" or string.format(", Expected Charlie time %d", math.ceil((eat - timer.getTime()) / 60))
				local temperature, pressure = lso.Carrier:getTemperatureAndPressure()
				local information
				if (lso.Carrier.turning) then
					local nextBRC = lso.Carrier:getBRC()
					information = string.format("99, Mother is turning, expected BRC is %03d, Altimeter %.2f%s.", nextBRC, pressure, charlieTime)
				else
					local brc = lso.Carrier:getBRC(true)
					information = string.format("99, Mother's BRC is %03d, Altimeter %.2f%s.", brc, pressure, charlieTime)
				end
				local radio = lso.RadioCommand:new("mather_information", "Marshal", information, nil, 4, lso.RadioCommand.Priority.NORMAL, 8)
				radio:send()
				self:coolDown(radio:getDuration())
				self.needInformation = false
			end)
	end
end
-- 广播航母开始转向或停止转向
function lso.Marshal:startOrStopTurning(event)
	if (event == lso.Broadcast.event.TURNING_START) then
		table.insert(self.queue, function(timestamp)
				local nextBRC = lso.Carrier:getBRC()
				local radio = lso.RadioCommand:new("turning", "Marshal", string.format("99, Mother start turning, Expected BRC is %03d.", nextBRC), nil, 3, lso.RadioCommand.Priority.NORMAL)
				radio:send()
				self:coolDown(radio:getDuration())
			end)
	elseif (event == lso.Broadcast.event.TURNING_STOP) then
		table.insert(self.queue, function(timestamp)
				local brc = lso.Carrier:getBRC(true)
				local radio = lso.RadioCommand:new("turning", "Marshal", string.format("99, Mother's new BRC is %03d.", brc), nil, 3, lso.RadioCommand.Priority.NORMAL)
				radio:send()
				self:coolDown(radio:getDuration())
			end)
	end
end
-- 广播航母开始回收或停止回收作业
function lso.Marshal:startOrStopRecovery(event)
	local units = lso.process.getUnitsInStatus(lso.process.Status.CHECK_IN + lso.process.Status.IN_SIGHT)
	if (event == lso.Broadcast.event.RECOVERY_START) then
		table.insert(self.queue, function(timestamp)
			local radio = lso.RadioCommand:new("recovery", "Marshal", "99, Charlie.", nil, 2, lso.RadioCommand.Priority.NORMAL)
			radio:send()
			self:coolDown(radio:getDuration())
		end)
		for i, unit in ipairs(units) do
			lso.Menu:removeMenu(unit, lso.Menu.Command.EMERGENCY)
		end
	elseif (event == lso.Broadcast.event.RECOVERY_STOP) then
		if (#lso.Carrier.inProcess > 0) then
			table.insert(self.queue, function(timestamp)
				local eat = lso.Carrier:getEAT()
				if eat then
					local radio = lso.RadioCommand:new("recovery", "Marshal", string.format("99, Expected Charlie time %d.", math.ceil((eat - timer.getTime()) / 60)), nil, 3, lso.RadioCommand.Priority.NORMAL)
					radio:send()
					self:coolDown(radio:getDuration())
				end
			end)
		end
		for i, unit in ipairs(units) do
			lso.Menu:addMenu(unit, lso.Menu.Command.EMERGENCY)
		end
	end
end
-- 初始化 Marshal 模块
function lso.Marshal:init()
	self.frameID = lso.addCheckFrame(self) -- 添加 Marshal 检测帧程序
	
	lso.Broadcast:receive(lso.Broadcast.event.RECOVERY_START + lso.Broadcast.event.RECOVERY_STOP, function(event)
		self:startOrStopRecovery(event)
	end)
	lso.Broadcast:receive(lso.Broadcast.event.TURNING_START + lso.Broadcast.event.TURNING_STOP, function(event)
		self:startOrStopTurning(event)
	end)
end
-- 处理管制飞机
function lso.Marshal:process()
	if (#self.queue == 0) then
		if (#self.visual > 0) then
			for i, unitName in pairs(self.visual) do
				local plane = lso.Plane.get(unitName)
				if (plane and plane:inAir()) then
					if (lso.process.getStatus(plane.unit) == lso.process.Status.CHECK_IN) then
						lso.RadioCommand:new(string.format("%s.switch_tower", plane.name), "Marshal", string.format("%s, Switch Tower.", plane.number), nil, 2, lso.RadioCommand.Priority.NORMAL)
							:onFinish(function()
								lso.RadioCommand:new(string.format("%s.switch_tower_roger", plane.name), plane.number, string.format("%s, Roger, Switch Tower.", plane.number), nil, 2, lso.RadioCommand.Priority.NORMAL)
									:send()
							end)
							:send()
						self.coolDownTime = timer.getTime() + 4
						lso.process.changeStatus(plane.unit, lso.process.Status.IN_SIGHT)
						lso.Menu:removeMenu(plane.unit, lso.Menu.Command.IN_SIGHT)
						lso.Broadcast:send(lso.Broadcast.event.IN_SIGHT, plane)
						table.remove(self.visual, i)
						break
					end
				end
				table.remove(self.visual, i)
			end
		elseif (#self.check > 0) then
			for i, unitName in pairs(self.check) do
				local plane = lso.Plane.get(unitName)
				if (plane and plane:inAir()) then
					local _, recoveryStarted = lso.Carrier:addPlane(plane)
					local eat = lso.Carrier:getEAT()
					local charlieTime = (recoveryStarted or eat == nil) and "" or string.format(", Expected Charlie time %d", math.ceil((eat - timer.getTime()) / 60))
					local charlieTimeRoger = (recoveryStarted or eat == nil) and "" or string.format(", Charlie time %d", math.ceil((eat - timer.getTime()) / 60))
					local temperature, pressure = lso.Carrier:getTemperatureAndPressure()
					local replyMsg, rogerMsg
					if (lso.carrierSailing and (lso.Carrier.turning or (recoveryStarted and not lso.Carrier:getCharlie()))) then
						local nextBRC = lso.Carrier:getBRC()
						replyMsg = string.format("%s, Radar contact, Case I recovery, Expected BRC is %03d, Altimeter %.2f%s, Report see me.", plane.number, nextBRC, pressure, charlieTime)
						rogerMsg = string.format("%s, Roger, Expected BRC %03d, %.2f%s.", plane.number, nextBRC, pressure, charlieTimeRoger)
					else
						local brc = lso.Carrier:getBRC(true)
						replyMsg = string.format("%s, Radar contact, Case I recovery, BRC is %03d, Altimeter %.2f%s, Report see me.", plane.number, brc, pressure, charlieTime)
						rogerMsg = string.format("%s, Roger, BRC %03d, %.2f%s.", plane.number, brc, pressure, charlieTimeRoger)
					end
					local radio = lso.RadioCommand:new(string.format("%s.check_in_reply", plane.name), "Marshal", replyMsg, nil, 4, lso.RadioCommand.Priority.NORMAL, 8)
							:prepare()
						+ lso.RadioCommand:new(string.format("%s.check_in_roger", plane.name), plane.number, rogerMsg, nil, 2, lso.RadioCommand.Priority.NORMAL)
							:prepare()
					radio:send()
					self:coolDown(radio:getDuration())
					lso.process.changeStatus(plane.unit, lso.process.Status.CHECK_IN)
					lso.Menu:removeMenu(plane.unit, lso.Menu.Command.CHECK_IN)
					lso.Menu:addMenu(plane.unit, lso.Menu.Command.IN_SIGHT)
					lso.Menu:addMenu(plane.unit, lso.Menu.Command.INFO)
					lso.Menu:addMenu(plane.unit, lso.Menu.Command.DEPART)
					if not (lso.Carrier.recovery) then
						lso.Menu:addMenu(plane.unit, lso.Menu.Command.EMERGENCY)
					end
					lso.Broadcast:send(lso.Broadcast.event.CHECK_IN, plane)
					table.remove(self.check, i)
					break
				end
				table.remove(self.check, i)
			end
		else
			local units = lso.process.getUnitsInStatus(lso.process.Status.CHECK_IN + lso.process.Status.IN_SIGHT)
			for i, unit in ipairs(units) do
				local plane = lso.Plane.get(unit)
				if (plane and plane.fuelLow == false) then
					local fuelMess = lso.Converter.KG_LB(plane.fuel) / 1000
					-- 燃油小于 1500 磅
					if (fuelMess < self.lowFuel) then
						plane.fuelLow = true
						self.lowFuel = lso.math.random(1, 2, true)
						table.insert(self.queue, function(timestamp)
							local radio = lso.RadioCommand:new(string.format("saystate_%s", plane.name), "Marshal", string.format("%s, Say state.", plane.number), nil, 2, lso.RadioCommand.Priority.NORMAL)
									:prepare()
								+ lso.RadioCommand:new(string.format("saystate_reply_%s", plane.name), plane.number, string.format("%s, State %.1f.", plane.number, fuelMess), nil, 2, lso.RadioCommand.Priority.NORMAL)
									:prepare()
								+ lso.RadioCommand:new(string.format("saystate_charlie_%s", plane.name), "Marshal", string.format("%s, Charlie.", plane.number), nil, 2, lso.RadioCommand.Priority.NORMAL)
									:prepare()
							radio:send()
							self:coolDown(radio:getDuration())
							lso.Broadcast:send(lso.Broadcast.event.EMERGENCY, plane)
						end)
						break
					end
				end
			end
		end
	end
end
function lso.Marshal:onFrame()
	if (self:isCoolDown() and lso.LSO.contact ~= true) then
		self:process()
		if (#self.queue > 0) then
			local func = table.remove(self.queue, 1)
			func(timer.getTime())
		end
	end
end



-- Tower 塔台模块

lso.Tower = {}
lso.Tower.coolDownTime = 0
function lso.Tower:coolDown(cdTime)
	self.coolDownTime = timer.getTime() + cdTime
end
function lso.Tower:isCoolDown()
	return timer.getTime() > self.coolDownTime
end
-- 初始化 Tower 模块
function lso.Tower:init()
	self.frameID = lso.addCheckFrame(self) -- 添加 Tower 检测帧程序
	
	-- 处理 ABORT 消息
	lso.Broadcast:receive(lso.Broadcast.event.ABORT, function(event, timestamp, plane)
		local radio = lso.RadioCommand:new(string.format("%s.re-enter", plane.name), "Tower", string.format("%s, Re-enter holding pattern.", plane.number), nil, 2, lso.RadioCommand.Priority.NORMAL)
		radio:send()
		self:coolDown(radio:getDuration())
		lso.process.changeStatus(plane.unit, lso.process.Status.ABORT)
	end)
end
function lso.Tower:onFrame()
	if (self:isCoolDown()) then
		for i, unit in ipairs(
			lso.process.getUnitsInStatus(
				lso.process.Status.IN_SIGHT
				+ lso.process.Status.INITIAL
				+ lso.process.Status.BREAK
				+ lso.process.Status.ABORT
			)
		) do
			local plane = lso.Plane.get(unit)
			if (plane and plane.unit:inAir()) then
				local carrierHeadding = lso.Carrier:getHeadding(true)
				local status = lso.process.getStatus(plane)
				if (status == lso.process.Status.ABORT) then
					local carrierPoint = lso.Carrier.unit:getPoint()
					if (
						math.abs(lso.math.getAzimuthError(plane.heading, lso.math.getAzimuth(plane.point.z, plane.point.x, carrierPoint.z, carrierPoint.x, true))) > 90
						or lso.Converter.M_FT(plane.altitude) > 1200
						or lso.Converter.M_NM(plane.distance) > 3
					) then
						lso.process.changeStatus(plane.unit, lso.process.Status.IN_SIGHT)
						lso.Menu:removeMenu(plane.unit, lso.Menu.Command.ABORT)
						if not (lso.Carrier.recovery) then
							lso.Menu:addMenu(plane.unit, lso.Menu.Command.EMERGENCY)
						end
						break
					end
				elseif (status == lso.process.Status.BREAK) then
					if (
						lso.Converter.M_FT(plane.altitude) > 1200
						or lso.Converter.MS_KNOT(plane.speed) > 500
						or lso.Converter.M_NM(plane.distance) > 4
					) then
						lso.Broadcast:send(lso.Broadcast.event.ABORT, plane)
						break
					end
				elseif (status == lso.process.Status.IN_SIGHT) then
					-- 在航母的相对方位 160-200° 之间
					if (plane.azimuth > 160 and plane.azimuth < 200) then
						-- 距离 0.5-3 nm
						if (lso.Converter.M_NM(plane.distance) > 0.5 and lso.Converter.M_NM(plane.distance) < 3) then
							-- 高度低于 1300 ft，速度小于 500 节 
							if (lso.Converter.M_FT(plane.altitude) < 1200 and lso.Converter.MS_KNOT(plane.speed) < 500) then
								-- 航向为航母航向 ±20°
								if (math.abs(lso.math.getAzimuthError(plane.heading, carrierHeadding, true)) < 20) then
									if (lso.Carrier.recovery and not lso.Carrier.turning) then
										lso.RadioCommand:new(string.format("%s.initial", plane.name), plane.number, string.format("%s, Initial.", plane.number), nil, 2, lso.RadioCommand.Priority.NORMAL)
											:onFinish(function()
												lso.RadioCommand:new(string.format("%s.initial_reply", plane.name), "Tower", string.format("Roger, %s.", plane.number), nil, 2, lso.RadioCommand.Priority.NORMAL)
													:send()
											end)
											:send()
										self.coolDownTime = timer.getTime() + 4
										lso.process.changeStatus(plane.unit, lso.process.Status.INITIAL)
										lso.Menu:removeMenu(plane.unit, lso.Menu.Command.EMERGENCY)
										lso.Menu:addMenu(plane.unit, lso.Menu.Command.ABORT)
										lso.Broadcast:send(lso.Broadcast.event.INITIAL, plane)
									else
										lso.Broadcast:send(lso.Broadcast.event.ABORT, plane)
									end
									break
								end
							end
						end
					end
				elseif (status == lso.process.Status.INITIAL) then
					local headdingError = lso.math.getAzimuthError(plane.heading, carrierHeadding, true)
					if (plane.rtg < 300) then
						-- 在航母的相对方位 270-360° 之间
						if ((plane.azimuth > 270 and plane.azimuth < 360) or plane.azimuth < 45) then
							-- 高度低于 1000 ft，速度小于 400 节 
							if (lso.Converter.M_FT(plane.altitude) < 1000 and lso.Converter.MS_KNOT(plane.speed) < 400) then
								-- 飞机侧倾角向左大于25度
								if ((plane.roll > 25 and headdingError < -5) or (plane.roll > 10 and headdingError < -30)) then
									lso.RadioCommand:new(string.format("%s.break", plane.name), plane.number, string.format("%s, Breaking.", plane.number), nil, 2, lso.RadioCommand.Priority.NORMAL)
										:onFinish(function()
											lso.RadioCommand:new(string.format("%s.break_reply", plane.name), "Tower", string.format("%s, Dirty up.", plane.number), nil, 2, lso.RadioCommand.Priority.NORMAL)
												:send()
										end)
										:send()
									self.coolDownTime = timer.getTime() + 5
									lso.process.changeStatus(plane.unit, lso.process.Status.BREAK)
									lso.Broadcast:send(lso.Broadcast.event.BREAK, plane)
									break
								end
							end
						end
					end
					if (
						lso.Converter.M_FT(plane.altitude) > 1300
						or lso.Converter.MS_KNOT(plane.speed) > 450
						or lso.Converter.M_NM(plane.distance) > 3
						or math.abs(lso.math.getAzimuthError(plane.heading, carrierHeadding, true)) > 90
					) then
						lso.Broadcast:send(lso.Broadcast.event.ABORT, plane)
						break
					end
				end
			end
		end
	end
end



-- Paddles 着舰信号官模块
lso.LSO = {}
lso.LSO.contact = false -- 是否在指挥
-- 降落阶段
lso.LSO.Stage = Enum(
	"TURNING",
	"START",
	"MIDDLE",
	"IN_CLOSE",
	"AT_RAMP"
)
-- 降落结果
lso.LSO.Result = Enum(
	"LAND",
	"BOLTER",
	"WAVEOFF"
)
-- 成绩
lso.LSO.Grade = Enum(
	"OK_UNDERLINE",
	"OK",
	"FAIR",
	"NO_GRADE",
	"CUT"
)
-- 原因
lso.LSO.Cause = Enum(
	"LONG", -- long in the groove
	"DEVIATE",
	"SETTLE", -- settle in close
	"IDLE", -- idle in the wire
	"WIRE1", -- caught 1 wire
	"FOUL_DECK"
)

-- 着舰信号官固定指令
lso.LSO.command = {
	CONTACT 	= 	lso.RadioCommand:new("lso.CONTACT", 		"LSO", 	"%s, Paddles contact.", 		lso.Sound.PADDLES_CONTACT	, 1.5, lso.RadioCommand.Priority.NORMAL),
	CALL_BALL 	= 	lso.RadioCommand:new("lso.CALL_THE_BALL", 	"LSO", 	"%s, 3/4 miles, Call the ball.",lso.Sound.CALL_THE_BALL		, 2.1, lso.RadioCommand.Priority.NORMAL, 	1.5),
	BALL 		= 	lso.RadioCommand:new("lso.BALL_CALL", 		nil, 	"%s, %s ball, %.1f.",			nil							, 1.0, lso.RadioCommand.Priority.NORMAL, 	1.5),
	ROGER_BALL 	= 	lso.RadioCommand:new("lso.ROGER_BALL", 		"LSO", 	"Roger ball.", 					lso.Sound.ROGER_BALL		, 1.2, lso.RadioCommand.Priority.NORMAL, 	1.5),
					
	KEEP_TURN	= 	lso.RadioCommand:new("lso.KEEP_TURN", 		"LSO", 	"Keep your turn in.", 			lso.Sound.KEEP_TURN			, 1.5, lso.RadioCommand.Priority.NORMAL, 	1.5),
	HIGH 		= 	lso.RadioCommand:new("lso.HIGH", 			"LSO", 	"You're high!", 				lso.Sound.HIGH				, 1.5, lso.RadioCommand.Priority.NORMAL, 	1.5),
	LOW 		= 	lso.RadioCommand:new("lso.LOW", 			"LSO", 	"power.", 						lso.Sound.LOW				, 1.5, lso.RadioCommand.Priority.NORMAL, 	1.5),
	TOO_LOW 	= 	lso.RadioCommand:new("lso.TOO_LOW", 		"LSO", 	"Power!!", 						lso.Sound.TOO_LOW			, 1.5, lso.RadioCommand.Priority.NORMAL,	1.5),
	LEFT 		= 	lso.RadioCommand:new("lso.LEFT", 			"LSO", 	"Right for lineup!", 			lso.Sound.RIGHT				, 1.5, lso.RadioCommand.Priority.NORMAL,	1.5),
	RIGHT 		= 	lso.RadioCommand:new("lso.RIGHT", 			"LSO", 	"Come left!", 					lso.Sound.LEFT				, 1.5, lso.RadioCommand.Priority.NORMAL,	1.5),
	EASY 		= 	lso.RadioCommand:new("lso.EASY", 			"LSO", 	"Easy with it.", 				lso.Sound.EASY				, 1.5, lso.RadioCommand.Priority.NORMAL,	1.5),
	FAST 		= 	lso.RadioCommand:new("lso.FAST", 			"LSO", 	"You're fast!", 				lso.Sound.FAST				, 1.5, lso.RadioCommand.Priority.NORMAL,	1.5),
	SLOW 		= 	lso.RadioCommand:new("lso.SLOW", 			"LSO", 	"You're slow!", 				lso.Sound.SLOW				, 1.5, lso.RadioCommand.Priority.NORMAL,	1.5),
	SETTLE 		= 	lso.RadioCommand:new("lso.SETTLE", 			"LSO", 	"Don't settle!", 				lso.Sound.SETTLE			, 1.5, lso.RadioCommand.Priority.NORMAL,	1.5),
	CLIMB 		= 	lso.RadioCommand:new("lso.CLIMB", 			"LSO", 	"Don't climb!", 				lso.Sound.CLIMB				, 1.5, lso.RadioCommand.Priority.NORMAL,	1.5),

	LIG			= 	lso.RadioCommand:new("lso.LIG", 			"LSO", 	"You're long in the groove, Wave off.", lso.Sound.LIG		, 6, lso.RadioCommand.Priority.HIGH),
	FOUL_DECK	= 	lso.RadioCommand:new("lso.FOUL_DECK",		"LSO", 	"Wave off, Foul deck.", 				lso.Sound.FOUL_DECK , 6, lso.RadioCommand.Priority.HIGH),
	WAVE_OFF	= 	lso.RadioCommand:new("lso.WAVE_OFF",		"LSO", 	"Wave off! Wave off!", 					lso.Sound.WAVEOFF	, 6, lso.RadioCommand.Priority.HIGH),
	BOLTER 		= 	lso.RadioCommand:new("lso.BOLTER", 			"LSO", 	"Bolter! Bolter! Bolter!", 				lso.Sound.BOLTER	, 6, lso.RadioCommand.Priority.HIGH),
}

-- 着舰信号官指令记录
lso.LSO.commands = {
	currentCommand = nil, -- 当前指令
	sendTime = nil, -- 当前指令下达时间
	coolDown = {}, -- 指令冷却状态
}

-- 下达指令
function lso.LSO:showCommand(cmd, speaker, force, data)
	local commandData = self.commands
	local nowTime = timer.getTime()

	-- 检查上一条指令是否结束
	-- 当上一条指令已结束或新指令优先级高于上一条指令时，将上一条指令设置冷却，并继续执行
	-- 否则忽略新指令
	if ((not force) and commandData.currentCommand and commandData.sendTime) then
		local prior = cmd.priority > commandData.currentCommand.priority
		local endTime = commandData.sendTime + commandData.currentCommand:getDuration()
		if (prior or nowTime >= endTime) then
			local cd = commandData.coolDown or {}
			cd[commandData.currentCommand.tag] = {
				command = commandData.currentCommand,
				coolTime = endTime + 4
			}
			commandData.coolDown = cd
			commandData.sendTime = nil
			commandData.currentCommand = nil
			self.commands = commandData
		else
			return false
		end
	end

	-- 更新所有指令的冷却状态
	-- 并检查新指令是否处于冷却期
	local cooling = false
	for tag, cdItem in pairs(commandData.coolDown) do
		if (nowTime >= cdItem.coolTime) then
			commandData.coolDown[tag] = nil
		else
		local coolTag = tag == "lso.TOO_LOW" and "lso.LOW" or tag
		local cmdTag = cmd.tag == "lso.TOO_LOW" and "lso.LOW" or cmd.tag
			if (coolTag == cmdTag) then
				cooling = true
			end
		end
	end
	self.commands = commandData

	-- 如果新指令未处于冷却期或新指令优先级为“立即执行”，则下达新指令
	if ((not force) and cooling and cmd.priority ~= lso.RadioCommand.Priority.IMMEDIATELY) then
		return false
	else
		commandData.currentCommand = cmd
		commandData.sendTime = nowTime
		self.commands = commandData
		cmd:send(speaker, data)
		return true
	end
end


-- 追踪数据类
-- 用于记录着陆阶段所有飞行数据
lso.LSO.TrackData = {__class="TrackData", plane, data, commands, processTime}
function lso.LSO.TrackData:new(plane)
	assert(plane ~= nil, "TrackData: unit cannot be nil");
	local obj = {
		plane = plane,
		data = {},
		commands = {},
		processTime = {
			start,ball,middle,close,ramp,
		},
	}
	setmetatable(obj, {__index = self})
	return obj
end
function lso.LSO.TrackData:track(timestamp)
	local plane = self.plane
	local deckHeadding = (lso.Carrier:getHeadding(true) - lso.Carrier.data.deck) % 360
	-- 记录新的飞行数据
	local flightData = {
		headingError = lso.math.getAzimuthError(deckHeadding, plane.heading, true), -- 飞机航向相对倾斜甲板朝向的偏差（北修正）（角度值）
		distance = plane.distance, -- 到航母平面距离（m）
		rtg = plane.rtg, -- RangeToGo（m）
		angleError = plane.angleError, -- lineup偏差(左正右负)（角度值）
		gs = plane.gs, -- 飞机当前所处下滑道位置（相对着舰点）（角度值）
		gsError = plane.gsError, -- 飞机当前所处下滑道偏差（高正低负）（角度值）
		aoa = plane.aoa, -- 迎角（角度值）
		roll = plane.roll, -- 滚转角（角度值）
		pitch = plane.pitch, -- 俯仰角（角度制）
		altitude = plane.atltitude, -- 高度（m）
		speed = plane.speed, -- 示空速（m/s）
		vs = plane.vs, -- 垂直速度（m/s）
		fuel = plane.fuel, -- 燃油余量 (kg)
		timestamp = timestamp or timer.getTime(), -- 数据记录时间戳（ModelTime）（秒）
	}
	table.insert(self.data, flightData)
end
function lso.LSO.TrackData:getData(timestamp)
	if (#self.data > 0) then
		if (type(timestamp) == "number") then
			local dt = nil
			local data = nil
			for i, item in ipairs(self.data) do
				local newDt = math.abs(timestamp - item.timestamp)
				if (data == nil or newDt <= dt) then
					data = item
					dt = newDt
				elseif (newDt > dt) then
					break
				end
			end
			return data
		else
			return self.data[#self.data]
		end
	else
		return nil
	end
end
function lso.LSO.TrackData:getDataRecord(dataType, length, timestamp)
	length = (type(length) == "number" and length <= #self.data) and length or #self.data
	local tmp = {}
	for i = #self.data, #self.data - length + 1, -1 do
		if (self.data[i][dataType] ~= nil and (timestamp == nil or self.data[i].timestamp <= timestamp)) then
			table.insert(tmp, self.data[i][dataType])
		end
	end
	local data = {}
	for i = 1, #tmp do
		data[i] = table.remove(tmp)
	end
	return data
end
function lso.LSO.TrackData:addCommand(command, timestamp)
	table.insert(self.commands, {
			command = command,
			timestamp = timestamp or timer.getTime()
		})
end


function lso.LSO:init()
	self.frameID = lso.addCheckFrame(self) -- 添加 LSO 检测帧程序
end
function lso.LSO:onFrame()
	-- 检查 Paddles Contact
	for i, unit in ipairs(lso.process.getUnitsInStatus(lso.process.Status.BREAK)) do
		local plane = lso.Plane.get(unit)
		if (plane and plane.unit:inAir()) then
			self:checkContact(plane)
		end
	end
end


function lso.LSO:checkContact(plane)
	if (lso.LSO.contact) then
		return false
	end
	local carrierHeadding = lso.Carrier:getHeadding(true)
	local carrierTail = (carrierHeadding + 180) % 360
	
	-- 在航母的相对方位 225-275° 之间
	if (plane.azimuth > 170 and plane.azimuth < 270) then
		-- 距离 0.2-2 nm
		if (lso.Converter.M_NM(plane.distance) > 0.2 and lso.Converter.M_NM(plane.distance) < 2) then
			-- 高度低于 800 ft，速度小于 220 节 
			if (lso.Converter.M_FT(plane.altitude) < 800 and lso.Converter.MS_KNOT(plane.speed) < 300) then
				-- 航向为航母舰尾 ±45°
				if (math.abs(lso.math.getAzimuthError(plane.heading, carrierTail, true)) < 45) then
					-- 改变状态 Paddles Contact
					lso.process.changeStatus(plane.unit, lso.process.Status.PADDLES)
					lso.Menu:removeMenu(plane.unit, lso.Menu.Command.DEPART)
					self.command.CONTACT:send({plane.number})
					lso.Broadcast:send(lso.Broadcast.event.PADDLES_CONTACT, plane)
					lso.LSO:track(plane)
					lso.LSO.contact = true
					return true
				end
			end
		end
	end
	return false
end


-- 着舰信号官开始指挥
-- 成功返回 true
-- 着舰信号官正忙返回 false
function lso.LSO:track(plane)
	local callTheBall = 0
	local landTime = nil
	local stage = nil
	local inGroove = false
	local turning = true
	local lig = false
	local result = nil
	local cause = nil
	local wire = nil
	local trackData = self.TrackData:new(plane)
	local trackCommand = function(cmd, check, timestamp, force)
		if check then
			if self:showCommand(cmd, nil, force) then
				trackData:addCommand(cmd, timestamp)
				return true
			end
		end
		return false
	end
	local landFinish = function()
		lso.LSO.contact = false
		lso.process.removePlane(plane.unit)
	end
	local goAround = function()
		lso.LSO.contact = false
		lso.process.changeStatus(plane.unit, lso.process.Status.BREAK)
		lso.Menu:addMenu(plane.unit, lso.Menu.Command.DEPART)
	end
	local depart = function()
		lso.LSO.contact = false
		lso.Broadcast:send(lso.Broadcast.event.ABORT, plane)
		lso.Menu:addMenu(plane.unit, lso.Menu.Command.DEPART)
	end
	local grade = function()
		lso.print(string.format("Result: %d\nCause: %d", result.value, cause and cause.value or 0), 5, true)
		if (lso.dumpTrackData and mist) then
			mist.debug.writeData(mist.utils.serialize, {"data", trackData}, "TrackData.text")
			lso.print("TrackData dump to \"Saved Games/DCS/Logs/TrackData.text\"", 5, true)
		end
		if type(lso.LSO.comment) == "function" then
			lso.LSO:comment(trackData, result, cause, wire)
		else
			if (result == lso.LSO.Result.LAND) then
				lso.LSO:grade(trackData, result, cause, wire)
			end
		end
	end
	local trackFrame = function(args, trackTime)
		local status, err = pcall(function()	
			if (plane:updateData() and lso.process.getStatus(plane) == lso.process.Status.PADDLES + lso.process.Status.BREAK) then -- 更新飞行数据
			
				-- 检查是否进入下滑道
				if (not inGroove) then
					-- 检查飞机是否在正确的位置
					local deckHeadding = (lso.Carrier:getHeadding(true) - lso.Carrier.data.deck) % 360
					if (
						plane.azimuth > 90 and plane.azimuth < 270 -- 在航母后半圆
						and lso.Converter.M_NM(plane.distance) < 2 -- 距离小于 2 nm
						and lso.Converter.M_FT(plane.altitude) < 800 -- 高度低于 800 ft
					) then
						deckAzimuthError = lso.math.getAzimuthError(plane.heading, deckHeadding, true) -- 飞机航向与甲板朝向的偏差
						-- 当飞机距离下滑道650m以内时检查是否需要提醒保持转向
						if (
							plane.angleError > 0
							and math.sin(math.rad(plane.angleError)) * plane.distance < 650 -- 到下滑道垂足距离
							and math.abs(deckAzimuthError) > 75
						)then
							self:showCommand(self.command.KEEP_TURN)
						end
						-- 当飞机位于the90时距离大于1.25nm，判定LIG
						if (stage ~= lso.LSO.Stage.TURNING and deckAzimuthError < 90) then
							stage = lso.LSO.Stage.TURNING
							if (plane.rtg > 2315) then
								cause = lso.LSO.Cause.LONG + cause
								-- 判定LIG时如果后面有飞机已经Break则WaveOff
								if (#lso.process.getUnitsInStatus(lso.process.Status.BREAK) > 0) then
									inGroove = true
									result = lso.LSO.Result.WAVEOFF + result
									trackCommand(self.command.LIG, true, trackTime)
								end
							end
						end
						-- 判断飞机是否进入下滑道
						-- 1.飞机进入下滑道偏差±6°以内
						-- 2.飞机整朝向航母方向±甲板斜角以内
						local carrierPoint = lso.Carrier.unit:getPoint()
						if (
							math.abs(lso.math.getAzimuthError(plane.heading, lso.math.getAzimuth(plane.point.z, plane.point.x, carrierPoint.z, carrierPoint.x, true))) < lso.Carrier.data.deck
							or plane.angleError < 6
						) then
							inGroove = true
							-- 距离大于1600m，判定LIG
							if (plane.rtg > 1600) then
								cause = lso.LSO.Cause.LONG + cause
								-- 判定LIG时如果后面有飞机已经Break则WaveOff
								if (#lso.process.getUnitsInStatus(lso.process.Status.BREAK) > 0) then
									result = lso.LSO.Result.WAVEOFF + result
									trackCommand(self.command.LIG, true, trackTime)
								end
							else
								return timer.getTime() + 1
							end
						end
						return timer.getTime() + 0.1
					else
						depart()
						return nil
					end
					return timer.getTime() + 0.1
				end
			
				-- 获取前一条数据
				local previousData = trackData:getData()
				
				-- 检查是否完成转向
				if (turning and (plane.angleError < 0.5 or plane.roll < 5 or (previousData and previousData.angleError <= plane.angleError))) then
					turning = false
				end
				
				-- 当剩余距离小于20m时停止指挥，开始连续检测是否成功钩上
				if (plane.rtg < 20 and previousData) then
					lso.print(string.format("landTime: %.3f\ninAir: %s\ndecrease: %.3f\nspeedDiff: %.3f\nalt: %.3f\ndistance: %.3f",
						landTime or "0",
						plane.unit:inAir() and "True" or "false",
						previousData.speed - plane.speed,
						lso.Converter.MS_KNOT(plane.groundSpeed - lso.Carrier:getSpeed()),
						plane.altitude - lso.Carrier.data.offset.y,
						plane.distance
					), 5, true, "trackDataLanding")
					if (landTime == nil and ((not plane.unit:inAir()) or (plane.groundSpeed - lso.Carrier:getSpeed()) < lso.Converter.KNOT_MS(20) or (previousData.speed - plane.speed) > 20)) then -- 迅速减速，着舰完成
						landTime = timer.getTime()
					end
					if (landTime ~= nil) then
						if (timer.getTime() - landTime > 8) then
							landFinish()
							return nil
						elseif ((plane.groundSpeed - lso.Carrier:getSpeed()) < lso.Converter.KNOT_MS(2)) then
							if (plane.distance <= 37.5) then
								wire = 1
								cause = lso.LSO.Cause.WIRE1 + cause
							elseif (plane.distance > 37.5 and plane.distance <= 49.5) then
								wire = 2
							elseif (plane.distance > 49.5 and plane.distance <= 61.5) then
								wire = 3
							elseif (plane.distance > 61.5 and plane.distance <= 86.5) then
								wire = 4
							end
							if wire then
								result = lso.LSO.Result.LAND + result
								lso.print(string.format("Fuel Used: %.3f", lso.Converter.KG_LB(previousData.fuel - plane.fuel)), 10, true)
								if (lso.Converter.KG_LB(previousData.fuel - plane.fuel) < 6) then
									cause = lso.LSO.Cause.IDLE + cause
								end
							end
							grade()
							landFinish()
							return nil
						end
					end
					if (plane.rtg < -60 and (plane.groundSpeed - lso.Carrier:getSpeed()) > lso.Converter.KNOT_MS(80)) then -- 穿过着舰区，脱钩
						if (plane.altitude - lso.Carrier.data.offset.y < 5 or landTime) then
							trackCommand(self.command.BOLTER, true, trackTime, true)
							result = lso.LSO.Result.BOLTER + result
						end
						grade()
						if (result ~= lso.LSO.Result.WAVEOFF) then
							goAround()
						end
						return nil
					end
					return timer.getTime() + 0.01
				else
					if (plane.groundSpeed < lso.Converter.KNOT_MS(20)) then
						landFinish()
						return nil
					end
				end
				
				-- 记录新的飞行数据
				trackData:track(trackTime)
				
				-- 近距离时预处理角度误差，以消除快速发散
				local angleError = plane.angleError * math.min(1, plane.rtg / 160)
				-- local gsError = plane.gsError * math.min(1, plane.rtg / 160)
				local gsError = plane.gsError
				
				-- 计算飞行数据变化
				local rollVariance = lso.math.getVariance(trackData:getDataRecord("roll", 20))
				local vsVariance = lso.math.getVariance(trackData:getDataRecord("vs", 20))
				local vsVariation = previousData and (plane.vs - previousData.vs) or 0
				local gsVariation = previousData and (gsError - previousData.gsError) or 0
				
				-- 判断AOA
				local aoaError = 0
				local aoaHigh = 0
				local aoaLow = 0
				local aoaData = trackData:getDataRecord("aoa", 30)
				for i, aoa in ipairs(aoaData) do
					local aoaDiff = aoa - plane.model.aoa
					if (aoaDiff > 1.4) then
						aoaHigh = aoaHigh + 1
					elseif (aoaDiff < -1.4) then
						aoaLow = aoaLow + 1
					end
				end
				if (aoaHigh == #aoaData) then
					aoaError = 1
				elseif (aoaLow == #aoaData) then
					aoaError = -1
				end

				-- 记录进入每个着舰阶段的时间
				if (trackData.processTime.start == nil and plane.rtg <= 1389 and plane.rtg > 695) then
					trackData.processTime.start = trackTime
					stage = lso.LSO.Stage.START
					-- lso.print("start", 2, true, "start")
				elseif (trackData.processTime.middle == nil and plane.rtg <= 695 and plane.rtg > 300) then
					trackData.processTime.middle = trackTime
					stage = lso.LSO.Stage.MIDDLE
					-- lso.print("middle", 2, true, "middle")
				elseif (trackData.processTime.close == nil and plane.rtg <= 300 and plane.rtg > (lso.Carrier.data.runway.length / 2)) then
					trackData.processTime.close = trackTime
					stage = lso.LSO.Stage.IN_CLOSE
					-- lso.print("close", 2, true, "close")
				elseif (trackData.processTime.ramp == nil and plane.rtg <= (lso.Carrier.data.runway.length / 2)) then
					trackData.processTime.ramp = trackTime
					stage = lso.LSO.Stage.AT_RAMP
					-- lso.print("ramp", 2, true, "ramp")
				end
				
				if (result ~= nil and result == lso.LSO.Result.WAVEOFF) then
					if (plane.vs < -2 and gsError < 5) then
						trackCommand(self.command.WAVE_OFF, true, trackTime)
					end
				
				else
				
					-- 判断是否需要复飞
					local shouldWaveOff = false
					switch( stage,
						{lso.LSO.Stage.IN_CLOSE, function()
							shouldWaveOff = (
								math.abs(angleError) > 1.5
								or gsError > 1
								or gsError < -0.8
							)
							return true
						end},
						{lso.LSO.Stage.MIDDLE, function()
							shouldWaveOff = (
								math.abs(angleError) > 3
								or gsError > 1.2
								or gsError < -1.1
							)
							return true
						end},
						{lso.LSO.Stage.START, function()
							shouldWaveOff = (
								math.abs(angleError) > 6
								or gsError > 1.8
								or gsError < -1.4
							)
							return true
						end},
						{lso.LSO.Stage.TURNING, function()
							shouldWaveOff = (
								math.abs(angleError) > 6
								or gsError > 2.5
								or (gsError < -1.6 and plane.altitude < lso.Converter.FT_M(250))
							)
							return true
						end}
					)
					if (shouldWaveOff) then
						if trackCommand(self.command.WAVE_OFF, true, trackTime) then
							result = lso.LSO.Result.WAVEOFF + result
							cause = lso.LSO.Cause.DEVIATE + cause
							goAround()
						end
					end
					
					-- 判断Foul Deck复飞
					if (lso.Carrier.turning or (stage ~= lso.LSO.Stage.AT_RAMP and plane.rtg < 1500 and lso.Carrier.foulDeck)) then
						if trackCommand(self.command.FOUL_DECK, true, trackTime) then
							result = lso.LSO.Result.WAVEOFF + result
							cause = lso.LSO.Cause.FOUL_DECK + cause
							goAround()
						end
					end
					
					-- call the ball
					if (trackData.processTime.ball == nil and stage == lso.LSO.Stage.START) then
						local fuelMess = lso.Converter.KG_LB(plane.fuel) / 1000 -- 千磅
						if (self:showCommand(
								self.command.CALL_BALL:prepare({plane.number}) 
								+ self.command.BALL:prepare(plane.number, {plane.number, plane.model.name, fuelMess})
								+ self.command.ROGER_BALL
							)) then
							trackData.processTime.ball = trackTime
						end
					end
					
					-- 记录 In close 阶段下沉
					if (plane.rtg < 300 and plane.rtg > 50 and gsVariation < 0 and gsError < 0 and (vsVariation < -0.12 or gsVariation < -0.02)) then
						cause = lso.LSO.Cause.SETTLE + cause
					end
					
					if (stage ~= lso.LSO.Stage.AT_RAMP) then

						-- 根据飞行数据下达指令
						-- 遵循“先爬升后加速，先减速后下高”原则
						trackCommand(self.command.TOO_LOW, 		(gsError < -0.6), 							trackTime)
						trackCommand(self.command.SETTLE,		(gsVariation < 0 and gsError < 0 and (vsVariation < -0.08 or gsVariation < -0.02)),	trackTime)
						trackCommand(self.command.LOW, 			(gsError < -0.4 and gsError >= -0.6), 		trackTime)
						
						trackCommand(self.command.LEFT, 		(turning == false and angleError > 0.75), 	trackTime)
						trackCommand(self.command.RIGHT, 		(angleError < -0.75), 						trackTime)
						
						trackCommand(self.command.SLOW, 		(turning == false and aoaError == 1), 		trackTime)
						trackCommand(self.command.FAST, 		(aoaError == -1), 							trackTime)
						
						trackCommand(self.command.CLIMB,		(gsError > 0 and gsVariation > 0.02),		trackTime)
						trackCommand(self.command.HIGH, 		(gsError > 0.5), 							trackTime)
						
						trackCommand(self.command.EASY, 		(vsVariance > 0.8 or rollVariance > 80), 	trackTime)
						
					end
					
				end
				
				lso.print(lso.utils.tableShow(trackData:getData()).."\ngsErrorFix: "..gsError.."\nangleErrorFix: "..angleError.."\nvsVariation: "..vsVariation.."\ngsVariation: "..gsVariation, 5, true, "trackData")
				return timer.getTime() + 0.1
			else
				-- env.error("LSO lost track.")
				lso.LSO.contact = false
				lso.Menu:addMenu(plane.unit, lso.Menu.Command.DEPART)
				return nil
			end
		end)
		if status then
			return err
		else
			lso.print(err, 5, true, "TrackError")
			env.error(err)
			self.command.FOUL_DECK:send()
			goAround()
		end
	end

	timer.scheduleFunction(trackFrame, nil, timer.getTime() + 0.5)
	return true
end
-- 着舰信号官着陆评分（临时）
function lso.LSO:grade(trackData, result, cause, wire)
	local plane = trackData.plane
	-- Grades: 1=OK 2=Fair 3=No Grade 4=Cut
	local grades = {"OK", "Fair", "No Grade", "Cut"}
	local grade = 0
	if (result == lso.LSO.Result.WAVEOFF or cause == lso.LSO.Cause.IDLE) then
		grade = 4
	else
		for i, data in ipairs(trackData.data) do
			local angleError = data.angleError * math.min(1, data.rtg / 160)
			local gsError = data.gsError * math.min(1, data.rtg / 160)
			if (
				(trackData.processTime.ball == nil or data.timestamp > trackData.processTime.ball)
				and (trackData.processTime.ramp == nil or data.timestamp < trackData.processTime.ramp)
			) then
				if (
					math.abs(angleError) > 2.2
					or gsError > 1
					or gsError < -0.8
				) then
					grade = 3
					break
				end
			end
		end
		if (wire == 1 or (cause ~= nil and cause == lso.LSO.Cause.WIRE1 + lso.LSO.Cause.SETTLE)) then
			grade = 3
		end
		local command = 0
		for i, cmd in ipairs(trackData.commands) do
			if (trackData.processTime.start == nil or cmd.timestamp > trackData.processTime.start) then
				command = command + 1
			end
		end
		if (command > 1 or cause == lso.LSO.Cause.LONG) then
			grade = 2
		else
			grade = 1
		end
	end
	local gradeMsg = grade == 0 and "" or string.format(", %s", grades[grade])
	local wireMsg = wire == nil and "" or string.format(", %d wire%s", wire, wire == 1 and "" or "s")
	local lig = cause == lso.LSO.Cause.LONG and ", LIG" or ""
	if (gradeMsg ~= "" and wireMsg ~= "") then
		local gradeSound = ({lso.Sound.OK, lso.Sound.FAIR, lso.Sound.NO_GRADE, lso.Sound.CUT})[grade]
		local wireSound = ({lso.Sound.ONE_WIRE, lso.Sound.TWO_WIRES, lso.Sound.THREE_WIRES, lso.Sound.FOUR_WIRES})[wire]
		lso.RadioCommand:new("lso.on_board", "LSO", string.format("%s%s%s%s.", plane.number, lig, gradeMsg, wireMsg), {gradeSound, wireSound}, 3, lso.RadioCommand.Priority.NORMAL)
			:send()
	end
end


-- 主检测帧
function lso:onFrame()
	-- 遍历所有飞机
	local allPlanes = coalition.getPlayers(lso.Carrier.unit:getCoalition())
	for i, unit in ipairs(allPlanes) do
		local plane = lso.Plane.get(unit)
		if plane and plane:updateData() then
			local angleError = plane.angleError * math.min(1, plane.rtg / 160)
			local gsError = plane.gsError * math.min(1, plane.rtg / 160)
			local flightData = {
				heading = plane.heading, -- 飞机航向（北修正）（角度值）
				distance = plane.distance, -- 到航母平面距离（m）
				rtg = plane.rtg, -- RangeToGo（m）
				angleError = plane.angleError, -- lineup偏差(左正右负)（角度值）
				gs = plane.gs, -- 飞机当前所处下滑道位置（相对着舰点）（角度值）
				gsError = plane.gsError, -- 飞机当前所处下滑道偏差（高正低负）（角度值）
				aoa = plane.aoa, -- 迎角（角度值）
				roll = plane.roll, -- 滚转角（角度值）
				atltitude = plane.point.y, -- 高度（m）
				speed = plane.speed, -- 示空速（m/s）
				vs = plane.vs, -- 垂直速度（m/s）
				fuel = plane.fuel, -- 燃油余量 (kg)
				timestamp = timer.getTime(), -- 数据记录时间戳（ModelTime）（秒）
			}
			lso.print(lso.utils.tableShow(flightData).."\ngsErrorFix: "..gsError.."\nangleErrorFix: "..angleError, 5, true, "logData")
		end
	end
end

-- 全局事件处理器
lso.eventHandler = {}
function lso.eventHandler:onEvent(event)
	local status, err = pcall(function(event)
			if event == nil or event.initiator == nil then
				return false
			end
			switch(
				event.id,
				{world.event.S_EVENT_BIRTH, function()
					if (event.initiator:getPlayerName()) then
						lso.process.initPlane(event.initiator)
					end
					return true
				end},
				{world.event.S_EVENT_TAKEOFF, function()
					local state = lso.process.getStatus(event.initiator)
					if (state == nil or state == lso.process.Status.NONE) then
						lso.process.initPlane(event.initiator)
					end
					return true
				end}
			)
			return true
		end, event)
	if (not status) then
		env.error("Error while handling event")
	end
end

-- 初始化函数
function lso.init()
	if (not lso.Carrier:init()) then
		if (lso.Carrier.unit) then
			env.error(string.format("Carrier init failed. unsupported carrier type <%s>.", lso.Carrier.unit:getTypeName()), true)
		else
			env.error("Carrier init failed.", true)
		end
	end
	-- lso.mainProcess = lso.addCheckFrame(lso) -- 添加主检测帧程序
	lso.DB.init() -- 初始化数据库
	lso.Menu:init() -- 初始化菜单管理模块
	lso.Marshal:init() -- 初始化 Marshal 模块
	lso.Tower:init() -- 初始化 Tower 模块
	lso.LSO:init() -- 初始化 LSO 模块

	world.addEventHandler(lso.eventHandler)

	-- 遍历初始化所有飞机状态
	for unitName, plane in pairs(lso.DB.planes) do
		if (plane:updateData()) then
			lso.process.initPlane(plane.unit)
		end
	end
	
	lso.start()
	trigger.action.outText("Smart-LSO script loaded successfully.", 5)
end


lso.init() -- 初始化


