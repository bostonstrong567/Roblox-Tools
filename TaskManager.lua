if getgenv().taskManager then return getgenv().taskManager end

local RunService = game:GetService("RunService")

local Assert = assert
local Type = type
local Typeof = typeof
local ToString = tostring
local PCall = pcall
local Warn = warn
local Select = select

local Now = os.clock

local CoroutineRunning = coroutine.running
local CoroutineYield = coroutine.yield
local CoroutineResume = coroutine.resume

local TaskDefer = task.defer
local TaskSpawn = task.spawn
local TaskWait = task.wait

local TablePack = table.pack
local TableUnpack = table.unpack
local TableClear = table.clear
local TableSort = table.sort
local TableMove = table.move

local Pairs = pairs

local TaskManager = {}

local TasksByName = {}
local Loops = {}

local ProtectedCalls = true
local MaxQueuePerStep = math.huge
local MaxTimersPerStep = math.huge
local MaxStepTime = 0

local SchedulerNow = 0

local function DefaultErrorHandler(kind, name, err)
	Warn(("TaskManager %s '%s' error: %s"):format(ToString(kind), ToString(name), ToString(err)))
end

local ErrorHandler = DefaultErrorHandler

local function AssertName(name: any)
	Assert(Type(name) == "string" and name ~= "", "name must be a non-empty string")
end

local function AssertCallback(callback: any)
	Assert(Type(callback) == "function", "callback must be a function")
end

local function AssertSignal(signalLike: any)
	Assert(Typeof(signalLike) == "RBXScriptSignal", "signalLike must be RBXScriptSignal")
end

local function SetArgs(entry, ...)
	local n = Select("#", ...)
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

	entry.args = TablePack(...)
end

local function CallNoEvent(entry)
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
		cb(TableUnpack(args, 1, args.n))
	end
end

local function CallEvent1(entry, a1)
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
		cb(a1, TableUnpack(args, 1, args.n))
	end
end

local function CallEvent2(entry, a1, a2)
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
		cb(a1, a2, TableUnpack(args, 1, args.n))
	end
end

local function CallEvent3(entry, a1, a2, a3)
	local cb = entry.callback
	local n = entry.argCount

	if n == 0 then
		cb(a1, a2, a3)
	elseif n == 1 then
		cb(a1, a2, a3, entry.arg1)
	elseif n == 2 then
		cb(a1, a2, a3, entry.arg1, entry.arg2)
	elseif n == 3 then
		cb(a1, a2, a3, entry.arg1, entry.arg2, entry.arg3)
	elseif n == 4 then
		cb(a1, a2, a3, entry.arg1, entry.arg2, entry.arg3, entry.arg4)
	else
		local args = entry.args
		cb(a1, a2, a3, TableUnpack(args, 1, args.n))
	end
end

local function CallEvent4(entry, a1, a2, a3, a4)
	local cb = entry.callback
	local n = entry.argCount

	if n == 0 then
		cb(a1, a2, a3, a4)
	elseif n == 1 then
		cb(a1, a2, a3, a4, entry.arg1)
	elseif n == 2 then
		cb(a1, a2, a3, a4, entry.arg1, entry.arg2)
	elseif n == 3 then
		cb(a1, a2, a3, a4, entry.arg1, entry.arg2, entry.arg3)
	elseif n == 4 then
		cb(a1, a2, a3, a4, entry.arg1, entry.arg2, entry.arg3, entry.arg4)
	else
		local args = entry.args
		cb(a1, a2, a3, a4, TableUnpack(args, 1, args.n))
	end
end

local function CallSignal(entry, ...)
	if entry.argCount == 0 then
		entry.callback(...)
		return
	end

	local eventCount = Select("#", ...)
	if eventCount == 0 then
		CallNoEvent(entry)
	elseif eventCount == 1 then
		CallEvent1(entry, ...)
	elseif eventCount == 2 then
		CallEvent2(entry, ...)
	elseif eventCount == 3 then
		CallEvent3(entry, ...)
	elseif eventCount == 4 then
		CallEvent4(entry, ...)
	else
		local packed = TablePack(...)
		local n = packed.n

		local extraN = entry.argCount
		if extraN <= 4 then
			if extraN >= 1 then n += 1; packed[n] = entry.arg1 end
			if extraN >= 2 then n += 1; packed[n] = entry.arg2 end
			if extraN >= 3 then n += 1; packed[n] = entry.arg3 end
			if extraN >= 4 then n += 1; packed[n] = entry.arg4 end
		else
			local extra = entry.args
			TableMove(extra, 1, extra.n, n + 1, packed)
			n += extra.n
		end

		packed.n = n
		entry.callback(TableUnpack(packed, 1, n))
	end
end

local TimerHeap = {}

local function HeapSwap(i, j)
	local a = TimerHeap[i]
	local b = TimerHeap[j]
	TimerHeap[i] = b
	TimerHeap[j] = a
	a.heapIndex = j
	b.heapIndex = i
