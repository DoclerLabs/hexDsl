package hex.compiletime.util;

#if macro
import haxe.macro.Context;
import hex.core.ContextTypeList;
using tink.CoreApi;

/**
 * ...
 * @author Francis Bourre
 */
class ClassImportHelper
{
	static var _primType : Array<String> = [ContextTypeList.STRING,
											ContextTypeList.INT,
											ContextTypeList.UINT,
											ContextTypeList.FLOAT,
											ContextTypeList.BOOLEAN,
											ContextTypeList.NULL,
											ContextTypeList.OBJECT,
											ContextTypeList.XML,
											ContextTypeList.CLASS,
											ContextTypeList.FUNCTION,
											ContextTypeList.ARRAY];
													
	var _compiledClass : Array<String>;

	public function new() 
	{
		this._compiledClass = [];
	}
	
	public function forceCompilation( type : String ) : Bool
	{
		if ( type != null )
		{
			type = type.split( '<' )[ 0 ];
			
			if ( ClassImportHelper._primType.indexOf( type.split( '<' )[ 0 ] ) == -1 && this._compiledClass.indexOf( type ) == -1 )
			{
				this._compiledClass.push( type );
				try
				{
					Context.getType( type );
				}
				catch ( e : Dynamic )
				{
					if ( Std.is( e, TypedError ) )
					{
						Context.error( "Failed to get type '" + type + "': " + e.message, e.pos );
					}
					else
					{
						Context.error( "Failed to get type '" + type + "': " + e, Context.currentPos() );
					}
				}
				
				return true;
			}

			return false;
		}

		return false;
	}

	public function getClassFullyQualifiedNameFromStaticVariable( staticRef : String ) : String
	{
		var a = staticRef.split( "." );
		a.splice( a.length - 1, 1 );
		return a.join( "." );
	}

	public function includeStaticRef( staticRef : String ) : Bool
	{
		if ( staticRef != null )
		{
			this.forceCompilation( this.getClassFullyQualifiedNameFromStaticVariable( staticRef ) );
			return true;
		}
		else
		{
			return false;
		}
	}

	public function includeClass( arg : Dynamic ) : Bool
	{
		if ( arg.type == ContextTypeList.CLASS )
		{
			this.forceCompilation( arg.value );
			return true;
		}
		else
		{
			return false;
		}
	}
}
#end