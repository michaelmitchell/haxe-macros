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
		trace('before all');

		if (i == 1) {
			trace(1);

			@await bar(1);

			while (i > 0) {
				trace(1);

				if (i == 2) {
					break;
				}

				do {
					trace(1);

					//@await bar(2);

					if (i == 2) {
						return;
					}

					if (i == 3) {
						continue;
					}
					else {
						break;
					}
				}
				while (i < 0);

				if (i == 3) {
					continue;
				}
				
				@await bar(1);

				trace(2);
			}

			trace('after while');

			return;
		}
		
		trace('after all');
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
