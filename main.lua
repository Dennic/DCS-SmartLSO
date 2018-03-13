local lso = {}

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

function lso.main(arg, frameTime)
	local i = 1
	while i <= #lso.checkFrames do
		if lso.checkFrames[i] ~= nil then
			lso.checkFrames[i].frame:onFrame()
		end
		i = i + 1
	end
	return frameTime + 0.1
end

timer.scheduleFunction(lso.main, nil, timer.getTime() + 1)



lso.utils = {}
lso.utils.math = {}

function lso.utils.math.getOffset(l, k, d)
	local dx = l / math.sqrt(math.pow(k, 2) + 1)
	local dy = l * k / math.sqrt(math.pow(k, 2) + 1)
	if (d % (math.pi * 2) > math.pi) then
		return dx, dy
	else
		return -dx, -dy
	end
end

function lso.utils.math.getK(r)
	local deg = 90 - math.deg(r) % 360
	local k = tonumber(string.format("%.3f",math.tan(math.rad(deg))))
	return k
end

function lso.utils.math.getOffsetPoint(x, y, h, l)
	local k = lso.utils.math.getK(h)
	local dx, dy = lso.utils.math.getOffset(l, k, h)
	return x+dx, y+dy
end





lso.test = {}

function lso.test:onFrame()
	local ship = Unit.getByName("ship")
	local plane = Unit.getByName("plane")
	local shipPoint = ship:getPoint()
	local planePoint = plane:getPoint()
	local shipHeadding = mist.getHeading(ship)
	local planeHeadding = mist.getHeading(plane)
	
	local shipData = string.format("船位置 x=%.3f y=%.3f z=%.3f \n船航向 %.3f", shipPoint.x, shipPoint.y, shipPoint.z, shipHeadding)
	local planeData = string.format("飞机位置 x=%.3f y=%.3f z=%.3f \n飞机航向 %.3f", planePoint.x, planePoint.y, planePoint.z, planeHeadding)
	
	local cx, cy = lso.utils.math.getOffsetPoint(shipPoint.z, shipPoint.x, shipHeadding, 58)
	local bx, by = lso.utils.math.getOffsetPoint(cx, cy ,shipHeadding + math.pi * 0.5, 14)
	
	local offset = math.sqrt(math.pow(planePoint.z - bx, 2) + math.pow(planePoint.x - by, 2))
	
	local msg = {} 
    msg.text = shipData .. "\n" .. planeData .. "\n接地点偏移：" .. offset
    msg.displayTime = 5
    msg.msgFor = {coa = {"all"}}
    msg.name = "test"
    mist.message.add(msg)
end

lso.addCheckFrame(lso.test)