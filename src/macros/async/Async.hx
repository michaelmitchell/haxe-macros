package macros.async;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
#end

class Async {
	#if macro
	var callStack: Array<Expr> = [];

	var currentBlock:Array<Expr>;

	var currentExpr: Expr;

	var exprStack: Array<Expr> = [];

	var rootExpr: Expr;

	var rootBlock: Array<Expr>;

	var method: Function;

	var field: Field;

	var isAsync: Bool = false;

	var isReturned: Bool = false;

	public static function build() {
		var fields = Context.getBuildFields();

		for (field in fields) {
			switch (field.kind) {
				case FFun(method): {
					if (method.expr != null) {
						method = Async.transform(field, method);
					}
				}
				default:
			}
		}

		return fields;
	}

	static function transform(field: Field, method: haxe.macro.Function) {
		var instance = new Async(field, method);

		method.expr = instance.handleRootExpr();

		return method;
	}

	function new(field: Field, method: haxe.macro.Function) {
		this.field = field;
		this.method = method;

		this.rootExpr = method.expr;
		this.currentExpr = this.rootExpr;

		this.rootBlock = [];
		this.currentBlock = this.rootBlock;

		if (field != null) {
			for (m in field.meta) {
				if (m.name == 'async') {
					this.isAsync = true;
				}
			}
		}

		if (this.isAsync) {
			var returnType: ComplexType = method.ret;
			var type: ComplexType = null;

			// apply return type to callback function for type checking
			if (returnType != null) {
				type = TFunction([
					TPath({name: 'Dynamic', pack: [], params: []}),
					returnType
				], TPath({name: 'Void', pack: [], params: []}));
			}

			// add callback to method as last argument
			this.method.args.push({
				name: '__return',
				type: type,
				opt: true
			});
		}
	}

	function getExprSummary(exprs: Array<Expr>): Array<String> {
		var stack = [];

		for (expr in exprs) {
			switch (expr.expr) {
				case EBinop(op, e1, e2): {
					stack.push('Binop');
				}
				case EBlock(exprs): {
					stack.push('Block');
				}
				case ECall({ expr: EConst(CIdent('EVar')) }, params): {
					stack.push('Var');
				}
				case ECall(e, params): {
					stack.push('Call');
				}
				case EConst(CIdent('ECatch')): {
					stack.push('Catch');
				}
				case EIf(econd, eif, eelse): {
					stack.push('If');
				}
				case EConst(CIdent('EElseIf')): {
					stack.push('ElseIf');
				}
				case EConst(CIdent('EElse')): {
					stack.push('ElseIf');
				}
				case EFor(econd, expr): {
					stack.push('For');
				}
				case EFunction(name, f): {
					stack.push('Function');
				}
				case EMeta(s, e): {
					stack.push('Meta');
				}
				case EThrow(e): {
					stack.push('Throw');
				}
				case ETry(e, catches): {
					stack.push('Try');
				}
				case EVars(vars): {
					stack.push('Vars');
				}
				case ESwitch(e, cases, edef): {
					stack.push('Switch');
				}
				case EWhile(econd, e, normalWhile): {
					if (normalWhile) {
						stack.push('While');
					}
					else {
						stack.push('Do');
					}
				}
				default: {
					stack.push(null);
				}
			}
		}

		return stack;
	}

	function isCalled(exprName: String) {
		var exprSummary = this.getExprSummary(this.exprStack);
		var exprs = this.exprStack.slice(exprSummary.lastIndexOf(exprName));

		for (expr in exprs) {
			if (this.callStack.indexOf(expr) > -1) {
				return true;
			}
		}

		return false;
	}

	function isNestedTry() {
		var exprSummary = this.getExprSummary(this.exprStack);

		if (exprSummary.lastIndexOf('Try') > exprSummary.indexOf('Try')) {
			return true;
		}

		return false;
	}

	function isInTry() {
		var exprSummary = this.getExprSummary(this.exprStack);

		if (exprSummary.indexOf('Try') != -1) {
			return true;
		}

		return false;
	}

	function isInCatch() {
		var exprSummary = this.getExprSummary(this.exprStack);

		if (exprSummary.indexOf('Catch') != -1) {
			return true;
		}

		return false;
	}

