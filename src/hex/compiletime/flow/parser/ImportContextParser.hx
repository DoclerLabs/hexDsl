package hex.compiletime.flow.parser;

#if macro
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import hex.compiletime.flow.parser.ExpressionParser;
import hex.compiletime.util.ContextBuilder;
import hex.core.ContextTypeList;
import hex.core.VariableExpression;
import hex.vo.ConstructorVO;

using hex.util.LambdaUtil;

/**
 * ...
 * @author Francis Bourre
 */
class ImportContextParser extends AbstractExprParser<hex.compiletime.basic.BuildRequest>
{
	var _parser 			: ExpressionParser;
	
	public function new( parser : ExpressionParser ) 
	{
		super();
		this._parser = parser;
	}
	
	override public function parse() : Void 
	{
		this.transformContextData
		( 
			function( exprs :Array<Expr> ) 
			{
				var transformation = exprs.transformAndPartition( _transform );
				transformation.is.map( _parseImport );
				return transformation.isNot;
			}
		);
	}
	
	private function _transform( e : Expr ) : Transformation<Expr, ContextImport>
	{
		return switch ( e )
		{
			case macro $i{ident} = new Context( $a{params} ):
				Transformed( {
								id:ident, 
								isPublic: false,
								fileName: 	switch( params[ 0 ].expr )
											{
												case EConst(CString(s)): s; 
												case _: ''; 
											}, 
								arg: params.length>1 ? this._parser.parseArgument( this._parser, ident, params[ 1 ] ): null,
								pos:e.pos 
							});
							
			case macro @public $i{ident} = new Context( $a{params} ):
				Transformed( {
								id:ident, 
								isPublic: true,
								fileName: 	switch( params[ 0 ].expr )
											{
												case EConst(CString(s)): s; 
												case _: ''; 
											}, 
								arg: params.length>1 ? this._parser.parseArgument( this._parser, ident, params[ 1 ] ): null,
								pos:e.pos 
								});
			
			case _: Original( e );
		}
	}
	
	function _parseImport( i : ContextImport )
	{
		var contextID = ContextBuilder.getNextID();
		var className = this._applicationContextName + '_' + i.id;
		
		var e = this._getCompiler( i.fileName)( i.fileName, className, null, null, macro this._applicationAssembler );
		ContextBuilder.forceGeneration( className );
		
		var args = [ { className: 'hex.context' + contextID + '.' + className, expr: e, arg: i.arg } ];
		var vo = new ConstructorVO( i.id, ContextTypeList.CONTEXT, args );
		vo.isPublic = true;
		vo.filePosition = i.pos;
		this._builder.build( OBJECT( vo ) );
	}
	
	function _getCompiler( url : String )
	{
		//TODO remove hardcoded compilers assigned to extensions
		switch( url.split('.').pop() )
		{
			case 'xml':
				return hex.compiletime.xml.BasicStaticXmlCompiler._readFile;
				
			case 'flow':
				return BasicStaticFlowCompiler._readFile;
				
			case ext:
				trace( ext );
				
		}
		
		return null;
	}
}
#end
