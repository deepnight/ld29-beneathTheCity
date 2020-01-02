import mt.deepnight.Buffer;
import mt.deepnight.Lib;
import mt.flash.Key;
import mt.MLib;
import mt.deepnight.slb.*;
import mt.flash.Sfx;
import Const;
import flash.display.Sprite;
import flash.display.Bitmap;
import flash.display.BitmapData;

@:bitmap("assets/tiles.png") class GfxTiles extends flash.display.BitmapData {}

class Game extends mt.deepnight.Mode { //}
	public static var ME : Game;
	public static var SBANK = Sfx.importDirectory("assets/sounds");

	public var buffer		: Buffer;
	public var fx			: Fx;
	public var tiles		: BLib;
	public var sdm			: mt.flash.DepthManager;
	var cine				: mt.deepnight.Cinematic;

	public var wrapper		: Sprite;
	public var scroller		: Sprite;

	public var level		: Level;
	public var hero			: en.Hero;
	public var turn			: Int;
	var music				: Sfx;
	public var gameOver		: Bool;

	public var inventory	: Map<String, Int>;
	public var viewport		: {x:Float, y:Float, wid:Float,hei:Float, dx:Float,dy:Float};

	// UI
	var curMsg				: Null<Bitmap>;
	public var gem			: BSprite;
	public var menu			: Null<ActionMenu>;
	public var lid			: Int;
	public var doneTuto		: Map<String,Bool>;

	public function new() {
		super();
		ME = this;
		gameOver = false;
		cine = new mt.deepnight.Cinematic();
		doneTuto = new Map();
		lid = 0;

		inventory = new Map();
		wrapper = new Sprite();
		root.addChild(wrapper);

		root.stage.quality = flash.display.StageQuality.LOW;

		fx = new Fx();

		tiles = new BLib( new GfxTiles(0,0) );
		tiles.setSliceGrid(16,16);
		tiles.sliceGrid("ground", 0,0, 2);
		tiles.sliceGrid("grass", 7,0, 3);
		tiles.sliceGrid("wall", 0,1, 4);
		tiles.sliceGrid("swall", 5,0, 2);
		tiles.sliceGrid("props", 4,1, 3);
		tiles.sliceGrid("torch", 0,2, 6);
		tiles.sliceGrid("icon", 0,3, 10);
		tiles.sliceGrid("gem", 0,4, 3);
		tiles.sliceGrid("stair", 3,0, 2);
		tiles.sliceGrid("blood", 7,1, 5);
		tiles.sliceGrid("sister", 7,1, 5);


		tiles.slice("halo", 0,320, 16*4,16*4);

		tiles.slice("bigProps", 224,0, 32,32,5);

		tiles.setSliceGrid(16,32);
		tiles.sliceAnimGrid("hidle",1, 0,3, 1);
		tiles.sliceAnimGrid("hrun",3, 1,3, 4);
		tiles.sliceAnimGrid("hlean_r",1, 0,4);
		tiles.sliceAnimGrid("hlean_l",1, 1,4);

		tiles.sliceAnimGrid("mwalk",4, 0,5, 7);
		tiles.sliceAnimGrid("midle_calm",1, 0,6, 1);
		tiles.sliceAnimGrid("midle_angry",1, 1,6, 1);
		tiles.sliceAnimGrid("mrun",4, 2,6, 2);

		buffer = new Buffer(320,200, Const.UPSCALE, false, 0x0);
		wrapper.addChild(buffer.render);
		buffer.setTexture( Buffer.makeMosaic(Const.UPSCALE), 0.04, true );

		viewport = {x:0, y:0, wid:buffer.width, hei:buffer.height, dx:0, dy:0};

		scroller = new Sprite();
		buffer.dm.add(scroller, Const.DP_BG);
		sdm = new mt.flash.DepthManager(scroller);

		gem = tiles.get("gem");
		buffer.dm.add(gem, Const.DP_UI);
		gem.setCenter(0.5,0);
		gem.x = Std.int(buffer.width*0.5);
		gem.y = 1;

		var bag = tiles.get("icon", 6);
		buffer.dm.add(bag, Const.DP_UI);
		bag.setCenter(0,0);
		bag.x = 1;
		bag.y = 1;

		//#if debug
		//root.addChild( new mt.flash.Stats(Const.WID-70) );
		//#end

		buffer.render.addEventListener( flash.events.MouseEvent.CLICK, onLeftClick );


		#if debug
		Sfx.disable();
		#end
		Sfx.setGlobalVolume(1);
		Sfx.setChannelVolume(1, 0.5);
		music = SBANK.music();

		startLevel();
	}


	function startMusic() {
		music.playLoopOnChannel(1);
		music.setVolume(0);
		music.tweenVolume(1, 3000);
	}

