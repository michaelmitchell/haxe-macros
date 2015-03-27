package macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;

class Await {

	var field:Field;

	var method:Function;

	var metadata:Metadata;

	var rootExpr:Expr;

	var rootBlock:Array<Expr>;

	var currentBlock:Array<Expr>;

	var currentExpr:Expr;

	var currentBinop:Binop;
	
	var currentBinopExpr1:Expr;

	var currentBinopExpr2:Expr;

	var currentMetadataEntry:MetadataEntry;

	var currentMetadataExpr:Expr;

	var currentVar:Var;

	var wasCalled:Bool = false;

	var isInIf:Bool = false;

	static function build() {
		var fields = Context.getBuildFields();

		for (field in fields) {
			switch (field.kind) {
				case FFun(method):
					if (method.expr != null) {
						method = Await.run(field, method);
					}
				default:
			}
		}

		return fields;
	}

	static function run(field:Field, method:haxe.macro.Function) {
		var instance = new Await(field, method);

		method.expr = instance.handle();

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
		for (expr in exprs) {
			this.currentExpr = expr;

			switch(expr.expr) {
				case EBinop(op, e1, e2):
					this.handleBinop(op, e1, e2);

				case EBlock(exprs):
					this.handleBlock(exprs);

				case EIf(econd, eif, eelse):
					this.handleIf(econd, eif, eelse);

				case EMeta(s, e):
					this.handleMeta(s, e);

				case ETry(e, catches):
					this.handleTry(e, catches);

				case EVars(vars):
					this.handleVars(vars);

				default:
					this.append(this.currentExpr);
			}
		}
	}

	function handleIf(econd: Expr, eif: Expr, eelse: Null<Expr>) {
		var currentBlock = this.currentBlock,
			isInIf = this.isInIf;
	
		this.isInIf = true;

		if (!isInIf) {
			this.wasCalled = false;
		}

		var blocks = [];

		if (eif != null) {
			var newIfBlock = [];

			this.currentBlock = newIfBlock;

			switch(eif.expr) {
				case EBlock(exprs):
					this.handleBlock(exprs);

				default:
			}

			blocks.push(this.currentBlock);

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

			if (this.isInIf) {
				blocks.push(this.currentBlock);
			}

			eelse.expr = EBlock(newElseBlock);
		}

		// switch back to previous block
		this.currentBlock = currentBlock;

		var method;

		// only add the "after if" callback if there was an async call made within the if statement
		if (this.wasCalled) {
			if (!isInIf) {	
				method = Context.parse('var __continue = function() {}', econd.pos);

				this.append(method);
			}

			// add calls to __continue where needed
			for (block in blocks) {
				var lastExpr = block[block.length - 1];

				if (lastExpr != null) {
					switch (lastExpr.expr) {
						case EReturn(e):
							// don't add a call to continue if already returned...
						default:
							var call = Context.parse('__continue()', econd.pos);

							block.push(call);
					}	
				}
				else {
					var call = Context.parse('__continue()', econd.pos);

					block.push(call);
				}
			}
		}

		this.append({
			expr: EIf(econd, eif, eelse),
			pos: econd.pos
		});

		if (this.wasCalled && !isInIf) {
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

		this.append({
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
						this.append(this.currentExpr);
				}
			}
			else {
				this.append(this.currentExpr);
			}

			this.currentBinop = null;
			this.currentBinopExpr1 = null;
			this.currentBinopExpr2 = null;
		}
		else {
			this.append(this.currentExpr);
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
						this.append(this.currentExpr);
				}
			}
			else {
				this.append(this.currentExpr);
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
					this.wasCalled = true;

					this.handleCall(e, p);

				default:
					this.append(this.currentExpr);
			}
		}
		else {
			this.append(this.currentExpr);
		}

		this.currentMetadataEntry = null;
		this.currentMetadataExpr = null;
	}

	function handleCall(ce, p) {
		var pos = Context.currentPos();

		this.append({expr: EBlock([this.currentMetadataExpr]), pos: pos});

		// create write block
		var binopExpr1 = this.currentBinopExpr1,
			currentVar = this.currentVar,
			name;

		//work out the name of assignment if any
		if (binopExpr1 != null) {
			switch (binopExpr1.expr) {
				case EConst(c):
					switch (c) {
						case CIdent(s):
							name = s;
						default:
					}
				default:
			}
		}
		else if (currentVar != null) {
			name = 'var ' + currentVar.name;
		}
		
		var method = Context.parse('function(__error, __result) {}', pos);

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

	function handle() {
		var expr = this.rootExpr;

		this.currentExpr = expr;

		// first expr should be block
		switch (expr.expr) {
			case EBlock(exprs):
				this.handleBlock(exprs);

			default:
				this.append(expr);
		}

		return {
			expr: EBlock(this.rootBlock),
			pos: Context.currentPos()
		};
	}

	function append(expr:Expr) {
		this.currentBlock.push(expr);
	}

}
