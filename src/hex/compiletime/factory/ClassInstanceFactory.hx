package hex.compiletime.factory;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.TypeTools;
import hex.compiletime.factory.ArgumentFactory;
import hex.util.MacroUtil;

using hex.error.Error;

/**
 * ...
 * @author Francis Bourre
 */
class ClassInstanceFactory
{
	/** @private */ function new() throw new PrivateConstructorException();

	static var _fqcn = MacroUtil.getFQCNFromExpression;
	static inline function _staticRefFactory( tp, staticRef, factoryMethod, args, position ) return macro @:pos(position) $p{ tp }.$staticRef.$factoryMethod( $a{ args } );
	static inline function _staticCallFactory( tp, staticCall, factoryMethod, args, staticArgs, position ) return macro @:pos(position) $p{ tp }.$staticCall( $a{ staticArgs } ).$factoryMethod( $a{ args } );
	static inline function _staticCall( tp, staticCall, args, position ) return macro @:pos(position) $p{ tp }.$staticCall( $a{ args } );
	static inline function _nullArray( length : UInt ) return  [ for ( i in 0...length ) macro null ];
	static inline function _varType( type, position ) return TypeTools.toComplexType( Context.typeof( Context.parseInlineString( '( null : ${type})', position ) ) );
	static inline function _blankType( vo ) { vo.cType = tink.macro.Positions.makeBlankType( vo.filePosition ); return MacroUtil.getFQCNFromComplexType( vo.cType ); }
	
	public static inline function getResult( e, id, vo ) 
	{
		return if ( vo.shouldAssign && !vo.lazy )
		{
			var t = vo.cType != null ? vo.cType : _varType( vo.type, vo.filePosition ); 
			macro @:pos( vo.filePosition ) var $id : $t = $e;
			
		} else e;
	}
	
	static public function build<T:hex.compiletime.basic.vo.FactoryVOTypeDef>( factoryVO : T ) : Expr
	{
		return _build( factoryVO, 
			function( typePath, args, id, vo )
			{
				var p = '';
				if ( typePath.pack.length != 0 )
				{
					p = typePath.pack.join('.') + '.';
				}

				var t =  Context.getType( p + typePath.name );
				switch( t )
				{
					case TInst( t, params ): if ( !t.get().constructor.get().isPublic ) 
						Context.error( 'WTF, you try to instantiate a class with a private constructor!', vo.filePosition );
					case _:
				}
				
				return getResult( macro @:pos(vo.filePosition) new $typePath( $a { args } ), id, vo );
			}
		);
	}
	
	static public function _build<T:hex.compiletime.basic.vo.FactoryVOTypeDef>( factoryVO : T, elseDo ) : Expr
	{
		var vo 				= factoryVO.constructorVO;
		var pos 			= vo.filePosition;
		var id 				= vo.ID;
		var args 			= ArgumentFactory.build( factoryVO, vo.arguments );
		var pack 			= MacroUtil.getPack( vo.className, pos );
		var typePath 		= MacroUtil.getTypePath( vo.className, pos );
		var staticCall 		= vo.staticCall;
		var staticArgs		= ArgumentFactory.build( factoryVO, vo.staticArgs );
		var factoryMethod 	= vo.factory;
		var staticRef 		= vo.staticRef;
		var classType 		= MacroUtil.getClassType( vo.className, pos );

		var result = //Assign result
		if ( factoryMethod != null )//factory method
		{
			//TODO implement the same behavior @runtime issue#1
			if ( staticRef != null )//static variable - with factory method
			{
				var e = _staticRefFactory( pack, staticRef, factoryMethod, args, pos );
				vo.type = vo.abstractType != null ? vo.abstractType : 
					try _fqcn( e ) catch ( e : Dynamic ) _blankType( vo );
				getResult( e, id, vo );
			}
			else if ( staticCall != null )//static method call - with factory method
			{
				var e = _staticCallFactory( pack, staticCall, factoryMethod, args, staticArgs, pos );
				vo.type = vo.abstractType != null ? vo.abstractType : 
					try _fqcn( e ) catch ( e : Dynamic ) _blankType( vo );
				
				getResult( e, id, vo );
			}
			else//factory method error
			{
				Context.error( 	"'" + factoryMethod + "' method cannot be called on '" +  vo.className + 
								"' class. Add static method or variable to make it working.", pos );
			}
		}
		else if ( staticCall != null )//simple static method call
		{
			var e = _staticCall( pack, staticCall, args, pos );
			vo.type = vo.abstractType != null ? vo.abstractType : 
				try _fqcn( e ) catch ( e : Dynamic ) _blankType( vo );

			getResult( e, id, vo );
		}
		else//Standard instantiation
		{
			elseDo( typePath, args, id, vo );
		}

		return macro @:pos(pos) $result;
	}
}
#end