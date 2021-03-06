package hex.mock;

/**
 * ...
 * @author Francis Bourre
 */
class Sample
{
	static public var value : Sample;
	public var name : String;
	
	public function new() this.name = 'test';

	public function testType( value : Sample ) : Void
		Sample.value = value;

	static public function getSomething<T>() : T
		return cast new Sample();
		
	static public function test() : Void->String
		return function () return "test";
		
	public function testBind( value : String, anotherValue : Int ) : String
		return value + anotherValue;
		
	static public function testStaticBind( value : String, anotherValue : Int ) : String
		return value + anotherValue;
		
	static public function testRecursivity( newInstance : Bool ) return newInstance? new Sample() : value;
	public function getConcanetatedName( prefix : String ) return prefix + this.name;
}