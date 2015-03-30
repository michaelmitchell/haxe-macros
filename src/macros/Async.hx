package macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;

class Async {

	var field:Field;

	var method:Function;

	var metadata:Metadata;

	var rootExpr:Expr;

	var rootBlock:Array<Expr>;

	var currentBlock:Array<Expr>;

	var currentExpr:Expr;

	var returnType:ComplexType;

	var isReturned:Bool = false;

	var isInTry:Bool = false;

	static function build() {
		var fields = Context.getBuildFields();

		for (field in fields) {
			switch (field.kind) {
				case FFun(method):
					if (method.expr != null) {
						method = Async.run(field, method);
					}
				default:
			}
		}

		return fields;
	}

	static function run(field:Field, method:haxe.macro.Function) {
		var instance = new Async(field, method);

		for (metadata in field.meta) {
			if (metadata.name == 'async') {
				method.expr = instance.handle();
			}
		}

		return method;
	}

	function new(field:Field, method:haxe.macro.Function) {
		this.field = field;
		this.method = method;
		this.metadata = field.meta;

		this.rootExpr = method.expr;
		this.currentExpr = this.rootExpr;

		this.rootBlock = [];
		this.currentBlock = this.rootBlock;
	}

	function handleBlock(exprs:Array<Expr>) {
		var i = 0;

		for (expr in exprs) {
			this.currentExpr = expr;

			switch(expr.expr) {
				case EBlock(exprs):
					this.handleBlock(exprs);

				case EIf(econd, eif, eelse):
					this.handleIf(econd, eif, eelse);

				case EFor(it, expr):
					this.handleFor(it, expr);

				case ESwitch(e, cases, edef):
					this.handleSwitch(e, cases, edef);

				case EThrow(e):
					this.handleThrow(e);

				case EReturn(e):
					this.handleReturn(e);

				case ETry(e, catches):
					this.handleTry(e, catches);

				case EWhile(econd, e, normalWhile):
					this.handleWhile(econd, e, normalWhile);

				default:
					this.append(this.currentExpr);
			}

			i++;

			// make sure we are back on the root block
			if (this.currentBlock == this.rootBlock) {
				// if return has not been used add a callback to the end of the function
				if (!this.isReturned && i == exprs.length) {
					this.append({
						expr: ECall({
							expr: EConst(CIdent('__return')),
							pos: expr.pos
						}, [{
							expr: EConst(CIdent('null')),
							pos: expr.pos
						}, {
							expr: EConst(CIdent('null')),
							pos: expr.pos
						}]),
						pos: expr.pos
					});

					// prevent callbacks from being called more than once
					this.append({expr: EReturn(null), pos: expr.pos});
				}
			}
		}

		this.isReturned = false;
	}

	function handleTry(e, catches: Array<Catch>) {
		var currentBlock = this.currentBlock;

		if (e != null) {
			this.isInTry = true;

			var newBlock = [];

			this.currentBlock = newBlock;

			switch (e.expr) {
				case EBlock(exprs):
					this.handleBlock(exprs);
				default:
			}

			e.expr = EBlock(newBlock);

			this.isInTry = false;
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

		this.append({
			expr: ETry(e, catches),
			pos: e.pos
		});
	}

	function handleSwitch(e, cases: Array<Case>, edef) {
		var currentBlock = this.currentBlock;

		for (c in cases) {
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

		if (edef != null) {
			var newBlock = [];

			this.currentBlock = newBlock;

			switch (edef.expr) {
				case EBlock(exprs):
					this.handleBlock(exprs);

				default:
			}

			edef.expr = EBlock(newBlock);
		}
		
		// switch back to previous block
		this.currentBlock = currentBlock;

		this.append({
			expr: ESwitch(e, cases, edef),
			pos: e.pos
		});
	}

	function handleWhile(econd, e, normalWhile) {
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
	
		// switch back to previous block
		this.currentBlock = currentBlock;

		this.append({
			expr: EWhile(econd, e, normalWhile),
			pos: econd.pos
		});
	}

	function handleFor(it, expr) {
		var currentBlock = this.currentBlock;

		if (expr != null) {
			var newBlock = [];

			this.currentBlock = newBlock;

			switch (expr.expr) {
				case EBlock(exprs):
					this.handleBlock(exprs);

				default:
			}

			expr.expr = EBlock(newBlock);
		}
	
		// switch back to previous block
		this.currentBlock = currentBlock;

		this.append({
			expr: EFor(it, expr),
			pos: it.pos
		});

	}

	function handleIf(econd: Expr, eif: Expr, eelse: Null<Expr>) {
		var currentBlock = this.currentBlock;

		if (eif != null) {
			var newIfBlock = [];

			this.currentBlock = newIfBlock;

			switch(eif.expr) {
				case EBlock(exprs):
					this.handleBlock(exprs);

				default:
			}

			eif.expr = EBlock(newIfBlock);
		}

		if (eelse != null) {
			var newElseBlock = [];

			this.currentBlock = newElseBlock;

			switch(eelse.expr) {
				case EBlock(exprs):
					this.handleBlock(exprs);

				case EIf(econd, eif, eelse):
					this.handleIf(econd, eif, eelse);

				default:
			}
			
			eelse.expr = EBlock(newElseBlock);
		}

		// switch back to previous block
		this.currentBlock = currentBlock;

		this.append({
			expr: EIf(econd, eif, eelse),
			pos: econd.pos
		});
	}

	function handleThrow(e) {
		//don't replace throw with callback if it is inside a try blcok
		if (!this.isInTry) {
			if (!this.isReturned) {
				//replace return wtih call to callback function supporting error first callback style
				this.append({
					expr: ECall({
						expr: EConst(CIdent('__return')),
						pos: e.pos
					}, [e, {
						expr: EConst(CIdent('null')),
						pos: e.pos
					}]),
					pos: e.pos
				});

				// prevent callbacks from being called more than once
				this.append({expr: EReturn(null), pos: e.pos});

				this.isReturned = true;
			}
			else {
				Context.error('Unreachable callback', e.pos);
			}
		}
		else {
			this.append(this.currentExpr);
		}
	}

	function handleReturn(e) {
		if (!this.isReturned) {
			//replace return wtih call to callback function supporting error first callback style
			this.append({
				expr: ECall({
					expr: EConst(CIdent('__return')),
					pos: e.pos
				}, [{
					expr: EConst(CIdent('null')),
					pos: e.pos
				}, e]),
				pos: e.pos
			});

			// prevent callbacks from being called more than once
			this.append({expr: EReturn(null), pos: e.pos});

			this.isReturned = true;
		}
		else {
			Context.error('Unreachable callback', e.pos);
		}
	}

	function handle() {
		// cache return type to apply to callback value
		this.returnType = this.method.ret;

		//remove return type requirement
		this.method.ret = null;
		
		var type = null;

		//@TODO Fix this?
		// apply return type to callback function for type checking
		if (this.returnType != null) {
			type = TFunction([
					TPath({name: null, pack: []}),
					this.returnType
				],
				TPath({name: 'Void', pack: []})
			);
		}

		// add callback to method as last argument
		this.method.args.push({
			name: '__return',
			type: type 
		});

		var expr = this.rootExpr;

		this.currentExpr = expr;

		// first expr should be block
		switch(expr.expr) {
			case EBlock(exprs):
				this.handleBlock(exprs);

			default:
				this.append(expr);
		}

		return {
			expr: EBlock(this.rootBlock),
			pos: expr.pos
		};
	}

	function append(expr:Expr) {
		this.currentBlock.push(expr);
	}

}