	public function hideMessage() {
		if( curMsg!=null ) {
			var bmp = curMsg;
			curMsg = null;
			tw.terminate(curMsg);
			tw.create(bmp, "alpha", 0, 300).onEnd = function() {
				bmp.bitmapData.dispose();
				bmp.bitmapData = null;
				bmp.parent.removeChild(bmp);
			}
		}
	}


	public function message(txt:String, ?col=0x0F252D) {
		hideMessage();

		//txt+="\n\n[Press ESCAPE]";

		var wrapper = new Sprite();

		var tf = createField(txt);
		tf.multiline = tf.wordWrap = true;
		tf.height = 100;
		tf.width = 150;
		tf.height = tf.textHeight+5;
		tf.width = tf.textWidth+5;

		var bg = new Sprite();
		bg.graphics.beginFill(col, 0.9);
		bg.graphics.drawRect(0,0,tf.width, tf.height-2);

		wrapper.addChild(bg);
		wrapper.addChild(tf);
		bg.filters = [
			new flash.filters.DropShadowFilter(12,-90, Level.SHADOW,0.5, 0,16,1, 1,true),
			new flash.filters.DropShadowFilter(1,90, 0x0,0.5, 0,0,1, 1,true),
			new flash.filters.GlowFilter(0x0,0.2, 0,0,1, 1,true),
			new flash.filters.GlowFilter(0xFFFFFF,1, 2,2,10),
		];

		curMsg = Lib.flatten(wrapper,2);
		buffer.dm.add(curMsg, Const.DP_UI);
		curMsg.x = Std.int(buffer.width*0.5 - curMsg.width*0.5) + Lib.irnd(0,30,true);
		curMsg.y = buffer.height;
		tw.create(curMsg, "y", Std.int(buffer.height*0.7 - curMsg.height*0.5) + Lib.irnd(0,15,true), 200);
	}


	function tutorial() {
		var cx = hero.cx;
		var cy = hero.cy;

		if( lid==0 ) {
			if( !doneTuto.exists("wait") && cx==8 && cy<=25 ) {
				doneTuto.set("wait", true);
				cine.create({
					message("Each time I move, the guards also move.", 0x6F151C) > end;
					message("Sometime it's a good idea to wait (press SPACE key to skip turns).", 0x11598E) > end;
				});
			}

			if( !doneTuto.exists("quote1") && cx>=10 && cy<24 ) {
				doneTuto.set("quote1", true);
				cine.create({
					message("I must avoid the guards.", 0x512649) > end;
					message("As Lice used to say, better crawling in the sludge than facing a 'Hammerite'.", 0x512649) > end;
				});
			}
		}

		if( lid==1 ) {
			if( !doneTuto.exists("torch") && cx==20 && cy==13 ) {
				doneTuto.set("torch", true);
				cine.create({
					message("I could use a few tricks of mine here.") > end;
					message("Let's put this torch out with a Water Arrow (press ENTER to open your backpack).", 0x11598E) > end;
				});
			}
			if( !doneTuto.exists("torch2") && cx<=15 && cy<=11 ) {
				doneTuto.set("torch2", true);
				cine.create({
					message("My gem (at the top of the screen shows how visible I am.") > end;
					message("The darker, the better.", 0x101118) > end;
				});
			}
		}

		if( lid==6 ) {
			if( !doneTuto.exists("sister") && cx==14 && cy==15 ) {
				doneTuto.set("sister", true);
				cine.create({
					message("Lice?") > end;
					message("I'm sorry, brother...", 0xBC1894) > end;
					message("You must leave me here.", 0xBC1894) > end;
					message("I... killed everyone.", 0xBC1894) > end;
					message("Something is eating me from inside...", 0xBC1894) > end;
					message("Lice, I can't let you!") > end;
					message("I'm sorry, brother. You must go.", 0xBC1894) > end;
					message("It...", 0xBC1894) > end;
					message("It... HURTS!!!", 0xFF0000) > end;
					level.render();
					fx.blood(14,13);
					1200;
					message("Lice!!!", 0x6F151C) >end;
					nextLevel();
				});
			}
		}

		if( lid==7 ) {
			if( !doneTuto.exists("end") && cy<=13 ) {
				doneTuto.set("end", true);
				cine.create({
					message("Sorry for the poor ending :)")>end;
					message("48h was too short to do everything in this game.", 0x880000)>end;
					message("Anywawy.")>end;
					message("Thank you for playing!", 0xBC1894)>end;
					message("Pay me a visit on: www.deepnight.net ;)")>end;
				});
			}
		}
	}


	public function openMenu() {
		menu = new ActionMenu();
	}


