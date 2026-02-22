-- TaskManager.lua
-- Named task scheduler for RunService steps, signals, deferred work, queued work, and timed callbacks.
--
-- Design goals:
-- - Single task per name (re-register replaces the old one).
-- - Minimal allocations in the hot paths (Heartbeat loops and repeat callbacks).
-- - Optional protected execution via pcall and a configurable error handler.
-- - Priority buckets for per-step repeat tasks.
-- - Min-heap for timers and a linked-list queue for queued callbacks.
--
-- Intended usage: Roblox Luau ModuleScript (require caching provides singleton behavior).

if getgenv().taskManager then return getgenv().taskManager end

local RunService = game:GetService("RunService")

--// Hot locals (reduces global lookups in tight loops)
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

-- Name -> entry
local TasksByName = {}

-- stepName -> loop object
local Loops = {}

-- Scheduler settings
local ProtectedCalls = true
local MaxQueuePerStep = math.huge
local MaxTimersPerStep = math.huge
local MaxStepTime = 0 -- seconds, 0 disables time budget

-- Updated once per Heartbeat before timers/queue/repeat work.
local SchedulerNow = 0

-- Error handler
local function DefaultErrorHandler(kind, name, err)
	Warn(("TaskManager %s '%s' error: %s"):format(ToString(kind), ToString(name), ToString(err)))
end

local ErrorHandler = DefaultErrorHandler

--////////////////////////////////////////////////////////////////////
-- Validation helpers
--////////////////////////////////////////////////////////////////////

local function AssertName(name: any)
	Assert(Type(name) == "string" and name ~= "", "name must be a non-empty string")
end

local function AssertCallback(callback: any)
	Assert(Type(callback) == "function", "callback must be a function")
end

local function AssertSignal(signalLike: any)
	Assert(Typeof(signalLike) == "RBXScriptSignal", "signalLike must be RBXScriptSignal")
end

--////////////////////////////////////////////////////////////////////
-- Arg storage (avoids table allocations for small argument counts)
--////////////////////////////////////////////////////////////////////

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

--////////////////////////////////////////////////////////////////////
-- Callback invocation helpers
-- entry.argCount is the count of stored args to append after event args.
--////////////////////////////////////////////////////////////////////

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

-- Used by Signal/Once/OnceTimeout to append stored args after an unknown number of signal args.
-- Fast path for 0..4 signal args; fallback allocates once if the signal fires with >4 args.
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
		-- Slow path: build one argument list so unpack happens once.
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

--////////////////////////////////////////////////////////////////////
-- Timer heap (min-heap by dueTime)
--////////////////////////////////////////////////////////////////////

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

--////////////////////////////////////////////////////////////////////
-- Queue (linked list)
--////////////////////////////////////////////////////////////////////

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

--////////////////////////////////////////////////////////////////////
-- Loop scheduling (RunService steps)
--////////////////////////////////////////////////////////////////////

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
				if entry.active == false then
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

					-- If entry removed itself during execution, bucket[i] now holds a different entry.
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
				if entry.active == false then
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

		buckets = {},          -- priority -> array of entries
		priorityOrder = {},    -- sorted list of priorities
		dirty = false,

		repeatCount = 0,       -- number of active repeat entries in this loop
	}

	Loops[stepName] = loop
	return loop
end

local function EnsureLoopConnection(loop)
	if loop.connection then
		return
	end

	-- Client-only steps
	if loop.name == "preRender" or loop.name == "renderStepped" then
		Assert(RunService:IsClient(), loop.name .. " is client-only")
	end

	-- Heartbeat is special: drives timers + queue + heartbeat repeat tasks.
	if loop.name == "heartbeat" then
		loop.connection = loop.signal:Connect(function(dt)
			SchedulerNow = Now()
			local usePcall = ProtectedCalls
			local errHandler = ErrorHandler
			local budgetStart = SchedulerNow

			-- Process due timers (bounded).
			local timersProcessed = 0
			while timersProcessed < MaxTimersPerStep do
				local top = TimerHeap[1]
				if not top or top.dueTime > SchedulerNow then
					break
				end

				local timerEntry = HeapPop()

				-- Remove by-name mapping only if it still points at this entry.
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

			-- Process queue work (bounded).
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

			-- Run heartbeat repeat tasks last.
			RunLoopEvent1(loop, dt)

			MaybeDisconnectHeartbeat()
		end)

		return
	end

	-- Non-heartbeat steps only run repeat tasks for that step.
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

--////////////////////////////////////////////////////////////////////
-- Stop logic
--////////////////////////////////////////////////////////////////////

local function StopInternal(name, entry)
	if not entry or entry.active == false then
		return
	end

	entry.active = false

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

--////////////////////////////////////////////////////////////////////
-- Public configuration
--////////////////////////////////////////////////////////////////////

-- TaskManager.SetProtectedCalls(enabled)
-- When enabled, callback execution is wrapped in pcall and routed to the current error handler.
function TaskManager.SetProtectedCalls(enabled)
	ProtectedCalls = enabled == true
