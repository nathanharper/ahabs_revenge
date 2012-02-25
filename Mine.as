package{
	import flash.display.*;
	import flash.text.*;
	import flash.events.*;
	import flash.utils.*;
	
	public class Mine extends Object{
		
		private var myColor:String;
		private var powerup:String="null";
		
		//a mine is stable if there is a stable mine above it, ot to its left or right
		private var isStable:Boolean=true;
		
		public function Mine(clr:String){
			myColor=clr;
		}
		
		//set the powerup type
		public function setPowerup(power:String){
			powerup=power;
		}
		
		//return the powerup type
		public function getPowerup(){
			return powerup;
		}
		
		//return this mine's color
		public function getColor(){
			return myColor;
		}
		
		//destabilize this Mine
		public function notStable(){
			isStable=false;
		}
		//check if the mine is stable
		public function getStable(){
			return isStable;
		}
	}
}