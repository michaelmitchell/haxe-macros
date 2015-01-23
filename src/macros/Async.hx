package macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Printer;

class Async {

    public static function build() {
		var fields = Context.getBuildFields();

		//trace(fields);
		
		for (field in fields) {
			switch (field.kind) {
				case FFun(method):
					if (method.expr != null) {
						loop(method.expr);
					}
				default:
			}
		}
		
		return fields;
	}
	
	public static function loop(e:Expr) {
		switch(e.expr) {
			case EMeta(s, e):
				if (s.name == 'wait') {
					//modify(e);
				}

			case EVars(vs):
				for (v in vs) {
					var ve = v.expr;

					if (ve != null) {
						switch (ve.expr) {
							case EMeta(s, se):
								if (s.name == "wait") {
									switch (se.expr) {
										case ECall(ce, p):
											//var method = Context.parse('var a1', e.pos);

											// replace with new block of code

											// clone an expression... convert to string then parse it
											var exprStr = ExprTools.toString(e),
												newExpr = Context.parse(exprStr, Context.currentPos());

											e.expr = EBlock([newExpr]);


										default:
									}
								}

							default:
						}
					}
				}

			case EBlock(exprs):
				for (expr in exprs) {
					loop(expr);
				}

			default:
				//trace(e);
		}
	}

	public static function modify(e:Expr) {
		switch(e.expr) {
			case ECall(x, p):
				var method = Context.parse('function(result:Dynamic) {}', e.pos);

				//p.push(method);

				e.expr = ECall(x, p);

			default:
		}
	}
	
}
