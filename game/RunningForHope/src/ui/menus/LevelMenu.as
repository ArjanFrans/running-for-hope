package ui.menus
{
	import flash.filters.ConvolutionFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Rectangle;
	
	import model.Level;
	import model.Model;
	
	import starling.display.Button;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.*;
	import starling.text.TextField;
	import starling.textures.Texture;
	import starling.utils.HAlign;
	
	import ui.buttons.NumberButton;
	
	/**
	 * ...
	 * @author Wim Barelds
	 */
	public class LevelMenu extends Sprite
	{
		private var callback:Function;
		private var backCallback:Function;
		private var titleText:String;
		
		public function LevelMenu(callback:Function, backCallback:Function, titleText:String):void 
		{
			this.callback = callback;
			this.backCallback = backCallback;
			this.titleText = titleText;
			
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init():void
		{
			// Set the title
			MenuState.setTitle(titleText);
			
			// Create button to go back to the main menu
			var backButton:NumberButton = new NumberButton(Assets.getTexture("Interface", "btnBack"), 0, "", backCallback, 250, 0xFF440000);
			backButton.x = 540;
			backButton.y = 520;
			addChild(backButton);
			
			// Add buttons for each level
			var m:Model = Main.getModel();
			var numLevels:int = m.numLevels();
			for (var i:int = 0; i < numLevels; i++) {
				var level:Level = m.getLevel(i); 
				var button:NumberButton = new NumberButton(Assets.getTexture("Interface", "btnGeneric"), i + 1, level.name, callbackWrapper, 250);
				button.x = 50;
				button.y = 150 + (i * 75);
				addChild(button);
				
				var highscoreTextField:TextField = new TextField(470, 50, "Highscore: " + level.highscores().getHighScore(0).toString(), "Arial", 15);
				highscoreTextField.hAlign = HAlign.LEFT;
				highscoreTextField.x = 320;
				highscoreTextField.y = 162 + (i * 75);
				highscoreTextField.color = 0xFFFFFFFF;
				addChild(highscoreTextField);
			}
		}
		
		/**
		 * We asign numbers to the (level) buttons from 1 and up, level indexes start from 0. So we do -1.
		 * @param	level
		 */
		private function callbackWrapper(level:int):void {
			callback(level - 1);
		}
	}
}