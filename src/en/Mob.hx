package en;

import mt.deepnight.Lib;
import mt.MLib;
import Const;
import flash.display.Sprite;
import mt.deepnight.slb.BSprite;

class Mob extends en.Actor {
	public static var ALL : Array<Mob> = [];

	var patrolPoints		: Array<{cx:Int, cy:Int}>;
	//var patrolPoints		: Map<Int,Bool>;
	var doneList			: Map<Int,Bool>;
	var lastPatrolDir		: {dx:Int, dy:Int};
	var history				: Array<{cx:Int, cy:Int}>;
	var arrow				: BSprite;
	var alertIcon			: BSprite;
	var fovEnd				: BSprite;
	var pnext				: BSprite;
	var ghost				: BSprite;
	public var alert		: Int;
	var guessedFleeDir		: Bool;

	public function new(x,y) {
		super(x,y);
		ALL.push(this);
		guessedFleeDir = false;
		doneList = new Map();
		priority = 0;
		dir = 0;
		alert = 0;
		//speed*=0.6;
		history = [];

		patrolPoints = new Array();
		explorePatrolPoints(cx,cy);
		lastPatrolDir = {dx:0, dy:0}

		alertIcon = Game.ME.tiles.get("icon", 1);
		spr.addChild(alertIcon);
		alertIcon.setCenter(0.5,1);
		alertIcon.blendMode = ADD;
		alertIcon.visible = false;
		alertIcon.y = -5;

		ghost = game.tiles.get("icon", 5);
		game.sdm.add(ghost, Const.DP_BG);
		ghost.setCenter(0.5,0.5);
		ghost.alpha = 0.3;
		ghost.visible = false;

		fovEnd = Game.ME.tiles.get("icon", 3);
		fovEnd.setCenter(0.5,0.5);
		fovEnd.alpha = 0.;
		game.sdm.add(fovEnd, Const.DP_MOBS);

		pnext = Game.ME.tiles.get("icon", 3);
		pnext.setCenter(0.5,0.5);
		pnext.alpha = 0.2;
		game.sdm.add(pnext, Const.DP_MOBS);

		arrow = Game.ME.tiles.get("icon", 0);
		game.sdm.add(arrow, Const.DP_BG);
		arrow.setCenter(-0.2,0.5);
		arrow.alpha = 0.6;

		//spr.graphics.clear();
		//spr.graphics.beginFill(0xFF0000,1);
		//spr.graphics.lineStyle(1,0x0,0.2,false,NONE);
		//spr.graphics.drawCircle(0,0,3);
		spr.setCenter(0.5, 0.8);
		spr.a.registerStateAnim("mrun", 3, function() return (dx!=0 || dy!=0) && alert>=2);
		spr.a.registerStateAnim("mwalk", 2, function() return dx!=0 || dy!=0 );
		spr.a.registerStateAnim("midle_angry", 1, function() return alert>0);
		spr.a.registerStateAnim("midle_calm", 0);

		setAction(Patrol);
	}

	inline function hero() {
		return Game.ME.hero;
	}

	override function toString() {
		return "Mob("+super.toString()+")";
	}

	override function setDir(d) {
		super.setDir(d);
		arrow.rotation = MLib.toDeg(getDirAng());
		updatePreviews();
		if( dir>=2 )
			spr.scaleX=-1;
		else
			spr.scaleX=1;
	}

	override function sightCheck(x,y) {
		var dx = 0;
		var dy = 0;
		switch( dir ) {
			case 0 : dy = -1;
			case 1 : dx = 1;
			case 2 : dy = 1;
			case 3 : dx = -1;
		}
		return Game.ME.level.sightCheck(cx,cy, x,y, false) || Game.ME.level.sightCheck(cx+dx,cy+dy, x,y, false);
	}


	public function spottedSomething(cx:Int,cy:Int) {
		history = [];
		if( hero().cx==cx && hero().cy==cy ) {
			setGhost(cx,cy);
			guessedFleeDir = false;
		}
		else
			guessedFleeDir = true;
		setAction(Hunt(cx,cy));

		if( alert<2 )
			Fx.ME.alert(this);

		setAlert(alert+1);
	}

