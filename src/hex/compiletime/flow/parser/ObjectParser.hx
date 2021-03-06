package hex.compiletime.flow.parser;

#if macro
import haxe.macro.*;
import haxe.macro.Expr;
import hex.compiletime.flow.AbstractExprParser;
import hex.core.ContextTypeList;
import hex.vo.ConstructorVO;
import hex.vo.MethodCallVO;
import hex.vo.PropertyVO;

/**
 * ...
 * @author Francis Bourre
 */
class ObjectParser extends AbstractExprParser<hex.compiletime.basic.BuildRequest>
{
	var logger 				: hex.log.ILogger;
	var parser 				: ExpressionParser;
	var _runtimeParam 		: hex.preprocess.RuntimeParam;
	var _dependencyChecker	: hex.core.IDependencyChecker = new hex.core.DependencyChecker();

	public function new( parser : ExpressionParser, ?runtimeParam : hex.preprocess.RuntimeParam ) 
	{
		super();
		
		this.logger 		= hex.log.LogManager.getLoggerByInstance( this );
		this.parser 		= parser;
		this._runtimeParam 	= runtimeParam;
	}
	
	override public function parse() : Void this._getExpressions().map( this._parse );
	private function _parse( e : Expr ) this._parseExpression( e, new ConstructorVO( '' ) );

	private function _parseExpression( e : Expr, constructorVO : ConstructorVO ) : Void
	{
		switch ( e )
		{
			case macro $i{ ident } = _if( $a{ args } ):

				constructorVO.ID = ident;
				constructorVO.filePosition = e.pos;
				constructorVO.type = ContextTypeList.IF;

				var arg0 = args[0];
				var arg1 = args[1];
				var arg2 = args[2];
				var e = macro @:pos( constructorVO.filePosition ) tink.state.Observable.auto( function () return if ( $arg0 ) $arg1 else $arg2 );

				constructorVO.arguments = [ e ];
				constructorVO.arguments = constructorVO.arguments.concat( args.map( function( param ) return this.parser.parseArgument( this.parser, ident, param ) ) );
				//Register dependency
				this._dependencyChecker.registerDependency( constructorVO );
				this._builder.build( OBJECT( constructorVO ) );

			case macro $i{ ident } = _or( $a{ args } ):

				constructorVO.ID = ident;
				constructorVO.filePosition = e.pos;
				constructorVO.type = ContextTypeList.BOOL_OP;

				var arg0 = args[0];
				var arg1 = args[1];
				var e = macro @:pos( constructorVO.filePosition ) tink.state.Observable.auto( function () return $arg0 || $arg1 );

				constructorVO.arguments = [ e ];
				constructorVO.arguments = constructorVO.arguments.concat( args.map( function( param ) return this.parser.parseArgument( this.parser, ident, param ) ) );
				//Register dependency
				this._dependencyChecker.registerDependency( constructorVO );
				this._builder.build( OBJECT( constructorVO ) );

			case macro $i{ ident } = _and( $a{ args } ):

				constructorVO.ID = ident;
				constructorVO.filePosition = e.pos;
				constructorVO.type = ContextTypeList.BOOL_OP;

				var arg0 = args[0];
				var arg1 = args[1];
				var e = macro @:pos( constructorVO.filePosition ) tink.state.Observable.auto(function () return $arg0 && $arg1 );

				constructorVO.arguments = [ e ];
				constructorVO.arguments = constructorVO.arguments.concat( args.map( function( param ) return this.parser.parseArgument( this.parser, ident, param ) ) );
				//Register dependency
				this._dependencyChecker.registerDependency( constructorVO );
				this._builder.build( OBJECT( constructorVO ) );

			case macro $i{ ident } = $value:
				constructorVO.ID = ident;

				//Register dependency
				this._dependencyChecker.registerDependency( constructorVO );

				this._builder.build( OBJECT( this._getConstructorVO( constructorVO, value ) ) );
			
			case macro $i{ ident }.$field = $assigned:	
				var propertyVO = this.parser.parseProperty( this.parser, ident, field, assigned );
				this._builder.build( PROPERTY( propertyVO ) );
			
			case macro $i{ ident }.$field( $a{ params } ):
				var args = params.map( function( param ) return this.parser.parseArgument( this.parser, ident, param ) );
				var methodCallVO = new MethodCallVO( ident, field, args );
				methodCallVO.filePosition = e.pos;

				//Register dependency
				//this._dependencyChecker.registerDependency( constructorVO );

				this._builder.build( METHOD_CALL( methodCallVO ) );
			
			case macro @inject_into( $a{ args } ) $e:
				constructorVO.injectInto = true;
				this._parseExpression ( e, constructorVO );
				
			case macro @map_type( $a{ args } ) $e:
				constructorVO.mapTypes = args.map( function( e ) return switch( e.expr ) 
				{ 
					case EConst(CString( mapType )) : mapType; 
					case _: "";
				} );
				this._parseExpression ( e, constructorVO );
				
			case macro @type( $a{ args } ) $e:
				constructorVO.abstractType = switch( args[ 0 ].expr ) 
				{ 
					case EConst(CString( abstractType )) : abstractType; 
					case _: "";
				}
				this._parseExpression ( e, constructorVO );
				
			case macro @lazy( $a{ args } ) $e:
				constructorVO.lazy = true;
				this._parseExpression ( e, constructorVO );
				
			case macro @public( $a{ args } ) $e:
				constructorVO.isPublic = true;
				this._parseExpression ( e, constructorVO );

			case _:
				
				switch( e.expr )
				{
					case EMeta( meta, e ):
						trace( e );
				
					//TODO refactor - Should be part of the property parser
					case EBinop( OpAssign, _.expr => EField( ref, field ), value ):
						var fields = ExpressionUtil.compressField( ref, field ).split('.');
						var ident = fields.shift();
						var fieldName = fields.join('.');
						this._builder.build( PROPERTY( this.parser.parseProperty( this.parser, ident, fieldName, value ) ) );
					
					//TODO refactor - Should be part of the method parser	
					case ECall( _.expr => EField( ref, field ), params ):
						var ident = ExpressionUtil.compressField( ref );
						var args = params.map( function( param ) return this.parser.parseArgument( this.parser, ident, param ) );
						var methodCallVO = new MethodCallVO( ident, field, args );
						methodCallVO.filePosition = e.pos;
						
						//Register dependency
						//this._dependencyChecker.registerDependency( constructorVO );
						
						this._builder.build( METHOD_CALL( methodCallVO ) );
						
					case _:
						//TODO remove
						logger.error( 'Unknown expression' );
						logger.debug( e.pos );
						logger.debug( e );
						logger.debug( e.expr );
						haxe.macro.Context.error( 'Invalid expression', e.pos );
				}
				
		}
		//logger.debug(e); 
	}