	function isInDo() {
		var exprSummary = this.getExprSummary(this.exprStack);

		if (exprSummary.indexOf('Do') != -1) {
			return true;
		}

		return false;
	}

	function isInWhile() {
		var exprSummary = this.getExprSummary(this.exprStack);

		if (exprSummary.indexOf('While') != -1) {
			return true;
		}

		return false;
	}

	function isRootIf() {
		var exprStack = this.exprStack;
		var lastExpr = exprStack[exprStack.length - 1];

		var isRootIf = switch (lastExpr.expr) {
			case EIf(econd, eif, eelse): {
				true;
			}
			default: {
				false;
			}
		}

		return isRootIf;
	}

	function findExprs(ein: Expr, names: Array<String>, ?ignore: Array<String>) {
		if (ignore == null) {
			ignore = [];
		}

		var result = [];

		switch(ein.expr) {
			case EBlock(exprs): {
				for (expr in exprs) {
					if (expr != null) {
						result = result.concat(this.findExprs(expr, names, ignore));
					}
				}
			}
			case EBreak: {
				if (names.indexOf('Break') != -1) {
					result.push(ein);
				}
			}
			case EContinue: {
				if (names.indexOf('Continue') != -1) {
					result.push(ein);
				}
			}
			case EThrow(e): {
				if (names.indexOf('Throw') != -1) {
					result.push(ein);

					if (e != null) {
						result = result.concat(this.findExprs(e, names, ignore));
					}
				}
			}
			case EFor(it, expr): {
				if (ignore.indexOf('For') == -1) {
					if (expr != null) {
						result = result.concat(this.findExprs(expr, names, ignore));
					}
				}
			}
			case EIf(econd, eif, eelse): {
				if (ignore.indexOf('If') == -1) {
					if (eif != null) {
						result = result.concat(this.findExprs(eif, names, ignore));
					}

					if (eelse != null) {
						result = result.concat(this.findExprs(eelse, names, ignore));
					}
				}
			}
			case EMeta(s, e): {
				if (ignore.indexOf('Meta') == -1) {
					if (e.expr != null) {
						result = result.concat(this.findExprs(e, names, ignore));
					}
				}
			}
			case ESwitch(e, cases, edef): {
				if (ignore.indexOf('Switch') == -1) {
					for(c in cases) {
						if (c.expr != null) {
							result = result.concat(this.findExprs(c.expr, names, ignore));
						}
					}

					if (edef != null) {
						result = result.concat(this.findExprs(edef, names, ignore));
					}
				}
			}
			case ETry(e, catches): {
				if (ignore.indexOf('Try') == -1) {
					if (e != null) {
						result = result.concat(this.findExprs(e, names, ignore));
					}

					for(c in catches) {
						if (c.expr != null) {
							result = result.concat(this.findExprs(c.expr, names, ignore));
						}
					}
				}
			}
			case EWhile(econd, e, normalWhile): {
				if (ignore.indexOf('While') == -1) {
					if (e != null) {
						result = result.concat(this.findExprs(e, names, ignore));
					}
				}
			}
			case EVars(vars): {
				for (v in vars) {
					result = result.concat(this.findExprs(v.expr, names, ignore));
				}
			}
			default:
		}

		return result;
	}

	function handleRootExpr() {
		var rootExpr = this.rootExpr;

		this.currentExpr = rootExpr;

		// first expr should be block
		switch (rootExpr.expr) {
			case EBlock(exprs): {
				for (expr in exprs) {
					this.callStack = [];
					this.exprStack = [];

					this.handleExpr(expr);
				}
			}
			default: {
				this.appendExpr(rootExpr);
			}
		}

		if (this.isAsync && !this.isReturned) {
			this.appendExpr(macro {
				__return(null, null);
				return;
			});
		}

		var newExpr = {
			expr: EBlock(this.rootBlock),
			pos: rootExpr.pos
		};

		return newExpr;
	}

