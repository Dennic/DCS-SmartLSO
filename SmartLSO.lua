-- 创建枚举表
function Enum(...)
	local enum = {}
	local index = 0
	for i, v in ipairs({...}) do
        enum[v] = index + i
    end
	return enum
end


local lso = {}
lso.logger = mist.Logger:new("LSO", "info") -- 初始化日志记录


-- 航母 unit name
lso.carrierName = "ship"
lso.carrierRadioName = "ship_radio"


-- 检测帧实现模块
lso.frameId = 1
lso.checkFrames = {}
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
	local i = 1
	while i <= #lso.checkFrames do
		if lso.checkFrames[i] ~= nil then
			local status, err = pcall(function(frame)
				frame:onFrame(frameTime)
				return true
			end, lso.checkFrames[i].frame)
			if (not status) then
				error(err)
			end
		end
		i = i + 1
	end
	return timer.getTime() + 2
end
timer.scheduleFunction(lso.doFrame, nil, timer.getTime() + 1)


-- 初始化航母参数
function lso.init()
	local carrier = {}
	local unit = Unit.getByName(lso.carrierName)
	local typeName = unit:getTypeName()
	for name, data in pairs(lso.data.carriers) do
		if (name == typeName) then
			carrier.data = data
			carrier.unit = unit
			break
		end
	end
	-- assert(carrier.unit, "Carrier not ready.")
	assert(carrier.unit, string.format("Carrier not ready. unsupported carrier type <%s>.", typeName))
	carrier.radio = Unit.getByName(lso.carrierRadioName)
	lso.carrier = carrier
end


-- 飞机类
-- 包含了所需的飞行参数
lso.Plane = {
	unit, -- 飞机单位
	name, -- 飞机单位名称
	model, -- 飞机型号
	number, -- 机身编号
	point, -- 飞机位置
	autitude, -- 飞机高度（米）
	heading, -- 飞机航向（角度）
	azimuth, -- 飞机位于航母的方位角（角度）
	angle, -- 飞机到着陆点角度（角度）
	angleError, -- 相对着陆甲板角度误差（角度）
	distance, -- 到着陆点的平面距离（米）
	rtg, -- Range-to-go 到着陆点的空间距离（米）
	gs, -- 当前下滑道角度（角度）
	gsError, -- 当前下滑道相对标准下滑道误差（角度）
	aoa, -- 攻角（角度）
	roll, -- 侧倾角
	speed, -- 空速（m/s）
	vs, -- 垂直速度（m/s）
	fuel, -- 剩余油量（kg）
}
function lso.Plane:new(unit)
	local unitObj, unitName
	if (type(unit) == "string") then
		unitObj = Unit.getByName(unit)
		unitName = unit
	else
		unitObj = unit
		unitName = unit:getName()
	end
	local number = mist.DBs.unitsByName[unitName].onboard_num
	local aircraft = lso.data.getAircraft(unitObj)
	if (not aircraft) then
		return nil
	else
		local obj = {
			unit = unitObj,
			name = unitName,
			model = aircraft,
			number = number
		}
		setmetatable(obj, {__index = self, __eq = self.equalTo, __tostring = self.toString})
		if (obj:updateData()) then
			return obj
		else
			return nil
		end
	end
end
function lso.Plane:updateData()
	if (self.unit and self.unit:isExist()) then
		self.point = self.unit:getPoint()
		self.autitude = self.point.y
		self.heading = math.deg(mist.getHeading(self.unit, true) or 0)
		local lx, ly = lso.utils.getLandingPoint()
		self.angle = lso.utils.math.getAzimuth(self.point.z, self.point.x, lx, ly, true)
		self.angleError = lso.utils.getAngleError(self.angle, true)
		self.azimuth = (self.angle + 180 - lso.utils.getCarrierHeadding(true)) % 360
		self.distance = lso.utils.getDistance(self.point.z, self.point.x, lx, ly)
		self.rtg = self.distance * math.cos(math.rad(self.angleError))
		self.gs = lso.utils.getGlideSlope(self.distance, self.point.y)
		self.gsError = self.gs - lso.carrier.data.gs
		self.aoa = math.deg(mist.getAoA(self.unit) or 0)
		self.roll = math.deg(mist.getRoll(self.unit) or 0)
		self.speed = lso.utils.getAirSpeed(self.unit)
		self.vs = lso.utils.getVerticalSpeed(self.unit)
		local fuelMassMax = self.unit:getDesc().fuelMassMax -- 总油重 千克
		self.fuel = fuelMassMax * self.unit:getFuel()
		return true
	else
		return false
	end
end
function lso.Plane.equalTo(self, another)
	local selfName, anotherName
	if (type(self) == "table") then
		selfName = self:getName()
	else
		selfName = self
	end
	if (type(another) == "table") then
		anotherName = another:getName()
	else
		anotherName = another
	end
	return selfName == anotherName
end
function lso.Plane.toString(self)
	return self.unit:getName()
end


