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
		if (i == 1) {
			trace('before');

			@await foo(1);

			trace('after');

			return 1;
		}
		else {
			return 2;
		}

		trace(i);

		if (i == 2) {
			trace('before');

			@await foo(2);

			trace('after');
		}
		else {
			return 3;
		}

		return i;
	}

}

class Error {

	var message: String;
	
	public function new(m: String) {
		this.message = m;
	}

}