	function handleExpr(expr: Expr, preventStack: Bool = false) {
		var exprStack = this.exprStack.copy();

		this.currentExpr = expr;

		// add exprs to stack but ignore certain exprs if needed
		switch (expr.expr) {
			default: {
				if (preventStack == false) {
					this.exprStack.push(expr);
				}
			}
		}

		switch (expr.expr) {
			case EBinop(op, e1, e2): {
				this.handleBinop(op, e1, e2);
			}
			case EBlock(exprs): {
				this.handleBlock(exprs);
			}
			case EIf(econd, eif, eelse): {
				this.handleIf(econd, eif, eelse);
			}
			case EFor(it, expr): {
				this.handleFor(it, expr);
			}
			case EFunction(name, f): {
				this.handleFunction(name, f);
			}
			case EMeta(s, e): {
				this.handleMeta(s, e);
			}
			case EReturn(e): {
				this.handleReturn(e);
			}
			case ESwitch(e, cases, edef): {
				this.handleSwitch(e, cases, edef);
			}
			case EThrow(e): {
				this.handleThrow(e);
			}
			case ETry(e, catches): {
				this.handleTry(e, catches);
			}
			case EWhile(econd, e, normalWhile): {
				this.handleWhile(econd, e, normalWhile);
			}
			case EVars(vars): {
				this.handleVars(vars);
			}
			default: {
				this.appendExpr(this.currentExpr);
			}
		}

		this.exprStack = exprStack;

		this.currentExpr = null;
	}

	function handleBlock(exprs:Array<Expr>, isRoot: Bool = false) {
		for (expr in exprs) {
			this.handleExpr(expr);
		}

		this.isReturned = false;
	}

	function handleThrow(e) {
		if (this.isAsync && (!this.isInTry() || this.isInCatch())) {
			if (!this.isReturned) {
				this.appendExpr(macro {
					__return($e, null);
					return;
				});

				this.isReturned = true;
			}
			else {
				Context.error('Unreachable callback', e.pos);
			}
		}
		else {
			this.appendExpr(this.currentExpr);
		}
	}

	function handleReturn(e) {
		if (this.isAsync) {
			if (!this.isReturned) {
				this.appendExpr(macro {
					__return(null, $e);
					return;
				});

				this.isReturned = true;
			}
			else {
				Context.error('Unreachable callback', e.pos);
			}
		}
		else {
			this.appendExpr(this.currentExpr);
		}
	}

	function handleFunction(name: String, f: Function) {
		var exprSummary = this.getExprSummary(this.exprStack);
		var	i = exprSummary.length - 1;
		var	metaExprs = [];

		// get metadata for nested function
		while (--i >= 0) {
			if (exprSummary[i] == 'Meta')	{
				switch (this.exprStack[i].expr) {
					case EMeta(s, e): {
						metaExprs.push(s);
					}
					default:
				}
			}
			else break;
		}

		var field: Field = null;

		// create a Field to pass to transform and include metadata if any
		if (metaExprs.length > 0) {
			field = {
				pos: f.expr.pos,
				name: name,
				meta: metaExprs,
				kind: FFun(f),
				doc: null,
				access: null
			};
		}

		f = Async.transform(field, f);

		this.appendExpr({expr: EFunction(name, f), pos: f.expr.pos});
	}