-- RadioCommand 类
-- 创建和发送无线电指令
lso.RadioCommand = {id, tag, speaker, msg, sound, duration, priority, callback}
lso.RadioCommand.count = 0
lso.RadioCommand.Priority = Enum(
	"LOW",
	"NORMAL",
	"HIGH",
	"IMMEDIATELY"
)
function lso.RadioCommand:new(tag, speaker, msg, sound, duration, priority)
	assert(msg ~= nil, "RadioCommand: msg cannot be nil");
	self.count = self.count + 1
	local obj = {
		id = self.count,
		tag = tag or ("RadioCommand"..self.count),
		speaker = speaker,
		msg = msg,
		sound = sound or "l10n/DEFAULT/radio_on.wav",
		duration = duration or 1,
		priority = priority or lso.RadioCommand.Priority.NORMAL,
	}
	setmetatable(obj, {__index = self, __eq = self.equalTo, __tostring = self.toString})
	return obj
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
function lso.RadioCommand:send(unit, data)
	local content = self.msg:format(unpack(data or {}))
	local msg = string.format("%s: %s", self.speaker, content)
	if (unit and unit:isExist()) then
		trigger.action.outTextForCoalition(lso.carrier.unit:getCoalition(), msg, self.duration)
		
		-- local group = unit:getGroup()
		-- trigger.action.outTextForGroup(group:getID(), msg, self.duration)
		
		-- local controller = unit:getController()
		-- local command = { 
		  -- id = 'TransmitMessage', 
		  -- params = {
			-- duration = self.duration,
			-- subtitle = msg,
			-- loop = false,
			-- file = self.sound,
		  -- } 
		-- }
		-- controller:setCommand(command)
		
		if (self.callback) then
			timer.scheduleFunction(self.callback, self, timer.getTime() + self.duration)
		end
	end
end


-- 数据库模块
-- 包含了所需的固定数据
lso.data = {}
lso.data.carriers = {
	["VINSON"] = {
		offset = {180.9, 95.2},
		height = 20,
		deck = 10,
		gs = 3.5,
	},
	["Stennis"] = {
		offset = {181.4, 92.6},
		height = 20,
		deck = 10,
		gs = 3.5,
	},
	["KUZNECOW"] = {
		offset = {188.67, 58.02},
		height = 18,
		deck = 8,
		gs = 4,
	},
}
lso.data.aircrafts = {
	["FA-18C_hornet"] = {
		name = "hornet",
		aoa = 8,
	},
	["Su-33"] = {
		name = "falcon",
		aoa = 9,
	},
}
function lso.data.getAircraft(unit)
	if (unit and unit:isExist()) then
		local typeName = unit:getTypeName()
		for name, data in pairs(lso.data.aircrafts) do
			if (name == typeName) then
				return data
			end
		end
	end
	return nil
end



-- 单位转换器
lso.Converter = {
	KG_LB = function(src)
		return src * 2.204623
	end,
	M_MI = function(src)
		return src * 0.000621
	end,
	M_NM = function(src)
		return src * 0.00054
	end,
	M_FT = function(src)
		return src * 3.28084
	end,
	PA_INHG = function(src)
		return src * 0.007502 * 0.03937
	end,
	MS_KNOT = function(src)
		return src * 1.944012
	end,
}


-- 工具模块
lso.utils = {}

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

-- 计算当前航母的接地点坐标
-- 返回值 bx, by: 接地点 vec2 坐标
function  lso.utils.getLandingPoint()
	local carrierPoint = lso.carrier.unit:getPoint()
	local carrierHeadding = math.deg(mist.getHeading(lso.carrier.unit, true) or 0)
	local dir = (carrierHeadding + lso.carrier.data.offset[1]) % 360
	local x, y = lso.utils.math.getOffsetPoint(carrierPoint.z, carrierPoint.x, dir, lso.carrier.data.offset[2])
	return x, y
end

-- 根据距离和高度，计算出当前所处下滑道角度
-- distance: 距离
-- altitude: 高度
-- 返回值: 下滑道角度
function lso.utils.getGlideSlope(distance, altitude)
	return math.deg(math.atan((altitude - lso.carrier.data.height)/distance))
end

-- 获取航母航向
-- degrees: 是否返回角度值
-- 返回值: 航母航向
function lso.utils.getCarrierHeadding(degrees)
	return math.deg(mist.getHeading(lso.carrier.unit, degrees) or 0)
end

-- 计算当前进近角相对于当前着陆甲板朝向的角度偏差
-- angle: 当前进近角
-- degrees: 是否返回角度值
-- 返回值: 角度偏差
function lso.utils.getAngleError(angle, degrees)
	local carrierHeadding = lso.utils.getCarrierHeadding(true)
	local stdAngle = (carrierHeadding - lso.carrier.data.deck) % 360
	local offset = lso.utils.math.getAzimuthError(angle, stdAngle, true)
	if (degrees) then
		return offset
	else
		return math.rad(offset)
	end
end

-- 计算两点欧氏距离
function lso.utils.getDistance(x1, y1, x2, y2)
	return math.sqrt(math.pow(x1 - x2, 2) + math.pow(y1 - y2, 2))
end

-- 获取飞机垂直速度 m/s
function lso.utils.getVerticalSpeed(plane)
	local unit
	if (type(plane) == "string") then
		unit = Unit.getByName(plane)
	else
		unit = plane
	end
	return unit:getVelocity().y