	function _getConstructorVO( constructorVO : ConstructorVO, value : Expr ) : ConstructorVO 
	{
		switch( value.expr )
		{
			case EConst(CString(v)):
				constructorVO.type = ContextTypeList.STRING;
				constructorVO.arguments = [ v ];
			
			case EConst(CInt(v)):
				constructorVO.type = ContextTypeList.INT;
				constructorVO.arguments = [ v ];
				
			case EConst(CFloat(v)):
				constructorVO.type = ContextTypeList.FLOAT;
				constructorVO.arguments = [ v ];
				
			case EConst(CIdent(v)):
				
				switch( v )
				{
					case "null":
						constructorVO.type = ContextTypeList.NULL;
						constructorVO.arguments = [ v ];
						
					case "true" | "false":
						constructorVO.type = ContextTypeList.BOOLEAN;
						constructorVO.arguments = [ v ];
						
					case _:
						var type = hex.preprocess.RuntimeParametersPreprocessor.getType( v, this._runtimeParam );
						var arg = new ConstructorVO( constructorVO.ID, (type==null? ContextTypeList.INSTANCE : type), null, null, null, v );
						arg.filePosition = value.pos;
						
						constructorVO.type = ContextTypeList.ALIAS;
						constructorVO.arguments = [ arg ];
						constructorVO.ref = v;
				}
				
			case ENew( t, params ):
				this.parser.parseType( this.parser, constructorVO, value );
				

			case EBlock([]):
				constructorVO.type = ContextTypeList.EXPRESSION;
				constructorVO.arguments = [ value ];

			case EObjectDecl( fields ):
				constructorVO.type = ContextTypeList.OBJECT;
				fields.map( function(field) this._builder.build( 
					PROPERTY( this.parser.parseProperty( this.parser, constructorVO.ID, field.field, field.expr ) )
				) );
				
			case EArrayDecl( values ):
				
				var isMap = function ( v ) return switch( v[ 0 ].expr ) { case EBinop( op, e1, e2 ): op == OpArrow;  case _: false; };
				
				if ( values.length > 0 && isMap( values ) )
				{
					constructorVO.type = ContextTypeList.EXPRESSION;
					constructorVO.arguments = [ value ];
					constructorVO.arguments = constructorVO.arguments.concat( values.map( function (e) return this.parser.parseMapArgument( this.parser, constructorVO.ID, e ) ) );
				}
				else
				{
					constructorVO.type = ContextTypeList.ARRAY;
					constructorVO.arguments = [];
					values.map( function( e ) constructorVO.arguments.push( this.parser.parseArgument( this.parser, constructorVO.ID, e ) ) );
				}
					
			case EField( e, field ):
				
				var className = ExpressionUtil.compressField( e, field );

				try
				{
					//
					var exp = Context.parse( '(null: ${className})', e.pos );

					switch( exp.expr )
					{
						case EParenthesis( _.expr => ECheckType( ee, TPath(p) ) ):

							constructorVO.type = ContextTypeList.EXPRESSION;
							constructorVO.arguments = [ value ];

						case _:
							logger.error( exp );
					}
				}
				catch ( e : Dynamic )
				{
					//TODO refactor
					var type = hex.preprocess.RuntimeParametersPreprocessor.getType( className, this._runtimeParam );
					var arg = new ConstructorVO( constructorVO.ID, (type==null? ContextTypeList.INSTANCE : type), null, null, null, className );
					arg.filePosition = e.pos;
					
					constructorVO.type = ContextTypeList.ALIAS;
					constructorVO.arguments = [ arg ];
					constructorVO.ref = className;
				}
				
			case ECall( _.expr => EConst(CIdent(keyword)), params ):
				if ( this.parser.buildMethodParser.exists( keyword ) )
				{
					return this.parser.buildMethodParser.get( keyword )( this.parser, constructorVO, params, value );
				}
				else
				{
					constructorVO.ref = ExpressionUtil.compressField( value );
					constructorVO.arguments = params.map( function (e) return this.parser.parseArgument( this.parser, constructorVO.ID, e ) );
					constructorVO.instanceCall = constructorVO.ref;
					constructorVO.type = ContextTypeList.CLOSURE_FACTORY;
					constructorVO.shouldAssign = true;
				}
				
				
			case ECall( _.expr => EField( e, field ), params ):
				switch( e.expr )
				{
					case EField( ee, ff ):

						if ( field != 'bind' )
						{
							constructorVO.type = ContextTypeList.EXPRESSION;
							constructorVO.arguments = [ value ];
						}
						else
						{
							constructorVO.arguments = [];
							constructorVO.type = ContextTypeList.CLOSURE;
							constructorVO.ref = ExpressionUtil.compressField( e );
						}
						
					case ECall( ee, pp ):

						constructorVO.type = ContextTypeList.EXPRESSION;
						constructorVO.arguments = [ value ];
						constructorVO.arguments = constructorVO.arguments.concat( pp.map( function (e) return this.parser.parseArgument( this.parser, constructorVO.ID, e ) ) );
						

					case EConst( ee ):
						
						var comp = ExpressionUtil.compressField( e );
						
						constructorVO.type = ContextTypeList.EXPRESSION;
						constructorVO.arguments = [ value ];
						
						try
						{
							Context.getType( comp );
						}
						catch ( e: Dynamic )
						{
							constructorVO.ref = comp.split('.')[0];
						}

					case _:
						logger.error( e.expr );
				}
				
				if ( params.length > 0 )
				{
					constructorVO.arguments = constructorVO.arguments.concat( params.map( function (e) return this.parser.parseArgument( this.parser, constructorVO.ID, e ) ) );
				}

				
			case _:
				logger.error( value.expr );
		}
		
		constructorVO.filePosition = value.pos;
		//Register dependency
		this._dependencyChecker.registerDependency( constructorVO );
		return constructorVO;
	}
}
#end