	public function startLevel() {
		turn = -1;
		gameOver = false;

		inventory = new Map();
		inventory.set("dash", 2);
		inventory.set("arrow", 1);
		inventory.set("noise", 1);
		inventory.set("knock", 1);

		level = new Level(lid);

		var pt = level.getSpots("hero")[0];
		hero = new en.Hero(pt.cx,pt.cy);

		for(pt in level.getSpots("mobs"))
			new en.Mob(pt.cx, pt.cy);

		viewport.x = hero.xx;
		viewport.y = hero.yy;

		nextTurn();

		if( lid==0 && !doneTuto.exists("0") ) {
			doneTuto.set("0", true);
			cine.create({
				message("My little sister Lice is trapped somewhere inside the Hammer Watch prison.") > end;
				message("They took her yesterday.", 0x6F151C) > end;
				message("Just because I stole some bread at the Crimson Cup.", 0x6F151C) > end;
				SBANK.bell().play();
				4000>>SBANK.bell(0.7);
				6000>>startMusic();
			});
		}

		if( lid==1 && !doneTuto.exists("1") ) {
			doneTuto.set("1", true);
			cine.create({
				SBANK.bell().play(0.25).setPanning(-1);
				4000 >> SBANK.bell().play(0.15).setPanning(-1);
				message("I never trusted adults in the City.") > end;
				message("But to put Lice in jail because I took a small piece of bread?", 0x6F151C) > end;
				message("Something is off.") > end;
			});
		}

		if( lid==2 && !doneTuto.exists("2") ) {
			doneTuto.set("2", true);
			cine.create({
				message("Ok I'm in.") > end;
				message("Now where is Lice?", 0x6F151C) > end;
			});
		}

		if( lid==3 && !doneTuto.exists("3") ) {
			doneTuto.set("3", true);
			cine.create({
				message("Is that... blood on the walls?",0x6F151C) > end;
				message("I must find Lice!") > end;
			});
		}

		if( lid==4 && !doneTuto.exists("4") ) {
			doneTuto.set("4", true);
			cine.create({
				message("What is the Hammer Watch hidding down here?",0x6F151C) > end;
				message("What kind of... secret is hidden beneath the City?") > end;
			});
		}

		if( lid==5 && !doneTuto.exists("5") ) {
			doneTuto.set("5", true);
			cine.create({
				message("It's cold and the air stinks here.") > end;
				message("The cells.",0x6F151C) > end;
			});
		}
	}


	public function nextLevel() {
		lid++;
		resetLevel();
	}


	public function resetLevel() {
		while( Entity.ALL.length>0 )
			Entity.ALL[0].unregister();

		level.destroy();

		startLevel();
	}



	public function onActorDone() {
		var done = true;
		for(e in en.Actor.ALL )
			if( e.isActing || !e.playedThisTurn() )
				done = false;

		if( done )
			nextTurn();
		else if( en.Actor.getWaitingActors().length>0 )
			nextActor();
	}

	public function nextActor() {
		if( hero.isWaitingOrder() )
			return;

		var waiting = en.Actor.getWaitingActors();
		if( waiting.length==0 )
			nextTurn();
		else {
			waiting.sort( function(a,b) return -Reflect.compare(a.priority, b.priority) );
			var next = waiting.shift();
			next.playTurn();
			if( next.extraActions==0 ) // multiple actions
				while( waiting.length>0 )
					waiting.shift().playTurn();

		}
	}

	public function nextTurn() {
		turn++;
		#if debug
		//trace("----Turn "+turn);
		#end

		en.Actor.initLocks();

		for(e in en.Actor.ALL)
			e.turnInit();

		tutorial();
	}



	public function gotcha() {
		if( !gameOver )  {
			gameOver = true;
			resetLevel();
		}
	}


	public function noise(cx:Int,cy:Int, ?r=3) {
		fx.noise(cx,cy, r);
		for(e in en.Mob.ALL)
			if( e.alert==0 && Lib.distanceSqr(cx,cy, e.cx, e.cy)<=r*r )
				e.spottedSomething(cx,cy);
	}



	public function createField(str:Dynamic, ?fit=true, ?col=0xFFFFFF) {
		var f = new flash.text.TextFormat();
		f.font = "def";
		f.size = 8;
		f.color = col;

		var tf = new flash.text.TextField();
		tf.width = fit ? 500 : 300;
		tf.height = 50;
		tf.mouseEnabled = tf.selectable = false;
		tf.defaultTextFormat = f;
		//tf.antiAliasType = flash.text.AntiAliasType.ADVANCED;
		//tf.sharpness = 800;
		tf.embedFonts = true;
		tf.htmlText = Std.string(str);
		tf.multiline = tf.wordWrap = true;
		if( fit ) {
			tf.width = tf.textWidth+5;
			tf.height = tf.textHeight+5;
		}
		return tf;
	}


	function onLeftClick(_) {
	}