end

-- 获取飞机真空速 m/s
function lso.utils.getAirSpeed(plane)
	local unit
	if (type(plane) == "string") then
		unit = Unit.getByName(plane)
	else
		unit = plane
	end
	return lso.utils.math.getMag(unit:getVelocity())
end

-- 获取飞机地速 m/s
function lso.utils.getGroundSpeed(plane)
	local unit
	if (type(plane) == "string") then
		unit = Unit.getByName(plane)
	else
		unit = plane
	end
	local vel = unit:getVelocity()
	return lso.utils.math.getMag(vel.x, vel.z)
end


-- 数学计算工具模块
lso.utils.math ={}

function lso.utils.math.dirToAngle(direction, degrees)
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
function lso.utils.math.angleToDir(angle, degrees)
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

function lso.utils.math.getOffsetPoint(x, y, dir, dist)
	local angle = math.rad(lso.utils.math.dirToAngle(dir, true))
	local dx = math.cos(angle) * dist
	local dy = math.sin(angle) * dist
	return x + dx, y + dy
end


-- 计算相对方位角
-- 根据给定的坐标，计算出两点的相对方位角
-- xs,ys:基准点坐标
-- xt,yt:目标点坐标
-- degrees:布尔值，是否返回角度（默认返回弧度）
function  lso.utils.math.getAzimuth(xs, ys, xt, yt, degrees)
	local dx = xt - xs
	local dy = yt - ys

	if (dx == 0) then
		return 0
	else
		local deg = lso.utils.math.angleToDir(math.atan(dy/dx))
		if (xt < xs) then
			deg = deg + math.pi
		end
		if (degrees) then
			return math.deg(deg)
		else
			return deg
		end
	end
end

