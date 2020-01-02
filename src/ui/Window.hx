package ui;

import mt.deepnight.Buffer;
import mt.deepnight.Lib;
import mt.flash.Key;
import flash.display.*;
import mt.MLib;
import mt.deepnight.slb.*;
import Const;

class Window extends mt.deepnight.mui.Window {

	public function new(p) {
		super(p, false);
		color = 0x053e40;

		autoCenterX = autoCenterY = false;
		hasBackground = false;
		setWidth(100);
		margin = 2;
	}

	override function renderBackground(w,h) {
		bg.graphics.clear();
		bg.graphics.beginFill(color, bgAlpha);
		bg.graphics.drawRect(0,0, w,h);
	}


	override function prepareRender() {
		super.prepareRender();

		//setPos(Game.ME.buffer.width*0.5-getWidth()*0.5, 10);
	}
}
