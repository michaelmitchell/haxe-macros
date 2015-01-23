@:build(macros.Async.build())

@ext
class Main {

	public static function main() {
		var a:Int, b:Int, c:Int;

		var d = "something";

		var result1 = @wait foo('Hello');

		trace('Hello');
	}
	
	@async public static function foo(value:String) {
		return value;
	}

}
