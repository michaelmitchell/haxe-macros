package macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type;
#end

class Await {
	#if macro
	var currentBlock:Array<Expr>;

	var currentExpr:Expr;

	var currentBinop:Binop;
	
	var currentBinopExpr1:Expr;

	var currentBinopExpr2:Expr;

	var currentMetadataEntry:MetadataEntry;

	var currentMetadataExpr:Expr;

	var currentVar:Var;

	var field:Field;

	var isCalled:Bool = false;

	var isInIf:Bool = false;

	var method:Function;

	var rootExpr:Expr;

	var rootBlock:Array<Expr>;

	public static function build() {
		var fields = Context.getBuildFields();

		for (field in fields) {
			switch (field.kind) {
				case FFun(method):
					if (method.expr != null) {
						method = Await.transform(field, method);
					}
				default:
			}
		}

		return fields;
	}

	static function transform(field:Field, method:haxe.macro.Function) {
		var instance = new Await(field, method);

		method.expr = instance.handleRootExpr();

		return method;
	}

	function new(field:Field, method:haxe.macro.Function) {
		this.field = field;
		this.method = method;

		this.rootExpr = method.expr;
		this.currentExpr = this.rootExpr;

		this.rootBlock = [];
		this.currentBlock = this.rootBlock;
	}

	function handleRootExpr() {
		var expr = this.rootExpr;

		this.currentExpr = expr;

		// first expr should be block
		switch (expr.expr) {
			case EBlock(exprs):
				this.handleBlock(exprs);

			default:
				this.appendExpr(expr);
		}

		return {
			expr: EBlock(this.rootBlock),
			pos: expr.pos
		};
	}

	function handleExpr(expr: Expr) {
		this.currentExpr = expr;

		switch(expr.expr) {
			case EBinop(op, e1, e2):
				this.handleBinop(op, e1, e2);

			case EBlock(exprs):
				this.handleBlock(exprs);

			case EFor(it, expr):
				this.handleFor(it, expr);

			case EIf(econd, eif, eelse):
				this.handleIf(econd, eif, eelse);

			case EMeta(s, e):
				this.handleMeta(s, e);

			case ETry(e, catches):
				this.handleTry(e, catches);

			case EWhile(econd, e, normalWhile):
				this.handleWhile(econd, e, normalWhile);

			case EVars(vars):
				this.handleVars(vars);

			default:
				this.appendExpr(this.currentExpr);
		}

		this.currentExpr = null;
	}

	function handleWhile(econd: Expr, e: Expr, normalWhile:  Bool) {
		var currentBlock = this.currentBlock,
			block;

		// test for async calls
		this.isCalled = false;

		if (e != null) {
			var newBlock = [];

			this.currentBlock = newBlock;

			this.handleExpr(e);

			block = this.currentBlock;

			e.expr = EBlock(newBlock);
		}

		this.currentBlock = currentBlock;

		var isCalled = this.isCalled,
			expr;

		if (isCalled) {
			var method = macro var __continue = function () {};

			if (normalWhile) {
				//async while
				expr = macro {
					$method;
					var __while = null;

					__while = function () {
						if ($econd) {
							$e;
						}
						else {
							__continue();
						}
					}
				};
			}
			else {
				// async do 
				expr = macro {
					$method;
					var __do = null; 
					
					__do = function () {
						$e;
					};
				}
			}

			var lastExpr = block[block.length - 1],
				hasReturn = false;

			if (lastExpr != null) {
				hasReturn = switch (lastExpr.expr) {
					case EReturn(e): true;
					default: false;
				}	
			}

			if (!hasReturn) {
				if (normalWhile) {
					block.push(macro __while());
				}
				else {
					block.push(macro {
						if ($econd) {
							__do();
						}
						else {
							__continue();
						}
					});
				}
			}
			
			this.appendExpr(expr);

			var newBlock = [];
			
			switch (method.expr) {
				case EVars(vars):
					for (v in vars) {
						var expr = v.expr;

						switch (expr.expr) {
							case EFunction(name, fe):
								// replace new methods block with new write target
								fe.expr = {
									expr: EBlock(newBlock),
									pos: econd.pos
								};

							default:
						}
					}

				default:
			}

			// shift current block to new "after if" callback
			this.currentBlock = newBlock;
		}
		else {
			this.appendExpr({
				expr: EWhile(econd, e, normalWhile),
				pos: econd.pos
			});
		}
	}

	function handleBlock(exprs:Array<Expr>) {
		for (expr in exprs) {
			this.handleExpr(expr);
		}
	}