	function setGhost(cx,cy) {
		ghost.visible = true;
		ghost.x = (cx+0.5)*Const.GRID;
		ghost.y = (cy+0.5)*Const.GRID;
	}

	function setAlert(n) {
		if( n>2 ) n = 2;
		alert = n;
		alertIcon.visible = alert>0;
		alertIcon.setFrame( alert==1 ? 1 : 2 );
	}

	override function turnInit() {
		super.turnInit();
		if( alert>=2 )
			extraActions = 1;
	}

	override function playTurn() {
		if( action==None ) {
			var pt = patrolPoints[0];
			if( cx==pt.cx && cy==pt.cy )
				setAction(Patrol);
			else
				setAction(Walk(pt.cx,pt.cy));
		}

		super.playTurn();

		if( isSkipping )
			return;

		//watch();
		pnext.visible = action==Patrol;

		if( action!=Patrol )
			doneList = new Map();

		switch( action ) {
			case None, Pass :

			case Walk(_) :

			case Patrol :
				var nexts = patrolPoints.filter( function(pt) {
					return ( pt.cx==cx || pt.cy==cy ) && ( pt.cx!=cx || pt.cy!=cy ) && sightCheck(pt.cx, pt.cy);
				});
				var best = nexts.filter( function(pt) {
					return
						lastPatrolDir.dx<0 && pt.cx<=cx ||
						lastPatrolDir.dx>0 && pt.cx>=cx ||
						lastPatrolDir.dy<0 && pt.cy<=cy ||
						lastPatrolDir.dy>0 && pt.cy>=cy;
				});
				var pt = best.length>0 ? best[0] : nexts[0];
				headTo(pt.cx, pt.cy);
				if( !tryToLockCell(nextCell.cx, nextCell.cy) )
					skipTurn();
				else {
					setAutoDir();
					lastPatrolDir = {dx:MLib.sgn(pt.cx-cx), dy:MLib.sgn(pt.cy-cy)};
					pnext.x = (pt.cx+0.5)*Const.GRID;
					pnext.y = (pt.cy+0.5)*Const.GRID;
				}

			case Hunt(x,y) :
				var h = Game.ME.hero;
				if( !guessedFleeDir && h.nextCell!=null && MLib.iabs(h.cx-x)<=1 && MLib.iabs(h.cx-x)<=1 ) {
					guessedFleeDir = true;
					x = h.nextCell.cx;
					y = h.nextCell.cy;
					setGhost(x,y);
					setAction(Hunt(x,y));
				}
				if( cx==x && cy==y ) {
					setAction(ExploreAround(x,y));
					skipTurn();
				}
				else
					headTo(x,y);
				setAutoDir();

			case ExploreAround(tx,ty) :
				ghost.visible = true;
				ghost.x = (tx+0.5)*Const.GRID;
				ghost.y = (ty+0.5)*Const.GRID;
				setVisited(tx,ty);
				setVisited(cx,cy);
				var r = 3;
				var spots = [];
				for(x in tx-r...tx+r+1)
					for(y in ty-r...ty+r+1)
						if( !alreadyVisited(x,y) && game.level.sightCheck(tx,ty,x,y) )
							spots.push({cx:x, cy:y});

				if( spots.length==0 ) {
					setAlert(0);
					setAction(None);
					skipTurn();
				}
				else {
					var rseed = new mt.Rand(0);
					spots = Lib.shuffle(spots, rseed.random);
					headTo(spots[0].cx, spots[0].cy);
					setAutoDir();
				}
		}
	}


	function setVisited(cx,cy) {
		if( !alreadyVisited(cx,cy) )
			history.push({cx:cx,cy:cy});
	}

	function alreadyVisited(cx,cy) {
		for(pt in history)
			if( pt.cx==cx && pt.cy==cy )
				return true;
		return false;
	}

