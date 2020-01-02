import flash.display.BlendMode;
import flash.display.Sprite;
import flash.display.Bitmap;
import flash.display.BitmapData;

import mt.deepnight.Particle;
import mt.MLib;
import mt.deepnight.Lib;
import mt.deepnight.Color;

import Const;

class Fx {
	public static var ME : Fx;

	var game			: Game;
	var pt0				: flash.geom.Point;

	public function new() {
		ME = this;
		game = Game.ME;
		pt0 = new flash.geom.Point(0,0);
	}

	public function register(p:Particle, ?b:BlendMode) {
		game.sdm.add(p, Const.DP_FX);
		p.blendMode = b!=null ? b : BlendMode.ADD;
	}
	public function registerOver(p:Particle, ?b:BlendMode) {
		game.sdm.add(p, Const.DP_FX_TOP);
		p.blendMode = b!=null ? b : BlendMode.ADD;
	}
	public function registerUI(p:Particle, ?b:BlendMode) {
		game.buffer.dm.add(p, Const.DP_FX_TOP);
		p.blendMode = b!=null ? b : BlendMode.ADD;
	}
	public function registerUnder(p:Particle, ?b:BlendMode) {
		game.sdm.add(p, Const.DP_FX_BG);
		p.blendMode = b!=null ? b : BlendMode.ADD;
	}

	public function marker(cx,cy, ?col=0xFFFF00, ?l=40) {
		//var pt = Entity._isoToScreen(Std.int(cx), Std.int(cy));
		var p = new Particle((Std.int(cx)+0.5)*Const.GRID, (Std.int(cy)+0.5)*Const.GRID);
		p.drawCircle(3, col);
		p.life = l;
		p.filters = [ new flash.filters.GlowFilter(col,1, 8,8,1) ];
		register(p);
	}

	public function tap(x,y) {
		var p = new Particle(x,y);
		p.drawCircle(4, 0x818CA3, 0.5,false);
		p.scaleY = 0.6;
		p.ds = -0.06;
		p.life = 0;
		p.filters = [ new flash.filters.BlurFilter(2,2) ];
		registerUnder(p, NORMAL);
	}


	public function dot(x,y) {
		var p = new Particle(x,y);
		p.drawBox(2,2, 0xFFFF00);
		p.life = 40;
		p.filters = [ new flash.filters.GlowFilter(0xFFBF00,1, 8,8,3, 2) ];
		register(p);
		for(i in 0...10) {
			var p = new Particle(x,y);
			p.drawBox(1,1, 0xFFFF00);
			p.alpha = 0;
			p.da = 0.1;
			p.life = rnd(5,20);
			p.moveAng( rnd(0,6.28), rnd(2,4));
			p.frict = rnd(0.9, 0.97);
			p.gx = rnd(0,0.2,true);
			p.gy = rnd(0,0.2,true);
			p.filters = [ new flash.filters.GlowFilter(0xFFBF00,1, 4,4,3) ];
			register(p);
		}
	}

	public function blood(cx,cy) {
		for(i in 0...50) {
			var p = new Particle((cx+0.5)*Const.GRID, (cy+1)*Const.GRID);
			p.drawBox(rnd(1,3),1, 0xC10000);
			p.dr = rnd(2,10,true);
			p.alpha = 0;
			p.da = 0.1;
			p.delay = rnd(0,5);
			p.life = rnd(20,40);
			p.moveAng( rnd(0,6.28), rnd(2,4));
			p.dx = rnd(0,2,true);
			p.dy = -rnd(3,6);
			p.frict = rnd(0.9, 0.97);
			p.gy = rnd(0.1,0.2);
			p.filters = [ new flash.filters.DropShadowFilter(1,90, 0x590000,1, 0,0) ];
			register(p);
		}

		for(i in 0...10) {
			var p = new Particle((cx+0.5)*Const.GRID, (cy+1)*Const.GRID);
			p.drawBox(rnd(1,3),1, 0xE3CB91);
			p.dr = rnd(2,10,true);
			p.alpha = 0;
			p.da = 0.1;
			p.delay = rnd(0,5);
			p.life = rnd(20,40);
			p.moveAng( rnd(0,6.28), rnd(2,4));
			p.dx = rnd(0,2,true);
			p.dy = -rnd(6,9);
			p.frict = rnd(0.9, 0.97);
			p.gy = rnd(0.1,0.2);
			p.filters = [ new flash.filters.GlowFilter(0xC10000,0.2, 4,4,3) ];
			register(p);
		}
	}

	public function notify(txt:String) {
		var p = new Particle(5, game.buffer.height-5);
		var tf = game.createField(txt, 0xD0829D);
		p.addChild(tf);
		p.dy = -1.5;
		p.frict = 0.95;
		p.life = 80;
		registerUI(p);
	}

