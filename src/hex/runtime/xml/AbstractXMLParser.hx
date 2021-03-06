package hex.runtime.xml;

import hex.core.IApplicationContext;
import hex.parser.AbstractContextParser;
import hex.runtime.error.ParsingException;

using hex.error.Error;

/**
 * ...
 * @author Francis Bourre
 */
class AbstractXMLParser<RequestType> extends AbstractContextParser<Xml, RequestType>
{
	var _applicationContextName : String = 'applicationContext';
	var _isContextNameLocked 	: Bool = false;
	
	function new()
	{
		super();
	}
	
	@final
	public function getApplicationContext() : IApplicationContext
	{
		return this._applicationAssembler.getApplicationContext( this._applicationContextName, this._applicationContextDefaultClass );
	}
	
	@final
	override public function setContextData( data : Xml ) : Void
	{
		if ( data != null )
		{
			if ( Std.is( data, Xml ) )
			{
				this._contextData = data;
				this._findApplicationContextName( data );
				this._findApplicationContextClassName( data );
				
				var applicationContext = this._applicationAssembler.getApplicationContext( this._applicationContextName, this._applicationContextDefaultClass );
				this._builder = this._applicationAssembler.getFactory( this._factoryClass, applicationContext );
			}
			else
			{
				throw new IllegalArgumentException( "Context data is not an instance of Xml." );
			}
		}
		else
		{
			throw new NullPointerException( "Context data is null." );
		}
	}
	
	@final
	override public function setApplicationContextName( name : String, locked : Bool = false ) : Void
	{
		if ( !this._isContextNameLocked && name != null )
		{
			this._isContextNameLocked = locked;
			this._applicationContextName = name;
		}
		else
		{
			/*#if debug
			trace( "Warning: Application context cannot be set to '" + name + "' name. "
				+ " It's already locked previously to '" +  this._applicationContextName + "'" );
			#end*/
		}
	}
	
	function _findApplicationContextName( xml : Xml ) : Void
	{
		this.setApplicationContextName( xml.firstElement().get( "name" ) );
		if ( this._applicationContextName == null )
		{
			throw new ParsingException( "Fails to retrieve applicationContext name. Attribute 'name' is missing in the root node of your context." );
		}
	}
	
	function _findApplicationContextClassName( xml : Xml ) : Void
	{
		var applicationContextClassName = this._contextData.firstElement().get( "type" );

		if ( applicationContextClassName != null )
		{
			try
			{
				this._applicationContextDefaultClass = cast Type.resolveClass( applicationContextClassName ); 
			}
			catch ( error : Dynamic )
			{
				throw new ParsingException( "Fails to instantiate applicationContext class named '" + applicationContextClassName + "'." );
			}
		}
	}
}