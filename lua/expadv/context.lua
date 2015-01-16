/* --- --------------------------------------------------------------------------------
	@: Create A Context object
   --- */

EXPADV.RootContext = { __deph = 0 }

EXPADV.RootContext.__index = EXPADV.RootContext

/* --- --------------------------------------------------------------------------------
	@: A few things that we need local.
   --- */

pcall = pcall
setmetatable = setmetatable

/* --- --------------------------------------------------------------------------------
	@: Now we need a way to build this object
   --- */
   
-- Builds a new context from a compilers instance.
function EXPADV.BuildNewContext( Instance, Player, Entity ) -- Table, Player, Entity
	local Context = setmetatable( { player = Player, entity = Entity, Online = false }, EXPADV.RootContext )

	Context.Trigger = { }
	Context.Changed = { }

	Context.Memory = {  }
	Context.Delta = {  }

	Context.Data = { }
	Context.Definitions = { }
	
	Context.Cells = Instance.Cells or { }
	Context.OutClick = Instance.OutClick or { }
	Context.Strings = Instance.Strings or { }
	Context.Traces = Instance.Traces or { }
	Context.Instructions = Instance.VMInstructions or { }
	Context.Enviroment = Instance.Enviroment or error( "No safe guard.", 0 )

	Context.Status = {
		Perf = 0,
		Counter = 0,
		StopWatch = 0,
		Memory = 0,
	}

	return Context
end

/* --- --------------------------------------------------------------------------------
	@: Executeion
   --- */

EXPADV.Updates = { }

local SysTime = SysTime
local debug_sethook = debug.sethook

-- Safely execute a function on this context.
function EXPADV.RootContext:Execute( Location, Operation, ... ) -- String, Function, ...
	
	local Status = self.Status

	-- Ops monitoring:

		local function op_counter( )
			Status.Perf = Status.Perf + expadv_luahook
			if Status.Perf > expadv_tickquota then
				debug.sethook( )
				error( { Trace = {0,0}, Quota = true, Msg = Message, Context = Context }, 0 )
			end

			Status.BenchMark = SysTime( )
		end

		Status.MemoryMark = collectgarbage("count")
		Status.BenchMark = SysTime( )
		
		debug_sethook( op_counter, "", expadv_luahook )

	-- Execuiton:

		local Ok, Result, ResultType = pcall( Operation, Instance or self, ... )

	-- Reset Ops Monitor
		debug.sethook( )

		Status.StopWatch = Status.StopWatch + (SysTime( ) - Status.BenchMark)
		Status.Memory = Status.Memory + (collectgarbage("count") - Status.MemoryMark)

	if !Ok and isstring( Result ) then
		if IsValid( self.entity ) then -- This is the only way, :(
			if Result:find("attempt to perform arithmetic on a nil value") then
				Result = "attempt to perform arithmetic on void"
			elseif Result:find("attempt to index a nil value") then
				Result = "attempt to reach void"
			elseif Result:find("attempt to call a nil value") then
				Result = "attempt to call void"
			end 

			self.entity:ScriptError( Result )
		end
		
		self:ShutDown( )

		return false
	end

	if Ok or Result.Exit then

		if (Status.Counter + Status.Perf - expadv_softquota) > expadv_hardquota then

			if IsValid( self.entity ) then self.entity:HitHardQuota( ) end
			
			self:ShutDown( )

			return false

		elseif Status.Memory > expadv_memorylimit then
			self.entity:ScriptError( "Memory limit exceeded" )

			self:ShutDown( )

			return false
		end

		EXPADV.Updates[self] = true

		return true, Result, ResultType

	end

	if !IsValid( self.entity ) then
		-- Do nothing :P
	elseif Result.Quota then
		self.entity:HitTickQuota( )
	elseif Result.Script then
		self.entity:ScriptError( Result )
	elseif Result.Exception then
		self.entity:Exception( Result )
	end

	self:ShutDown( )

	return false
end

/* --- --------------------------------------------------------------------------------
	@: Breakouts
   --- */

-- Exits the currently executing code.
function EXPADV.RootContext:Exit( )
	error( { Exit = true, Context = self }, 0 )
end

-- Throws an exception
function EXPADV.RootContext:Throw( Trace, Name, Message ) -- Table, String, String
	error( { Trace = Trace, Exception = Name, Msg = Message, Context = self }, 0 )
end

-- Throws a script error, and shuts down the context.
function EXPADV.RootContext:ScriptError( Trace, Message ) -- Table, String
	error( { Trace = Trace, Script = true, Msg = Message, Context = self }, 0 )
end

/* --- --------------------------------------------------------------------------------
	@: Staring / Stopping
   --- */

-- Runs the root execution of the code.
function EXPADV.RootContext:StartUp( Execution ) -- Function
	self.Online = true

	EXPADV.RegisterContext( self )

	EXPADV.CallHook( "StartUp", self )

	if IsValid( self.entity ) then self.entity:StartUp( ) end

	return self:Execute( "Root", Execution, self )
end

-- Shuts down the context and execution.
function EXPADV.RootContext:ShutDown( )
	if !self.Online then return end

	self.Online = false

	EXPADV.UnregisterContext( self )

	EXPADV.CallHook( "ShutDown", self )

	if IsValid( self.entity ) then self.entity:ShutDown( ) end
end

/* --- --------------------------------------------------------------------------------
	@: Context registery.
--- */
   
local Registery = EXPADV.CONTEXT_REGISTERY or { }

EXPADV.CONTEXT_REGISTERY = Registery

function EXPADV.RegisterContext( Context )
	Registery[Context] = Context

	EXPADV.CallHook( "RegisterContext", Context )
end

function EXPADV.UnregisterContext( Context )
	Registery[Context] = nil

	EXPADV.CallHook( "UnregisterContext", Context )
end

/* --- --------------------------------------------------------------------------------
	@: Context Updating.
   --- */

hook.Add( "Tick", "ExpAdv2.Update", function( )
	for Context, _ in pairs( EXPADV.Updates ) do
		if !IsValid( Context.entity ) then continue end

		local Ok, Msg = pcall( Context.entity.UpdateTick, Context.entity )

		if !Ok then
			Context.entity:LuaError( Msg )
			Context:ShutDown( )
		end
	end

	EXPADV.Updates = { }
end )

/* --- --------------------------------------------------------------------------------
	@: Context Monitoring.
   --- */

EXPADV_STATE_COMPILE = -1
EXPADV_STATE_OFFLINE = 0
EXPADV_STATE_ONLINE = 1
EXPADV_STATE_ALERT = 2
EXPADV_STATE_CRASHED = 3
EXPADV_STATE_BURNED = 4


hook.Add( "Tick", "ExpAdv2.Performance", function( )
	for Context, _ in pairs( EXPADV.CONTEXT_REGISTERY ) do
		if !Context.Online then continue end

		local status = Context.Status

		local Counter = status.Counter or 0

		Counter = Counter + status.Perf - expadv_softquota
		
		if Counter < 0 then Counter = 0 end

		status.Counter = Counter

		if IsValid(Context.entity) and Context.entity.CalculateOps then
			if Context.entity.CalculateOps(Context.entity, Context) then continue end
		end

		status.Perf = 0
		status.Memory = 0
		status.StopWatch = 0
	end
end )

/* --- --------------------------------------------------------------------------------
	@: Reloading.
   --- */

hook.Add( "Expadv.UnloadCore", "expadv.context", function( )
	for Context, _ in pairs( Registery ) do
		Context:ShutDown( )
	end
end )