	override function endTurn() {
		super.endTurn();
		//watch();

		setVisited(cx,cy);

		while( history.length>30 )
			history.shift();

		if( game.level.inFog(cx,cy) && Lib.distanceSqr(cx,cy, hero().cx, hero().cy)<=5*5 )
			Fx.ME.mobNoise(cx,cy);

		switch( action ) {
			case Hunt(x,y) :
				if( cx==x && cy==y )
					setAction(ExploreAround(x,y));

			default :
		}
	}


	function viewRange(cx,cy) {
		return switch( game.level.getIllumination(cx,cy) ) {
			case 0 : 2;
			case 1 : 4;
			case 2 : 6;
			default : 6;
		};
	}



	public function watch() {
		var h = hero();
		var r = viewRange(h.cx,h.cy);

		var a = getDirAng();
		//if( h.getIllumination()==2 && Lib.distanceSqr(cx,cy,h.cx,h.cy)<=1*1 && Lib.angularDistanceRad(a, Math.atan2(h.cy-cy, h.cx-cx))<=3.15 ) {
			//// Corner in light
			//spottedSomething(h.cx, h.cy);
			//lookAt(h);
		//}
		//else {
			// Sight check
			var da = getDirAng();
			var d = Lib.distanceSqr(cx,cy,h.cx,h.cy);
			var a = Math.atan2(h.cy-cy, h.cx-cx);
			var cone = alert==0 ? 3.14/3 : 3.14;
			if( d<=r*r && sightCheck(h.cx, h.cy) && Lib.angularDistanceRad(da,a)<=cone*0.5 )
				spottedSomething(h.cx, h.cy);

			#if debug
			//for(x in cx-r...cx+r+1)
				//for(y in cy-r...cy+r+1) {
					//var a = Math.atan2(y-cy, x-cx);
					//if( sightCheck(x,y) && Lib.angularDistanceRad(da,a)<=cone*0.5 ) {
						//Fx.ME.marker(x,y,0xFF9900);
					//}
				//}
			#end
		//}

	}


	function explorePatrolPoints(cx,cy) {
		var l = Game.ME.level;
		for(d in [{dx:-1,dy:0}, {dx:1,dy:0}, {dx:0,dy:-1}, {dx:0,dy:1}]) {
			var cx = cx+d.dx;
			var cy = cy+d.dy;
			while( !l.hasCollision(cx,cy) ) {
				var exists = false;
				for( pt in patrolPoints )
					if( pt.cx==cx && pt.cy==cy ) {
						exists = true;
						break;
					}

				if( exists )
					break;

				if( l.hasSpot(cx,cy,"patrol") ) {
					patrolPoints.push({cx:cx, cy:cy});
					explorePatrolPoints(cx,cy);
					break;
				}
				cx+=d.dx;
				cy+=d.dy;
			}
		}
	}


	function updatePreviews() {
		if( fovEnd!=null ) {
			var dx = 0;
			var dy = 0;
			switch( dir ) {
				case 0 : dy = -1;
				case 1 : dx = 1;
				case 2 : dy = 1;
				case 3 : dx = -1;
			}
			var cx = cx;
			var cy = cy;
			var d = 0;
			while( d<viewRange(cx,cy) && !game.level.hasCollision(cx,cy) ) {
				fovEnd.x = (cx+0.5)*Const.GRID;
				fovEnd.y = (cy+0.5)*Const.GRID;
				cx+=dx;
				cy+=dy;
				d++;
			}
		}

		if( arrow!=null ) {
			arrow.x = spr.x;
			arrow.y = spr.y+5;
		}
	}


	override function updateSprite() {
		super.updateSprite();
		updatePreviews();
	}


	override function unregister() {
		super.unregister();
		fovEnd.destroy();
		arrow.destroy();
		alertIcon.destroy();
		pnext.destroy();
		ghost.destroy();
		ALL.remove(this);
	}

	override function update() {
		super.update();
	}
}


