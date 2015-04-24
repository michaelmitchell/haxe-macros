import macros.Await;

@:build(macros.Await.build())
class Main {

	static function main() {}

	public static function foo(i: Int) {
		if (i == 2) {
			var fn = function () {
				return 1;
			};
		}

		//trace(a);
	}

}