	public function water(x,y) {
		var col = 0x5788E3;
		var p = new Particle(x,y);
		p.drawCircle(8,col,0.5,true);
		p.life = 0;
		p.ds = 0.1;
		register(p);

		for(i in 0...15) {
			var p = new Particle(x,y);
			p.drawBox(rnd(2,3),rnd(1,3), col, rnd(0.3, 0.6));
			p.life = rnd(5,20);
			p.moveAng( rnd(0,6.28), rnd(1,3));
			p.frict = rnd(0.9, 0.97);
			p.gy = rnd(0.1, 0.15);
			p.filters = [ new flash.filters.BlurFilter(2,2) ];
			register(p);
		}
	}

	public function revealFog(cx,cy) {
		//var x = (cx+0.5)*Const.GRID;
		//var y = (cy+0.5)*Const.GRID;
		//for(i in 0...3) {
			//var p = new Particle(x+rnd(0,8,true), y+rnd(0,8,true));
			//p.drawCircle(3, 0x241625);
			//p.life = rnd(10,20);
			//p.dx = rnd(0,1,true);
			//p.dy = rnd(0,1,true);
			//p.frict = 0.9;
			//p.filters = [ new flash.filters.BlurFilter(16,16) ];
			//register(p, NORMAL);
		//}
	}

	public function noise(cx,cy,r) {
		for(i in 0...3 ) {
			var p = new Particle((cx+0.5)*Const.GRID, (cy+0.5)*Const.GRID);
			p.drawCircle(r*Const.GRID*0.2, 0xAEB3D2, 0.4, false);
			p.ds = 0.30;
			p.delay = i*5;
			p.alpha = 0;
			p.da = 0.1;
			p.onUpdate = function() p.ds*=0.9;
			p.life = 10;
			registerOver(p);
		}
	}

	public function mobNoise(cx,cy) {
		var p = new Particle((cx+0.5)*Const.GRID, (cy+0.5)*Const.GRID);
		p.drawCircle(Const.GRID*0.2, 0xAEB3D2, 0.1, false);
		p.ds = 0.40;
		p.alpha = 0;
		p.da = 0.1;
		p.onUpdate = function() p.ds*=0.9;
		p.life = 10;
		registerOver(p);
	}

	public function alert(e:Entity) {
		var n = 15;
		for(i in 0...n) {
			//var a = e.getDirAng() + rnd(0,1,true);
			var a = 6.25*i/n + rnd(0, 0.1, true);
			var p = new Particle(e.xx,e.yy);
			p.drawBox(rnd(2,3),1, 0xFF0000);
			p.alpha = 0;
			p.da = 0.1;
			p.life = rnd(5,20);
			p.moveAng( a, rnd(2,3));
			p.rotation = MLib.toDeg(a);
			p.frict = 0.8;
			p.delay = 8;
			p.onStart = function() p.setPos(e.xx,e.yy);
			p.filters = [ new flash.filters.GlowFilter(0xFF0000,0.7, 8,8,3) ];
			registerOver(p);
		}
	}

	public function firefly(cx,cy) {
		var col = 0x91D32C;
		var p = new Particle((cx+0.5)*Const.GRID + rnd(4,10,true), (cy+0.5)*Const.GRID + rnd(4,10,true));
		p.drawBox(1,1, col, rnd(0.5,1));
		p.filters = [ new flash.filters.GlowFilter(col,0.6, 2,2,3) ];
		p.alpha = 0;
		p.da = rnd(0.02,0.05);
		p.dx = rnd(0,1,true);
		p.dy = rnd(0,1,true);
		p.gx = rnd(0,0.1,true);
		p.gy = rnd(0,0.1,true);
		p.life = rnd(5,20);
		p.frict = 0.7;
		register(p);
	}

	public function smoke(x:Float,y:Float) {
		var col = 0x51667D;
		var p = new Particle(x,y-rnd(0,3));
		var w = rnd(1,2);
		p.drawBox(w,w, col, rnd(0.5,1));
		p.filters = [ new flash.filters.GlowFilter(col,0.6, 2,2,3) ];
		p.alpha = 0;
		p.da = rnd(0.02,0.05);
		p.gy = -rnd(0.10, 0.15);
		p.life = rnd(15,30);
		p.filters = [ new flash.filters.BlurFilter(4,4) ];
		p.frict = 0.7;
		register(p);
	}

	inline function rnd(min,max,?sign) { return Lib.rnd(min,max,sign); }
	inline function irnd(min,max,?sign) { return Lib.irnd(min,max,sign); }

	public function update() {
		Particle.update();
	}
}