end

-- TaskManager.SetQueueLimits(maxPerStep, maxSeconds, maxTimersPerStep)
-- Limits work processed inside Heartbeat:
-- - maxPerStep: maximum queued callbacks processed per Heartbeat (default math.huge)
-- - maxSeconds: time budget in seconds for (timers + queue) processing (default 0 = disabled)
-- - maxTimersPerStep: maximum due timers processed per Heartbeat (default math.huge)
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

-- TaskManager.SetErrorHandler(handler)
-- handler(kind, name, err) is called when ProtectedCalls is enabled and a callback errors.
function TaskManager.SetErrorHandler(handler)
	Assert(handler == nil or Type(handler) == "function", "handler must be function or nil")
	ErrorHandler = handler or DefaultErrorHandler
end

-- TaskManager.SetClock(clockFn)
-- Overrides the clock used for timers/timeouts. Must be monotonic increasing seconds.
function TaskManager.SetClock(clockFn)
	Assert(Type(clockFn) == "function", "clockFn must be a function")
	Now = clockFn
end

--////////////////////////////////////////////////////////////////////
-- Public lifecycle and querying
--////////////////////////////////////////////////////////////////////

-- TaskManager.Get(name) -> entry|nil
function TaskManager.Get(name)
	return TasksByName[name]
end

-- TaskManager.Exists(name) -> boolean
function TaskManager.Exists(name)
	return TasksByName[name] ~= nil
end

-- TaskManager.Stop(name)
-- Stops the named task if it exists.
function TaskManager.Stop(name)
	local entry = TasksByName[name]
	if entry then
		StopInternal(name, entry)
	end
end

-- TaskManager.StopAll()
-- Stops all registered named tasks.
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

-- TaskManager.StopPattern(prefix)
-- Stops all tasks whose name begins with prefix.
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

