local log = {}

local logfile = love.filesystem.newFile("log.txt", "a")

function log.append(...)
	local strs = {}
	for i = 1, select("#", ...) do
		strs[i] = tostring(select(i, ...))
	end
	local str = table.concat(strs, "\t")
	logfile:write(str)
	logfile:write("\n")
end

function log.save()
	logfile:flush()
end

return log