	function handleSwitch(e: Expr, cases: Array<Case>, edef) {
		var exprSummary = this.getExprSummary(this.exprStack);
		var binopExpr = this.exprStack[exprSummary.lastIndexOf('Binop')];
		var varExpr = this.exprStack[exprSummary.lastIndexOf('Var')];
		var varName;

		if (binopExpr != null) {
			switch (binopExpr.expr) {
				case EBinop(op, {expr: EConst(CIdent(s))}, e2): {
					varName = s;
				}
				default:
			}
		}
		else if (varExpr != null) {
			switch (varExpr.expr) {
				case ECall({expr: EConst(CIdent('EVar')) }, [{ expr: EConst(CIdent(s)) }]): {
					varName = s;

					this.appendExpr(Context.parse('var ' + s, e.pos));
				}
				default:
			}
		}

		var currentBlock = this.currentBlock;
		var blocks = [];

		for (c in cases) {
			var e = c.expr;

			if (e != null) {
				var newBlock = [];

				this.currentBlock = newBlock;

				if (varName != null) {
					var block = [];
					var lastExpr;

					switch (e.expr) {
						case EBlock([{expr: EBlock(exprs)}]): {
							lastExpr = exprs.splice(exprs.length - 1, 1)[0];
							block = exprs;
						}
						case EBlock(exprs): {
							lastExpr = exprs.splice(exprs.length - 1, 1)[0];
							block = exprs;
						}
						default:
					}

					lastExpr = macro {
						$i{varName} = $lastExpr;
					};

					block.push(lastExpr);
				}

				this.handleExpr(e);

				blocks.push(this.currentBlock);

				e.expr = EBlock(newBlock);
			}
		}

		if (edef != null && edef.expr != null) {
			var newBlock = [];

			this.currentBlock = newBlock;

			if (varName != null) {
				var block = [];
				var lastExpr;

				switch (edef.expr) {
					case EBlock([{expr: EBlock(exprs)}]): {
						lastExpr = exprs.splice(exprs.length - 1, 1)[0];
						block = exprs;
					}
					case EBlock(exprs): {
						lastExpr = exprs.splice(exprs.length - 1, 1)[0];
						block = exprs;
					}
					default:
				}

				lastExpr = macro {
					$i{varName} = $lastExpr;
				};

				block.push(lastExpr);
			}

			this.handleExpr(edef);

			blocks.push(this.currentBlock);

			edef.expr = EBlock(newBlock);
		}

		this.currentBlock = currentBlock;

		var isCalled = this.isCalled('Switch');
		var newBlock;

		if (isCalled) {
			newBlock = [];

			var newBlockExpr = {
				expr: EBlock(newBlock),
				pos: e.pos
			};

			this.appendExpr(macro var __after_switch = function () { $newBlockExpr; });

			if (edef == null) {
				var newDefaultBlock = [];

				edef = {expr: EBlock(newDefaultBlock), pos: e.pos};

				blocks.push(newDefaultBlock);
			}

			for (block in blocks) {
				block.push(macro {
					__after_switch();
					return;
				});
			}
		}

		this.appendExpr({expr: ESwitch(e, cases, edef), pos: e.pos});

		if (newBlock != null) {
			this.currentBlock = newBlock;
		}
	}

