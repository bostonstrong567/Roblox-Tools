local runService = game:GetService("RunService")

local assert = assert
local type = type
local typeof = typeof
local tostring = tostring
local pcall = pcall
local warn = warn
local select = select
local osClock = os.clock
local coroutineRunning = coroutine.running
local coroutineYield = coroutine.yield
local coroutineResume = coroutine.resume
local taskDefer = task.defer
local tablePack = table.pack
local tableUnpack = table.unpack
local tableClear = table.clear
local tableSort = table.sort
local pairs = pairs

local taskManager = {}

local tasksByName = {}

local protectedCalls = true
local maxQueuePerStep = math.huge
local maxStepTime = 0

local function defaultErrorHandler(kind, name, err)
	warn(("taskManager %s '%s' error: %s"):format(tostring(kind), tostring(name), tostring(err)))
end

local errorHandler = defaultErrorHandler

function taskManager.setProtectedCalls(enabled)
	protectedCalls = enabled == true
end

function taskManager.setQueueLimits(maxPerStep, maxSeconds)
	if maxPerStep ~= nil then
		maxQueuePerStep = maxPerStep
	end
	if maxSeconds ~= nil then
		maxStepTime = maxSeconds
	end
end

function taskManager.setErrorHandler(handler)
	errorHandler = handler or defaultErrorHandler
end

local function assertName(name)
	assert(type(name) == "string" and name ~= "", "name must be a non-empty string")
end

local function assertCallback(callback)
	assert(type(callback) == "function", "callback must be a function")
end

local function assertSignal(signalLike)
	assert(typeof(signalLike) == "RBXScriptSignal", "signalLike must be RBXScriptSignal")
end

local function setArgs(entry, ...)
	local n = select("#", ...)
	entry.argCount = n
	entry.arg1 = nil
	entry.arg2 = nil
	entry.arg3 = nil
	entry.arg4 = nil
	entry.args = nil

	if n == 0 then
		return
	end
	if n == 1 then
		entry.arg1 = ...
		return
	end
	if n == 2 then
		entry.arg1, entry.arg2 = ...
		return
	end
	if n == 3 then
		entry.arg1, entry.arg2, entry.arg3 = ...
		return
	end
	if n == 4 then
		entry.arg1, entry.arg2, entry.arg3, entry.arg4 = ...
		return
	end

	entry.args = tablePack(...)
end

local function callNoEvent(entry)
	local cb = entry.callback
	local n = entry.argCount
	if n == 0 then
		cb()
	elseif n == 1 then
		cb(entry.arg1)
	elseif n == 2 then
		cb(entry.arg1, entry.arg2)
	elseif n == 3 then
		cb(entry.arg1, entry.arg2, entry.arg3)
	elseif n == 4 then
		cb(entry.arg1, entry.arg2, entry.arg3, entry.arg4)
	else
		local args = entry.args
		cb(tableUnpack(args, 1, args.n))
	end
end

local function callEvent1(entry, a1)
	local cb = entry.callback
	local n = entry.argCount
	if n == 0 then
		cb(a1)
	elseif n == 1 then
		cb(a1, entry.arg1)
	elseif n == 2 then
		cb(a1, entry.arg1, entry.arg2)
	elseif n == 3 then
		cb(a1, entry.arg1, entry.arg2, entry.arg3)
	elseif n == 4 then
		cb(a1, entry.arg1, entry.arg2, entry.arg3, entry.arg4)
	else
		local args = entry.args
		cb(a1, tableUnpack(args, 1, args.n))
	end
end

local function callEvent2(entry, a1, a2)
	local cb = entry.callback
	local n = entry.argCount
	if n == 0 then
		cb(a1, a2)
	elseif n == 1 then
		cb(a1, a2, entry.arg1)
	elseif n == 2 then
		cb(a1, a2, entry.arg1, entry.arg2)
	elseif n == 3 then
		cb(a1, a2, entry.arg1, entry.arg2, entry.arg3)
	elseif n == 4 then
		cb(a1, a2, entry.arg1, entry.arg2, entry.arg3, entry.arg4)
	else
		local args = entry.args
		cb(a1, a2, tableUnpack(args, 1, args.n))
	end
end

local loops = {}

local queueHead = nil
local queueTail = nil
local queueCount = 0

local timerHeap = {}
local timerCount = 0

local schedulerNow = 0

local function heapSwap(i, j)
	local a = timerHeap[i]
	local b = timerHeap[j]
	timerHeap[i] = b
	timerHeap[j] = a
	a.heapIndex = j
	b.heapIndex = i