end

local function HeapSiftUp(i)
	while i > 1 do
		local p = i // 2
		if TimerHeap[p].dueTime <= TimerHeap[i].dueTime then
			return
		end
		HeapSwap(i, p)
		i = p
	end
end

local function HeapSiftDown(i)
	local n = #TimerHeap
	while true do
		local l = i * 2
		if l > n then
			return
		end

		local r = l + 1
		local c = l
		if r <= n and TimerHeap[r].dueTime < TimerHeap[l].dueTime then
			c = r
		end

		if TimerHeap[i].dueTime <= TimerHeap[c].dueTime then
			return
		end

		HeapSwap(i, c)
		i = c
	end
end

local function HeapPush(entry)
	local n = #TimerHeap + 1
	TimerHeap[n] = entry
	entry.heapIndex = n
	HeapSiftUp(n)
end

local function HeapPop()
	local n = #TimerHeap
	if n == 0 then
		return nil
	end

	local root = TimerHeap[1]
	local last = TimerHeap[n]
	TimerHeap[n] = nil

	if n > 1 then
		TimerHeap[1] = last
		last.heapIndex = 1
		HeapSiftDown(1)
	end

	root.heapIndex = nil
	return root
end

local function HeapRemove(entry)
	local index = entry.heapIndex
	if not index then
		return false
	end

	local n = #TimerHeap
	local last = TimerHeap[n]
	TimerHeap[n] = nil

	if index < n then
		TimerHeap[index] = last
		last.heapIndex = index

		local p = index // 2
		if p > 0 and TimerHeap[p].dueTime > last.dueTime then
			HeapSiftUp(index)
		else
			HeapSiftDown(index)
		end
	end

	entry.heapIndex = nil
	return true
end

local QueueHead = nil
local QueueTail = nil
local QueueCount = 0

local function RemoveFromQueue(entry)
	local prev = entry.prev
	local nextEntry = entry.next

	if prev then
		prev.next = nextEntry
	else
		QueueHead = nextEntry
	end

	if nextEntry then
		nextEntry.prev = prev
	else
		QueueTail = prev
	end

	entry.prev = nil
	entry.next = nil
end

