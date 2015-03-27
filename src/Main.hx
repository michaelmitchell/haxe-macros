/**
import com.dongxiguo.continuation.Continuation;

@:build(com.dongxiguo.continuation.Continuation.cpsByMeta("async"))
/**/

/**/
@:build(macros.Async.build())
@:build(macros.Await.build())
/**/

class Main {

	static function main() {
	}

	@async public static function foo(i: Int) {
		if (i == 2) {
			trace('before');

			trace('after');
		}
		else if(i == 3) {
			trace('here');

			trace('there');

		}
		else {
			trace('there');

			@await foo(1);

			if (i == 4) {
				trace('before');

				@await foo(4);

				trace('after');
			}
			else {
				trace('banana');
			}
		}

		if (i == 10) {
			trace(1);

			@await foo(10);

			trace(2);
		}
		else if (i == 20) {
			trace(3);
			trace(4);
		}
		else {
			trace(5);
			trace(6);
		}

		return i;
	}

	static function bar() {

	}

}

class Error {

	var message: String;
	
	public function new(m: String) {
		this.message = m;
	}

}
