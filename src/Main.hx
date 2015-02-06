@:build(macros.async.Macro.build())

class Main {

	public static function main() {
		var result1 = @await foo('1');

		trace(result1);

		var result2 = @await foo('2');

		trace(result2);

		var result3 = @await foo('3');

		trace(result3);

		main2();
	}
	
	public static function main2() {
		var resulta = @await foo('a');

		trace(resulta);

		var resultb = @await foo('b');

		trace(resultb);

		var resultc = @await foo('c');

		trace(resultc);
	}

	
	public static function foo(value:String, ?cb) {
		cb(value);

		return 1;
	}

}
