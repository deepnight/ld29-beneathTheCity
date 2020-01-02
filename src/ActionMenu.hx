import mt.deepnight.Buffer;
import mt.deepnight.Lib;
import mt.flash.Key;
import flash.display.*;
import mt.MLib;
import ui.*;
import mt.deepnight.slb.*;
import Const;

class ActionMenu {
	var game				: Game;
	public var wrapper		: Sprite;
	var win					: ui.Window;
	var active				: Int;
	var frameSkip			: Int;
	var tip					: mt.deepnight.mui.Label;

	public function new() {
		game = Game.ME;
		frameSkip = 5;
		active = 0;

		wrapper = new Sprite();
		game.buffer.dm.add(wrapper, Const.DP_UI);
		//wrapper.visible = false;

		win = new Window(wrapper);

		var b = new Button(win, "CANCEL", destroy, "");
		b.color = 0x484675;

		var b = new Button(win, "Dash"+itemCountStr("dash"), onDash, "Gives an extra free action.");
		if( !hasItem("dash") )
			b.disable();

		var b = new Button(win, "Water arrow"+itemCountStr("arrow"), onArrow, "Shoots the closest light and turn it off.");
		if( !hasItem("arrow") )
			b.disable();

		var b = new Button(win, "Bell"+itemCountStr("noise"), onNoise, "Make a noise to attract ennemies.");
		if( !hasItem("noise") )
			b.disable();

		//var b = new Button(win, "Blackjack"+itemCountStr("knock"), onKnock, "Knock a guard. You must stand behind him, unseen.");
		//if( !hasItem("knock") )
			//b.disable();

		win.setPos(5, 5);

		tip = new mt.deepnight.mui.Label(wrapper, "");
		tip.setFont("def", 8);
		tip.setHAlign(Left);
		tip.setVAlign(Top);
		tip.setWidth(180);
		//tip.hasBackground = true;

		tip.x = win.x + win.getWidth() + 5;
		tip.y = win.y + win.getHeight() - 18;

		setActive(0);
	}

	public function destroy() {
		wrapper.parent.removeChild(wrapper);
		win.destroy();
		tip.destroy();
		game.menu = null;
	}


	public function setTip(str:String) {
		if( str=="" )
			tip.hide();
		else {
			tip.show();
			tip.setText(str);
		}
	}



	function hero() {
		return game.hero;
	}

	function hasItem(a) {
		return game.inventory.get(a)>0;
	}

	function itemCountStr(a) {
		return hasItem(a) ? " x"+game.inventory.get(a) : "";
	}

	function useItem(a) {
		game.inventory.set(a, game.inventory.get(a)-1);
	}

	function onDash() {
		if( hasItem("dash") ) {
			hero().extraActions = 1;
			useItem("dash");
			destroy();
		}
	}

	function onNoise() {
		if( hasItem("noise") ) {
			game.noise(hero().cx, hero().cy, 9);
			useItem("noise");
			destroy();
		}
	}

	//function onKnock() {
		//if( hasItem("knock") ) {
			//useItem("knock");
			//var cx = hero().cx;
			//var cy = hero().cy;
			//var all = en.Mob.ALL.filter( function(e) {
				//return e.cx
			//}
			//for(e in en.Mob.ALL) {
				//if( e.cx==hero().cx || e.cy==hero().cy )
			//}
			//game.noise(hero().cx, hero().cy, 6);
			//destroy();
		//}
	//}

	function onArrow() {
		if( hasItem("arrow") ) {
			var h = hero();
			var best = null;
			var dist = 99999.;
			for(pt in game.level.lightSources) {
				var d = Lib.distanceSqr(h.cx,h.cy,pt.cx,pt.cy);
				if( pt.active && h.sightCheck(pt.cx, pt.cy) && d<dist && d<=6*6 ) {
					best = pt;
					dist = d;
				}
			}

			if( best!=null ) {
				useItem("arrow");
				best.active = false;
				game.level.render();
				//game.noise(h.cx, h.cy, 2);
				game.noise(best.cx, best.cy, 2);
				Fx.ME.water((best.tx+0.5)*Const.GRID, (best.ty+0.5)*Const.GRID);
				destroy();
			}
			else {
				Fx.ME.notify("No torch around.");
			}
		}
	}

	function setActive(n) {
		if( n<0 ) n = 0;
		if( n>=win.getChildren().length ) n = win.getChildren().length-1;
		active = n;
		for(c in win.getChildren())
			c.removeState("active");
		win.getChildren()[active].addState("active");
	}

	public function update() {
		if( frameSkip>0 ) {
			frameSkip--;
			return;
		}

		if( Key.isToggled(Key.UP) )
			setActive(active-1);

		if( Key.isToggled(Key.DOWN) )
			setActive(active+1);

		if( Key.isToggled(Key.SPACE) || Key.isToggled(Key.ENTER) ) {
			cast( win.getChildren()[active] ).use();
		}
	}
}
