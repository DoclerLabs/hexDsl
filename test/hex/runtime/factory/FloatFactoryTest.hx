package hex.runtime.factory;

import hex.core.IApplicationContext;
import hex.runtime.basic.IRunTimeContextFactory;
import hex.runtime.basic.IRunTimeCoreFactory;
import hex.runtime.basic.vo.FactoryVOTypeDef;
import hex.unittest.assertion.Assert;
import hex.vo.ConstructorVO;

using hex.error.Error;

/**
 * ...
 * @author Francis Bourre
 */
class FloatFactoryTest
{
	@Test( "Test execute with positive value" )
    public function testExecuteWithPositiveValue() : Void
    {
		var constructorVO = new ConstructorVO( "test", "Float", ["4.7"] );
		Assert.equals( 4.7, FloatFactory.build( this._getFactoryVO( constructorVO ) ), "constructorVO.result should equal '4.7'" );
	}
	
	@Test( "Test execute with negative value" )
    public function testExecuteWithNegativeValue() : Void
    {
		var constructorVO = new ConstructorVO( "test", "Float", ["-3.8"] );
		Assert.equals( -3.8, FloatFactory.build( this._getFactoryVO( constructorVO ) ), "constructorVO.result should equal '-3.8'" );
	}
	
	@Test( "Test execute with invalid argument" )
    public function testExecuteWithInvalidArgument() : Void
    {
		var constructorVO = new ConstructorVO( "test", "Float", ["a"] );
		Assert.methodCallThrows( IllegalArgumentException, FloatFactory, FloatFactory.build, [ this._getFactoryVO( constructorVO ) ], "command execution should throw IllegalArgumentException" );
	}
	
	@Test( "Test execute with no argument array" )
    public function testExecuteWithNoArgumentArray() : Void
    {
		var constructorVO = new ConstructorVO( "test", "Float", null );
		Assert.methodCallThrows( IllegalArgumentException, FloatFactory, FloatFactory.build, [ this._getFactoryVO( constructorVO ) ], "command execution should throw IllegalArgumentException" );
	}
	
	@Test( "Test execute with empty argument array" )
    public function testExecuteWithEmptyArgumentArray() : Void
    {
		var constructorVO = new ConstructorVO( "test", "Float", [] );
		Assert.methodCallThrows( IllegalArgumentException, FloatFactory, FloatFactory.build, [ this._getFactoryVO( constructorVO ) ], "command execution should throw IllegalArgumentException" );
	}
	
	@Test( "Test execute with null argument" )
    public function testExecuteWithNullArgument() : Void
    {
		var constructorVO = new ConstructorVO( "test", "Float", [null] );
		Assert.methodCallThrows( IllegalArgumentException, FloatFactory, FloatFactory.build, [ this._getFactoryVO( constructorVO ) ], "command execution should throw IllegalArgumentException" );
	}
	
	function _getFactoryVO( constructorVO : ConstructorVO = null ) : FactoryVOTypeDef
	{
		return { constructorVO : constructorVO, contextFactory : new MockContextFactory() };
	}
}

private class MockContextFactory implements IRunTimeContextFactory
{
	public function new()	
	{
		
	}
	
	public function buildVO( constructorVO : ConstructorVO, ?id : String ) : Dynamic
	{
		return null;
	}
	
	public function buildObject( id : String ) : Void
	{
		
	}
	
	public function getApplicationContext() : IApplicationContext
	{
		return null;
	}
	
	public function getCoreFactory() : IRunTimeCoreFactory
	{
		return null;
	}
}