	public function getMouse() {
		var screen = buffer.globalToLocal(wrapper.mouseX, wrapper.mouseY);
		//var iso = Entity._screenToIso(screen.x, screen.y);
		return {
			sx	: screen.x,
			sy	: screen.y,
			cx	: Std.int(screen.x/Const.GRID),
			cy	: Std.int(screen.y/Const.GRID),
		}
	}


	override function destroy() {
	}

	//public function zsort(layer:Int) {
		//var all = [];
		//buffer.dm.iterPlan( layer, function(o) if( o.visible ) all.push(o) );
		//all.sort( function(a,b) return Reflect.compare(a.y, b.y) );
		//for(o in all)
			//buffer.dm.over(o);
	//}


	override function preUpdate() {
		super.preUpdate();
		Key.update();
	}


	override function update() {
		super.update();


		if( curMsg==null ) {
			// Hero controls
			if( !gameOver && menu==null && hero.isWaitingOrder() ) {
				var cx = hero.cx;
				var cy = hero.cy;
				if( Key.isDown(Key.RIGHT) && !level.hasCollision(cx+1,cy) )
					hero.decide( Walk(cx+1, cy) );
				else if( Key.isDown(Key.LEFT) && !level.hasCollision(cx-1,cy) )
					hero.decide( Walk(cx-1, cy) );
				else if( Key.isDown(Key.UP) && !level.hasCollision(cx,cy-1) )
					hero.decide( Walk(cx, cy-1) );
				else if( Key.isDown(Key.DOWN) && !level.hasCollision(cx,cy+1) )
					hero.decide( Walk(cx, cy+1) );
				else if( Key.isToggled(Key.SPACE) )
					hero.decide( Pass );
				else if( Key.isToggled(Key.ENTER) )
					openMenu();
			}

			// Global controls
			if( Key.isToggled(flash.ui.Keyboard.R) ) {
				resetLevel();
			}

			#if debug
			if( Key.isToggled(flash.ui.Keyboard.D) ) {
				trace("-----");
				trace(hero+" "+hero.isWaitingOrder());
				trace("acting="+en.Actor.ALL.filter(function(e) return e.isActing));
				for(e in en.Actor.ALL)
					if( e.isActing )
						trace(e+" "+e.nextCell);
				trace("waiting="+en.Actor.getWaitingActors());
			}

			if( Key.isToggled(flash.ui.Keyboard.N) )
				nextLevel();
			#end
		}

		// Entities
		for(e in Entity.ALL) {
			e.update();
			e.updateSprite();
		}


		// Death
		if( !en.Actor.anyoneIsActing() )
			for( e in en.Mob.ALL )
				if( hero.cx==e.cx && hero.cy==e.cy )
					gotcha();


		var i = 0;
		while( i<Entity.ALL.length )
			if( Entity.ALL[i].destroyAsked )
				Entity.ALL[i].unregister();
			else
				i++;


		if( menu!=null )
			menu.update();

		if( curMsg!=null && ( Key.isToggled(Key.SPACE) || Key.isToggled(Key.ESCAPE) || Key.isToggled(Key.ENTER) ) ) {
		//if( curMsg!=null && Key.isToggled(Key.ESCAPE) ) {
			hideMessage();
			cine.signal("msg");
		}
	}

	override function postUpdate() {
		super.postUpdate();
		fx.update();
	}

	override function render() {
		super.render();

		// Scrolling
		var d = Lib.distanceSqr(viewport.x, viewport.y, hero.xx, hero.yy);
		if( d>=20*20 ) {
			var a = Math.atan2(hero.yy-viewport.y, hero.xx-viewport.x);
			var s =0.5;
			viewport.dx += Math.cos(a)*s;
			viewport.dy += Math.sin(a)*s;
		}
		else {
			viewport.dx*=0.6;
			viewport.dy*=0.6;
		}
		viewport.x+=viewport.dx;
		viewport.y+=viewport.dy;
		if( viewport.x-viewport.wid*0.5<0 ) viewport.x = viewport.wid*0.5;
		if( viewport.x+viewport.wid*0.5>=level.wid*Const.GRID ) viewport.x = level.wid*Const.GRID-viewport.wid*0.5;
		if( viewport.y-viewport.hei*0.5<0 ) viewport.y = viewport.hei*0.5;
		if( viewport.y+viewport.hei*0.5>=level.hei*Const.GRID-15 ) viewport.y = level.hei*Const.GRID-viewport.hei*0.5-15;
		viewport.dx*=0.8;
		viewport.dy*=0.8;
		scroller.x = -Std.int(viewport.x-viewport.wid*0.5);
		scroller.y = -Std.int(viewport.y-viewport.hei*0.5);


		cine.update();
		BSprite.updateAll();
		mt.deepnight.mui.Component.updateAll();
		level.update();
		buffer.update();
		Sfx.update();
	}
}

