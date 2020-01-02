package en;

import flash.display.Sprite;
import mt.deepnight.slb.BSprite;
import mt.deepnight.Lib;
import mt.MLib;
import Const;

class Actor extends Entity {
	public static var ALL : Array<Actor> = [];
	public static var LOCKED_CELLS : Map<Int, Bool> = new Map();

	var tf			: flash.text.TextField;
	public var isActing			: Bool;
	public var action			: Action;
	public var lastTurn			: Int;
	public var priority			: Int;
	var isSkipping				: Bool;
	public var extraActions		: Int;
	public var tcd				: mt.Cooldown;

	public function new(x,y) {
		super(x,y);
		tcd = new mt.Cooldown();
		ALL.push(this);
		isActing = false;
		isSkipping = false;
		action = None;
		lastTurn = -1;
		extraActions = 0;

		tf = Game.ME.createField("?");
		#if debug
		spr.addChild(tf);
		#end
		tf.width = 200;
	}

	inline function turn() {
		return Game.ME.turn;
	}

	public static function initLocks() {
		LOCKED_CELLS = new Map();
	}

	public static function getWaitingActors() {
		return en.Actor.ALL.filter( function(e) return !e.playedThisTurn() );
	}

	public function skipTurn() {
		#if debug
		//trace("skipped turn: "+this);
		#end
		lastTurn = turn();
		isSkipping = true;
		nextCell = null;
		endTurn();
	}

	override function toString() {
		return "Actor#"+uid+"("+action+")@"+cx+","+cy+","+playedThisTurn();
	}

	public function turnInit() {
		tcd.update();
		isSkipping = false;
	}

	public function playTurn() {
		#if debug
		//trace("play: "+this+" ("+action+") "+extraActions);
		#end
		tryToLockCell(cx,cy);
		lastTurn = turn();
		isActing = true;

		switch( action ) {
			case None :
				skipTurn();

			case Pass :
				endTurn();

			case Hunt(_), ExploreAround(_) :

			case Walk(cx,cy) :
				headTo(cx,cy);
				if( nextCell!=null && !tryToLockCell(nextCell.cx, nextCell.cy) ) {
					stop();
					skipTurn();
				}
				else
					setAutoDir();

			case Patrol :
		}
	}

	public function tryToLockCell(cx:Int,cy:Int) {
		return true;
		if( LOCKED_CELLS.exists(coordToId(cx,cy)) )
			return false;
		else {
			LOCKED_CELLS.set(coordToId(cx,cy), true);
			return true;
		}
	}

	public inline function playedThisTurn() {
		return lastTurn>=turn();
	}

	public function setAction(a:Action) {
		action = a;
	}

	public static function anyoneIsActing() {
		for(e in ALL)
			if( e.isActing )
				return true;
		return false;
	}

	override function unregister() {
		super.unregister();
		ALL.remove(this);
	}

	function endTurn() {
		#if debug
		//trace("end: "+this);
		#end
		stop();
		isActing = false;
		switch( action ) {
			case Walk(x,y) :
				if( cx==x && cy==y )
					setAction(None);

			case Hunt(_), ExploreAround(_) :

			case None, Patrol:

			case Pass :
				extraActions = 0;
				setAction(None);
		}

		if( extraActions>0 ) {
			extraActions--;
			lastTurn = turn()-1;
			#if debug
			//trace("play again");
			#end
		}

		Game.ME.onActorDone();
	}

	public function interruptAction() {
		action = None;
	}

	override function update() {
		super.update();

		tf.text = lastTurn+Std.string(action)+":"+isActing;

		if( isActing ) {
			switch( action ) {
				case Walk(_), ExploreAround(_), Hunt(_), Patrol :
					if( nextCell==null )
						skipTurn(); // strange bug, dirty fix!
				case Pass, None :
			}
		}

		// Follow path
		if( nextCell!=null ) {
			var pt = { x:nextCell.cx+0.5, y:nextCell.cy+0.5 };
			var x = cx+xr;
			var y = cy+yr;
			if( cx==nextCell.cx && cy==nextCell.cy ) {
				endTurn();
			}
			else {
				var a = Math.atan2(pt.y-y, pt.x-x);
				dx+=Math.cos(a)*getSpeed();
				dy+=Math.sin(a)*getSpeed();
			}
		}

		// Auto center
		if( !isActing ) {
			var c = getCellCenter();
			var d = Lib.distanceSqr(c.xr, c.yr, xr,yr);
			if( d>=0.05*0.05 ) {
				var a = Math.atan2(c.yr-yr, c.xr-xr);
				var d = Math.sqrt(d);
				dx+=Math.cos(a)*d*0.2;
				dy+=Math.sin(a)*d*0.2;
			}
			else {
				xr = c.xr;
				yr = c.yr;
				updateSprite();
			}
		}


		if( (dx!=0 || dy!=0) && game.time%4==0 )
			Fx.ME.tap(xx, yy+5);
	}
}

