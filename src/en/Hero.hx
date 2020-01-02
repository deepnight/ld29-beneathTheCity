package en;

import mt.flash.Key;
import Const;
import flash.display.Sprite;
import mt.deepnight.slb.BSprite;

class Hero extends en.Actor {
	public var sneaking			: Bool;

	public function new(x,y) {
		super(x,y);

		priority = 1;
		sneaking = false;

		//spr.graphics.clear();
		//spr.graphics.beginFill(0x00FF40,1);
		//spr.graphics.lineStyle(1,0x0,0.2,false,NONE);
		//spr.graphics.drawCircle(0,0,5);

		//spr.a.play("hidle");
		spr.setCenter(0.5, 0.8);
		//spr.a.registerStateAnim("hrun", 10);
		spr.a.registerStateAnim("hlean_l", 3, function() return dx==0 && dy==0 && xr<0.5);
		spr.a.registerStateAnim("hlean_r", 2, function() return dx==0 && dy==0 && (xr!=0.5 || yr!=0.5));
		//spr.a.registerStateAnim("hlean_r", 2, function() return dx==0 && dy==0 && (xr!=0.5 || yr!=0.5));
		spr.a.registerStateAnim("hrun", 1, function() return dx!=0 || dy!=0);
		spr.a.registerStateAnim("hidle", 0);
	}

	public function isWaitingOrder() {
		return !playedThisTurn() && action==None && !isActing;
	}


	override function getSpeed() {
		return super.getSpeed() * (sneaking ? 0.5 : 1);
	}

	override function tryToLockCell(x,y) {
		return true;
	}

	override function toString() {
		return "Hero("+super.toString()+")";
	}

	public function decide(a:Action) {
		#if debug
		//trace("decide : "+a);
		#end
		setAction(a);
		switch( a ) {
			case Walk(_) :
				cd.set("lean", 3);

			case Pass :
				skipTurn();

			default :
		}
		Game.ME.nextActor();
	}

	public inline function getIllumination() {
		return game.level.getIllumination(cx,cy);
	}

	function getLeanDir() {
		if( cd.has("lean") )
			return null;

		var level = Game.ME.level;

		var closest : Mob = null;
		var best = 9999.;
		for(e in Mob.ALL) {
			var d = mt.deepnight.Lib.distanceSqr(cx,cy,e.cx,e.cy);
			if( d<best ) {
				closest = e;
				best = d;
			}
		}

		if( closest==null )
			return null;

		var p = getPath(closest.cx,closest.cy);
		if( p.length>8 )
			return null;


		var dx = 0;
		var dy = 0;
		if( level.hasCollision(cx-1, cy) && closest.cx<cx )
			dx = -1;
		if( level.hasCollision(cx+1, cy) && (dx==0 || closest.cx>cx) )
			dx = 1;

		if( level.hasCollision(cx, cy-1) && closest.cy<cy )
			dy = -1;
		if( level.hasCollision(cx, cy+1) && (dy==0 || closest.cy>cy) )
			dy = 1;

		return {dx:dx, dy:dy}
	}

	override function getCellCenter() {
		var c = super.getCellCenter();

		var l = getLeanDir();
		if( l==null )
			return c;

		if( l.dx<0 ) { c.xr-=0.3; c.yr+=0.; }
		else if( l.dx>0 ) { c.xr+=0.3; c.yr+=0.; }
		else if( l.dy<0 ) c.yr=0.2;
		else if( l.dy>0 ) { c.yr=0.51; }
		return c;
	}

	override function setDir(d) {
		super.setDir(d);
		if( dir>=2 )
			spr.scaleX=-1;
		else
			spr.scaleX=1;
	}

	override function turnInit() {
		super.turnInit();
		//extraActions = 2;
	}

	override function playTurn() {
		super.playTurn();
	}

	override function endTurn() {
		super.endTurn();

		for(e in Mob.ALL)
			e.watch();

		if( game.level.hasSpot(cx,cy,"exit") )
			game.nextLevel();
	}

	override function update() {
		super.update();

		var level = game.level;

		if( game.time%4==0 )
			level.revealFog(cx,cy);

		var f = 0.3 + 0.7*level.getLight(cx,cy);
		spr.transform.colorTransform = new flash.geom.ColorTransform(f,f,f,1);
		tf.visible = false;

		var gem = game.gem;
		switch( getIllumination() ) {
			case 0 :
				gem.setFrame(2);
				gem.filters = [];

			case 1 :
				gem.setFrame(1);
				gem.filters = [ new flash.filters.GlowFilter(0x0b8f39,0.3, 16,16) ];

			case 2 :
				gem.setFrame(0);
				gem.filters = [ new flash.filters.GlowFilter(0x11D957,0.3+Math.cos(game.time*0.2)*0.05, 16,16) ];
		}


		if( !isActing ) {
			//if( getCellCenter().xr<0.5 )
				//setDir(3);
			//if( getCellCenter().xr>0.5 )
				//setDir(1);
		}
	}
}