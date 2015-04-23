import macros.Await;
import q.Q; 

@:build(macros.Async.build())
@:build(macros.Await.build())
class Main {

	static function main() {}

	public static function foo(i: Int) {
		trace(1);

		var x = switch (i) {
			case 1: 2;
			case 2: 3;
			default: 0;
		}

		trace(2);
	}

	public static function bar(i: Int, ?__return) {
		return i;
	}

}

class Error {}
class AnotherError {}
