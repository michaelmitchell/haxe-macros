package q;

extern class Deferred {
	var promise: Promise;
	function resolve(result: Dynamic): Void;
	function reject(result: Dynamic): Void;
}
