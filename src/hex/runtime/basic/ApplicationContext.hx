package hex.runtime.basic;

import hex.core.AbstractApplicationContext;
import hex.core.IApplicationContext;
import hex.di.IBasicInjector;
import hex.di.IDependencyInjector;
import hex.domain.ApplicationDomainDispatcher;
import hex.domain.Domain;
import hex.domain.DomainUtil;
import hex.event.IDispatcher;
import hex.event.MessageType;
import hex.ioc.core.CoreFactory;
import hex.log.DomainLogger;
import hex.log.ILogger;

/**
 * ...
 * @author Francis Bourre
 */
class ApplicationContext extends AbstractApplicationContext
{
	var _dispatcher 			: IDispatcher<{}>;
	
	override public function dispatch( messageType : MessageType, ?data : Array<Dynamic> ) : Void
	{
		this._dispatcher.dispatch( messageType, data );
	}

	
	@:allow( hex.runtime )
	function new( applicationContextName : String )
	{
		//build contextDispatcher
		var domain = DomainUtil.getDomain( applicationContextName, Domain );
		this._dispatcher = ApplicationDomainDispatcher.getInstance().getDomainDispatcher( domain );
		
		//build injector
		var injector : IDependencyInjector = cast Type.createInstance( Type.resolveClass( 'hex.di.Injector' ), [] );
		injector.mapToValue( IBasicInjector, injector );
		injector.mapToValue( IDependencyInjector, injector );
		
		var logger = new DomainLogger( domain );
		injector.mapToValue( ILogger, logger );
		
		//build coreFactory
		var coreFactory = new CoreFactory( injector, annotationProvider );
		
		//register applicationContext
		injector.mapToValue( IApplicationContext, this );
		coreFactory.register( applicationContextName, this );
		
		super( coreFactory, applicationContextName );
		
		coreFactory.getInjector().mapClassNameToValue( "hex.event.IDispatcher<{}>", this._dispatcher );
		this._initStateMachine();
	}
	
	override public function dispose() : Void
	{
		
	}
}