	function handleFor(it, expr) {
		switch(it.expr) {
			case EIn(e1, e2): {
				var name = switch (e1.expr) {
					case EConst(c): {
						switch (c) {
							case CIdent(s): {
								s;
							}
							default: {
								Context.error("Expect identify before \"in\".", e1.pos);
							}
						}
					}
					default: {
						Context.error("Expect identify before \"in\".", e1.pos);
					}
				}

				var toIteratorExpr = {
					expr: ECall(macro macros.Await.toIterator, [e2]),
					pos: it.pos
				};

				var hasNextExpr = {
					expr: ECall(macro macros.Await.hasNext, [e2]),
					pos: it.pos
				};

				var nextExpr = {
					expr: ECall(macro macros.Await.next, [e2]),
					pos: it.pos
				};

				var expr = macro {
					var __iterator = $toIteratorExpr;
					while ($hasNextExpr) {
						var $name = $nextExpr;
						$expr;
					}
				};

				this.handleExpr(expr);
			}

			default: {
				this.appendExpr(this.currentExpr);
			}
		}
	}

	function handleIf(econd: Expr, eif: Expr, eelse: Null<Expr>) {
		var currentBlock = this.currentBlock,
			isInIf = this.isInIf;
	
		this.isInIf = true;

		if (!isInIf) {
			this.isCalled = false;
		}

		var blocks = [];

		if (eif != null) {
			var newIfBlock = [];

			this.currentBlock = newIfBlock;

			this.handleExpr(eif);
			
			blocks.push(this.currentBlock);

			eif.expr = EBlock(newIfBlock);
		}

		if (eelse != null) {
			var newElseBlock = [];

			this.currentBlock = newElseBlock;

			this.handleExpr(eelse);

			if (this.isInIf) {
				blocks.push(this.currentBlock);
			}

			eelse.expr = EBlock(newElseBlock);
		}

		// switch back to previous block
		this.currentBlock = currentBlock;

		var isCalled = this.isCalled,
			method;

		// only add the "after if" callback if there was an async call made within the if statement
		if (isCalled) {
			if (!isInIf) {	
				method = macro var __continue = function () {};
				
				this.appendExpr(method);
			}

			// add calls to __continue where needed
			for (block in blocks) {
				var lastExpr = block[block.length - 1];

				if (lastExpr != null) {
					switch (lastExpr.expr) {
						case EReturn(e):
							// don't add a call to continue if already returned...
						default:
							block.push(macro __continue());
					}	
				}
				else {
					block.push(macro __continue());
				}
			}
		}

		this.appendExpr({
			expr: EIf(econd, eif, eelse),
			pos: econd.pos
		});

		if (isCalled && !isInIf) {
			// the new root block inside the callback function
			var newBlock = [];
			
			switch (method.expr) {
				case EVars(vars):
					for (v in vars) {
						var expr = v.expr;

						switch (expr.expr) {
							case EFunction(name, fe):
								// replace new methods block with new write target
								fe.expr = {
									expr: EBlock(newBlock),
									pos: econd.pos
								};


							default:
						}
					}

				default:
			}

			// shift current block to new "after if" callback
			this.currentBlock = newBlock;
		}

		this.isInIf = false;
	}

	function handleTry(e, catches: Array<Catch>) {
		var currentBlock = this.currentBlock;

		if (e != null) {
			var newBlock = [];

			this.currentBlock = newBlock;

			switch (e.expr) {
				case EBlock(exprs):
					this.handleBlock(exprs);
				default:
			}

			e.expr = EBlock(newBlock);
		}

		for (c in catches) {
			var e = c.expr;

			if (e != null) {
				var newBlock = [];

				this.currentBlock = newBlock;

				switch (e.expr) {
					case EBlock(exprs):
						this.handleBlock(exprs);

					default:
				}

				e.expr = EBlock(newBlock);
			}
		};

		// switch back to previous block
		this.currentBlock = currentBlock;

		this.appendExpr({
			expr: ETry(e, catches),
			pos: e.pos
		});
	}

	function handleBinop(op, e1, e2) {
		if (op == OpAssign) {
			this.currentBinop = op;
			this.currentBinopExpr1 = e1;
			this.currentBinopExpr2 = e2;

			var expr = e2.expr;

			if (expr != null) {
				switch (expr) {
					case EMeta(s, e):
						this.handleMeta(s, e);

					default:
						this.appendExpr(this.currentExpr);
				}
			}
			else {
				this.appendExpr(this.currentExpr);
			}

			this.currentBinop = null;
			this.currentBinopExpr1 = null;
			this.currentBinopExpr2 = null;
		}
		else {
			this.appendExpr(this.currentExpr);
		}
	}