local function RebuildLoopOrder(loop)
	TableClear(loop.priorityOrder)
	for priority in Pairs(loop.buckets) do
		loop.priorityOrder[#loop.priorityOrder + 1] = priority
	end
	TableSort(loop.priorityOrder)
	loop.dirty = false
end

local function RunLoopEvent1(loop, a1)
	if loop.dirty then
		RebuildLoopOrder(loop)
	end

	local buckets = loop.buckets
	local order = loop.priorityOrder
	local usePcall = ProtectedCalls
	local errHandler = ErrorHandler

	for o = 1, #order do
		local priority = order[o]
		local bucket = buckets[priority]
		if bucket then
			local i = 1
			while i <= #bucket do
				local entry = bucket[i]
				if entry.active == false or entry.paused then
					i += 1
				else
					if usePcall then
						local ok, err = PCall(CallEvent1, entry, a1)
						if not ok then
							errHandler(loop.name, entry.name, err)
						end
					else
						CallEvent1(entry, a1)
					end

					if bucket[i] == entry then
						i += 1
					end
				end
			end
		end
	end
end

local function RunLoopEvent2(loop, a1, a2)
	if loop.dirty then
		RebuildLoopOrder(loop)
	end

	local buckets = loop.buckets
	local order = loop.priorityOrder
	local usePcall = ProtectedCalls
	local errHandler = ErrorHandler

	for o = 1, #order do
		local priority = order[o]
		local bucket = buckets[priority]
		if bucket then
			local i = 1
			while i <= #bucket do
				local entry = bucket[i]
				if entry.active == false or entry.paused then
					i += 1
				else
					if usePcall then
						local ok, err = PCall(CallEvent2, entry, a1, a2)
						if not ok then
							errHandler(loop.name, entry.name, err)
						end
					else
						CallEvent2(entry, a1, a2)
					end

					if bucket[i] == entry then
						i += 1
					end
				end
			end
		end
	end
end

local function MaybeDisconnectHeartbeat()
	local loop = Loops.heartbeat
	if not loop then
		return
	end

	if loop.connection and loop.repeatCount == 0 and QueueCount == 0 and #TimerHeap == 0 then
		loop.connection:Disconnect()
		loop.connection = nil
	end
end

local function MaybeDisconnectLoop(loop)
	if loop.name == "heartbeat" then
		return
	end

	if loop.connection and loop.repeatCount == 0 then
		loop.connection:Disconnect()
		loop.connection = nil
	end
end

local function EnsureLoop(stepName)
	local loop = Loops[stepName]
	if loop then
		return loop
	end

	local signal
	local eventArity = 1

	if stepName == "heartbeat" then
		signal = RunService.Heartbeat
	elseif stepName == "preSimulation" then
		signal = RunService.PreSimulation
	elseif stepName == "postSimulation" then
		signal = RunService.PostSimulation
	elseif stepName == "preAnimation" then
		signal = RunService.PreAnimation
	elseif stepName == "preRender" then
		signal = RunService.PreRender
	elseif stepName == "renderStepped" then
		signal = RunService.RenderStepped
	elseif stepName == "stepped" then
		signal = RunService.Stepped
		eventArity = 2
	else
		error(("unknown stepName: %s"):format(ToString(stepName)))
	end

	loop = {
		name = stepName,
		signal = signal,
		eventArity = eventArity,
		connection = nil,
		buckets = {},
		priorityOrder = {},
		dirty = false,
		repeatCount = 0,
	}

	Loops[stepName] = loop
	return loop
end

local function EnsureLoopConnection(loop)
	if loop.connection then
		return
	end

	if loop.name == "preRender" or loop.name == "renderStepped" then
		Assert(RunService:IsClient(), loop.name .. " is client-only")
	end

	if loop.name == "heartbeat" then
		loop.connection = loop.signal:Connect(function(dt)
			SchedulerNow = Now()
			local usePcall = ProtectedCalls
			local errHandler = ErrorHandler
			local budgetStart = SchedulerNow

			local timersProcessed = 0
			while timersProcessed < MaxTimersPerStep do
				local top = TimerHeap[1]
				if not top or top.dueTime > SchedulerNow then
					break
				end

				local timerEntry = HeapPop()

				if timerEntry.name and TasksByName[timerEntry.name] == timerEntry then
					TasksByName[timerEntry.name] = nil
				end

				if timerEntry.active ~= false then
					if usePcall then
						local ok, err = PCall(CallNoEvent, timerEntry)
						if not ok then
							errHandler("delay", timerEntry.name or "delay", err)
						end
					else
						CallNoEvent(timerEntry)
					end
				end

				timersProcessed += 1
				if MaxStepTime > 0 and (Now() - budgetStart) >= MaxStepTime then
					break
				end
			end

			local processed = 0
			while QueueHead and processed < MaxQueuePerStep do
				local entry = QueueHead
				QueueHead = entry.next
				if QueueHead then
					QueueHead.prev = nil
				else
					QueueTail = nil
				end

				entry.next = nil
				entry.prev = nil
				QueueCount -= 1

				if entry.name and TasksByName[entry.name] == entry then
					TasksByName[entry.name] = nil
				end

				if entry.active ~= false then
					if usePcall then
						local ok, err = PCall(CallNoEvent, entry)
						if not ok then
							errHandler("queue", entry.name or "queue", err)
						end
					else
						CallNoEvent(entry)
					end
				end

				processed += 1
				if MaxStepTime > 0 and (Now() - budgetStart) >= MaxStepTime then
					break
				end
			end

			RunLoopEvent1(loop, dt)
			MaybeDisconnectHeartbeat()
		end)

		return
	end

	if loop.eventArity == 2 then
		loop.connection = loop.signal:Connect(function(a1, a2)
			RunLoopEvent2(loop, a1, a2)
			MaybeDisconnectLoop(loop)
		end)
	else
		loop.connection = loop.signal:Connect(function(a1)
			RunLoopEvent1(loop, a1)
			MaybeDisconnectLoop(loop)
		end)
	end
end

local function RemoveFromBucket(entry)
	local loop = entry.loop
	local bucket = loop.buckets[entry.priority]
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
		loop.buckets[entry.priority] = nil
		loop.dirty = true
	end
end

local function StopInternal(name, entry)
	if not entry or entry.active == false then
		return
	end

	entry.active = false
	entry.paused = nil

	local kind = entry.kind

	if kind == "repeat" then
		RemoveFromBucket(entry)

		local loop = entry.loop
		loop.repeatCount -= 1

		if TasksByName[name] == entry then
			TasksByName[name] = nil
		end

		if loop.name == "heartbeat" then
			MaybeDisconnectHeartbeat()
		else
			MaybeDisconnectLoop(loop)
		end

		return
	end

	if kind == "queue" then
		RemoveFromQueue(entry)
		QueueCount -= 1

		if TasksByName[name] == entry then
			TasksByName[name] = nil
		end

		MaybeDisconnectHeartbeat()
		return
	end

	if kind == "timer" then
		HeapRemove(entry)

		if TasksByName[name] == entry then
			TasksByName[name] = nil
		end

		MaybeDisconnectHeartbeat()
		return
	end

	if kind == "connection" then
		if entry.connection then
			entry.connection:Disconnect()
			entry.connection = nil
		end

		if TasksByName[name] == entry then
			TasksByName[name] = nil
		end

		return
	end

	if kind == "renderBind" then
		RunService:UnbindFromRenderStep(entry.bindName)

		if TasksByName[name] == entry then
			TasksByName[name] = nil
		end

		return
	end

	if kind == "thread" then
		entry.cancelled = true

		if TasksByName[name] == entry then
			TasksByName[name] = nil
		end

		return
	end

	if kind == "loop" then
		if TasksByName[name] == entry then
			TasksByName[name] = nil
		end

		return
	end

	if kind == "signalWait" then
		if entry.connection then
			entry.connection:Disconnect()
			entry.connection = nil
		end

		if entry.timerEntry then
			HeapRemove(entry.timerEntry)
		end
		entry.timerEntry = nil

		if TasksByName[name] == entry then
			TasksByName[name] = nil
		end

		MaybeDisconnectHeartbeat()
		return
	end

	if kind == "hook" then
		if entry.original and entry.target then
			PCall(hookfunction, entry.target, entry.original)
		end

		if TasksByName[name] == entry then
			TasksByName[name] = nil
		end

		return
	end

	if kind == "hookMeta" then
		if entry.original and entry.object and entry.metamethod then
			PCall(hookmetamethod, entry.object, entry.metamethod, entry.original)
		end

		if TasksByName[name] == entry then
			TasksByName[name] = nil
		end

		return
	end

	if TasksByName[name] == entry then
		TasksByName[name] = nil
	end
end

-- Enables or disables pcall wrapping around all callback execution. When enabled, errors route to the error handler instead of crashing.
function TaskManager.SetProtectedCalls(enabled)
	ProtectedCalls = enabled == true
end

-- Sets per-frame limits for Heartbeat processing: max queued callbacks, time budget in seconds, and max due timers. Pass nil to leave a value unchanged.
function TaskManager.SetQueueLimits(maxPerStep, maxSeconds, maxTimersPerStep)
	if maxPerStep ~= nil then
		Assert(Type(maxPerStep) == "number", "maxPerStep must be number or nil")
		MaxQueuePerStep = maxPerStep
	end
	if maxSeconds ~= nil then
		Assert(Type(maxSeconds) == "number", "maxSeconds must be number or nil")
		MaxStepTime = maxSeconds
	end
	if maxTimersPerStep ~= nil then
		Assert(Type(maxTimersPerStep) == "number", "maxTimersPerStep must be number or nil")
		MaxTimersPerStep = maxTimersPerStep
	end
end

-- Sets a custom error handler function(kind, name, err) called when ProtectedCalls is on and a callback errors. Pass nil to restore the default handler.
function TaskManager.SetErrorHandler(handler)
	Assert(handler == nil or Type(handler) == "function", "handler must be function or nil")
	ErrorHandler = handler or DefaultErrorHandler
end

-- Overrides the clock function used for all timer and timeout calculations. Must return monotonically increasing seconds.
function TaskManager.SetClock(clockFn)
	Assert(Type(clockFn) == "function", "clockFn must be a function")
	Now = clockFn
end

-- Returns the internal entry table for a named task, or nil if not found.
function TaskManager.Get(name)
	return TasksByName[name]
end

-- Returns true if a task with the given name is currently registered.
function TaskManager.Exists(name)
	return TasksByName[name] ~= nil
end

-- Permanently stops and removes a named task, disconnecting connections and cleaning up all internal state.
function TaskManager.Stop(name)
	local entry = TasksByName[name]
	if entry then
		StopInternal(name, entry)
	end
end

-- Stops and removes every registered named task.
function TaskManager.StopAll()
	local names = {}
	for name in Pairs(TasksByName) do
		names[#names + 1] = name
	end
	for i = 1, #names do
		local n = names[i]
		local entry = TasksByName[n]
		if entry then
			StopInternal(n, entry)
		end
	end
end

-- Stops and removes all tasks whose name starts with the given prefix.
function TaskManager.StopPattern(prefix)
	Assert(Type(prefix) == "string" and prefix ~= "", "prefix must be a non-empty string")
	local prefixLen = #prefix

	local names = {}
	for name in Pairs(TasksByName) do
		if name:sub(1, prefixLen) == prefix then
			names[#names + 1] = name
		end
	end

	for i = 1, #names do
		local n = names[i]
		local entry = TasksByName[n]
		if entry then
			StopInternal(n, entry)
		end
	end
end

-- Returns an array of "name [kind]" strings for all active tasks. Paused tasks are marked with "(paused)".
function TaskManager.ListActive()
	local out = {}
	for name, entry in Pairs(TasksByName) do
		if entry.active ~= false then
			local suffix = entry.paused and " (paused)" or ""
			out[#out + 1] = name .. " [" .. entry.kind .. "]" .. suffix
		end
	end
	return out
end

-- Returns a snapshot table of scheduler statistics: task counts by kind, paused count, queue/timer counts, connection state, and limits.
function TaskManager.GetStats()
	local byKind = {}
	local total = 0
	local pausedCount = 0
	for _, entry in Pairs(TasksByName) do
		if entry.active ~= false then
			total += 1
			local k = entry.kind
			byKind[k] = (byKind[k] or 0) + 1
			if entry.paused then
				pausedCount += 1
			end
		end
	end

	local heartbeat = Loops.heartbeat
	return {
		ProtectedCalls = ProtectedCalls,
		TaskCount = total,
		PausedCount = pausedCount,
		ByKind = byKind,
		QueueCount = QueueCount,
		TimerCount = #TimerHeap,
		HeartbeatConnected = heartbeat and heartbeat.connection ~= nil or false,
		MaxQueuePerStep = MaxQueuePerStep,
		MaxTimersPerStep = MaxTimersPerStep,
		MaxStepTime = MaxStepTime,
	}
end

-- Replaces the stored extra arguments on an existing task without stopping it. Returns true on success.
function TaskManager.UpdateArgs(name, ...)
	local entry = TasksByName[name]
	if not entry or entry.active == false then
		return false
	end

	local kind = entry.kind
	if kind == "repeat" or kind == "queue" or kind == "timer" or kind == "thread" or kind == "connection" or kind == "renderBind" then
		SetArgs(entry, ...)
		return true
	end

	return false
end

-- Moves an existing repeat task to a different priority bucket without stopping it. Returns true on success.
function TaskManager.UpdatePriority(name, newPriority)
	AssertName(name)
	Assert(Type(newPriority) == "number", "newPriority must be number")

	local entry = TasksByName[name]
	if not entry or entry.active == false or entry.kind ~= "repeat" then
		return false
	end

	local loop = entry.loop

	RemoveFromBucket(entry)

	entry.priority = newPriority
	local bucket = loop.buckets[newPriority]
	if not bucket then
		bucket = {}
		loop.buckets[newPriority] = bucket
		loop.dirty = true
	end

	local idx = #bucket + 1
	bucket[idx] = entry
	entry.bucketIndex = idx

	return true
end

-- Pauses a named task so its callback is skipped each frame. The task stays registered with its priority and args intact.
function TaskManager.Pause(name)
	local entry = TasksByName[name]
	if entry and entry.active ~= false then
		entry.paused = true
	end
end

-- Resumes a previously paused task so its callback executes again.
function TaskManager.Resume(name)
	local entry = TasksByName[name]
	if entry and entry.active ~= false then
		entry.paused = nil
	end
end

-- Toggles a task between paused and running.
function TaskManager.Toggle(name)
	local entry = TasksByName[name]
	if entry and entry.active ~= false then
		if entry.paused then
			entry.paused = nil
		else
			entry.paused = true
		end
	end
end

-- Returns true if the named task exists and is currently paused.
function TaskManager.IsPaused(name)
	local entry = TasksByName[name]
	return entry ~= nil and entry.paused == true
end

-- Pauses all tasks whose name starts with the given prefix.
function TaskManager.PausePattern(prefix)
	Assert(Type(prefix) == "string" and prefix ~= "", "prefix must be a non-empty string")
	local prefixLen = #prefix
	for name, entry in Pairs(TasksByName) do
		if name:sub(1, prefixLen) == prefix and entry.active ~= false then
			entry.paused = true
		end
	end
end

-- Resumes all tasks whose name starts with the given prefix.
function TaskManager.ResumePattern(prefix)
	Assert(Type(prefix) == "string" and prefix ~= "", "prefix must be a non-empty string")
	local prefixLen = #prefix
	for name, entry in Pairs(TasksByName) do
		if name:sub(1, prefixLen) == prefix and entry.active ~= false then
			entry.paused = nil
		end
	end
end

-- Connects a callback to an RBXScriptSignal by name. Stored args are appended after the signal's emitted args on every fire.
function TaskManager.Signal(name, signalLike, callback, ...)
	AssertName(name)
	AssertSignal(signalLike)
	AssertCallback(callback)

	TaskManager.Stop(name)

	local entry = {
		kind = "connection",
		name = name,
		connection = nil,
		callback = callback,
		active = true,
		argCount = 0,
	}

	SetArgs(entry, ...)

	entry.connection = signalLike:Connect(function(...)
		if entry.active == false or entry.paused then
			return
		end

		if ProtectedCalls then
			local ok, err = PCall(CallSignal, entry, ...)
			if not ok then
				ErrorHandler("Signal", name, err)
			end
		else
			CallSignal(entry, ...)
		end
	end)

	TasksByName[name] = entry
	return entry
end

-- Connects a callback to an RBXScriptSignal that auto-disconnects after firing once. Stored args are appended after the signal's emitted args.
function TaskManager.Once(name, signalLike, callback, ...)
	AssertName(name)
	AssertSignal(signalLike)
	AssertCallback(callback)

	TaskManager.Stop(name)

	local entry = {
		kind = "connection",
		name = name,
		connection = nil,
		callback = callback,
		active = true,
		argCount = 0,
	}

	SetArgs(entry, ...)

	entry.connection = signalLike:Connect(function(...)
		if entry.active == false then
			return
		end

		TaskManager.Stop(name)

		if ProtectedCalls then
			local ok, err = PCall(CallSignal, entry, ...)
			if not ok then
				ErrorHandler("Once", name, err)
			end
		else
			CallSignal(entry, ...)
		end
	end)

	TasksByName[name] = entry
	return entry
end

-- Waits for a signal once within timeoutSeconds. Fires callback on signal or timeoutCallback on timeout.
function TaskManager.OnceTimeout(name, signalLike, timeoutSeconds, callback, timeoutCallback, ...)
	AssertName(name)
	AssertSignal(signalLike)
	Assert(Type(timeoutSeconds) == "number", "timeoutSeconds must be number")
	AssertCallback(callback)

	TaskManager.Stop(name)

	local entry = {
		kind = "signalWait",
		name = name,
		connection = nil,
		timerEntry = nil,
		callback = callback,
		active = true,
		argCount = 0,
	}

	SetArgs(entry, ...)

	local function OnTimeout()
		if entry.active == false then
			return
		end

		TaskManager.Stop(name)

		if timeoutCallback then
			if ProtectedCalls then
				local ok, err = PCall(timeoutCallback)
				if not ok then
					ErrorHandler("OnceTimeout", name, err)
				end
			else
				timeoutCallback()
			end
		end
	end

	local timerEntry = {
		kind = "timerInternal",
		name = nil,
		callback = OnTimeout,
		active = true,
		dueTime = Now() + timeoutSeconds,
		argCount = 0,
	}

	entry.timerEntry = timerEntry
	HeapPush(timerEntry)
	EnsureLoopConnection(EnsureLoop("heartbeat"))

	entry.connection = signalLike:Connect(function(...)
		if entry.active == false then
			return
		end

		TaskManager.Stop(name)

		if ProtectedCalls then
			local ok, err = PCall(CallSignal, entry, ...)
			if not ok then
				ErrorHandler("OnceTimeout", name, err)
			end
		else
			CallSignal(entry, ...)
		end
	end)

	TasksByName[name] = entry
	return entry
end

local function RegisterLoopTask(stepName, name, priorityLevel, callback, ...)
	AssertName(name)
	AssertCallback(callback)
	Assert(Type(priorityLevel) == "number", "priorityLevel must be number")

	TaskManager.Stop(name)

	local loop = EnsureLoop(stepName)
	EnsureLoopConnection(loop)

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
		active = true,
		argCount = 0,
	}

	SetArgs(entry, ...)

	local index = #bucket + 1
	bucket[index] = entry
	entry.bucketIndex = index

	loop.repeatCount += 1
	TasksByName[name] = entry

	return entry
end

-- Runs callback every Heartbeat at the given priority level. Lower numbers execute first. callback(dt, storedArgs...).
function TaskManager.Priority(name, priorityLevel, callback, ...)
	return RegisterLoopTask("heartbeat", name, priorityLevel, callback, ...)
end

-- Runs callback every Heartbeat at default priority 0. callback(dt, storedArgs...).
function TaskManager.Heartbeat(name, callback, ...)
	return RegisterLoopTask("heartbeat", name, 0, callback, ...)
end

-- Runs callback every PreSimulation step at the given priority. callback(dt, storedArgs...).
function TaskManager.PreSimulation(name, priorityLevel, callback, ...)
	return RegisterLoopTask("preSimulation", name, priorityLevel, callback, ...)
end

-- Runs callback every PostSimulation step at the given priority. callback(dt, storedArgs...).
function TaskManager.PostSimulation(name, priorityLevel, callback, ...)
	return RegisterLoopTask("postSimulation", name, priorityLevel, callback, ...)
end

-- Runs callback every PreAnimation step at the given priority. callback(dt, storedArgs...).
function TaskManager.PreAnimation(name, priorityLevel, callback, ...)
	return RegisterLoopTask("preAnimation", name, priorityLevel, callback, ...)
end

-- Runs callback every PreRender step at the given priority. Client-only. callback(dt, storedArgs...).
function TaskManager.PreRender(name, priorityLevel, callback, ...)
	return RegisterLoopTask("preRender", name, priorityLevel, callback, ...)
end

-- Runs callback every RenderStepped at the given priority. Client-only. callback(dt, storedArgs...).
function TaskManager.RenderStepped(name, priorityLevel, callback, ...)
	return RegisterLoopTask("renderStepped", name, priorityLevel, callback, ...)
end

-- Runs callback every Stepped at the given priority. callback(time, deltaTime, storedArgs...).
function TaskManager.Stepped(name, priorityLevel, callback, ...)
	return RegisterLoopTask("stepped", name, priorityLevel, callback, ...)
end

-- Binds a callback to RunService:BindToRenderStep with the given render priority. Client-only. Stoppable and pausable by name.
function TaskManager.BindToRenderStep(name, renderPriority, callback, ...)
	AssertName(name)
	AssertCallback(callback)
	Assert(Type(renderPriority) == "number", "renderPriority must be number")
	Assert(RunService:IsClient(), "BindToRenderStep is client-only")

	TaskManager.Stop(name)

	local entry = {
		kind = "renderBind",
		name = name,
		bindName = name,
		callback = callback,
		active = true,
		argCount = 0,
	}

	SetArgs(entry, ...)

	RunService:BindToRenderStep(name, renderPriority, function(dt)
		if entry.active == false or entry.paused then
			return
		end

		if ProtectedCalls then
			local ok, err = PCall(CallEvent1, entry, dt)
			if not ok then
				ErrorHandler("BindToRenderStep", name, err)
			end
		else
			CallEvent1(entry, dt)
		end
	end)

	TasksByName[name] = entry
	return entry
end

-- Adds a one-shot callback to the FIFO queue, processed during Heartbeat subject to queue limits.
function TaskManager.Queue(name, callback, ...)
	AssertName(name)
	AssertCallback(callback)

	TaskManager.Stop(name)

	local entry = {
		kind = "queue",
		name = name,
		callback = callback,
		prev = nil,
		next = nil,
		active = true,
		argCount = 0,
	}

	SetArgs(entry, ...)

	if QueueTail then
		QueueTail.next = entry
		entry.prev = QueueTail
		QueueTail = entry
	else
		QueueHead = entry
		QueueTail = entry
	end

	QueueCount += 1
	TasksByName[name] = entry

	EnsureLoopConnection(EnsureLoop("heartbeat"))
	return entry
end

-- Schedules a one-shot callback to fire after the given seconds, driven by the Heartbeat timer heap.
function TaskManager.Delay(name, seconds, callback, ...)
	AssertName(name)
	Assert(Type(seconds) == "number", "seconds must be number")
	AssertCallback(callback)

	TaskManager.Stop(name)

	local entry = {
		kind = "timer",
		name = name,
		dueTime = Now() + seconds,
		callback = callback,
		active = true,
		argCount = 0,
	}

	SetArgs(entry, ...)

	HeapPush(entry)
	TasksByName[name] = entry

	EnsureLoopConnection(EnsureLoop("heartbeat"))
	return entry
end

-- Schedules a callback via task.defer to run once on the next resumption cycle. Stoppable by name if it hasn't fired yet.
function TaskManager.Defer(name, callback, ...)
	AssertName(name)
	AssertCallback(callback)

	TaskManager.Stop(name)

	local entry = {
		kind = "thread",
		name = name,
		callback = callback,
		cancelled = false,
		active = true,
		argCount = 0,
	}

	SetArgs(entry, ...)

	TaskDefer(function()
		if entry.cancelled then
			return
		end
		if TasksByName[name] ~= entry then
			return
		end

		TasksByName[name] = nil

		if ProtectedCalls then
			local ok, err = PCall(CallNoEvent, entry)
			if not ok then
				ErrorHandler("Defer", name, err)
			end
		else
			CallNoEvent(entry)
		end
	end)

	TasksByName[name] = entry
	return entry
end

-- Spawns a persistent coroutine loop that calls callback every interval seconds. Interval <= 0 yields once per frame. Stoppable and pausable by name.
function TaskManager.Loop(name, interval, callback)
	AssertName(name)
	Assert(Type(interval) == "number", "interval must be a number")
	AssertCallback(callback)

	TaskManager.Stop(name)

	local entry = {
		kind = "loop",
		name = name,
		callback = callback,
		active = true,
	}

	TasksByName[name] = entry

	TaskSpawn(function()
		while entry.active do
			if not entry.paused then
				if ProtectedCalls then
					local ok, err = PCall(callback)
					if not ok then
						ErrorHandler("Loop", name, err)
					end
				else
					callback()
				end
			end

			if not entry.active then
				break
			end

			if interval > 0 then
				TaskWait(interval)
			else
				TaskWait()
			end
		end
	end)

	return entry
end

-- Polls a predicate each Heartbeat until it returns true or timeoutSeconds elapses. callback(true) on success, callback(false) on timeout. Pass nil timeout to wait forever.
function TaskManager.Condition(name, predicate, timeoutSeconds, callback)
	AssertName(name)
	AssertCallback(predicate)
	if timeoutSeconds ~= nil then
		Assert(Type(timeoutSeconds) == "number", "timeoutSeconds must be number or nil")
	end
	AssertCallback(callback)

	TaskManager.Stop(name)

	local dueTime = nil
	if timeoutSeconds ~= nil and timeoutSeconds > 0 then
		dueTime = Now() + timeoutSeconds
	end

	local entry
	entry = TaskManager.Priority(name, 0, function()
		if dueTime and SchedulerNow >= dueTime then
			TaskManager.Stop(name)
			callback(false)
			return
		end

		local ok, result
		if ProtectedCalls then
			ok, result = PCall(predicate)
			if not ok then
				TaskManager.Stop(name)
				ErrorHandler("Condition", name, result)
				return
			end
		else
			result = predicate()
		end

		if result then
			TaskManager.Stop(name)
			callback(true)
		end
	end)

	return entry
end

-- Yields the calling coroutine for the given seconds using the timer heap. Must be called from a coroutine.
function TaskManager.Sleep(seconds)
	Assert(Type(seconds) == "number", "seconds must be number")

	local thread = CoroutineRunning()
	if not thread then
		error("Sleep must be called from a coroutine")
	end

	local resumed = false
	local timerEntry = {
		kind = "timerInternal",
		name = nil,
		dueTime = Now() + seconds,
		callback = function()
			if resumed then
				return
			end
			resumed = true

			local ok, err = CoroutineResume(thread)
			if not ok then
				ErrorHandler("Sleep", "coroutine", err)
			end
		end,
		active = true,
		argCount = 0,
	}

	HeapPush(timerEntry)
	EnsureLoopConnection(EnsureLoop("heartbeat"))
	CoroutineYield()
end

-- Yields until the signal fires or timeoutSeconds elapses. Returns (true, signalArgs...) on fire, (false) on timeout. Must be called from a coroutine.
function TaskManager.AwaitSignal(signalLike, timeoutSeconds)
	AssertSignal(signalLike)
	if timeoutSeconds ~= nil then
		Assert(Type(timeoutSeconds) == "number", "timeoutSeconds must be number or nil")
	end

	local thread = CoroutineRunning()
	if not thread then
		error("AwaitSignal must be called from a coroutine")
	end

	local done = false
	local connection = nil
	local timerEntry = nil

	local function Finish(success, ...)
		if done then
			return
		end
		done = true

		if connection then
			connection:Disconnect()
			connection = nil
		end

		if timerEntry then
			HeapRemove(timerEntry)
			timerEntry = nil
		end

		local ok, err = CoroutineResume(thread, success, ...)
		if not ok then
			ErrorHandler("AwaitSignal", "coroutine", err)
		end
	end

	connection = signalLike:Connect(function(...)
		Finish(true, ...)
	end)

	if timeoutSeconds and timeoutSeconds > 0 then
		timerEntry = {
			kind = "timerInternal",
			name = nil,
			dueTime = Now() + timeoutSeconds,
			callback = function()
				Finish(false)
			end,
			active = true,
			argCount = 0,
		}

		HeapPush(timerEntry)
		EnsureLoopConnection(EnsureLoop("heartbeat"))
	end

	return CoroutineYield()
end

-- Yields until any signal in the array fires or timeoutSeconds elapses. Returns (true, index, signalArgs...) on fire, (false, nil) on timeout. Must be called from a coroutine.
function TaskManager.AwaitAny(signals, timeoutSeconds)
	Assert(Type(signals) == "table" and #signals > 0, "signals must be a non-empty table of RBXScriptSignals")
	for i = 1, #signals do
		AssertSignal(signals[i])
	end

	if timeoutSeconds ~= nil then
		Assert(Type(timeoutSeconds) == "number", "timeoutSeconds must be number or nil")
	end

	local thread = CoroutineRunning()
	if not thread then
		error("AwaitAny must be called from a coroutine")
	end

	local done = false
	local connections = {}
	local timerEntry = nil

	local function Finish(success, index, ...)
		if done then
			return
		end
		done = true

		for j = 1, #connections do
			connections[j]:Disconnect()
		end

		if timerEntry then
			HeapRemove(timerEntry)
			timerEntry = nil
		end

		local ok, err = CoroutineResume(thread, success, index, ...)
		if not ok then
			ErrorHandler("AwaitAny", "coroutine", err)
		end
	end

	for i = 1, #signals do
		connections[i] = signals[i]:Connect(function(...)
			Finish(true, i, ...)
		end)
	end

	if timeoutSeconds and timeoutSeconds > 0 then
		timerEntry = {
			kind = "timerInternal",
			name = nil,
			dueTime = Now() + timeoutSeconds,
			callback = function()
				Finish(false, nil)
			end,
			active = true,
			argCount = 0,
		}

		HeapPush(timerEntry)
		EnsureLoopConnection(EnsureLoop("heartbeat"))
	end

	return CoroutineYield()
end

-- Hooks targetFunction with replacementFunction via hookfunction/newcclosure. Returns the original function. Stop(name) restores it.
function TaskManager.Hook(name, targetFunction, replacementFunction)
	AssertName(name)

	TaskManager.Stop(name)

	local original = hookfunction(targetFunction, newcclosure(replacementFunction))
	local entry = {
		kind = "hook",
		name = name,
		original = original,
		target = targetFunction,
		active = true,
	}

	TasksByName[name] = entry
	return original, entry
end

-- Hooks a metamethod on the given object via hookmetamethod/newcclosure. Returns the original. Stop(name) restores it.
function TaskManager.HookMetamethod(name, object, metamethod, handler)
	AssertName(name)

	TaskManager.Stop(name)

	local original = hookmetamethod(object, metamethod, newcclosure(handler))
	local entry = {
		kind = "hookMeta",
		name = name,
		original = original,
		object = object,
		metamethod = metamethod,
		active = true,
	}

	TasksByName[name] = entry
	return original, entry
end

getgenv().taskManager = TaskManager
return TaskManager
