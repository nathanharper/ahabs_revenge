package {
	import flash.display.*;
	import flash.media.*;
	import flash.text.*;
	import flash.events.*;
	import flash.utils.*;
	import flash.ui.*;
	import flash.geom.*;
	import fl.transitions.*;
	import fl.transitions.easing.*;

	public class WhiteWhale extends MovieClip {
		private var myScore:int=0;
		//private var lifeArray:Array=new Array(new Ahab(),new Ahab(),new Ahab());
		private var crosshairs:Crosshairs=new Crosshairs();
		private var startscreen:StartScreen=new StartScreen();
		private var myHab:Object;
		private var myPoon:HarpoonGun;
		private var mobyLife:int=10;
		private var mineSpeed:Number;
		private var poonPause=false;
		private var clusterPos:Number;
		private var difficulty:String;
		private var scoreCounter:TextField=new TextField();
		private var myAlgae:Algae=new Algae(160,40);
		private var myPowerups:Powerups=new Powerups(80,40);
		private var startX:Number;
		private var startY:Number;
		private var goScreen:GameOver=new GameOver();
		private var scoreField:TextField=new TextField();
		private var instructionsScreen:Instructions=new Instructions();
		private var megArray:int = 0;
		private var deathTimer:Timer = new Timer(500, 600);
		private var soundFX:Boolean = true;
		//private var pendingPowerupsX:Array=new Array();
		//private var pendingPowerupsY:Array=new Array();
		private var musicOn:Boolean=true;
		
		//the SOUNDS
		private var boomSound:BoomSound=new BoomSound();
		private var boomChannel:SoundChannel=new SoundChannel();
		private var doopSound:DoopSound=new DoopSound();
		private var doopChannel:SoundChannel;
		private var mobySound:MobySound=new MobySound();
		private var mobyChannel:SoundChannel;
		private var pewSound:PewSound=new PewSound();
		private var pewChannel:SoundChannel=new SoundChannel();
		private var clusterSound:ClusterSound=new ClusterSound();
		private var clusterChannel:SoundChannel;
		private var bowSound:BowSound=new BowSound();
		private var bowChannel:SoundChannel;
		
		private var transformer:SoundTransform=new SoundTransform();
		private var cTransform:SoundTransform=new SoundTransform();
		
		private var myBmp:Bitmap;
		private var pScreen:Pause=new Pause();
		
		//indicates the scroll level. settings are 0-4
		private var currLevel:int=0;
		private var currY:Array;
		private var scrollTween:Tween;

		//times gap between shots
		private var poonTimer:Timer=new Timer(600);

		//TEST
		//var testText:TextField=new TextField();

		//current Game Mode. "pause" and "play".
		private var gameMode:String="pause";

		//random color array
		private var colorArray:Array=new Array("blue","yellow","red","green");

		//an Array of the game levels.
		//each level is an Object with a speed "spd",
		//a y coordinate,
		//a "lvl" int,
		//and a lft and rght boolean 
		private var levelArray:Array=new Array();

		//an Array of Mines.
		//last index contains array representing top row.
		private var mineArray:Array=new Array();

		//an array of Harpoons
		private var harpoonArray:Array=new Array();

		//get the game going!
		public function WhiteWhale() {
			oxygentext.mask = oxygenTank.oxygenmask;
			scoreCounter.autoSize=TextFieldAutoSize.LEFT;
			transformer.volume=.2;
			cTransform.volume=.3;

			makeLevels();
			makeCurrY();

			//set up mouse pointer
			crosshairs.visible=false;
			addChild(crosshairs);
			
			startX=masterlayer.ahablayer.ahab.x;
			startY=masterlayer.gamelevel.startplank.y;

			//setup the start screen
			startscreen.x=0;
			startscreen.y=0;
			addChild(startscreen);
			startscreen.instructions.addEventListener(MouseEvent.CLICK,clickInstructions);
			startscreen.easy.addEventListener(MouseEvent.CLICK,clickPlayButton);
			startscreen.medium.addEventListener(MouseEvent.CLICK,clickPlayButton);
			startscreen.hard.addEventListener(MouseEvent.CLICK,clickPlayButton);
			
			makeAhab();
			
			myPoon=new HarpoonGun();
			myPoon.x=masterlayer.ahablayer.ahab.x;
			myPoon.y=masterlayer.ahablayer.ahab.y-masterlayer.ahablayer.ahab.height/2;
			masterlayer.mypoonlayer.addChild(myPoon);
		}
		
		//bring up instructions screen
		public function clickInstructions(event:MouseEvent){
			startscreen.easy.removeEventListener(MouseEvent.CLICK,clickPlayButton);
			startscreen.medium.removeEventListener(MouseEvent.CLICK,clickPlayButton);
			startscreen.hard.removeEventListener(MouseEvent.CLICK,clickPlayButton);
			startscreen.instructions.removeEventListener(MouseEvent.CLICK,clickInstructions);
			instructionsScreen.x=0;
			instructionsScreen.y=0;
			addChild(instructionsScreen);
			instructionsScreen.back.addEventListener(MouseEvent.CLICK,goBack);
		}
		//close instructions screen
		public function goBack(event:MouseEvent){
			event.currentTarget.removeEventListener(MouseEvent.CLICK,goBack);
			removeChild(instructionsScreen);
			startscreen.easy.addEventListener(MouseEvent.CLICK,clickPlayButton);
			startscreen.medium.addEventListener(MouseEvent.CLICK,clickPlayButton);
			startscreen.hard.addEventListener(MouseEvent.CLICK,clickPlayButton);
			startscreen.instructions.addEventListener(MouseEvent.CLICK,clickInstructions);
		}
		
		public function deathTimerComplete(e:TimerEvent) {
			killAhab();
		}

		//MAIN GAME LOOP
		public function gameLoop(event:Event) {
			//trace(deathTimer.delay);
			//TEST
			//testText.text=harpoonArray.length.toString();
			
			scoreCounter.text = myScore.toString();
			
			oxygenTank.scaleX = (deathTimer.repeatCount - deathTimer.currentCount) / deathTimer.repeatCount;

			//change pointer position
			crosshairs.x=mouseX;
			crosshairs.y=mouseY;

			moveAhab();
			
			myPoon.x=masterlayer.ahablayer.ahab.x;
			myPoon.y=masterlayer.ahablayer.ahab.y-masterlayer.ahablayer.ahab.height/2;

			//point the harpoon gun
			myPoon.rotation=getAngle();
			replaceWhales();

			//move harpoons must go before move whales, because it filters the harpoon array
			moveHarpoons();
			moveWhales();

			//moveMines();
			myBmp.y+=mineSpeed;//.08;
			if(myBmp.y>0-masterlayer.localToGlobal(new Point(masterlayer.ahablayer.x,masterlayer.ahablayer.y)).y){
				addMines();
			}
			if(myBmp.y+myBmp.height-40>masterlayer.ahablayer.y+1800){
				removeMineRow();
			}
		}
		
		//load the y coordinate for each of the 5 pan levels
		public function makeCurrY(){
			currY=new Array();
			var ybuf:Number=masterlayer.y;
			currY.push(ybuf);
			for(var i:int=0;i<4;i++){
				ybuf +=310+i*5;
				currY.push(ybuf);
			}
		}

		//assign stats to myHab Object
		public function makeAhab() {
			myHab=new Object();

			myHab.mc=masterlayer.ahablayer.ahab;
			myHab.mc.x=startX;
			myHab.mc.y=startY;
			myHab.mc.gotoAndStop("stand");
			myHab.currentlevel=-1;
			myHab.dx=0.0;
			myHab.dy=0.0;
			myHab.inAir=false;
			
			//physics constants
			myHab.gravity=.25;//.99;
			myHab.gfriction=.7;
			myHab.afriction=.7;
			myHab.jspd=9;//18;
			myHab.spd=4.5;//9;

			//button press booleans
			myHab.lefty=false;
			myHab.righty=false;
			myHab.up=false;
			myHab.down=false;
			
			myHab.isLeft=false;
			myHab.isRight=false;
			
			myHab.animating = false;
			
			myHab.cTrans = new ColorTransform();
			myHab.isHurt=false;
			myHab.tween = new Tween(myHab.cTrans, "alphaOffset", None.easeNone, -100, 0, 40);
			myHab.cTween = new Tween(myHab.cTrans, "redOffset", None.easeNone, 255, 0, 40);
			myHab.cTween.addEventListener(TweenEvent.MOTION_CHANGE, updateColor);
			
			//indicates if ahab is in the middle of his first jump command
			myHab.sJump=false;
			myHab.jumpTimer=new Number(0);
		}
		
		public function updateColor(e:TweenEvent) {
			myHab.mc.transform.colorTransform = myHab.cTrans;
		}
		
		//restart the game when button is clicked 
		public function restartGame(event:MouseEvent){
			/*for(var p:int=0;p<lifeArray.length;p++){
				if(lifeArray[p] is Ahab){
					removeChild(lifeArray[p]);
				}
			}*/
			//crosshairs.visible=true;
			//addChild(crosshairs);
			for(var i:int=0;i<masterlayer.poonlayer.numChildren;i=i){
				if(masterlayer.poonlayer.getChildAt(i) is Harpoon){
					masterlayer.poonlayer.removeChildAt(i);
				}else{
					i+=1;
				}
			}
			for(var j:int=0;j<masterlayer.whalelayer.numChildren;j=j){
				if(masterlayer.whalelayer.getChildAt(j) is Whale){
					whaleCleaner(masterlayer.whalelayer.getChildAt(j));
				}else{
					j+=1;
				}
			}
			masterlayer.moby.gotoAndStop("sit");
			myPoon.visible=true;
			mineArray=new Array();
			event.currentTarget.removeEventListener(MouseEvent.CLICK,restartGame);
			
			removeChild(event.currentTarget.parent);
			
			removeChild(scoreField);
			makeAhab();
			startscreen.visible=true;
			startscreen.easy.addEventListener(MouseEvent.CLICK,clickPlayButton);
			startscreen.medium.addEventListener(MouseEvent.CLICK,clickPlayButton);
			startscreen.hard.addEventListener(MouseEvent.CLICK,clickPlayButton);
			startscreen.instructions.addEventListener(MouseEvent.CLICK,clickInstructions);
			myBmp.bitmapData.dispose();
			
			removeChild(scoreCounter);
			masterlayer.minelayer.removeChild(myBmp);
			
			//var p:Point=masterlayer.localToGlobal(new Point(masterlayer.ahablayer.x,masterlayer.ahablayer.y));
			//var pToo:Point=masterlayer.localToGlobal(new Point(masterlayer.minelayer.x,masterlayer.minelayer.y));
			if(scrollTween!=null)scrollTween.stop();
			masterlayer.y=-1270;
			
			myScore=0;
			//lifeArray=new Array(new Ahab(),new Ahab(),new Ahab());
			mobyLife=10;
			poonPause=false;
			myPoon.gotoAndStop("normal");
			currLevel=0;
			harpoonArray=new Array();
		}

		//MOVE AHAB
		public function moveAhab():Boolean {
			
			var vChange:Number=0;
			
			//update ahab's level
			if(myHab.currentlevel<8){
				if(myHab.mc.y<=levelArray[myHab.currentlevel+1].y){
					myHab.currentlevel+=1;
					//update currLevel
					if(myHab.currentlevel==1||myHab.currentlevel==3||myHab.currentlevel==5||myHab.currentlevel==7){
						currLevel+=1;
						if(scrollTween!=null) scrollTween.stop();
						var p:Point=masterlayer.localToGlobal(new Point(masterlayer.ahablayer.x,masterlayer.ahablayer.y));
						var pToo:Point=masterlayer.localToGlobal(new Point(masterlayer.minelayer.x,masterlayer.minelayer.y));
						scrollTween=new Tween(masterlayer,"y",Strong.easeOut,masterlayer.y+p.y-pToo.y,currY[currLevel],60, false);
						scrollTween.start();
					}
				}
			}
			
			if(myHab.inAir){
				myHab.dy+=myHab.gravity;
				vChange=myHab.dy;
				//land Ahab on start level
				if(myHab.currentlevel==-1&&myHab.mc.y+vChange>=masterlayer.gamelevel.startplank.y){
					vChange= masterlayer.gamelevel.startplank.y+1-myHab.mc.y;
					myHab.dy=0;
					myHab.inAir=false;
					myHab.sJump=false;
					//animate
					if(myHab.lefty||myHab.righty){
						myHab.mc.gotoAndPlay("walk");
						myHab.animating=true;
					}else{
						myHab.mc.gotoAndStop("stand");
					}
				}
				//land Ahab on higher levels
				if(myHab.currentlevel>=0&&myHab.mc.y+vChange>=levelArray[myHab.currentlevel].y){
					vChange=levelArray[myHab.currentlevel].y-myHab.mc.y;
					myHab.dy=0;
					myHab.inAir=false;
					myHab.sJump=false;
					//animate
					if(myHab.lefty||myHab.righty){
						myHab.mc.gotoAndPlay("walk");
						myHab.animating=true;
					}else{
						myHab.mc.gotoAndStop("stand");
					}
				}
			} else{
				if(myHab.up){
					myHab.inAir=true;
					myHab.sJump=true;
					myHab.jumpTimer=getTimer();
					myHab.dy=-myHab.jspd;
					vChange =myHab.dy;
					myHab.mc.gotoAndStop("jump");
					myHab.animating=false;
				}
				else if(myHab.down&&myHab.currentlevel>=0){
					myHab.inAir=true;
					myHab.currentlevel-=1;
					myHab.dy=3;
					vChange=myHab.dy;
					myHab.mc.gotoAndStop("jump");
					myHab.animating=false;
					//decrease currLevel
					if(myHab.currentlevel==0||myHab.currentlevel==2||myHab.currentlevel==4||myHab.currentlevel==6){
						currLevel-=1;
						if(scrollTween!=null) scrollTween.stop();
						var pd:Point=masterlayer.localToGlobal(new Point(masterlayer.ahablayer.x,masterlayer.ahablayer.y));
						var pdToo:Point=masterlayer.localToGlobal(new Point(masterlayer.minelayer.x,masterlayer.minelayer.y));
						scrollTween=new Tween(masterlayer,"y",Strong.easeOut,masterlayer.y+pd.y-pdToo.y,currY[currLevel],60, false);
						scrollTween.start();
					}
				}
				//else change stays zero
			}
			myHab.mc.y+=vChange;
			
			//y change is done. now handle x values...
			
			if(myHab.isRight){
				myHab.dx=myHab.spd;
				myHab.mc.scaleX=1;
			}
			if(myHab.isLeft){
				myHab.dx=-myHab.spd;
				myHab.mc.scaleX=-1;
			}
			
			if(myHab.inAir){
				myHab.dx*=myHab.afriction;
			}else{
				myHab.dx*=myHab.gfriction;
			}
			
			//set x position. Done!
			if(myHab.mc.x+(myHab.mc.width/2)+myHab.dx>=550){
				myHab.mc.x=550-myHab.mc.width/2;
				myHab.dx=0;
			}
			else if(myHab.mc.x-(myHab.mc.width/2)+myHab.dx<=0){
				myHab.mc.x=myHab.mc.width/2;
				myHab.dx=0;
			}else{
				myHab.mc.x+=myHab.dx;
			}
			//check if myHab has hit a mine
			if(!myHab.isHurt&&myBmp.hitTestObject(myHab.mc.hitbox)){
				//check a distribution of points across Ahab's hitbox
				var topLeft:Point=getMineCoords(new Point(myHab.mc.hitbox.x,myHab.mc.hitbox.y));
				var ivi1:Boolean=isValidIndex(topLeft);
				//arrPusher(ivi1,topLeft,true);
				
				var topRight:Point=getMineCoords(new Point(myHab.mc.hitbox.x+myHab.mc.hitbox.width,myHab.mc.hitbox.y));
				var ivi2:Boolean=isValidIndex(topRight);
				//arrPusher(ivi2,topRight,true);
				
				var botLeft:Point=getMineCoords(new Point(myHab.mc.hitbox.x,myHab.mc.hitbox.y+myHab.mc.hitbox.height));
				var ivi3:Boolean=isValidIndex(botLeft);
				
				var botRight:Point=getMineCoords(new Point(myHab.mc.hitbox.x+myHab.mc.hitbox.width,myHab.mc.hitbox.y+myHab.mc.hitbox.height));
				var ivi4:Boolean=isValidIndex(botRight);
				
				var midLeft:Point=getMineCoords(new Point(myHab.mc.hitbox.x,myHab.mc.hitbox.y+myHab.mc.hitbox.height/3));
				var ivi5:Boolean=isValidIndex(midLeft);
				
				var midRight:Point=getMineCoords(new Point(myHab.mc.hitbox.x+myHab.mc.hitbox.width,myHab.mc.hitbox.y+myHab.mc.hitbox.height/3));
				var ivi6:Boolean=isValidIndex(midRight);
				
				var midLeft2:Point=getMineCoords(new Point(myHab.mc.hitbox.x,myHab.mc.hitbox.y+(myHab.mc.hitbox.height/3)*2));
				var ivi7:Boolean=isValidIndex(midLeft2);
				
				var midRight2:Point=getMineCoords(new Point(myHab.mc.hitbox.x+myHab.mc.hitbox.width,myHab.mc.hitbox.y+(myHab.mc.hitbox.height/3)*2));
				var ivi8:Boolean=isValidIndex(midRight2);
				
				if(ivi1||ivi2||ivi3||ivi4||ivi5||ivi6||ivi7||ivi8){
					//myHab.isHurt = true;
					if (deathTimer.delay == 500) deathTimer.delay = 3;
					//PAIN ANIMATION
					if (myHab.tween != null && !myHab.tween.isPlaying) {
						myHab.tween.start();
						myHab.cTween.start();
						if(soundFX)doopChannel=doopSound.play(0,1);
					}
					return true;
				}
			}
			if (deathTimer.delay != 500) {
				deathTimer.delay = 500;
			}
			return false;
		}
		/*public function hurtEnd(event:TweenEvent){
			myHab.isHurt=false;
			myHab.tween.removeEventListener(TweenEvent.MOTION_FINISH,hurtEnd);
		}*/
		
		public function killAhab() {
			myHab.cTween.removeEventListener(TweenEvent.MOTION_CHANGE, updateColor);
			myHab.mc.gotoAndStop("death");
			Mouse.show();
			crosshairs.visible=false;
			if(scrollTween!=null)scrollTween.stop();
			for(var i:int=0;i<masterlayer.whalelayer.numChildren;i++){
				if(masterlayer.whalelayer.getChildAt(i) is Whale){
					masterlayer.whalelayer.getChildAt(i).stop();
				}
			}
			removeEventListener(Event.ENTER_FRAME, gameLoop);
			deathTimer.reset();
			deathTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, deathTimerComplete);
			removeEventListener(MouseEvent.MOUSE_DOWN,fireHarpoon);
			if(poonTimer.running)poonTimer.reset();
			poonTimer.removeEventListener(TimerEvent.TIMER,poonReload);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN,keyDownHandler);
			stage.removeEventListener(KeyboardEvent.KEY_UP,keyUpHandler);
						
			goScreen.x=0;
			goScreen.y=0;
			addChild(goScreen);
			goScreen.reset.addEventListener(MouseEvent.CLICK,restartGame);
						
			scoreField.defaultTextFormat=new TextFormat("arial",40,0x17F02D,true);
			scoreField.autoSize=TextFieldAutoSize.LEFT;
			scoreField.text=myScore.toString();
						
			scoreField.x=250;
			scoreField.y=400;
			addChild(scoreField);
						
			clusterChannel.stop();
		}
		//returns a point on Ahab's hitbox relative to the Mine Bitmap
		public function getMineCoords(point:Point){
			return myBmp.globalToLocal(myHab.mc.localToGlobal(point));
		}

		//indicates whether ahab has hit a stable mine, and activates powerups.
		public function isValidIndex(point:Point){
			var xi:int=Math.floor(point.x/40);
			var yi:int=mineArray.length-Math.ceil(point.y/40);
			if(xi>=0&&xi<14&&yi>=0&&yi<mineArray.length){
				if(mineArray[yi][xi].getStable()){
					return true;
				}
				else if(mineArray[yi][xi].getPowerup()=="rainbow"){
					activateRainbow();
					mineArray[yi][xi].setPowerup("null");
					myBmp.bitmapData.fillRect(new Rectangle(xi*40,myBmp.height-40-yi*40,40,40),0x000000);
					if(soundFX)bowChannel=bowSound.play(0,1);
				}
				else if(mineArray[yi][xi].getPowerup()=="mega"){
					myPoon.gotoAndStop("mega");
					megArray+=1;
					mineArray[yi][xi].setPowerup("null");
					myBmp.bitmapData.fillRect(new Rectangle(xi*40,myBmp.height-40-yi*40,40,40),0x000000);
					if(soundFX)bowChannel=bowSound.play(0,1);
				}
				else if (mineArray[yi][xi].getPowerup() == "oxygen") {
					deathTimer.repeatCount += 100;
					mineArray[yi][xi].setPowerup("null");
					myBmp.bitmapData.fillRect(new Rectangle(xi*40,myBmp.height-40-yi*40,40,40),0x000000);
					if(soundFX)bowChannel=bowSound.play(0,1);
				}
			}
			return false;
		}
		
		//activates rainbow powerup
		public function activateRainbow(){
			for(var i:int=0;i<masterlayer.whalelayer.numChildren;i++){
				if(masterlayer.whalelayer.getChildAt(i) is Whale){
					var whale:Whale=masterlayer.whalelayer.getChildAt(i);
					if(!whale.getAsplode()&&whale.isAlive()&&whale.getColor()!="rainbow"){
						whale.setRainbow();
					}
				}
			}
		}
		

		//fire a harpoon
		public function fireHarpoon(event:MouseEvent) {
			poonTimer.start();
			removeEventListener(MouseEvent.MOUSE_DOWN,fireHarpoon);
			myPoon.visible=false;
			var newPoon:Harpoon;
			if(myPoon.currentLabel=="mega"){
				megArray-=1;
				if(megArray>0) myPoon.gotoAndStop("mega");
				else myPoon.gotoAndStop("normal");
				newPoon=new Harpoon(true,getAngle());
			}else{
				newPoon=new Harpoon(false,getAngle());
			}
			newPoon.x=myPoon.x;
			newPoon.y=myPoon.y;
			harpoonArray.push(newPoon);
			if(newPoon.megaPoon()&&soundFX){
				pewChannel=pewSound.play(0,1);
				pewChannel.soundTransform=transformer;
			}
			masterlayer.poonlayer.addChild(newPoon);
		}

		//reload harpoons when poonTimer hits
		public function poonReload(event:TimerEvent) {
			poonTimer.reset();
			myPoon.visible=true;
			addEventListener(MouseEvent.MOUSE_DOWN,fireHarpoon);
		}
		public function makeSector(point:Point){
			return new Point(Math.floor(point.x/40),mineArray.length-Math.ceil(point.y/40));
		}
		//move harpoons
		public function moveHarpoons() {
			if (masterlayer.poonlayer.numChildren>1) {
				//get rid of dead harpoons
				harpoonArray=harpoonArray.filter(filterPoons);
				for (var i:int=0; i<harpoonArray.length; i++) {
					var xbuf:int=harpoonArray[i].getX();
					var ybuf:int=harpoonArray[i].getY();
					harpoonArray[i].x+=xbuf;
					harpoonArray[i].y+=ybuf;

					//move any attached whales
					for (var j:int=0; j<harpoonArray[i].myWhales.length; j++) {
						var myWhale:Whale;
						if (harpoonArray[i].myWhales[j] is Whale) {
							myWhale=harpoonArray[i].myWhales[j];
							harpoonArray[i].myWhales[j].x+=xbuf;
							harpoonArray[i].myWhales[j].y+=ybuf;
							//if the whale has hit the bitmap...
							if(myWhale.hitbox.hitTestObject(myBmp)&&!myWhale.getAsplode()) {
								var myBox:Object=myWhale.hitbox2;
								
								var yo1:Point=myWhale.localToGlobal(new Point(myBox.x,myBox.y));
								var yo2:Point=myWhale.localToGlobal(new Point(myBox.x+myBox.width,myBox.y));
								var yo3:Point=myWhale.localToGlobal(new Point(myBox.x,myBox.y+myBox.height));
								var yo4:Point=myWhale.localToGlobal(new Point(myBox.x+myBox.width,myBox.y+myBox.height));
								
								var topLeft:Point=makeSector(myBmp.globalToLocal(yo1));
								var topRight:Point=makeSector(myBmp.globalToLocal(yo2));
								var botLeft:Point=makeSector(myBmp.globalToLocal(yo3));
								var botRight:Point=makeSector(myBmp.globalToLocal(yo4));
								
								//rColls is an array of the (up to) 4 corals the whale is touching.
								var rColls:Array=new Array();
								if(myBmp.hitTestPoint(yo1.x,yo1.y)){
									if(topLeft.y>=0&&topLeft.y<mineArray.length&&topLeft.x>=0&&topLeft.x<14){
										if(mineArray[topLeft.y][topLeft.x].getStable()){
											rColls.push(topLeft);
										}
									}
								}
								if(myBmp.hitTestPoint(yo2.x,yo2.y)){
									if(topRight.y>=0&&topRight.y<mineArray.length&&topRight.x>=0&&topRight.x<14){
										if(mineArray[topRight.y][topRight.x].getStable()){
											rColls.push(topRight);
										}
									}
								}
								if(myBmp.hitTestPoint(yo3.x,yo3.y)){
									if(botLeft.y>=0&&botLeft.y<mineArray.length&&botLeft.x>=0&&botLeft.x<14){
										if(mineArray[botLeft.y][botLeft.x].getStable()){
											rColls.push(botLeft);
										}
									}
								}
								if(myBmp.hitTestPoint(yo4.x,yo4.y)){
									if(botRight.y>=0&&botRight.y<mineArray.length&&botRight.x>=0&&botRight.x<14){
										if(mineArray[botRight.y][botRight.x].getStable()){
											rColls.push(botRight);
										}
									}
								}
								
								//check for a color match
								if(rColls.length>0){
									var whaleDone:Boolean=false;
									for(var t:int=0;t<rColls.length;t++){
										if(mineArray[rColls[t].y][rColls[t].x].getStable()&&(myWhale.getColor()=="rainbow"||mineArray[rColls[t].y][rColls[t].x].getColor()==myWhale.getColor())){
											var points:int;
											if(difficulty=="easy") points=1;
											if(difficulty=="medium") points=3;
											if(difficulty=="hard") points=5;
											mineChain(rColls[t],points);
											if(whaleDone==false){
												if(soundFX) makeBoomSound();
												makeBoom(myWhale.x-20,myWhale.y-40);
												whaleCleaner(myWhale);
												whaleDone=true;
											}
											//t=rColls.length;
										}
									}
									//whale has hit off-color blocks
									if(!myWhale.getAsplode()){
										makeBoom(myWhale.x-20,myWhale.y-40);
										whaleCleaner(myWhale);
										if(soundFX)makeBoomSound();
									}
								}
								//collision with MOBY DICK boss if no mine collisions
								else if(currLevel==4&&masterlayer.moby.hitTestObject(myWhale)){
									makeBoom(myWhale.x-20,myWhale.y-40);
									whaleCleaner(myWhale);
									if(soundFX)makeBoomSound();
									if(soundFX)mobyChannel=mobySound.play(0,1);
									mobyLife-=1;
									if(mobyLife<=0){
										//KILL MOBY!
										if(poonTimer.running)poonTimer.reset();
										poonTimer.removeEventListener(TimerEvent.TIMER,poonReload);
										
										for(var v:int=0;v<masterlayer.whalelayer.numChildren;v++){
											if(masterlayer.whalelayer.getChildAt(v) is Whale){
												masterlayer.whalelayer.getChildAt(v).stop();
											}
										}
										removeEventListener(Event.ENTER_FRAME,gameLoop);
										removeEventListener(MouseEvent.MOUSE_DOWN, fireHarpoon);
										deathTimer.stop();
										deathTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, deathTimerComplete);
										stage.removeEventListener(KeyboardEvent.KEY_DOWN,keyDownHandler);
										stage.removeEventListener(KeyboardEvent.KEY_UP,keyUpHandler);
										masterlayer.moby.gotoAndPlay("die");
										var tim:Timer=new Timer(200,20);
										tim.addEventListener(TimerEvent.TIMER,mobyPop);
										crosshairs.visible=false;
										tim.start();
										if(soundFX)mobyChannel=mobySound.play(0,20);
										myHab.mc.stop();
										break;
									}else{
										masterlayer.moby.gotoAndPlay("hit");
									}
								}
							}
						}
					}//end whale loop
					//DEAL WITH HARPOONS WITHOUT WHALES
					if(harpoonArray[i].hitbox.hitTestObject(myBmp)){
						var poop:Boolean=false;
						for(var o:int=0;harpoonArray[i].myWhales.length>o;o++){
							if(!harpoonArray[i].myWhales[o].getAsplode()){
								poop=true;
							}
						}
						
						//ifthe harpoon has no whales and has hit myBmp...
						if(!poop){
							var myBox2:Object=harpoonArray[i].hitbox;
							var globalCenter2:Point=harpoonArray[i].localToGlobal(new Point(myBox2.x+myBox2.width/2,myBox2.y));
							if(myBmp.hitTestPoint(globalCenter2.x,globalCenter2.y)){
								var poonPoint:Point=myBmp.globalToLocal(globalCenter2);
								var xi2:int=Math.floor(poonPoint.x/40);
								var yi2:int=mineArray.length-Math.ceil(poonPoint.y/40);
								
								if(mineArray[yi2][xi2].getStable()){
									if(!harpoonArray[i].megaPoon()){
										var fade:HarpoonFade=new HarpoonFade();
										fade.rotation=harpoonArray[i].getAngle();
										fade.x=harpoonArray[i].x;
										fade.y=harpoonArray[i].y;
										fade.addEventListener("endFade",endFade);
										harpoonArray[i].killPoon();
										masterlayer.poonlayer.addChild(fade);
									}else{
										var points2:int;
										if(difficulty=="easy") points2=2;
										if(difficulty=="medium") points2=4;
										if(difficulty=="hard") points2=6;
										mineChain(new Point(xi2,yi2),points2);
										if(soundFX)makeBoomSound();
									}
								}
							}
						}
					}
				}//end harpoon loop
			}
		}
		
		//make a boom sound play once
		public function makeBoomSound(){
			boomChannel=boomSound.play(0,1);
			boomChannel.soundTransform=transformer;
		}
		
		//mobyPop: make final boss-kill-animation explosions and endscreen
		public function mobyPop(event:TimerEvent){
			if(event.currentTarget.currentCount<20){
				var boom:Explosion=new Explosion();
				boom.x=Math.floor(Math.random()*470);
				boom.y=Math.floor(Math.random()*180);
				boom.addEventListener("endExplosion",endExplosion);	
				masterlayer.moby.addChild(boom);
				if(soundFX)makeBoomSound();
				boomChannel.soundTransform=transformer;
			}else{
				event.currentTarget.removeEventListener(TimerEvent.TIMER,mobyPop);
				Mouse.show();
				masterlayer.moby.stop();
				if (mobyChannel != null) mobyChannel.stop();
				var win:WinScreen=new WinScreen();
				win.x=0;
				win.y=0;
				addChild(win);
				
				if(clusterChannel != null) clusterChannel.stop();
				
				//var scoreField:TextField=new TextField();
				scoreField.defaultTextFormat = new TextFormat("arial", 40, 0x17F02D, true);
				var timeCoefficient:Number;
				if(difficulty=="easy"){
					//myScore += 10000;
					timeCoefficient = 10;
				}
				else if(difficulty=="medium"){
					//myScore += 30000;
					timeCoefficient = 100;
				}
				else if(difficulty=="hard"){
					//myScore += 50000;
					timeCoefficient = 1000;
				}
				myScore += timeCoefficient * (deathTimer.repeatCount - deathTimer.currentCount);
				deathTimer.reset();
				scoreField.autoSize=TextFieldAutoSize.LEFT;
				scoreField.text=myScore.toString();
				//scoreField.selectable=false;
				scoreField.x=350;
				scoreField.y=425;
				addChild(scoreField);
				win.reset.addEventListener(MouseEvent.CLICK,restartGame);
			}
		}
		
		//make an explosion
		public function makeBoom(xc:int,yc:int){
			var boom:Explosion=new Explosion();
			boom.x=xc;
			boom.y=yc;
			boom.addEventListener("endExplosion",endExplosion);								
			masterlayer.minelayer.addChild(boom);
		}
		
		//removes harpoon fades
		public function endFade(event:Event){
			event.currentTarget.removeEventListener("endFade",endFade);
			masterlayer.poonlayer.removeChild(event.currentTarget);
		}
		
		//removes explosion animations upon completion
		public function endExplosion(event:Event){
			event.currentTarget.removeEventListener("endExplosion",endExplosion);
			event.currentTarget.parent.removeChild(event.currentTarget);
		}
		//kill all mines attached to a triggered mine
		public function mineChain(point:Point,score:int){
			mineArray[point.y][point.x].notStable();
			myScore+=score;
			
			makeBoom(point.x*40,(myBmp.height-40-point.y*40)+myBmp.y);
			
			var randy:int=poonRandom();
			
			//make powerups
			myBmp.bitmapData.lock();
			if(randy==4||randy==100){
				mineArray[point.y][point.x].setPowerup("rainbow");
				myBmp.bitmapData.copyPixels(myPowerups,new Rectangle(40,0,40,40),new Point(point.x*40,myBmp.height-40-point.y*40));
			}
			else if (randy == 60) {
				mineArray[point.y][point.x].setPowerup("oxygen");
				myBmp.bitmapData.copyPixels(myPowerups,new Rectangle(80,0,40,40),new Point(point.x*40,myBmp.height-40-point.y*40));
			}
			else if(randy==40){
				mineArray[point.y][point.x].setPowerup("mega");
				myBmp.bitmapData.copyPixels(myPowerups,new Rectangle(0,0,40,40),new Point(point.x*40,myBmp.height-40-point.y*40));
			}else{
				myBmp.bitmapData.fillRect(new Rectangle(point.x*40,myBmp.height-40-point.y*40,40,40),0x000000);
			}
			myBmp.bitmapData.unlock();
			
			if(point.y-1>=0){
				if(mineArray[point.y-1][point.x].getStable()&&mineArray[point.y-1][point.x].getColor()==mineArray[point.y][point.x].getColor()){
					mineChain(new Point(point.x,point.y-1),score+1);
				}
			}
			if(point.y+1<mineArray.length){
				if(mineArray[point.y+1][point.x].getStable()&&mineArray[point.y+1][point.x].getColor()==mineArray[point.y][point.x].getColor()){
					mineChain(new Point(point.x,point.y+1),score+1);
				}
			}
			if(point.x-1>=0){
				if(mineArray[point.y][point.x-1].getStable()&&mineArray[point.y][point.x-1].getColor()==mineArray[point.y][point.x].getColor()){
					mineChain(new Point(point.x-1,point.y),score+1);
				}
			}
			if(point.x+1<14){
				if(mineArray[point.y][point.x+1].getStable()&&mineArray[point.y][point.x+1].getColor()==mineArray[point.y][point.x].getColor()){
					mineChain(new Point(point.x+1,point.y),score+1);
				}
			}
		}
		//poon filter function
		private function filterPoons(harpoon:Harpoon, index:int, array:Array):Boolean {
			var poonX:int=harpoon.x;
			var poonY:int=harpoon.y;
			
			var p:Point=masterlayer.localToGlobal(new Point(masterlayer.ahablayer.x,masterlayer.ahablayer.y));
			if (poonX>stage.stageWidth||poonX<0||poonY<0-p.y||poonY>stage.stageHeight-p.y||harpoon.getDead()) {
				for (var i:int=0; i<harpoon.myWhales.length; i++) {
					if (harpoon.myWhales[i] is Whale) {
						var tempwhale:Whale=harpoon.myWhales[i];
						if (tempwhale.getMasDir()&&!tempwhale.getAsplode()) {
							levelArray[tempwhale.getLevel()].rght=false;
						} else if(!tempwhale.getAsplode()) {
							levelArray[tempwhale.getLevel()].lft=false;
						}
						if(!tempwhale.getAsplode()) masterlayer.whalelayer.removeChild(harpoon.myWhales[i]);
					}
				}//end whale loop
				masterlayer.poonlayer.removeChild(harpoon);
				return false;
			}
			return true;
		}

		//initialize mineArray. called once at beginning of game.
		public function initializeMines() {
			var tempBmp:BitmapData=new BitmapData(560,40*6);
			//make 6 initial rows. (maybe 7. easy to change.)
			for (var i:int=0; i<6; i++) {
				var tempArray:Array=new Array();
				//...with 14 individual mines.
				for (var j:int=0; j<14; j++) {
					var ctemp:int=randomFour();
					var mineBuffer:Mine=new Mine(colorArray[ctemp]);
					tempBmp.copyPixels(myAlgae,new Rectangle(ctemp*40,0,40,40),new Point(j*40,6*40-(40+40*i)));
					
					tempArray.push(mineBuffer);
					
					if((difficulty=="easy"||difficulty=="medium")&&j+1<14&&!(j==0&&i%2>0)){
						tempArray.push(new Mine(colorArray[ctemp]));
						tempBmp.copyPixels(myAlgae,new Rectangle(ctemp*40,0,40,40),new Point((j+1)*40,6*40-(40+40*i)));
						j+=1;
					}
				}//end mine loop
				mineArray.push(tempArray);
			}//end row loop
			myBmp=new Bitmap(tempBmp);
			myBmp.x=0;
			myBmp.y=1800-14*40;
			masterlayer.minelayer.addChild(myBmp);
		}

		//adds 14 new rows of mines
		public function addMines() {
			var tempBmp:BitmapData=new BitmapData(560,40*14+myBmp.height);
			//copy pixels from previous bitmap
			tempBmp.copyPixels(myBmp.bitmapData,myBmp.bitmapData.rect,new Point(0,40*14));
			//make 14 new rows.
			for (var i:int=0; i<14; i++) {
				var tempArray:Array=new Array();
				//loop through each mine in row i
				for(var j:int=0;j<14;j++){
					var ctemp:int=randomFour();
					var mineBuffer:Mine=new Mine(colorArray[ctemp]);
					tempBmp.copyPixels(myAlgae,new Rectangle(ctemp*40,0,40,40),new Point(j*40,tempBmp.height-myBmp.height-40-i*40));
					tempArray.push(mineBuffer);
					
					if((difficulty=="easy"||difficulty=="medium")&&j+1<14&&!(j==0&&i%2>0)){
						tempArray.push(new Mine(colorArray[ctemp]));
						tempBmp.copyPixels(myAlgae,new Rectangle(ctemp*40,0,40,40),new Point((j+1)*40,tempBmp.height-myBmp.height-40-i*40));
						j+=1;
					}
				}
				mineArray.push(tempArray);
			}
			myBmp.bitmapData.dispose();
			myBmp.y=myBmp.y-14*40;
			myBmp.bitmapData=tempBmp;
		}
		
		//remove the bottom-most row of mines
		public function removeMineRow(){
			var tempBmD:BitmapData=new BitmapData(560,myBmp.height-40);
			tempBmD.copyPixels(myBmp.bitmapData,new Rectangle(0,0,560,myBmp.height-40),new Point(0,0));
			
			myBmp.bitmapData.dispose();
			myBmp.bitmapData=tempBmD;
			mineArray.shift();
		}

		//replace any slaughtered Whales
		public function replaceWhales() {
			//loop through the Levels
			for (var i:int=0; i<9; i++) {
				var p:Point=masterlayer.localToGlobal(new Point(masterlayer.ahablayer.x,masterlayer.ahablayer.y));
				//only replace whales if the level is onscreen
				if(levelArray[i].y>0-p.y&&levelArray[i].y<stage.stageHeight-p.y){
					if (! levelArray[i].lft) {
						var tempone:Whale=new Whale(levelArray[i],false,colorArray[randomFour()]);
						masterlayer.whalelayer.addChild(tempone);
						levelArray[i].lft=true;
					}
					if (! levelArray[i].rght) {
						var temptwo:Whale=new Whale(levelArray[i],true,colorArray[randomFour()]);
						masterlayer.whalelayer.addChild(temptwo);
						levelArray[i].rght=true;
					}
				}
			}
		}

		//Move the Whales
		public function moveWhales() {
			for (var i:int=0; i<masterlayer.whalelayer.numChildren; i++) {
				if (masterlayer.whalelayer.getChildAt(i) is Whale) {
					var tempwhale:Whale=masterlayer.whalelayer.getChildAt(i) as Whale;
					if (tempwhale.isAlive()) {
						var p:Point=masterlayer.localToGlobal(new Point(masterlayer.ahablayer.x,masterlayer.ahablayer.y));
						//whale is alive and onscreen, so make him walk and check for harpoon collisions.
						if(tempwhale.y-tempwhale.height<stage.stageHeight-p.y&&tempwhale.y>0-p.y){
							var killer:Object=checkWhale(tempwhale);
							if (killer is Harpoon) {
								if(!killer.megaPoon()){
									killer.myWhales.push(masterlayer.whalelayer.getChildAt(i));
									tempwhale.killWhale();
								} else{
									makeBoom(tempwhale.x-20,tempwhale.y-40);
									whaleCleaner(tempwhale);
									if(soundFX)makeBoomSound();
								}
							} else {
								whaleWalk(masterlayer.whalelayer.getChildAt(i) as Whale);
							}
						}else/*whale is offscreen and must be killed*/{
							whaleCleaner(tempwhale);
						}
					}
				}
			}//end whalelayer loop
		}

		//BELOW LIE THE MOVE WHALE HELPER FUNCTIONS!!!

		//see if the whale has been speared, return the culprit
		public function checkWhale(whale:Whale) {
			for (var k:int = 0; k < harpoonArray.length; k++) {
				var hP:Point = harpoonArray[k].localToGlobal(new Point(harpoonArray[k].hitbox.x, harpoonArray[k].hitbox.y));
				if (whale.hitbox.hitTestPoint(hP.x,hP.y,true)&&!harpoonArray[k].getDead()) {
					return harpoonArray[k];
				}
			}
			return new Number(-1);
		}
		//if the whale is alive, adjust its x coordinates
		public function whaleWalk(whale:Whale) {
			var tempspeed:Number=whale.getSpeed();
			var horizontalChange:Number;
			//save Whale's speed in horizontalChange
			if (whale.getDirection()) {
				horizontalChange=tempspeed;
				if (whale.x+horizontalChange>550) {
					horizontalChange=550-whale.x;
					whale.reverseDirection();
				}
			} else {
				horizontalChange=- tempspeed;
				if (whale.x+horizontalChange<0) {
					horizontalChange=- whale.x;
					whale.reverseDirection();
				}
			}
			whale.x+=horizontalChange;
		}

		//PlayButton has been clicked, set game mode to "play"
		public function clickPlayButton(event:MouseEvent) {
			
			startscreen.visible=false;
			musicOn=true;
			startscreen.easy.removeEventListener(MouseEvent.CLICK,clickPlayButton);
			startscreen.medium.removeEventListener(MouseEvent.CLICK,clickPlayButton);
			startscreen.hard.removeEventListener(MouseEvent.CLICK,clickPlayButton);
			startscreen.instructions.removeEventListener(MouseEvent.CLICK,clickInstructions);
			difficulty=event.currentTarget.name;
			
			initializeMines();
			
			if(difficulty=="easy")mineSpeed=.08;
			if(difficulty=="medium")mineSpeed=.185//.175;//.35;
			if(difficulty=="hard")mineSpeed=.1;//.3;
			Mouse.hide();
			crosshairs.visible=true;
			gameMode="play";
			event.stopImmediatePropagation();
			addEventListener(Event.ENTER_FRAME, gameLoop);
			oxygenTank.scaleX = 1;
			deathTimer.delay = 500;
			deathTimer.repeatCount = 600;
			deathTimer.start();
			deathTimer.addEventListener(TimerEvent.TIMER_COMPLETE, deathTimerComplete);
			addEventListener(MouseEvent.MOUSE_DOWN,fireHarpoon);
			poonTimer.addEventListener(TimerEvent.TIMER,poonReload);
			stage.addEventListener(KeyboardEvent.KEY_DOWN,keyDownHandler);
			stage.addEventListener(KeyboardEvent.KEY_UP,keyUpHandler);
			
			clusterChannel=clusterSound.play(0,1);
			clusterChannel.soundTransform=cTransform;
			clusterChannel.addEventListener(Event.SOUND_COMPLETE,clusterReplay);
			
			scoreCounter.defaultTextFormat=new TextFormat("arial",20,0x17F02D,true);
			scoreCounter.text=myScore.toString();
			scoreCounter.x=440;
			scoreCounter.y=3.5;
			addChild(scoreCounter);
			
			soundFX = true;
		}
		
		//loop the BG music once it completes
		public function clusterReplay(event:Event){
			clusterChannel.removeEventListener(Event.SOUND_COMPLETE,clusterReplay);
			clusterChannel=clusterSound.play(0,1);
			clusterChannel.soundTransform=cTransform;
			clusterChannel.addEventListener(Event.SOUND_COMPLETE,clusterReplay);
		}

		//returns a random number between 0 and 3 (inclusive)
		public function randomFour() {
			return Math.floor(Math.random()*4);
		}

		//returns a random number for the powerups
		public function poonRandom() {
			return Math.floor(Math.random()*120);
		}
		
		//remove whale, update array
		public function whaleCleaner(whale:Whale){
			if (whale.getMasDir()) {
				levelArray[whale.getLevel()].rght=false;
			} else {
				levelArray[whale.getLevel()].lft=false;
			}
			whale.killWhale();
			whale.setAsplode();
			whale.gotoAndStop("blue");
			masterlayer.whalelayer.removeChild(whale);
		}

		//creates Level objects with:
		//lvl (exact coordinates)
		//spd (whale speed)
		//left
		//right
		//and y coordinate
		public function makeLevels() {
			for (var i:int=0; i<9; i++) {
				var temp:Object=new Object  ;
				makeLevelsHelper(temp,i,.2);
				levelArray[i]=temp;
			}
		}
		//helper for makeLevels. "s" is the speed of each level. (not implemented yet)
		public function makeLevelsHelper(foo:Object,thisLevel:int,s:Number) {
			foo.spd=s;
			foo.lvl=thisLevel;

			switch (thisLevel) {
				case 0 :
					foo.y=masterlayer.gamelevel.plankzero.y+1;
					break;
				case 1 :
					foo.y=masterlayer.gamelevel.plankone.y+1;
					break;
				case 2 :
					foo.y=masterlayer.gamelevel.planktwo.y+1;
					break;
				case 3 :
					foo.y=masterlayer.gamelevel.plankthree.y+1;
					break;
				case 4 :
					foo.y=masterlayer.gamelevel.plankfour.y+1;
					break;
				case 5 :
					foo.y=masterlayer.gamelevel.plankfive.y+1;
					break;
				case 6 :
					foo.y=masterlayer.gamelevel.planksix.y+1;
					break;
				case 7 :
					foo.y=masterlayer.gamelevel.plankseven.y+1;
					break;
				case 8 :
					foo.y=masterlayer.gamelevel.plankeight.y+1;
					break;
				default :
					break;
			}

			foo.lft=false;
			foo.rght=false;
		}

		//find angle degrees between harpoon gun and mouse. If you're wondering wtf is happening, law of cosines is.
		public function getAngle() {
			
			var mousePoint:Point=new Point(mouseX,mouseY);
			var xbuf:int=masterlayer.poonlayer.globalToLocal(mousePoint).x-myPoon.x;
			var ybuf:int=masterlayer.poonlayer.globalToLocal(mousePoint).y-myPoon.y;
			var angle = Math.atan(ybuf/xbuf)/(Math.PI/180);

			if (xbuf<0) {
				angle+=180;
			}
			if (xbuf>=0&&ybuf<0) {
				angle+=360;
			}

			return angle+90;
		}

		//handles player input: PRESSED KEY
		public function keyDownHandler(event:KeyboardEvent) {
			if(gameMode=="play") {
				if(event.keyCode==87){//w
					myHab.up=true;
				}
				if(event.keyCode==65){//a
					myHab.lefty=true;
					if(!myHab.righty){
						myHab.isLeft=true;
					}
					if(!myHab.inAir&&!myHab.animating){
						myHab.mc.gotoAndPlay("walk");
						myHab.animating=true;
					}
				}
				if(event.keyCode==83){//s
					myHab.down=true;
				}
				if(event.keyCode==68){//d
					myHab.righty=true;
					if(!myHab.lefty){
						myHab.isRight=true;
					}
					if(!myHab.inAir&&!myHab.animating){
						myHab.mc.gotoAndPlay("walk");
						myHab.animating=true;
					}
				}
				if(event.keyCode==77){
					if(musicOn){
						//clusterPos=clusterChannel.position;
						clusterChannel.stop();
						clusterChannel.removeEventListener(Event.SOUND_COMPLETE,clusterReplay);
						musicOn=false;
					}else{
						clusterChannel=clusterSound.play(0,1);
						clusterChannel.soundTransform=cTransform;
						clusterChannel.addEventListener(Event.SOUND_COMPLETE,clusterReplay);
						musicOn=true;
					}
				}
				if (event.keyCode == 78) {
					soundFX = !soundFX;
				}
			}
			if(event.keyCode==13){
				//enter
				if(gameMode=="play"){
					gameMode="pause";
					Mouse.show();
					crosshairs.visible=false;
					if(poonTimer.running){
						poonTimer.stop();
						poonPause=true;
					} 
					if(musicOn){
						clusterPos=clusterChannel.position;
						clusterChannel.stop();
						clusterChannel.removeEventListener(Event.SOUND_COMPLETE,clusterReplay);
					}
					
					removeEventListener(MouseEvent.MOUSE_DOWN,fireHarpoon);
					removeEventListener(Event.ENTER_FRAME, gameLoop);
					deathTimer.stop();
					pScreen.x=0;
					pScreen.y=0;
					addChild(pScreen);
					for(var i:int=0;i<masterlayer.whalelayer.numChildren;i++){
						if(masterlayer.whalelayer.getChildAt(i) is Whale){
							masterlayer.whalelayer.getChildAt(i).stop();
						}
					}
					myHab.mc.stop();
				}else if(gameMode=="pause"){
					gameMode="play";
					if(poonPause){
						poonPause=false;
						poonTimer.start();
					}
					crosshairs.visible=true;
					Mouse.hide();
					if(musicOn){
						clusterChannel=clusterSound.play(clusterPos,1);
						clusterChannel.soundTransform=cTransform;
						clusterChannel.addEventListener(Event.SOUND_COMPLETE,clusterReplay);
					}
					
					addEventListener(MouseEvent.MOUSE_DOWN,fireHarpoon);
					addEventListener(Event.ENTER_FRAME, gameLoop);
					deathTimer.start();
					removeChild(pScreen);
					for(var i2:int=0;i2<masterlayer.whalelayer.numChildren;i2++){
						if(masterlayer.whalelayer.getChildAt(i2) is Whale){
							masterlayer.whalelayer.getChildAt(i2).play();
						}
					}
				}
			}
		}

		//handles player input: KEY RELEASED
		public function keyUpHandler(event:KeyboardEvent) {
			switch (event.keyCode) {
				case 87 ://w
					myHab.up=false;
					myHab.jumpTimer=getTimer()-myHab.jumpTimer;
					if(myHab.sJump&&myHab.jumpTimer<=400){
						myHab.dy+=(401-myHab.jumpTimer)*0.1*myHab.gravity; //change static coefficient to change rate of slowing. (12)
					}
					myHab.sJump=false;
					break;
				case 65 ://a
					myHab.lefty=false;
					myHab.isLeft=false;
					if(myHab.righty){
						myHab.isRight=true;
					}else{
						myHab.animating=false
						if(myHab.inAir) myHab.mc.gotoAndStop("jump");
						else myHab.mc.gotoAndStop("stand");
					}
					break;
				case 83 ://s
					myHab.down=false;
					break;
				case 68 ://d
					myHab.righty=false;
					myHab.isRight=false;
					if(myHab.lefty){
						myHab.isLeft=true;
					}else{
						myHab.animating=false
						if(myHab.inAir) myHab.mc.gotoAndStop("jump");
						else myHab.mc.gotoAndStop("stand");
					}
					break;
				default :
					break;
			}
		}
	}
}