end

local function heapSiftUp(i)
	while i > 1 do
		local p = i // 2
		if timerHeap[p].dueTime <= timerHeap[i].dueTime then
			return
		end
		heapSwap(i, p)
		i = p
	end
end

local function heapSiftDown(i)
	local n = #timerHeap
	while true do
		local l = i * 2
		if l > n then
			return
		end
		local r = l + 1
		local c = l
		if r <= n and timerHeap[r].dueTime < timerHeap[l].dueTime then
			c = r
		end
		if timerHeap[i].dueTime <= timerHeap[c].dueTime then
			return
		end
		heapSwap(i, c)
		i = c
	end
end

local function heapPush(entry)
	local n = #timerHeap + 1
	timerHeap[n] = entry
	entry.heapIndex = n
	heapSiftUp(n)
end

local function heapPop()
	local n = #timerHeap
	if n == 0 then
		return nil
	end
	local root = timerHeap[1]
	local last = timerHeap[n]
	timerHeap[n] = nil
	if n > 1 then
		timerHeap[1] = last
		last.heapIndex = 1
		heapSiftDown(1)
	end
	root.heapIndex = nil
	return root
end

local function heapRemove(entry)
	local index = entry.heapIndex
	if not index then
		return false
	end
	local n = #timerHeap
	local last = timerHeap[n]
	timerHeap[n] = nil
	if index < n then
		timerHeap[index] = last
		last.heapIndex = index
		local p = index // 2
		if p > 0 and timerHeap[p].dueTime > last.dueTime then
			heapSiftUp(index)
		else
			heapSiftDown(index)
		end
	end
	entry.heapIndex = nil
	return true
end

