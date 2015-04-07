/**
import com.dongxiguo.continuation.Continuation;

@:build(com.dongxiguo.continuation.Continuation.cpsByMeta(":async"))
/**/

/**/
import macros.Await;

@:build(macros.Async.build())
@:build(macros.Await.build())
/**/

class Main {

	static function main() {

	}

	public static function foo(i: Int) {
		if (i == 0) {
			trace(1);

			@await bar(1);

			if (i == 1) {
				trace('before');

				//@await bar(2);

				trace('after');
			}
			else if(i == 2) {
				trace('before');

				trace('after');
			}
			else {
				if (i == 3) {
					trace('before');

					trace('after');
				}

				trace('after if');
			}

			trace(3);
		}
		else if (i == 1) {
			trace('before');

			@await bar(1);

			trace('after');
		}
		else {
			trace(3);
		}

		trace('after main if');
	}

	@async static function bar(i: Int) {
		return i;
	}

}

class Error {

	var message: String;
	
	public function new(m: String) {
		this.message = m;
	}

}