-- TaskManager.ListActive() -> {string}
-- Returns a list of "name [kind]" strings for active named tasks.
function TaskManager.ListActive()
	local out = {}
	for name, entry in Pairs(TasksByName) do
		if entry.active ~= false then
			out[#out + 1] = name .. " [" .. entry.kind .. "]"
		end
	end
	return out
end

-- TaskManager.GetStats() -> table
-- Lightweight introspection snapshot for debugging/perf monitoring.
function TaskManager.GetStats()
	local byKind = {}
	local total = 0
	for _, entry in Pairs(TasksByName) do
		if entry.active ~= false then
			total += 1
			local k = entry.kind
			byKind[k] = (byKind[k] or 0) + 1
		end
	end

	local heartbeat = Loops.heartbeat
	return {
		ProtectedCalls = ProtectedCalls,
		TaskCount = total,
		ByKind = byKind,
		QueueCount = QueueCount,
		TimerCount = #TimerHeap,
		HeartbeatConnected = heartbeat and heartbeat.connection ~= nil or false,
		MaxQueuePerStep = MaxQueuePerStep,
		MaxTimersPerStep = MaxTimersPerStep,
		MaxStepTime = MaxStepTime,
	}
end

-- TaskManager.UpdateArgs(name, ...) -> boolean
-- Updates stored args for supported task types (repeat/queue/timer/thread/connection/renderBind).
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

-- TaskManager.UpdatePriority(name, newPriority) -> boolean
-- Changes the priority of a repeat (RunService step) task in-place.
function TaskManager.UpdatePriority(name, newPriority)
	AssertName(name)
	Assert(Type(newPriority) == "number", "newPriority must be number")

	local entry = TasksByName[name]
	if not entry or entry.active == false or entry.kind ~= "repeat" then
		return false
	end

	local loop = entry.loop

	-- Remove from old bucket
	RemoveFromBucket(entry)

	-- Insert into new bucket
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

--////////////////////////////////////////////////////////////////////
-- Signals and one-shots
--////////////////////////////////////////////////////////////////////

-- TaskManager.Signal(name, signalLike, callback, ...)
-- Connects callback to a RBXScriptSignal.
-- Stored args (...) are appended after the signal's emitted args.
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
		if entry.active == false then
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

-- TaskManager.Once(name, signalLike, callback, ...)
-- Connects callback to a RBXScriptSignal and auto-disconnects after the first fire.
-- Stored args (...) are appended after the signal's emitted args.
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

		-- Stop first so re-entrancy doesn't double fire
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

-- TaskManager.OnceTimeout(name, signalLike, timeoutSeconds, callback, timeoutCallback, ...)
-- Waits for a signal once, but triggers timeoutCallback if timeoutSeconds elapses first.
-- If the signal fires, callback receives (signal args..., stored args...).
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

	-- Internal timer entry (not stored in TasksByName)
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

--////////////////////////////////////////////////////////////////////
-- Repeat tasks on RunService steps (priority buckets)
--////////////////////////////////////////////////////////////////////

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

-- TaskManager.Priority(name, priorityLevel, callback, ...)
-- Runs every Heartbeat in ascending priority order.
function TaskManager.Priority(name, priorityLevel, callback, ...)
	return RegisterLoopTask("heartbeat", name, priorityLevel, callback, ...)
end

-- TaskManager.Heartbeat(name, callback, ...)
-- Runs every Heartbeat at priority 0. callback(dt, storedArgs...)
function TaskManager.Heartbeat(name, callback, ...)
	return RegisterLoopTask("heartbeat", name, 0, callback, ...)
end

-- TaskManager.PreSimulation(name, priorityLevel, callback, ...)
function TaskManager.PreSimulation(name, priorityLevel, callback, ...)
	return RegisterLoopTask("preSimulation", name, priorityLevel, callback, ...)
end

-- TaskManager.PostSimulation(name, priorityLevel, callback, ...)
function TaskManager.PostSimulation(name, priorityLevel, callback, ...)
	return RegisterLoopTask("postSimulation", name, priorityLevel, callback, ...)
end

-- TaskManager.PreAnimation(name, priorityLevel, callback, ...)
function TaskManager.PreAnimation(name, priorityLevel, callback, ...)
	return RegisterLoopTask("preAnimation", name, priorityLevel, callback, ...)
end

-- TaskManager.PreRender(name, priorityLevel, callback, ...)
-- Client-only.
function TaskManager.PreRender(name, priorityLevel, callback, ...)
	return RegisterLoopTask("preRender", name, priorityLevel, callback, ...)
end

-- TaskManager.RenderStepped(name, priorityLevel, callback, ...)
-- Client-only.
function TaskManager.RenderStepped(name, priorityLevel, callback, ...)
	return RegisterLoopTask("renderStepped", name, priorityLevel, callback, ...)
end

-- TaskManager.Stepped(name, priorityLevel, callback, ...)
-- callback(time, deltaTime, storedArgs...)
function TaskManager.Stepped(name, priorityLevel, callback, ...)
	return RegisterLoopTask("stepped", name, priorityLevel, callback, ...)
end

--////////////////////////////////////////////////////////////////////
-- RenderStep binding
--////////////////////////////////////////////////////////////////////

-- TaskManager.BindToRenderStep(name, renderPriority, callback, ...)
-- Uses RunService:BindToRenderStep and can be stopped by name.
-- Client-only.
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
		if entry.active == false then
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

--////////////////////////////////////////////////////////////////////
-- Queue and timers (driven by Heartbeat)
--////////////////////////////////////////////////////////////////////

-- TaskManager.Queue(name, callback, ...)
-- Adds a callback to the queue, processed on Heartbeat.
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

-- TaskManager.Delay(name, seconds, callback, ...)
-- Schedules callback after seconds (driven by Heartbeat).
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

--////////////////////////////////////////////////////////////////////
-- Deferred/threaded work
--////////////////////////////////////////////////////////////////////

-- TaskManager.Defer(name, callback, ...)
-- Schedules callback via task.defer. Stop(name) cancels if it hasn't run yet.
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

-- TaskManager.Loop(name, interval, callback)
-- Spawns a coroutine loop. interval <= 0 yields once per cycle.
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
			if ProtectedCalls then
				local ok, err = PCall(callback)
				if not ok then
					ErrorHandler("Loop", name, err)
				end
			else
				callback()
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

--////////////////////////////////////////////////////////////////////
-- Condition helpers (runs predicate on Heartbeat until success/timeout)
--////////////////////////////////////////////////////////////////////

-- TaskManager.Condition(name, predicate, timeoutSeconds, callback)
-- Runs predicate each Heartbeat until it returns true or timeout expires.
-- callback(successBoolean)
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

--////////////////////////////////////////////////////////////////////
-- Coroutine utilities (Sleep / AwaitSignal / AwaitAny)
--////////////////////////////////////////////////////////////////////

-- TaskManager.Sleep(seconds)
-- Yields the current coroutine and resumes it after seconds (driven by Heartbeat).
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

-- TaskManager.AwaitSignal(signalLike, timeoutSeconds) -> success, ...
-- Yields until signal fires, or timeout expires.
-- Returns:
--   (true, signalArgs...) on signal
--   (false) on timeout
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

-- TaskManager.AwaitAny(signals, timeoutSeconds) -> success, index, ...
-- Yields until any signal fires, or timeout expires.
-- Returns:
--   (true, signalIndex, signalArgs...) on signal
--   (false, nil) on timeout
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

--////////////////////////////////////////////////////////////////////
-- Function hooking (executor environment)
--////////////////////////////////////////////////////////////////////

-- TaskManager.Hook(name, targetFunction, replacementFunction) -> original, entry
-- Hooks targetFunction with replacementFunction via hookfunction/newcclosure.
-- Stop(name) restores the original function.
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

-- TaskManager.HookMetamethod(name, object, metamethod, handler) -> original, entry
-- Hooks a metamethod on object via hookmetamethod/newcclosure.
-- Stop(name) restores the original metamethod.
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