local function rebuildLoopOrder(loop)
	tableClear(loop.priorityOrder)
	for priority in pairs(loop.buckets) do
		loop.priorityOrder[#loop.priorityOrder + 1] = priority
	end
	tableSort(loop.priorityOrder)
	loop.dirty = false
end

local function runLoopEvent1(loop, a1)
	if loop.dirty then
		rebuildLoopOrder(loop)
	end

	local buckets = loop.buckets
	local order = loop.priorityOrder

	for o = 1, #order do
		local priority = order[o]
		local bucket = buckets[priority]
		if bucket then
			local i = 1
			while i <= #bucket do
				local entry = bucket[i]
				if entry.active == false then
					i += 1
				else
					if protectedCalls then
						local ok, err = pcall(callEvent1, entry, a1)
						if not ok then
							errorHandler(loop.name, entry.name, err)
						end
					else
						callEvent1(entry, a1)
					end
					if bucket[i] == entry then
						i += 1
					end
				end
			end
		end
	end
end

local function runLoopEvent2(loop, a1, a2)
	if loop.dirty then
		rebuildLoopOrder(loop)
	end

	local buckets = loop.buckets
	local order = loop.priorityOrder

	for o = 1, #order do
		local priority = order[o]
		local bucket = buckets[priority]
		if bucket then
			local i = 1
			while i <= #bucket do
				local entry = bucket[i]
				if entry.active == false then
					i += 1
				else
					if protectedCalls then
						local ok, err = pcall(callEvent2, entry, a1, a2)
						if not ok then
							errorHandler(loop.name, entry.name, err)
						end
					else
						callEvent2(entry, a1, a2)
					end
					if bucket[i] == entry then
						i += 1
					end
				end
			end
		end
	end
end

local function maybeDisconnectHeartbeat()
	local loop = loops.heartbeat
	if not loop then
		return
	end
	if loop.connection and loop.repeatCount == 0 and queueCount == 0 and timerCount == 0 then
		loop.connection:Disconnect()
		loop.connection = nil
	end
end

local function maybeDisconnectLoop(loop)
	if loop.name == "heartbeat" then
		return
	end
	if loop.connection and loop.repeatCount == 0 then
		loop.connection:Disconnect()
		loop.connection = nil
	end
end

local function ensureLoop(stepName)
	local loop = loops[stepName]
	if loop then
		return loop
	end

	local signal
	local eventArity = 1

	if stepName == "heartbeat" then
		signal = runService.Heartbeat
	elseif stepName == "preSimulation" then
		signal = runService.PreSimulation
	elseif stepName == "postSimulation" then
		signal = runService.PostSimulation
	elseif stepName == "preAnimation" then
		signal = runService.PreAnimation
	elseif stepName == "preRender" then
		signal = runService.PreRender
	elseif stepName == "renderStepped" then
		signal = runService.RenderStepped
	elseif stepName == "stepped" then
		signal = runService.Stepped
		eventArity = 2
	else
		error(("unknown stepName: %s"):format(tostring(stepName)))
	end

	loop = {
		name = stepName,
		signal = signal,
		eventArity = eventArity,
		connection = nil,
		buckets = {},
		priorityOrder = {},
		dirty = false,
		repeatCount = 0
	}

	loops[stepName] = loop
	return loop
end

local function ensureLoopConnection(loop)
	if loop.connection then
		return
	end

	if loop.name == "preRender" or loop.name == "renderStepped" then
		assert(runService:IsClient(), loop.name .. " is client-only")
	end

	if loop.name == "heartbeat" then
		loop.connection = loop.signal:Connect(function(dt)
			schedulerNow = osClock()

			while true do
				local top = timerHeap[1]
				if not top or top.dueTime > schedulerNow then
					break
				end

				local timerEntry = heapPop()
				timerCount -= 1

				if timerEntry.name and tasksByName[timerEntry.name] == timerEntry then
					tasksByName[timerEntry.name] = nil
				end

				if timerEntry.active ~= false then
					if protectedCalls then
						local ok, err = pcall(callNoEvent, timerEntry)
						if not ok then
							errorHandler("delay", timerEntry.name or "delay", err)
						end
					else
						callNoEvent(timerEntry)
					end
				end
			end

			local processed = 0
			local start = schedulerNow

			while queueHead and processed < maxQueuePerStep do
				local entry = queueHead
				queueHead = entry.next
				if queueHead then
					queueHead.prev = nil
				else
					queueTail = nil
				end

				entry.next = nil
				entry.prev = nil

				queueCount -= 1

				if entry.name and tasksByName[entry.name] == entry then
					tasksByName[entry.name] = nil
				end

				if entry.active ~= false then
					if protectedCalls then
						local ok, err = pcall(callNoEvent, entry)
						if not ok then
							errorHandler("queue", entry.name or "queue", err)
						end
					else
						callNoEvent(entry)
					end
				end

				processed += 1

				if maxStepTime > 0 and (osClock() - start) >= maxStepTime then
					break
				end
			end

			runLoopEvent1(loop, dt)
			maybeDisconnectHeartbeat()
		end)

		return
	end

	if loop.eventArity == 2 then
		loop.connection = loop.signal:Connect(function(a1, a2)
			runLoopEvent2(loop, a1, a2)
			maybeDisconnectLoop(loop)
		end)
	else
		loop.connection = loop.signal:Connect(function(a1)
			runLoopEvent1(loop, a1)
			maybeDisconnectLoop(loop)
		end)
	end
end

local function removeFromQueue(entry)
	local prev = entry.prev
	local nextEntry = entry.next

	if prev then
		prev.next = nextEntry
	else
		queueHead = nextEntry
	end

	if nextEntry then
		nextEntry.prev = prev
	else
		queueTail = prev
	end

	entry.prev = nil
	entry.next = nil
end

local function removeFromBucket(entry)
	local loop = entry.loop
	local buckets = loop.buckets
	local bucket = buckets[entry.priority]
	if not bucket then
		return
	end

	local index = entry.bucketIndex
	if not index then
		return
	end

	local lastIndex = #bucket
	local lastEntry = bucket[lastIndex]
	bucket[lastIndex] = nil

	if index < lastIndex then
		bucket[index] = lastEntry
		lastEntry.bucketIndex = index
	end

	entry.bucketIndex = nil

	if #bucket == 0 then
		buckets[entry.priority] = nil
		loop.dirty = true
	end
end

local function stopInternal(name, entry)
	if not entry or entry.active == false then
		return
	end

	entry.active = false

	local kind = entry.kind

	if kind == "repeat" then
		removeFromBucket(entry)
		local loop = entry.loop
		loop.repeatCount -= 1
		if tasksByName[name] == entry then
			tasksByName[name] = nil
		end
		if loop.name == "heartbeat" then
			maybeDisconnectHeartbeat()
		else
			maybeDisconnectLoop(loop)
		end
		return
	end

	if kind == "queue" then
		removeFromQueue(entry)
		queueCount -= 1
		if tasksByName[name] == entry then
			tasksByName[name] = nil
		end
		maybeDisconnectHeartbeat()
		return
	end

	if kind == "timer" then
		if heapRemove(entry) then
			timerCount -= 1
		end
		if tasksByName[name] == entry then
			tasksByName[name] = nil
		end
		maybeDisconnectHeartbeat()
		return
	end

	if kind == "connection" then
		if entry.connection then
			entry.connection:Disconnect()
			entry.connection = nil
		end
		if tasksByName[name] == entry then
			tasksByName[name] = nil
		end
		return
	end

	if kind == "renderBind" then
		runService:UnbindFromRenderStep(entry.bindName)
		if tasksByName[name] == entry then
			tasksByName[name] = nil
		end
		return
	end

	if kind == "thread" then
		entry.cancelled = true
		if tasksByName[name] == entry then
			tasksByName[name] = nil
		end
		return
	end

	if kind == "signalWait" then
		if entry.connection then
			entry.connection:Disconnect()
			entry.connection = nil
		end
		if entry.timerEntry and heapRemove(entry.timerEntry) then
			timerCount -= 1
		end
		entry.timerEntry = nil
		if tasksByName[name] == entry then
			tasksByName[name] = nil
		end
		maybeDisconnectHeartbeat()
		return
	end

	if tasksByName[name] == entry then
		tasksByName[name] = nil
	end
end

function taskManager.stop(name)
	local entry = tasksByName[name]
	if entry then
		stopInternal(name, entry)
	end
end

function taskManager.stopAll()
	local names = {}
	for name in pairs(tasksByName) do
		names[#names + 1] = name
	end
	for i = 1, #names do
		local name = names[i]
		local entry = tasksByName[name]
		if entry then
			stopInternal(name, entry)
		end
	end
end

function taskManager.exists(name)
	return tasksByName[name] ~= nil
end

function taskManager.signal(name, signalLike, callback, ...)
	assertName(name)
	assertSignal(signalLike)
	assertCallback(callback)

	taskManager.stop(name)

	local extraCount = select("#", ...)
	local extraArgs = nil
	if extraCount > 0 then
		extraArgs = tablePack(...)
	end

	local entry = {
		kind = "connection",
		name = name,
		connection = nil,
		active = true
	}

	entry.connection = signalLike:Connect(function(...)
		if entry.active == false then
			return
		end
		if protectedCalls then
			local ok, err
			if extraArgs then
				ok, err = pcall(callback, ..., tableUnpack(extraArgs, 1, extraArgs.n))
			else
				ok, err = pcall(callback, ...)
			end
			if not ok then
				errorHandler("signal", name, err)
			end
		else
			if extraArgs then
				callback(..., tableUnpack(extraArgs, 1, extraArgs.n))
			else
				callback(...)
			end
		end
	end)

	tasksByName[name] = entry
	return entry
end

function taskManager.once(name, signalLike, callback, ...)
	assertName(name)
	assertSignal(signalLike)
	assertCallback(callback)

	taskManager.stop(name)

	local extraCount = select("#", ...)
	local extraArgs = nil
	if extraCount > 0 then
		extraArgs = tablePack(...)
	end

	local entry = {
		kind = "connection",
		name = name,
		connection = nil,
		active = true
	}

	entry.connection = signalLike:Connect(function(...)
		if entry.active == false then
			return
		end
		taskManager.stop(name)
		if protectedCalls then
			local ok, err
			if extraArgs then
				ok, err = pcall(callback, ..., tableUnpack(extraArgs, 1, extraArgs.n))
			else
				ok, err = pcall(callback, ...)
			end
			if not ok then
				errorHandler("once", name, err)
			end
		else
			if extraArgs then
				callback(..., tableUnpack(extraArgs, 1, extraArgs.n))
			else
				callback(...)
			end
		end
	end)

	tasksByName[name] = entry
	return entry
end

function taskManager.onceTimeout(name, signalLike, timeoutSeconds, callback, timeoutCallback, ...)
	assertName(name)
	assertSignal(signalLike)
	assert(type(timeoutSeconds) == "number", "timeoutSeconds must be number")
	assertCallback(callback)

	taskManager.stop(name)

	local extraCount = select("#", ...)
	local extraArgs = nil
	if extraCount > 0 then
		extraArgs = tablePack(...)
	end

	local entry = {
		kind = "signalWait",
		name = name,
		connection = nil,
		timerEntry = nil,
		active = true
	}

	local function onTimeout()
		if entry.active == false then
			return
		end
		taskManager.stop(name)
		if timeoutCallback then
			if protectedCalls then
				local ok, err = pcall(timeoutCallback)
				if not ok then
					errorHandler("onceTimeout", name, err)
				end
			else
				timeoutCallback()
			end
		end
	end

	local timerEntry = {
		kind = "timerInternal",
		name = nil,
		callback = onTimeout,
		active = true,
		dueTime = osClock() + timeoutSeconds,
		argCount = 0
	}

	entry.timerEntry = timerEntry
	timerCount += 1
	heapPush(timerEntry)

	ensureLoopConnection(ensureLoop("heartbeat"))

	entry.connection = signalLike:Connect(function(...)
		if entry.active == false then
			return
		end
		taskManager.stop(name)
		if protectedCalls then
			local ok, err
			if extraArgs then
				ok, err = pcall(callback, ..., tableUnpack(extraArgs, 1, extraArgs.n))
			else
				ok, err = pcall(callback, ...)
			end
			if not ok then
				errorHandler("onceTimeout", name, err)
			end
		else
			if extraArgs then
				callback(..., tableUnpack(extraArgs, 1, extraArgs.n))
			else
				callback(...)
			end
		end
	end)

	tasksByName[name] = entry
	return entry
end

local function registerLoopTask(stepName, name, priorityLevel, callback, ...)
	assertName(name)
	assertCallback(callback)
	assert(type(priorityLevel) == "number", "priorityLevel must be number")

	taskManager.stop(name)

	local loop = ensureLoop(stepName)
	ensureLoopConnection(loop)

	local bucket = loop.buckets[priorityLevel]
	if not bucket then
		bucket = {}
		loop.buckets[priorityLevel] = bucket
		loop.dirty = true
	end

	local entry = {
		kind = "repeat",
		name = name,
		loop = loop,
		priority = priorityLevel,
		callback = callback,
		bucketIndex = nil,
		active = true
	}

	setArgs(entry, ...)

	local index = #bucket + 1
	bucket[index] = entry
	entry.bucketIndex = index

	loop.repeatCount += 1

	tasksByName[name] = entry
	return entry
end

function taskManager.priority(name, priorityLevel, callback, ...)
	return registerLoopTask("heartbeat", name, priorityLevel, callback, ...)
end

function taskManager.heartbeat(name, callback, ...)
	return registerLoopTask("heartbeat", name, 0, callback, ...)
end

function taskManager.preSimulation(name, priorityLevel, callback, ...)
	return registerLoopTask("preSimulation", name, priorityLevel, callback, ...)
end

function taskManager.postSimulation(name, priorityLevel, callback, ...)
	return registerLoopTask("postSimulation", name, priorityLevel, callback, ...)
end

function taskManager.preAnimation(name, priorityLevel, callback, ...)
	return registerLoopTask("preAnimation", name, priorityLevel, callback, ...)
end

function taskManager.preRender(name, priorityLevel, callback, ...)
	return registerLoopTask("preRender", name, priorityLevel, callback, ...)
end

function taskManager.renderStepped(name, priorityLevel, callback, ...)
	return registerLoopTask("renderStepped", name, priorityLevel, callback, ...)
end

function taskManager.stepped(name, priorityLevel, callback, ...)
	return registerLoopTask("stepped", name, priorityLevel, callback, ...)
end

function taskManager.bindToRenderStep(name, renderPriority, callback, ...)
	assertName(name)
	assertCallback(callback)
	assert(type(renderPriority) == "number", "renderPriority must be number")
	assert(runService:IsClient(), "bindToRenderStep is client-only")

	taskManager.stop(name)

	local entry = {
		kind = "renderBind",
		name = name,
		bindName = name,
		callback = callback,
		active = true
	}

	setArgs(entry, ...)

	runService:BindToRenderStep(name, renderPriority, function(dt)
		if entry.active == false then
			return
		end
		if protectedCalls then
			local ok, err = pcall(callEvent1, entry, dt)
			if not ok then
				errorHandler("bindToRenderStep", name, err)
			end
		else
			callEvent1(entry, dt)
		end
	end)

	tasksByName[name] = entry
	return entry
end

function taskManager.queue(name, callback, ...)
	assertName(name)
	assertCallback(callback)

	taskManager.stop(name)

	local entry = {
		kind = "queue",
		name = name,
		callback = callback,
		prev = nil,
		next = nil,
		active = true
	}

	setArgs(entry, ...)

	if queueTail then
		queueTail.next = entry
		entry.prev = queueTail
		queueTail = entry
	else
		queueHead = entry
		queueTail = entry
	end

	queueCount += 1
	tasksByName[name] = entry

	ensureLoopConnection(ensureLoop("heartbeat"))
	return entry
end

function taskManager.delay(name, seconds, callback, ...)
	assertName(name)
	assert(type(seconds) == "number", "seconds must be number")
	assertCallback(callback)

	taskManager.stop(name)

	local entry = {
		kind = "timer",
		name = name,
		dueTime = osClock() + seconds,
		callback = callback,
		active = true
	}

	setArgs(entry, ...)

	timerCount += 1
	heapPush(entry)

	tasksByName[name] = entry
	ensureLoopConnection(ensureLoop("heartbeat"))
	return entry
end

function taskManager.defer(name, callback, ...)
	assertName(name)
	assertCallback(callback)

	taskManager.stop(name)

	local entry = {
		kind = "thread",
		name = name,
		callback = callback,
		cancelled = false,
		active = true
	}

	setArgs(entry, ...)

	local thread
	thread = taskDefer(function()
		if entry.cancelled then
			return
		end
		if tasksByName[name] ~= entry then
			return
		end
		tasksByName[name] = nil
		if protectedCalls then
			local ok, err = pcall(callNoEvent, entry)
			if not ok then
				errorHandler("defer", name, err)
			end
		else
			callNoEvent(entry)
		end
	end)

	entry.thread = thread
	tasksByName[name] = entry
	return entry
end

function taskManager.condition(name, predicate, timeoutSeconds, callback)
	assertName(name)
	assertCallback(predicate)
	if timeoutSeconds ~= nil then
		assert(type(timeoutSeconds) == "number", "timeoutSeconds must be number or nil")
	end
	assertCallback(callback)

	taskManager.stop(name)

	local dueTime = nil
	if timeoutSeconds ~= nil and timeoutSeconds > 0 then
		dueTime = osClock() + timeoutSeconds
	end

	local entry
	entry = taskManager.priority(name, 0, function()
		if dueTime and schedulerNow >= dueTime then
			taskManager.stop(name)
			callback(false)
			return
		end

		local ok, result
		if protectedCalls then
			ok, result = pcall(predicate)
			if not ok then
				taskManager.stop(name)
				errorHandler("condition", name, result)
				return
			end
		else
			result = predicate()
		end

		if result then
			taskManager.stop(name)
			callback(true)
		end
	end)

	return entry
end

function taskManager.sleep(seconds)
	assert(type(seconds) == "number", "seconds must be number")
	local thread = coroutineRunning()
	if not thread then
		error("sleep must be called from a coroutine")
	end

	local resumed = false

	local timerEntry = {
		kind = "timerInternal",
		name = nil,
		dueTime = osClock() + seconds,
		callback = function()
			if resumed then
				return
			end
			resumed = true
			local ok, err = coroutineResume(thread)
			if not ok then
				errorHandler("sleep", "coroutine", err)
			end
		end,
		active = true,
		argCount = 0
	}

	timerCount += 1
	heapPush(timerEntry)
	ensureLoopConnection(ensureLoop("heartbeat"))
	coroutineYield()
end

function taskManager.awaitSignal(signalLike, timeoutSeconds)
	assertSignal(signalLike)
	if timeoutSeconds ~= nil then
		assert(type(timeoutSeconds) == "number", "timeoutSeconds must be number or nil")
	end

	local thread = coroutineRunning()
	if not thread then
		error("awaitSignal must be called from a coroutine")
	end

	local done = false
	local connection = nil
	local timerEntry = nil

	local function finish(success, ...)
		if done then
			return
		end
		done = true
		if connection then
			connection:Disconnect()
			connection = nil
		end
		if timerEntry and heapRemove(timerEntry) then
			timerCount -= 1
		end
		timerEntry = nil
		local ok, err = coroutineResume(thread, success, ...)
		if not ok then
			errorHandler("awaitSignal", "coroutine", err)
		end
	end

	connection = signalLike:Connect(function(...)
		finish(true, ...)
	end)

	if timeoutSeconds and timeoutSeconds > 0 then
		timerEntry = {
			kind = "timerInternal",
			name = nil,
			dueTime = osClock() + timeoutSeconds,
			callback = function()
				finish(false)
			end,
			active = true,
			argCount = 0
		}
		timerCount += 1
		heapPush(timerEntry)
		ensureLoopConnection(ensureLoop("heartbeat"))
	end

	return coroutineYield()
end

return taskManager
