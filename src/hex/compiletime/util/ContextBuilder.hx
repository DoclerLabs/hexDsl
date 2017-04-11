package hex.compiletime.util;
import haxe.macro.Compiler;

#if macro
import haxe.macro.Expr.TypeDefinition;
import hex.core.IApplicationContext;
import hex.core.HashCodeFactory;
import hex.compiletime.util.ContextBuilder;

/**
 * ...
 * @author Francis Bourre
 */
class ContextBuilder 
{
	//Key is applicationContext name
	//Value is latest/updated iteration built for this application context's name
	static var _Iteration 			: Map<String, BuildIteration> = new Map();
	
	//Each application context owner got its own context builder
	static var _Map 				: Map<ApplicationContextOwner, ContextBuilder>;
	
	
	var _owner 						: ApplicationContextOwner;
	var _iteration 					: BuildIteration;

	public function new( owner : ApplicationContextOwner ) 
	{
		this._owner = owner;
		this._iteration = ContextBuilder._getContextIteration( owner.getApplicationContext().getName() );
	}
	
	static private function _getContextIteration( applicationContextName : String ) : BuildIteration
	{
		var contextIteration;
		
		if ( !ContextBuilder._Iteration.exists( applicationContextName ) )
		{
			var definition = ContextUtil.buildClassDefintion( applicationContextName + 0 );
			var iDefinition = ContextUtil.buildInterfaceDefintion( applicationContextName + 0 );
			contextIteration = { iteration: 0, definition: definition, iDefinition: iDefinition, contextName: applicationContextName, defined: false };
			ContextBuilder._Iteration.set( applicationContextName, contextIteration );
		}
		else
		{
			contextIteration = ContextBuilder._Iteration.get( applicationContextName );
			contextIteration.iteration++;
			contextIteration.definition = ContextUtil.updateClassDefintion( applicationContextName + contextIteration.iteration, contextIteration.definition );
			contextIteration.iDefinition = ContextUtil.extendInterfaceDefintion( applicationContextName + contextIteration.iteration, contextIteration.iDefinition );
		}

		return contextIteration;
	}
	
	static public function getInstance( owner : ApplicationContextOwner ) : ContextBuilder
	{
		if ( ContextBuilder._Map == null )
		{
			ContextBuilder._Map = new Map();
			haxe.macro.Context.onAfterTyping( ContextBuilder._onAfterTyping );
		}
		
		if ( !ContextBuilder._Map.exists( owner ) )
		{
			ContextBuilder._Map.set( owner, new ContextBuilder( owner ) );
		}
		
		return ContextBuilder._Map.get( owner );
	}
	
	//Each instance of the DSL is reprezented by a class property
	// The name of the property is the context ID.
	public function addField( fieldName : String, className : String ) : Void
	{
		var field = ContextUtil.buildInstanceField( fieldName, className );
		this._iteration.definition.fields.push( field );
	}
	
	public function instantiate()
	{
		return ContextUtil.instantiateContextDefinition( this._iteration.definition );
	}
	
	//For each DSL building iteration we add a new method that encapsulates all the building process
	public function buildFileExecution( fileName : String, e : haxe.macro.Expr ) : String
	{
		var methodName = 'm_' + haxe.crypto.Md5.encode( fileName );
		var contextExecution = ContextUtil.buildFileExecution( methodName, e );
		
		this._iteration.definition.fields.push( contextExecution.field );
		return methodName;
	}
	
	//This method return interface related to current DSL building iteration.
	//This interface extends the previous one tied to previous DSL building iteration.
	public function getType() : Null<haxe.macro.Expr.ComplexType>
	{
		var interfaceExpr = this._iteration.iDefinition;
		
		for ( field in this._iteration.definition.fields )
		{
			if ( field.name != 'new' )
			{
				switch( field.kind )
				{
					case FVar( t, e ):
						interfaceExpr.fields.push( { name: field.name, kind: FVar( t, e ), pos:haxe.macro.Context.currentPos(), access: [ APublic ] } );
						
					case FFun( f ):
						interfaceExpr.fields.push( { name: field.name, kind: FFun( {args: f.args, ret:macro:Void, expr:null, params:f.params} ), pos:haxe.macro.Context.currentPos(), access: [ APublic ] } );

					case _:
						haxe.macro.Context.error( 'field not handled here', haxe.macro.Context.currentPos() );
				}
				
			}
		}
		
		interfaceExpr.isExtern = false;
		haxe.macro.Context.defineType( interfaceExpr );

		haxe.macro.TypeTools.getClass( haxe.macro.Context.getType( 'hex.context.' + interfaceExpr.name ) ).fields.get();
		return haxe.macro.TypeTools.toComplexType( haxe.macro.Context.getType( 'hex.context.' + interfaceExpr.name ) );
	}
	
	//Build final class for each diffrent context name
	static function _onAfterTyping( types : Array<haxe.macro.Type.ModuleType> ) : Void
	{
		var iti = ContextBuilder._Iteration.keys();
		while ( iti.hasNext() )
		{
			var contextName = iti.next();
			var contextIteration = ContextBuilder._Iteration.get( contextName );
			
			if ( !contextIteration.defined )
			{
				contextIteration.defined = true;
				
				var td = ContextUtil.makeFinalClassDefintion( contextName, contextIteration.definition );
				haxe.macro.Context.defineType( td );
			}
		}
	}
}

typedef BuildIteration =
{
	var iteration 	: Int;
	var definition 	: TypeDefinition;
	var iDefinition : TypeDefinition;
	var contextName : String;
	var defined		: Bool;
}

typedef ApplicationContextOwner =
{
	function getApplicationContext() : IApplicationContext;
}
#end