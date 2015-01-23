package macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Printer;

class Async {

	/**
	 *
	 */
	var root:Array<Expr>;

	/**
	 *
	 */
	var write:Array<Expr>;

	/**
	 *
	 */
    public static function build() {
		var fields = Context.getBuildFields();

		//trace(fields);
		
		for (field in fields) {
			switch (field.kind) {
				case FFun(method):
					if (method.expr != null) {
						var async = new Async();

						method.expr = async.process(method.expr);
					}
				default:
			}
		}
		
		return fields;
	}

	/**
	 *
	 */
	public function new() {
		// root block
		this.root = [];

		// use root as default write block
		this.write = this.root;
	}

	/**
	 *
	 */
	public function process(e:Expr) {
		switch(e.expr) {
			// loop through blocks
			case EBlock(exprs):
				for (expr in exprs) {
					process(expr);
				}

			case EVars(vs):
				var manipulated = false;

				for (v in vs) {
					var ve = v.expr;

					if (ve != null) {
						switch (ve.expr) {
							case EMeta(s, se):
								if (s.name == 'wait') {
									switch (se.expr) {
										case ECall(ce, p):
											var method = Context.parse('function(' + v.name + ') {}', e.pos);

											p.push(method);

											// write new block
											this.write.push({
												expr: EBlock([se]),
												pos: Context.currentPos()
											});

											// create write block
											this.write = [];

											switch (method.expr) {
												case EFunction(name, fe):
													// replace new methods block with new write target
													fe.expr = {
														expr: EBlock(this.write),
														pos: Context.currentPos()
													};

												default:
											}

											manipulated = true;
										default:
									}
								}
							default:
						}
					}
				}

				if (manipulated == false) {
					this.write.push(e);
				}

			// unmanipulated expressions
			default:
				this.write.push(e);
		}

		return {
			expr: EBlock(this.root),
			pos: e.pos
		};
	}

}
