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
		var arr = [0,1,2,3,4,5,6,7,8,9];

		for (v in arr) {
			trace(v);
		}

		for (i in 0...10) {
			trace(i);
		}

		var map: Map<String, Int> = [
			'a' => 1,
			'b' => 2,
			'c' => 3
		];

		for(k in map.keys()) {
			trace(k);
		}

		var arr = ['a', 'b', 'c', 'd', 'e', 'f'];

		for (v in arr) {
			trace(v);
		}
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
