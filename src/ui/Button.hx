package ui;

import mt.deepnight.Buffer;
import mt.deepnight.Lib;
import mt.flash.Key;
import flash.display.*;
import mt.MLib;
import mt.deepnight.slb.*;
import Const;

class Button extends mt.deepnight.mui.Button {
	var desc		: String;

	public function new(p, l,cb, desc:String) {
		super(p, l,cb);
		this.desc = desc;
		//hasBackground = false;
		setFont("def", 8);
		minHeight = 0;
		color = 0x8B476B;
		setTextAlignLeft();
	}

	override function renderBackground(w,h) {
		bg.graphics.clear();
		bg.graphics.beginFill(color, bgAlpha);
		bg.graphics.drawRect(0,0, w,h);
	}

	public function use() {
		onClick();
	}

	override function applyStates() {
		super.applyStates();

		if( hasState("active") ) {
			Game.ME.menu.setTip(desc);
			bg.filters = [
				new flash.filters.GlowFilter(0xE4D7EA,1,2,2,4),
				new flash.filters.GlowFilter(0x804F97,0.5,8,8,2),
			];
		}
		else
			bg.filters = [
				new flash.filters.DropShadowFilter(1, -90, 0x0,0.2, 0,0,1, 1,true),
			];
	}
}
