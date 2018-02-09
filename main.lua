local lso = {}

local frameId = 1
local checkFrames = {}
function lso.addCheckFrame(frame)
	assert(type(frame) == "table", "argument expected table, got " .. type(frame))
	assert(frame.onFrame ~= nil and type(frame.onFrame) == "function", "didn't implement function 'onFrame'")
	table.insert(checkFrames, {frame = frame, id = frameId})
end

function lso.main(arg, frameTime)
	local i = 1
	while i <= #checkFrames do
		if checkFrames[i] ~= nil then
			checkFrames[i]:onFrame()
		end
		i = i + 1
	end
	return frameTime + 0.1
end

timer.scheduleFunction(lso.main, nil, timer.getTime() + 1)