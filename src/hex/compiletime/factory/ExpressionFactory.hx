package hex.compiletime.factory;

#if macro
import haxe.macro.*;
import hex.util.MacroUtil;

/**
 * ...
 * @author Francis Bourre
 */
class ExpressionFactory
{
	/** @private */ function new() throw new hex.error.PrivateConstructorException();
	
	static var _fqcn = MacroUtil.getFQCNFromExpression;
	static inline function _varType( type, position ) return TypeTools.toComplexType( Context.typeof( Context.parseInlineString( '( null : ${type})', position ) ) );
	static inline function _blankType( vo ) { vo.cType = tink.macro.Positions.makeBlankType( vo.filePosition ); return MacroUtil.getFQCNFromComplexType( vo.cType ); }
	
	static public function build<T:hex.compiletime.basic.vo.FactoryVOTypeDef>( factoryVO : T ) : Expr
	{
		var constructorVO = factoryVO.constructorVO;
		var e = constructorVO.arguments.shift();

		try
		{
			//Refact this nasty trick (condition)
			var o = constructorVO.arguments[0].key;
			MapArgumentFactory.build( factoryVO );
		}
		catch( e: Dynamic )
		{
			ArgumentFactory.build( factoryVO, constructorVO.arguments );
		}
		
		var idVar 				= constructorVO.ID;
		var args 				= constructorVO.arguments;
		
		//TODO Use fqcn everywhere
		constructorVO.type = constructorVO.fqcn != null ? constructorVO.fqcn : (constructorVO.abstractType != null ? constructorVO.abstractType : try _fqcn( e ) catch ( e : Dynamic ) _blankType( constructorVO ));

		//Used only if the result is not lazy and should be assigned
		var t = constructorVO.cType = constructorVO.cType != null ? constructorVO.cType : _varType( constructorVO.type, constructorVO.filePosition ); 

		//Building result
		return constructorVO.shouldAssign && !constructorVO.lazy ?
			macro @:pos( constructorVO.filePosition ) var $idVar : $t = $e:
			macro @:pos( constructorVO.filePosition ) $e;	
	}
}
#end