	function handleWhile(econd: Expr, e: Expr, normalWhile:  Bool, ?isFork: Bool = false) {
		var currentBlock = this.currentBlock;
		var controlExprs = [];
		var block;

		if (e != null) {
			controlExprs = this.findExprs(e, ['Break', 'Continue'], ['For', 'While']);

			var newBlock = [];

			this.currentBlock = newBlock;

			this.handleExpr(e);

			block = this.currentBlock;

			e.expr = EBlock(newBlock);
		}

		this.currentBlock = currentBlock;

		var isCalled = this.isCalled(normalWhile ? 'While' : 'Do');

		if (isCalled) {
			var newBlock = [];
			var newBlockExpr = {expr: EBlock(newBlock),	pos: econd.pos};
			var expr;

			if (normalWhile) {
				if (isFork) {
					//async forked while
					expr = macro {
						var __after_while = function () {
							$newBlockExpr;
						};

						var __counter = 0;
						var __while = null;

						__while = function () {
							if ($econd) {
								__counter++;
								$e;
								__while();
							}
						}

						__while();
					};
				}
				else {
					//async series while
					expr = macro {
						var __after_while = function () {
							$newBlockExpr;
						};

						var __while = null;

						__while = function () {
							if ($econd) {
								$e;
							}
							else {
								__after_while();
							}
						}

						__while();
					};
				}

				for (expr in controlExprs) {
					var newExpr = switch (expr.expr) {
						case EBreak:{
							if (isFork) {
								Context.error('Cannot use break inside fork.', e.pos);
							}
							else {
								macro {
									__after_while();
									return;
								};
							}
						}
						case EContinue: {
							if (isFork) {
								Context.error('Cannot use continue inside fork.', e.pos);
							}
							else {
								macro {
									__while();
									return;
								};
							}
						}
						default: {
							expr;
						}
					}

					expr.expr = newExpr.expr;
				}
			}
			else {
				if (isFork) {
					// async series do
					expr = macro {
						var __after_do = function () {
							$newBlockExpr;
						};

						var __counter = 0;
						var __do = null;

						__do = function () {
							__counter++;
							$e;
							if ($econd) {
								__do();
							}
						};

						__do();
					}
				}
				else {
					// async series do
					expr = macro {
						var __after_do = function () {
							$newBlockExpr;
						};

						var __do = null;

						__do = function () {
							$e;
						};

						__do();
					}
				}

				for (expr in controlExprs) {
					var newExpr = switch (expr.expr) {
						case EBreak: {
							if (isFork) {
								Context.error('Cannot use break inside fork.', e.pos);
							}
							else {
								macro {
									__after_do();
									return;
								};
							}
						}
						case EContinue: {
							if (isFork) {
								Context.error('Cannot use continue inside fork.', e.pos);
							}
							else {
								macro {
									if ($econd) {
										__do();
									}
									else {
										__after_do();
									}
									return;
								};
							}
						}
						default: {
							expr;
						}
					}

					expr.expr = newExpr.expr;
				}
			}

			if (normalWhile) {
				if (isFork) {
					block.push(macro {
						if (--__counter == 0) {
							__after_while();
						}
						return;
					});
				}
				else {
					block.push(macro {
						__while();
						return;
					});
				}
			}
			else {
				if (isFork) {
					block.push(macro {
						if (--__counter == 0) {
							__after_do();
						}
						return;
					});
				}
				else {
					block.push(macro {
						if ($econd) {
							__do();
							return;
						}
						else {
							__after_do();
							return;
						}
					});
				}
			}

			this.appendExpr(expr);

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

	function handleFor(it, expr, ?isFork: Bool = false) {
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
					expr: ECall(macro macros.Async.toIterator, [e2]),
					pos: it.pos
				};

				var hasNextExpr = {
					expr: ECall(macro macros.Async.hasNext, [e2]),
					pos: it.pos
				};

				var nextExpr = {
					expr: ECall(macro macros.Async.next, [e2]),
					pos: it.pos
				};

				this.appendExpr(macro var __iterator = $toIteratorExpr);

				var newExpr = macro {
					while ($hasNextExpr) {
						var $name = $nextExpr;
						$expr;
					}
				};

				switch (newExpr.expr) {
					case EBlock([{expr: EWhile(econd, e, normalWhile)}]): {
						this.handleWhile(econd, e, normalWhile, isFork);
					}
					default: {
						Context.error('This shouldn\'t happen...', expr.pos);
					}
				}
			}
			default: {
				this.appendExpr(this.currentExpr);
			}
		}
	}

	function handleIf(econd: Expr, eif: Expr, eelse: Null<Expr>) {
		var currentBlock = this.currentBlock;
		var isRootIf = this.isRootIf();
		var blocks = [];

		if (eif != null) {
			var newIfBlock = [];

			this.currentBlock = newIfBlock;

			this.handleExpr(eif, true);

			blocks.push(this.currentBlock);

			eif.expr = EBlock(newIfBlock);
		}

		if (eelse != null) {
			var newElseBlock = [];
			var isElse = false;

			this.currentBlock = newElseBlock;

			switch (eelse.expr) {
				case EIf(econd, eif, eelse): {
					this.exprStack.push(macro EElseIf);
				}
				default: {
					this.exprStack.push(macro EElse);

					isElse = true;
				}
			}

			// don't push to expr stack
			this.handleExpr(eelse, true);

			eelse.expr = EBlock(newElseBlock);

			if (isElse) {
				blocks.push(this.currentBlock);
			}
		}

		// switch back to previous block
		this.currentBlock = currentBlock;

		var isCalled = this.isCalled('If');
		var newBlock;

		// only add the "after if" callback if there was an async call made within the if statement
		if (isCalled) {
			if (isRootIf) {
				newBlock = [];

				var newBlockExpr = {expr: EBlock(newBlock),	pos: econd.pos};

				this.appendExpr(macro var __after_if = function () { $newBlockExpr; });
			}

			// if no else block supplied, create an empty one to ensure after if is called
			if (eelse == null) {
				var newElseBlock = [];

				eelse = {
					expr: EBlock(newElseBlock),
					pos: econd.pos
				};

				blocks.push(newElseBlock);
			}

			// add calls to __continue where needed
			for (block in blocks) {
				block.push(macro __after_if());
			}
		}

		this.appendExpr({expr: EIf(econd, eif, eelse), pos: econd.pos});

		// if there is a new block, change to it
		if (newBlock != null) {
			this.currentBlock = newBlock;
		}
	}

	function handleTry(e, catches: Array<Catch>) {
		var currentBlock = this.currentBlock;
		var tryBlock = [];
		var controlExprs;
		var block;

		if (e != null) {
			controlExprs = this.findExprs(e, ['Throw']);

			this.currentBlock = tryBlock;

			this.handleExpr(e, true);

			block = this.currentBlock;

			e.expr = EBlock(tryBlock);
		}

		for (c in catches) {
			var e = c.expr;

			if (e != null) {
				var newBlock = [];

				this.currentBlock = newBlock;

				this.exprStack.push(macro ECatch);

				this.handleExpr(e, true);

				e.expr = EBlock(newBlock);
			}
		};

		// switch back to previous block
		this.currentBlock = currentBlock;

		var isCalled = this.isCalled('Try');

		if (isCalled || this.isAsync) {
			var newBlock = [];

			var newBlockExpr = {
				expr: EBlock(newBlock),
				pos: e.pos
			};

			this.appendExpr(macro var __after_catch = function () { $newBlockExpr; });

			var catchBlock = [];

			var catchBlockExpr = {
				expr: EBlock(catchBlock),
				pos: e.pos
			};

			var nextBlock = catchBlock;

			for (c in catches) {
				var exceptionType = switch (c.type) {
					case TPath({name: result}): result;
					default: null;
				}

				var varName = c.name;
				var catchExpr = c.expr;

				var expr = macro {
					if (Std.is(__exception, $i{exceptionType})) {
						var $varName = __exception;
						$catchExpr;
						__after_catch();
					}
				}

				switch (expr.expr) {
					case EBlock([{expr: EIf(econd, eif, eelse)}]): {
						var elseBlock = [];

						nextBlock.push({expr: EIf(econd, eif, {expr: EBlock(elseBlock), pos: expr.pos}), pos: expr.pos});

						nextBlock = elseBlock;
					}
					default:
				}
			}

			this.appendExpr(macro var __catch = function (__exception) { $catchBlockExpr; });

			for (expr in controlExprs) {
				var newExpr = switch (expr.expr) {
					case EThrow(e): {
						macro {
							__catch($e);
							return;
						};
					}
					default: {
						expr;
					}
				}

				expr.expr = newExpr.expr;
			}

			if (this.isNestedTry()) {
				nextBlock.push(macro __catch(__exception));
			}
			else {
				if (this.isAsync) {
					nextBlock.push(macro __return(__exception, null));
				}
				else {
					nextBlock.push(macro throw __exception);
				}
			}

			this.appendExpr({expr: EBlock(tryBlock), pos: e.pos});

			block.push(macro __after_catch());

			this.currentBlock = newBlock;
		}
		else {
			this.appendExpr({expr: ETry(e, catches), pos: e.pos});
		}
	}

	function handleBinop(op, e1, e2) {
		if (op == OpAssign) {
			var expr = e2.expr;

			if (expr != null) {
				switch (expr) {
					case EMeta(s, e): {
						this.exprStack.push(e2);

						this.handleMeta(s, e);
					}
					case EFunction(name, f): {
						f = Async.transform(null, f);

						e2.expr = EFunction(name, f);

						this.appendExpr({expr: EBinop(op, e1, e2), pos: e2.pos});
					}
					case ESwitch(e, cases, edef): {
						this.handleSwitch(e, cases, edef);
					}
					default: {
						this.appendExpr(this.currentExpr);
					}
				}
			}
			else {
				this.appendExpr(this.currentExpr);
			}
		}
		else {
			this.appendExpr(this.currentExpr);
		}
	}

	function handleVars(vars:Array<Var>) {
		var newVars = [];
		var newBlock;

		for (v in vars) {
			this.exprStack.push(macro EVar($i{v.name}));

			var expr = v.expr;

			if (expr != null) {
				switch (expr.expr) {
					case EMeta(s, e): {
						this.exprStack.push(expr);

						this.handleMeta(s, e);
					}
					case EFunction(name, f): {
						f = Async.transform(null, f);

						v.expr = {expr: EFunction(name, f), pos: f.expr.pos};

						newVars.push(v);
					}
					case ESwitch(e, cases, edef): {
						this.handleSwitch(e, cases, edef);
					}
					default: {
						newVars.push(v);
					}
				}
			}
			else {
				newVars.push(v);
			}
		}

		this.appendExpr({expr: EVars(newVars), pos: Context.currentPos()});

		if (newBlock != null) {
			this.currentBlock = newBlock;
		}
	}

	function handleMeta(s, e) {
		if (s.name == 'await' || s.name == 'pwait') {
			switch (e.expr) {
				case ECall(e2, p): {
					this.exprStack.push(e);

					for (expr in this.exprStack) {
						this.callStack.push(expr);
					}

					this.handleCall(e2, p, s.name == 'pwait');

					return true;
				}
				default: {
					Context.error('Invalid use of await', e.pos);
				}
			}
		}
		else if (s.name == 'fork') {
			switch (e.expr) {
				case EFor(it, expr): {
					this.handleFor(it, expr, true);
				}
				case EWhile(econd, e, normalWhile): {
					this.handleWhile(econd, e, normalWhile, true);
				}
				default: {
					Context.error('Invalid use of fork', e.pos);
				}
			}
		}
		else {
			this.handleExpr(e);
		}

		return false;
	}

	function handleCall(ce, p, ?isPromise = false) {
		var exprSummary = this.getExprSummary(this.exprStack);
		var metaExpr = this.exprStack[exprSummary.lastIndexOf('Meta')];

		var binopIdx = exprSummary.lastIndexOf('Binop');
		var binopExpr;

		// binop and var should be exactly 2 behind otherwise the last was from something else...
		if (binopIdx == exprSummary.length - 3) {
			binopExpr = this.exprStack[binopIdx];
		}

		var varIdx = exprSummary.lastIndexOf('Var');
		var varExpr;
		var name;

		if (varIdx == exprSummary.length - 3) {
			varExpr = this.exprStack[varIdx];
		}

		//work out the name of assignment if any
		if (binopExpr != null) {
			switch (binopExpr.expr) {
				case EBinop(op, {expr: EConst(CIdent(s))}, e2): {
					name = s;
				}
				default:
			}
		}
		else if (varExpr != null) {
			switch (varExpr.expr) {
				case ECall({ expr: EConst(CIdent('EVar')) }, [{ expr: EConst(CIdent(s)) }]): {
					name = 'var ' + s;
				}
				default:
			}
		}

		var newBlock = [];

		var newExprBlock = {
			expr: EBlock(newBlock),
			pos: ce.pos
		};

		var method;

		if (!isPromise) {
			if (this.isInTry()) {
				method = macro function(__error, __result) {
					if (__error != null) {
						__catch(__error);
						return;
					}

					$newExprBlock;
				};
			}
			else if (this.isAsync) {
				method = macro function(__error, __result) {
					if (__error != null) {
						__return(__error, null);
						return;
					}

					$newExprBlock;
				};
			}
			else {
				method = macro function(__error, __result) {
					if (__error != null) {
						throw __error;
					}

					$newExprBlock;
				};
			}

			p.push(method);
		}
		else {
			if (this.isInTry()) {
				metaExpr = macro {
					$metaExpr.then(function (__result) {
						$newExprBlock;
					}, function (__error) {
						__catch(__error);
					});
				};
			}
			else if (this.isAsync) {
				metaExpr = macro {
					$metaExpr.then(function (__result) {
						$newExprBlock;
					}, function (__error) {
						__return(__error, null);
					});
				};
			}
			else {
				metaExpr = macro {
					$metaExpr.then(function (__result) {
						$newExprBlock;
					}, function (__error) {
						throw __error;
					});
				};
			}
		}

		// add assignment if there is one...
		if (name != null) {
			var opAssign =  Context.parse(name + ' = __result', ce.pos);

			newBlock.push(opAssign);
		}

		this.appendExpr({
			expr: EBlock([metaExpr]),
			pos: ce.pos
		});

		this.currentBlock = newBlock;
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
					case {kind: FVar(AccCall, _), name: "length"}: {
						return true;
					}
					default: {
						continue;
					}
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
							params: []
						}))
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