function lso.utils.math.getAzimuthError(a1, a2, degrees)
	local diff
	if (degrees) then
		diff = a1 - a2
	else
		diff = math.deg(a1-a2)
	end
	local angleDiff
	if (diff <= 180) then
		 angleDiff = diff
	else
		angleDiff = diff - 360
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
function lso.utils.math.getAverage(data)
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
function lso.utils.math.getVariance(data)
	if (#data < 2) then
		return 0
	end
	local avg = lso.utils.math.getAverage(data)
	local sum = 0
	for i, v in ipairs(data) do
		sum = sum + math.pow(v - avg, 2)
	end

	return sum / #data
end

-- 计算矢量合
function lso.utils.math.getMag(...)
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



lso.process = {}
lso.process.status = {}
lso.process.Status = Enum(
	"NONE",
	"CHECK_IN",
	"IN_SIGHT",
	"INITIAL",
	"PADDLES"
)
function lso.process.changeStatus(unit, newStatus)
	lso.process.status[unit:getName()] = newStatus
end
function lso.process.getStatus(unit)
	return lso.process.status[unit:getName()]
end
function lso.process.initPlane(unit)
	lso.process.changeStatus(unit, lso.process.Status.NONE)
	lso.menu.initMenu(unit)
end
function lso.process.removePlane(unit)
	lso.process.changeStatus(unit, nil)
end


lso.menu = {}

lso.menu.path = {}
function lso.menu.addMenu(unit, menu, handler)
	if (lso.menu.path[unit:getName()] == nil) then
		lso.menu.path[unit:getName()] = {}
	end
	if (lso.menu.path[unit:getName()][menu] == nil) then
		lso.menu.path[unit:getName()][menu] = missionCommands.addCommandForGroup(unit:getGroup():getID(), menu, nil, handler, unit)
		return true
	else
		return false
	end
end
function lso.menu.removeMenu(unit, menu)
	if (lso.menu.path[unit:getName()] == nil) then
		lso.menu.path[unit:getName()] = {}
	end
	if (lso.menu.path[unit:getName()][menu] ~= nil) then
		missionCommands.removeItemForGroup(unit:getGroup():getID(), lso.menu.path[unit:getName()][menu])
		lso.menu.path[unit:getName()][menu] = nil
		return true
	else
		return false
	end
end
function lso.menu.initMenu(unit)
	missionCommands.removeItemForGroup(unit:getGroup():getID())
	lso.menu.path[unit:getName()] = {}
	lso.menu.addMenu(unit, "Check in", lso.menu.handler.checkIn)
end

lso.menu.handler = {}
function lso.menu.handler.checkIn(unit)
	if (lso.process.getStatus(unit) == lso.process.Status.NONE) then
		local plane = lso.Plane:new(unit)
		if plane and plane:updateData() then
			local fuelMess = lso.Converter.KG_LB(plane.fuel) / 1000 -- 千磅
			local angel = lso.Converter.M_FT(plane.autitude) / 1000 -- 千英尺
			local distance = lso.Converter.M_NM(plane.distance) -- 海里
			
			lso.RadioCommand:new(string.format("%s.check_in", plane.number), plane.number, string.format("Marshal, %s, %03d for %d, Angels %d, State %.1f.", plane.number, plane.azimuth, distance, angel, fuelMess), nil, 4, lso.RadioCommand.Priority.NORMAL)
				:onFinish(function()
					lso.Marshal:checkIn(unit)
				end)
				:send(unit)
		end
	end
end
function lso.menu.handler.inSight(unit)
	if (lso.process.getStatus(unit) == lso.process.Status.CHECK_IN) then
		local plane = lso.Plane:new(unit)
		if plane and plane:updateData() then
			local distance = lso.Converter.M_NM(plane.distance) -- 海里
			
			lso.RadioCommand:new(string.format("%s.see_you", plane.number), plane.number, string.format("Marshal, %s, See you at %d.", plane.number, distance), nil, 2, lso.RadioCommand.Priority.NORMAL)
				:onFinish(function()
					lso.Marshal:inSight(unit)
				end)
				:send(unit)
		end
	end
end
function lso.menu.handler.abort(unit)
	local plane = lso.Plane:new(unit)
	if plane and plane:updateData() then
		lso.process.changeStatus(unit, lso.process.Status.NONE)
		lso.menu.removeMenu(unit, "In Sight")
		lso.menu.removeMenu(unit, "Abort")
		lso.menu.addMenu(unit, "Check in", lso.menu.handler.checkIn)
		lso.RadioCommand:new(string.format("%s.abort", plane.number), plane.number, string.format("%s, Departing.", plane.number), nil, 2, lso.RadioCommand.Priority.NORMAL)
			:send(unit)
	end
end



-- Marshal 雷达控制员模块

lso.Marshal = {}
lso.Marshal.check = {} -- 等待Check In的单位
lso.Marshal.visual = {} -- 报告See Me的单位
lso.Marshal.coolDownTime = 0

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

function lso.Marshal:onFrame()
	-- mist.message.add({
		-- text =  string.format("Marshal检测帧工作中 %d %d", #self.check, #self.visual),
		-- displayTime = 1,
		-- msgFor = {coa = {"all"}},
		-- name = "marshalFrame",
	-- })
	if (timer.getTime() > self.coolDownTime) then
		if (#self.visual > 0) then
			for i, unitName in pairs(self.visual) do
				local plane = lso.Plane:new(unitName)
				if (lso.process.getStatus(plane.unit) == lso.process.Status.CHECK_IN and plane) then
					lso.RadioCommand:new(string.format("%s.switch_tower", plane.name), "Marshal", string.format("%s, Switch Tower.", plane.number), nil, 2, lso.RadioCommand.Priority.NORMAL)
						:onFinish(function()
							lso.RadioCommand:new(string.format("%s.switch_tower_roger", plane.name), plane.number, string.format("%s, Roger, Switch Tower.", plane.number), nil, 2, lso.RadioCommand.Priority.NORMAL)
								:send(plane.unit)
						end)
						:send(lso.carrier.radio)
					self.coolDownTime = timer.getTime() + 4
					lso.process.changeStatus(plane.unit, lso.process.Status.IN_SIGHT)
					lso.menu.removeMenu(plane.unit, "In Sight")
					lso.Tower:checkIn(plane.unit)
					table.remove(self.visual, i)
					break
				else
					table.remove(self.visual, i)
				end
			end
		elseif (#self.check > 0) then
			for i, unitName in pairs(self.check) do
				local plane = lso.Plane:new(unitName)
				if (plane) then
					local brc = lso.utils.getCarrierHeadding(true) or 0
					local temperature, pressure = atmosphere.getTemperatureAndPressure(lso.carrier.unit:getPoint())
					pressure = lso.Converter.PA_INHG(pressure)
					lso.RadioCommand:new(string.format("%s.check_in_reply", plane.name), "Marshal", string.format("%s, Radar contact, Case I recovery, BRC is %03d, Altimeter %.2f, Report see me.", plane.number, brc, pressure), nil, 4, lso.RadioCommand.Priority.NORMAL)
						:onFinish(function()
							lso.RadioCommand:new(string.format("%s.check_in_roger", plane.name), plane.number, string.format("%s, Roger, BRC %03d, %.2f.", plane.number, brc, pressure), nil, 3, lso.RadioCommand.Priority.NORMAL)
								:send(plane.unit)
						end)
						:send(lso.carrier.radio)
					self.coolDownTime = timer.getTime() + 7
					lso.process.changeStatus(plane.unit, lso.process.Status.CHECK_IN)
					lso.menu.removeMenu(plane.unit, "Check in")
					lso.menu.addMenu(plane.unit, "In Sight", lso.menu.handler.inSight)
					lso.menu.addMenu(plane.unit, "Abort", lso.menu.handler.abort)
					table.remove(self.check, i)
					break
				else
					table.remove(self.check, i)
				end
			end
		end
	end
end



-- Tower 塔台模块

lso.Tower = {}
lso.Tower.monitoring = {} -- 雷达监控中的单位
lso.Tower.coolDownTime = 0

function lso.Tower:checkIn(unit)
	local unitName = unit:getName()
	if (lso.utils.listContains(self.monitoring, unitName)) then
		return false
	else
		table.insert(self.monitoring, unitName)
		return true
	end
end
function lso.Tower:onFrame()
	-- mist.message.add({
		-- text =  string.format("Tower检测帧工作中 %d", #self.monitoring),
		-- displayTime = 1,
		-- msgFor = {coa = {"all"}},
		-- name = "TowerFrame",
	-- })
	if (timer.getTime() > self.coolDownTime) then
		for i, unitName in pairs(self.monitoring) do
			local plane = lso.Plane:new(unitName)
			if (plane) then
				if (lso.process.getStatus(plane.unit) == lso.process.Status.IN_SIGHT) then
					if (lso.LSO:checkContact(plane)) then
						table.remove(self.monitoring, i)
						break
					end
				else
					table.remove(self.monitoring, i)
				end
			else
				table.remove(self.monitoring, i)
			end
		end
	end
end



-- Paddles 着舰信号官模块
lso.LSO = {}
lso.LSO.contact = false -- 是否接触
lso.LSO.trackProcess = nil -- 当前指挥程序

-- 着舰信号官固定指令
lso.LSO.command = {
	CONTACT 	= 	lso.RadioCommand:new("lso.CONTACT", 		"LSO", "%s, Paddles contact.", 			nil, 4, lso.RadioCommand.Priority.NORMAL),
	CALL_BALL 	= 	lso.RadioCommand:new("lso.CALL_THE_BALL", 	"LSO", "%s, 3/4 miles, Call the ball.", nil, 1, lso.RadioCommand.Priority.NORMAL),
	ROGER_BALL 	= 	lso.RadioCommand:new("lso.ROGER_BALL", 		"LSO", "Roger ball.", 					nil, 1, lso.RadioCommand.Priority.NORMAL),
					
	KEEP_TURN	= 	lso.RadioCommand:new("lso.KEEP_TURN", 		"LSO", "Keep your turn in!", 			nil, 2, lso.RadioCommand.Priority.NORMAL),
	HIGH 		= 	lso.RadioCommand:new("lso.HIGH", 			"LSO", "You're high!", 					nil, 2, lso.RadioCommand.Priority.NORMAL),
	LOW 		= 	lso.RadioCommand:new("lso.LOW", 			"LSO", "Little power!", 				nil, 2, lso.RadioCommand.Priority.NORMAL),
	TOO_LOW 	= 	lso.RadioCommand:new("lso.TOO_LOW", 		"LSO", "Power!", 						nil, 2, lso.RadioCommand.Priority.HIGH),
	LEFT 		= 	lso.RadioCommand:new("lso.LEFT", 			"LSO", "Right for lineup!", 			nil, 2, lso.RadioCommand.Priority.NORMAL),
	RIGHT 		= 	lso.RadioCommand:new("lso.RIGHT", 			"LSO", "Come left!", 					nil, 2, lso.RadioCommand.Priority.NORMAL),
	EASY 		= 	lso.RadioCommand:new("lso.EASY", 			"LSO", "Easy with it.", 				nil, 2, lso.RadioCommand.Priority.NORMAL),
	FAST 		= 	lso.RadioCommand:new("lso.FAST", 			"LSO", "You're fast!", 					nil, 2, lso.RadioCommand.Priority.NORMAL),
	SLOW 		= 	lso.RadioCommand:new("lso.SLOW", 			"LSO", "You're slow!", 					nil, 2, lso.RadioCommand.Priority.NORMAL),

	FOUL_DECK	= 	lso.RadioCommand:new("lso.FOUL_DECK",		"LSO", "Wave off, Foul deck.", 			nil, 3, lso.RadioCommand.Priority.IMMEDIATELY),
	WAVE_OFF	= 	lso.RadioCommand:new("lso.WAVE_OFF",		"LSO", "Wave off! Wave off!", 			nil, 3, lso.RadioCommand.Priority.IMMEDIATELY),
	BOLTER 		= 	lso.RadioCommand:new("lso.BOLTER", 			"LSO", "Bolter! Bolter! Bolter!", 		nil, 3, lso.RadioCommand.Priority.IMMEDIATELY),
}

-- 着舰信号官指令记录
lso.LSO.commands = {
	currentCommand = nil, -- 当前指令
	sendTime = nil, -- 当前指令下达时间
	coolDown = {}, -- 指令冷却状态
}

-- 下达指令
function lso.LSO:showCommand(cmd, unit, force, data, coolTime)
	local sender = unit or lso.carrier.radio
	local commandData = self.commands
	local nowTime = timer.getTime()
	
	-- 检查上一条指令是否结束
	-- 当上一条指令已结束或新指令优先级高于上一条指令时，将上一条指令设置冷却，并继续执行
	-- 否则忽略新指令
	if ((not force) and commandData.currentCommand and commandData.sendTime) then
		local prior = cmd.priority > commandData.currentCommand.priority
		local endTime = commandData.sendTime + commandData.currentCommand.duration
		if (prior or nowTime >= endTime) then
			local cd = commandData.coolDown or {}
			cd[commandData.currentCommand.tag] = {
				command = commandData.currentCommand,
				coolTime = endTime + (coolTime or 2)
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
			if (cdItem.command == cmd) then
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
		cmd:send(sender, data)
		return true
	end
end


-- 追踪数据类
-- 用于记录着陆阶段所有飞行数据
lso.LSO.TrackData = {plane, data, commands, processTime}
function lso.LSO.TrackData:new(plane)
		assert(plane ~= nil, "TrackData: unit cannot be nil");
		local obj = {
			plane = plane,
			data = {},
			commands = {},
			processTime = {
				start,middle,close,ramp,
			},
		}
		setmetatable(obj, {__index = self})
		return obj
end
function lso.LSO.TrackData:addData(flightData)
		table.insert(self.data, flightData)
end
function lso.LSO.TrackData:getData()
	if (#self.data > 0) then
		return self.data[#self.data]
	else
		return nil
	end
end
function lso.LSO.TrackData:getDataRecord(dataType, length)
	dataType = string.lower(dataType)
	length = length <= #self.data and length or #self.data
	local data = {}
	for i = #self.data, #self.data - length + 1, -1 do
		if (self.data[i][dataType] ~= nil) then
			table.insert(data, self.data[i][dataType])
		end
	end
	return data
end
function lso.LSO.TrackData:addCommand(command, timestamp)
	table.insert(self.commands, {
		command = command,
		timestamp = timestamp or timer.getTime()
	})
end


function lso.LSO:checkContact(plane)
	if (lso.LSO.contact) then
		return false
	end
	local carrierHeadding = lso.utils.getCarrierHeadding(true)
	local carrierTail = (carrierHeadding + 180) % 360
	local deckAngle = (carrierHeadding - lso.carrier.data.deck) % 360
	
	-- local data1 = string.format("飞机航向 %.3f\n飞机速度 %.3f", plane.heading, lso.Converter.MS_KNOT(plane.speed))
	-- local data2 = string.format("船航向 %.3f\n船尾 %.3f\n倾斜甲板 %.3f", carrierHeadding, carrierTail, deckAngle)
	-- local data3 = string.format("距离 %.3f\n方位角 %.3f", plane.distance, plane.azimuth)
	-- local data4 = string.format("相对船尾角度 %.3f\n高度 %.3f", lso.utils.math.getAzimuthError(plane.heading, carrierTail, true), plane.autitude)
	-- mist.message.add({
		-- text = data1 .. "\n" .. data2 .. "\n" .. data3 .. "\n" .. data4,
		-- displayTime = 5,
		-- msgFor = {units={plane.unit:getName()}},
		-- name = plane.unit:getName() .. "checkContact",
	-- })
	
	-- 在航母的相对方位 230-270° 之间
	if (plane.azimuth > 230 and plane.azimuth < 270) then
		-- 距离 0.2-1.5 nm
		if (lso.Converter.M_NM(plane.distance) > 0.2 and lso.Converter.M_NM(plane.distance) < 1.5) then
			-- 高度低于 800 ft，速度小于 220 节 
			if (lso.Converter.M_FT(plane.autitude) < 800 and lso.Converter.MS_KNOT(plane.speed) < 220) then
				-- 航向为航母舰尾 ±45°
				if (math.abs(lso.utils.math.getAzimuthError(plane.heading, carrierTail, true)) < 45) then
					-- 改变状态 Paddles Contact
					lso.process.changeStatus(plane.unit, lso.process.Status.PADDLES)
					lso.menu.removeMenu(plane.unit, "Abort")
					
					self.command.CONTACT:send(lso.carrier.radio, {plane.number})
					
					local paddleFrame = function(args, timestamp)
						local carrierHeadding = lso.utils.getCarrierHeadding(true)
						local carrierTail = (carrierHeadding + 180) % 360
						if plane:updateData() then -- 更新飞行数据
							if (
								plane.azimuth > 90 and plane.azimuth < 270 -- 在航母后半圆
								and lso.Converter.M_NM(plane.distance) < 2.5 -- 距离小于 2.5 nm
								and lso.Converter.M_FT(plane.autitude) < 800 -- 高度低于 800 ft
							) then
								-- local data1 = string.format("方位偏差 %.3f\n角度偏差 %.3f", plane.angleError, lso.utils.math.getAzimuthError(plane.heading, deckAngle, true))
								-- local data2 = string.format("距离下滑道 %.3f", math.sin(math.rad(math.abs(plane.angleError))) * plane.distance)
								-- mist.message.add({
									-- text = data1 .. "\n" .. data2,
									-- displayTime = 1,
									-- msgFor = {units={plane.unit:getName()}},
									-- name = plane.unit:getName() .. "paddles_contact",
								-- })
								
								if (lso.Converter.M_FT(plane.autitude) < 300) then
									self:showCommand(self.command.TOO_LOW)
								end
								if (
									plane.angleError > 0
									and math.sin(math.rad(plane.angleError)) * plane.distance < 650 -- 到下滑道垂足距离
									and math.abs(lso.utils.math.getAzimuthError(plane.heading, deckAngle, true)) > 90
								)then
									-- Keep your turn in
									self:showCommand(self.command.KEEP_TURN)
								end
								if (
									math.abs(lso.utils.math.getAzimuthError(plane.heading, deckAngle, true)) < 15
									and math.abs(plane.angleError) < 10
									-- and plane.gsError < 2.5 and plane.gsError > -1
								) then
									if (self:track(plane)) then
										return nil
									end
								end
								return timer.getTime() + 0.1
							else
								lso.LSO.contact = false
								lso.menu.handler.abort(plane.unit)
								return nil
							end
						else
							return nil
						end
					end
					timer.scheduleFunction(paddleFrame, nil, timer.getTime() + 1)
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
	if self.trackProcess ~= nil then
		return false
	end
	local callTheBall = 0
	local trackData = self.TrackData:new(plane)
	local trackCommand = function (cmd, check, timestamp)
		if check then
			if self:showCommand(cmd) then
				trackData:addCommand(cmd, timestamp)
			end
		end
	end
	local landFinish = function()
		self.trackProcess = nil
		lso.LSO.contact = false
		lso.process.initPlane(plane.unit)
	end
	local goAround = function()
		self.trackProcess = nil
		lso.LSO.contact = false
		lso.process.changeStatus(plane.unit, lso.process.Status.IN_SIGHT)
		lso.menu.addMenu(plane.unit, "Abort", lso.menu.handler.abort)
		lso.Tower:checkIn(plane.unit)
	end
	local trackFrame = function(args, trackTime)
		if plane:updateData() then -- 更新飞行数据
		
			-- 当剩余距离小于20m时停止指挥，开始连续检测是否成功钩上
			if (plane.rtg < 20) then
				local previousData = trackData:getData()
				if (plane.speed < 20 or (previousData and (previousData.speed - plane.speed) > 6)) then -- 迅速减速，着舰完成
					lso.RadioCommand:new("lso.on_board", "LSO", "You're on board.", nil, 3, lso.RadioCommand.Priority.NORMAL)
						:send(lso.carrier.radio)
					-- mist.message.add({
						-- text = "着舰完成",
						-- displayTime = 5,
						-- msgFor = {units={plane.unit:getName()}},
						-- name = plane.unit:getName() .. "done",
					-- })
					landFinish()
					return nil
				elseif (plane.rtg < -80 and plane.speed > 40) then -- 穿过着舰区，脱钩
					trackCommand(self.command.BOLTER, true, trackTime)
					goAround()
					return nil
				else
					return timer.getTime() + 0.01
				end
			end
			
			-- 记录新的飞行数据
			trackData:addData({
				heading = plane.heading,
				rtg = plane.rtg, -- range to go
				angle = plane.angleError,
				gs = plane.gs,
				aoa = plane.aoa,
				roll = plane.roll,
				atltitude = plane.point.y,
				speed = plane.speed,
				vs = plane.vs,
				timestamp = trackTime,
			})
			
			-- 计算历史飞行数据
			local rollVariance = lso.utils.math.getVariance(trackData:getDataRecord("roll", 20))
			local vsVariance = lso.utils.math.getVariance(trackData:getDataRecord("vs", 20))
			local aoaAvg = lso.utils.math.getAverage(trackData:getDataRecord("aoa", 20))
			local aoaDiff = aoaAvg - plane.model.aoa
			
			-- 近距离时将角度误差转换为距离误差，以消除快速发散
			local angleError = plane.angleError * math.min(1, plane.rtg / 120)
			local gsError = plane.gsError * math.min(1, plane.rtg / 120)

			-- 判断是否需要复飞
		 	local waveOff = (plane.rtg > 30 and (
				math.abs(angleError) > 8
				or gsError > 3 or gsError < -1
				or (plane.rtg < 300 and gsError < -0.8)
			))
			if (waveOff) then
				trackCommand(self.command.WAVE_OFF, true, trackTime)
				goAround()
				return nil
			end

			-- 记录进入每个着舰阶段的时间
			if (trackData.processTime.start == nil and plane.rtg > 800) then
				trackData.processTime.start = trackTime
			elseif (trackData.processTime.middle == nil and plane.rtg <= 800 and plane.rtg > 400) then
				trackData.processTime.middle = trackTime
			elseif (trackData.processTime.close == nil and plane.rtg <= 400 and plane.rtg > 160) then
				trackData.processTime.close = trackTime
			elseif (trackData.processTime.ramp == nil and plane.rtg < 60) then
				trackData.processTime.ramp = trackTime
			end
			
			-- local timestamp = string.format("时间 %.3f", trackTime)
			-- local data = string.format("偏移距 %.3f\n方位角 %.3f", plane.rtg, plane.angle)
			-- local msg = string.format("标准下滑道 %.3f\n下滑道 %.3f", lso.carrier.data.gs, plane.gs)
			-- local diff = string.format("偏移角 %.3f\n下滑道偏离 %.3f", plane.angleError, gsError)
			-- local aoa = string.format("攻角 %.3f\n平均攻角 %.3f\n攻角偏差 %.3f", plane.aoa, aoaAvg, aoaDiff)
			-- local vs = string.format("垂直速度 %.3f\n垂速变化 %.3f", plane.vs, vsVariance or 0)
			-- local roll = string.format("倾角 %.3f\n倾角变化 %.3f", plane.roll, rollVariance or 0)
			-- local length = string.format("数据数量 %d\n指令数量 %d", #trackData.data, #trackData.commands)
			-- mist.message.add({
				-- text = plane.unit:getTypeName() .. "\n".. timestamp .. "\n" .. data .. "\n" .. msg .. "\n" .. diff .. "\n" .. aoa .. "\n" .. vs.. "\n" .. roll.. "\n" .. length,
				-- displayTime = 5,
				-- msgFor = {units={plane.unit:getName()}},
				-- name = plane.unit:getName() .. "test",
			-- })
			
			if (
				(callTheBall == 0 or callTheBall == 1)
				and plane.distance < 1287 and plane.distance > 804 
			) then
				callTheBall = 1
				if (self:showCommand(self.command.CALL_BALL, nil, nil, {plane.number})) then
					callTheBall = 2
				end
			elseif (callTheBall == 2) then
				local fuelMess = lso.Converter.KG_LB(plane.fuel) / 1000 -- 千磅
				cmd = lso.RadioCommand:new(	"lso.BALL_CALL", plane.number, string.format("%s, %s ball, %.1f.", plane.number, plane.model.name, fuelMess), nil, 2, lso.RadioCommand.Priority.NORMAL)
				if (self:showCommand(cmd, plane.unit)) then
					callTheBall = 3
				end
			elseif (callTheBall == 3) then
				if (self:showCommand(self.command.ROGER_BALL)) then
					callTheBall = -1
				end
			end
			
			if callTheBall < 1 then

				-- 根据飞行数据下达指令
				-- 遵循“先爬升后加速，先减速后下高”原则
				trackCommand(self.command.TOO_LOW, 		(gsError < -0.6), 						trackTime)
				trackCommand(self.command.LOW, 			(gsError < -0.3 and gsError >= -0.6), 	trackTime)
				trackCommand(self.command.SLOW, 		(aoaDiff > 0.8), 						trackTime)
				
				trackCommand(self.command.LEFT, 		(angleError > 1.2), 					trackTime)
				trackCommand(self.command.RIGHT, 		(angleError < -1.2), 					trackTime)
				
				trackCommand(self.command.FAST, 		(aoaDiff < -0.8), 						trackTime)
				trackCommand(self.command.HIGH, 		(gsError > 0.6), 						trackTime)
				
				trackCommand(self.command.EASY, 		(vsVariance > 1 or rollVariance > 100), trackTime)
				
			end

			return timer.getTime() + 0.1
		else
			-- error("LSO onFrame lost unit.")
			self:showCommand(self.command.FOUL_DECK)
			goAround()
			return nil
		end
	end

	self.tracking = plane
	self.trackProcess = timer.scheduleFunction(trackFrame, nil, timer.getTime() + 2)
	return true
end


-- 主检测帧
function lso:onFrame()
	-- 遍历所有飞机
	local allPlanes = coalition.getPlayers(lso.carrier.unit:getCoalition())
	local lx, ly = lso.utils.getLandingPoint()
	for i, unit in ipairs(allPlanes) do
		local plane = lso.Plane:new(unit)
		if plane and plane:updateData() then
			mist.message.add({
				text =  string.format("倾角 %.3f", plane.roll),
				displayTime = 2,
				msgFor = {coa = {"all"}},
				name = "roll",
			})
		end
	end
	-- mist.message.add({
		-- text =  "主检测帧工作中",
		-- displayTime = 1,
		-- msgFor = {coa = {"all"}},
		-- name = "mainProcess",
	-- })
end

-- 全局事件处理器
lso.eventHandler = {}
function lso.eventHandler:onEvent(event)
	local status, err = pcall(function(event)
        if event == nil or event.initiator == nil then
            return false
        end
		if (
			world.event.S_EVENT_BIRTH == event.id
			) then
			lso.process.initPlane(event.initiator)
        end
		-- if (
			-- world.event.S_EVENT_LAND == event.id
			-- ) then
			-- lso.process.initPlane(event.initiator)
			-- if event.place == lso.carrier.unit then
				-- mist.message.add({
					-- text = "着舰",
					-- displayTime = 5,
					-- msgFor = {units={event.initiator:getName()}},
					-- name = event.initiator:getName() .. "donedone",
				-- })
			-- end
        -- end
		if (
			world.event.S_EVENT_CRASH == event.id
			or world.event.S_EVENT_EJECTION == event.id
			or world.event.S_EVENT_DEAD == event.id
			or world.event.S_EVENT_PILOT_DEAD == event.id
			) then
			lso.process.removePlane(event.initiator)
        end
		return true
    end, event)
    -- if (not status) then
        -- lso.logger:error("Error while handling event")
    -- end
end

lso.init() -- 初始化航母参数
-- lso.mainProcess = lso.addCheckFrame(lso) -- 添加主检测帧程序
lso.Marshal.frameID = lso.addCheckFrame(lso.Marshal) -- 添加 Marshal 检测帧程序
lso.Tower.frameID = lso.addCheckFrame(lso.Tower) -- 添加 Tower 检测帧程序

world.addEventHandler(lso.eventHandler)

-- 遍历所有飞机
local allPlanes = coalition.getPlayers(lso.carrier.unit:getCoalition())
local lx, ly = lso.utils.getLandingPoint()
for i, unit in ipairs(allPlanes) do
	local plane = lso.Plane:new(unit)
	if plane and plane:updateData() then
		lso.process.initPlane(unit)
	end
end
