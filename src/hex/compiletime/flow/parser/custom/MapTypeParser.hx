package hex.compiletime.flow.parser.custom;

#if macro
import haxe.macro.*;
import hex.compiletime.flow.parser.ExpressionParser;
import hex.core.ContextTypeList;
import hex.vo.ConstructorVO;

using hex.error.Error;

/**
 * ...
 * @author Francis Bourre
 */
class MapTypeParser 
{
	/** @private */ function new() throw new PrivateConstructorException();
	static var logger = hex.log.LogManager.LogManager.getLoggerByClass( MapTypeParser );
	
	public static function parse( parser : ExpressionParser, constructorVO : ConstructorVO, params : Array<Expr>, expr : Expr ) : ConstructorVO
	{
		if ( params.length < 2 )
		{
			Context.error( 'Invalid number of arguments', Context.currentPos() );
		}
		
		switch( params[1].expr )
		{
			case EArrayDecl( values ):
				constructorVO.mapTypes = values.map( function( e ) return switch( e.expr ) 
				{ 
					case EConst(CString( mapType )) : mapType; 
					case _: "";
				} );
				
			case wtf:
				logger.error( wtf );
		}
		
		constructorVO.filePosition = expr.pos;
		return parser.parseType( parser, constructorVO, params[0] );
	}
}
#end