	function handleVars(vars:Array<Var>) {
		for (v in vars) {
			this.currentVar = v;
			
			var expr = v.expr;

			if (expr != null) {
				switch (expr.expr) {
					case EMeta(s, e):
						this.handleMeta(s, e);

					default:
						this.appendExpr(this.currentExpr);
				}
			}
			else {
				this.appendExpr(this.currentExpr);
			}
			
			this.currentVar = null;
		}
	}

	function handleMeta(s, e) {
		this.currentMetadataEntry = s;
		this.currentMetadataExpr = e;

		if (s.name == 'await') {
			switch (e.expr) {
				case ECall(e, p):
					this.isCalled = true;

					this.handleCall(e, p);

				default:
					this.appendExpr(this.currentExpr);
			}
		}
		else {
			this.appendExpr(this.currentExpr);
		}

		this.currentMetadataEntry = null;
		this.currentMetadataExpr = null;
	}

	function handleCall(ce, p) {
		var pos = ce.pos;

		this.appendExpr({expr: EBlock([this.currentMetadataExpr]), pos: pos});

		// create write block
		var binopExpr1 = this.currentBinopExpr1,
			currentVar = this.currentVar,
			name;

		//work out the name of assignment if any
		if (binopExpr1 != null) {
			name = switch (binopExpr1.expr) {
				case EConst(CIdent(s)): s;
				default: null;
			}
		}
		else if (currentVar != null) {
			name = 'var ' + currentVar.name;
		}
		
		var method = macro function(__error, __result) {};

		p.push(method);

		// the new root block inside the callback function
		var newBlock = [];

		// add assignment if there is one...
		if (name != null) {
			var opAssign =  Context.parse(name + ' = __result', pos);

			newBlock.push(opAssign);
		}

		switch (method.expr) {
			case EFunction(name, fe):
				// replace new methods block with new write target
				fe.expr = {
					expr: EBlock(newBlock),
					pos: pos
				};

				this.currentBlock = newBlock;

			default:
		}
	}

	function appendExpr(expr:Expr) {
		this.currentBlock.push(expr);
	}

	static function hasArrayAccess(type: AbstractType): Bool {
		if (type.meta.has(":arrayAccess")) {
			return true;
		} else {
			return type.array.length == 0;
		}
	}

	static function hasLength(type: AbstractType): Bool {
		var impl = type.impl;

		if (impl == null) {
			return false;
		} else {
			for (field in impl.get().statics.get()) {
				switch (field) {
					case {kind: FVar(AccCall, _), name: "length"}:
						return true;
					default:
						continue;
				}
			}

			return false;
		}
	}

	static function isIterator(type: Type): Bool {
		if (type != null) {
			var iteratorType = Context.typeof({
				expr: ECheckType(macro null, TPath({
					name: "Iterator",
					pack: [],
					sub: null,
					params: [
						TPType(TPath({
							name: "Dynamic",
							pack: [],
							sub: null,
							params: [],
						})),
					]
				})),
				pos: Context.currentPos()
			});

			return Context.unify(type, iteratorType);
		}

		return false;
	}
	#end

	macro public static function toIterator(iterable: Expr): Expr {
		var type = Context.follow(Context.typeof(iterable));

		switch(type) {
			case TInst(_.get() => {module: 'Array', name: 'Array'}, _): {
				return macro 0;
			}
			case TAbstract(_.get() => a, _) if (hasArrayAccess(a) && hasLength(a)): {
				return macro 0;
			}
			case type: {
				if (isIterator(type)) {
					return iterable;
				}
				else {
					return macro $iterable.iterator();
				}
			}
		}
	}

	macro public static function hasNext(iterable: Expr): Expr {
		var type = Context.follow(Context.typeof(iterable));

		switch(type) {
			case TInst(_.get() => {module: 'Array', name: 'Array'}, _): {
				return macro __iterator < $iterable.length;
			}
			case TAbstract(_.get() => a, _) if (hasArrayAccess(a) && hasLength(a)): {
				return macro __iterator < $iterable.length;
			}
			default: {
				return macro __iterator.hasNext();
			}
		}
	}

	macro public static function next(iterable: Expr): Expr {
		var type = Context.follow(Context.typeof(iterable));

		switch(type) {
			case TInst(_.get() => {module: 'Array', name: 'Array'}, _): {
				return macro $iterable[__iterator++];
			}
			case TAbstract(_.get() => a, _) if (hasArrayAccess(a) && hasLength(a)): {
				return macro $iterable[__iterator++];
			}
			default: {
				return macro __iterator.next();
			}
		}
	}

}
