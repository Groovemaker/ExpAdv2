/* --- --------------------------------------------------------------------------------
	@: Create A Base Compoent
   --- */

EXPADV.EXPADV_BaseComponent = { Default_Enabled = false }

EXPADV.EXPADV_BaseComponent.__index = EXPADV.EXPADV_BaseComponent

local BaseComponent = EXPADV.EXPADV_BaseComponent

/* --- --------------------------------------------------------------------------------
	@: Class Support
   --- */

-- Define and create a new class (on the component), this returns the classes module.
function BaseComponent:AddClass( Name, Short ) -- String, String
	return EXPADV.AddClass( self, Name, Short )
end

/* --- --------------------------------------------------------------------------------
	@: Operator Support
   --- */

-- Creates a new inline operator (on the component).
function BaseComponent:AddInlineOperator( Name, Input, Return, Inline ) -- String, String, String, String
	return EXPADV.AddInlineOperator( self, Name, Input, Return, Inline )
end

-- Creates a new prepared operator (on the component), with optional inline.
function BaseComponent:AddPreparedOperator( Name, Input, Return, Prepare, Inline ) -- String, String, String, String, String
	return EXPADV.AddPreparedOperator( self, Name, Input, Return, Prepare, Inline )
end

-- Creates a new virtual operator (on the component).
function BaseComponent:AddVMOperator( Name, Input, Return, Function ) -- String, String, String, function( Context, Trace, ... )
	return EXPADV.AddVMOperator( self, Name, Input, Return, Function )
end

-- Creates a new generated operator (on the component).
function BaseComponent:AddGeneratedOperator( Name, Input, Return, Function ) -- String, String, String, function( Context, Trace, ... )
	return EXPADV.AddGeneratedOperator( self, Name, Input, Return, Function )
end

/* --- --------------------------------------------------------------------------------
	@: Function Support
   --- */

-- Creates a new inline function (on the component).
function BaseComponent:AddInlineFunction( Name, Input, Return, Inline ) -- String, String, String, String
	return EXPADV.AddInlineFunction( self, Name, Input, Return, Inline )
end

-- Creates a new prepared function (on the component), with optional inline.
function BaseComponent:AddPreparedFunction( Name, Input, Return, Prepare, Inline ) -- String, String, String, String, String
	return EXPADV.AddPreparedFunction( self, Name, Input, Return, Prepare, Inline )
end

-- Creates a new virtual function (on the component).
function BaseComponent:AddVMFunction( Name, Input, Return, Function ) -- String, String, String, function( Context, Trace, ... )
	return EXPADV.AddVMFunction( self, Name, Input, Return, Function )
end

-- Creates a new generated function (on the component).
function BaseComponent:AddGeneratedFunction( Name, Input, Return, Function ) -- String, String, String, function( Context, Trace, ... )
	return EXPADV.AddGeneratedFunction( self, Name, Input, Return, Function )
end

/* --- --------------------------------------------------------------------------------
	@: Function Helper Data
   --- */

-- Creates a helper entry for a function on the component.
function BaseComponent:AddFunctionHelper( Name, Input, Description ) -- String, String, String
	return EXPADV.AddFunctionHelper( self, Name, Input, Description )
end

/* --- --------------------------------------------------------------------------------
	@: Exceptions
   --- */

-- Registers a new exception type on this component.
function BaseComponent:AddException( Exception ) -- String
	EXPADV.AddException( self, Exception )
end

/* --- --------------------------------------------------------------------------------
	@: Events
   --- */

-- Registers a new event type on this component.
function BaseComponent:AddEvent( Name, Input, Return ) -- String, String, String
	EXPADV.AddEvent( self, Name, Input, Return )
end

/* --- --------------------------------------------------------------------------------
	@: Features
   --- */

-- Registers a new Feature on this component.
function BaseComponent:AddFeature( Name, Description, Icon ) -- String, String
	EXPADV.AddFeature( self, Name, Description, Icon )
end

/* --- --------------------------------------------------------------------------------
	@: Directives Support
   --- */

-- Registers a new Directive:
function BaseComponent:AddServerDirective( Name, Function ) -- String, String
	EXPADV.ServerDirective( self, Name, Function )
end

function BaseComponent:AddClientDirective( Name, Function ) -- String, String
	EXPADV.ClientDirective( self, Name, Function )
end

function BaseComponent:AddDirective( Name, Function ) -- String, String
	EXPADV.AddDirective( self, Name, Function )
end

/* --- --------------------------------------------------------------------------------
	@: Component Settings
   --- */

function BaseComponent:CreateSetting( Name, Default ) -- String, Obj
	local Config = EXPADV.Config.components[self.Name] or { }
	
	EXPADV.Config.components[self.Name] = Config
	
	Name = string.lower( Name )

	Config[ Name ] = Config[ Name ] or Default

	return Default
end

-- Reads a setting from the config.
function BaseComponent:ReadSetting( Name, Default ) -- String, Obj
	local Config = EXPADV.Config.components[self.Name] or { }
	
	EXPADV.Config.components[self.Name] = Config
	
	Name = string.lower( Name )

	return Config[ Name ] or Default
end

function BaseComponent:CreateUserSetting( Name, Default ) -- String, Obj
	if SERVER then return end

	local Config = EXPADV.CL_Settings.components[self.Name] or { }
	
	EXPADV.CL_Settings.components[self.Name] = Config
	
	Name = string.lower( Name )

	Config[ Name ] = Config[ Name ] or Default

	return Default
end

-- Reads a setting from the config.
function BaseComponent:ReadUserSetting( Name, Default ) -- String, Obj
	if SERVER then return Default end
	
	local Config = EXPADV.CL_Settings.components[self.Name] or { }
	
	EXPADV.CL_Settings.components[self.Name] = Config
	
	Name = string.lower( Name )

	return Config[ Name ] or Default
end

/* --- --------------------------------------------------------------------------------
	@: New Component
   --- */

local Temp_Components = { }

-- Registers and retruns a new component object.
function EXPADV.AddComponent( Name, Enabled ) -- String, Boolean
	local Component = setmetatable( { Name = Name, Default_Enabled = Enabled }, BaseComponent )

	Temp_Components[Name] = Component

	return Component
end

function EXPADV.GetComponent( Name ) -- String
	return Temp_Components[Name]
end

/* --- --------------------------------------------------------------------------------
	@: Load Components
   --- */

-- Internal function, you can call it, but your break everything.
function EXPADV.LoadComponents( )
	EXPADV.Components = { }

	local ConfigEnabled = EXPADV.Config.enabledcomponents

	for _, Component in pairs( Temp_Components ) do

		if ConfigEnabled[ Component.Name ] ~= nil then
			Component.Enabled = tobool( ConfigEnabled[ Component.Name ] )
		else
			Component.Enabled = Component.Default_Enabled or false
			ConfigEnabled[ Component.Name ] = Component.Enabled and 1 or 0
		end

		if !Component.Enabled then
			EXPADV.Msg( "Skipping component: " .. Component.Name )
			continue
		end

		EXPADV.Msg( "Registered component: " .. Component.Name )

		if Component.OnEnable then Component.OnEnable( ) end

		EXPADV.Components[ Component.Name ] = Component

		EXPADV.CallHook( "EnableComponent", Component )
	end

	EXPADV.CallHook( "PostLoadComponents" )
end