import macros.Async;

@:build(macros.Async.build())
class Main {

	static function main() {}

	public static function foo(i: Int) {
		while (i > 0) {
			@await bar(i);
		}

		return -1;
	}

	@async public static function bar(i: Int) {
		return 1;
	}

}