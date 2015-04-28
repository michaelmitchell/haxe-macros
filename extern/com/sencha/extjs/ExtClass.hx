package com.sencha.extjs;

@:native('Ext.Class')
extern class ExtClass {

	public static function create(klass: Dynamic, data: Dynamic): Void;

	public static function process(klass: Dynamic, data: Dynamic, ?onCreated: Dynamic): Void;

}
