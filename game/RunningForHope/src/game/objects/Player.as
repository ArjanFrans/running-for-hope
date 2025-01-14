package game.objects
{
	import audio.Audio;
	
	import citrus.CustomHero;
	import citrus.core.CitrusEngine;
	import citrus.input.InputAction;
	import citrus.input.controllers.Keyboard;
	import citrus.objects.NapePhysicsObject;
	import citrus.objects.platformer.nape.Platform;
	import citrus.physics.nape.NapeUtils;
	import citrus.view.starlingview.AnimationSequence;
	import citrus.view.starlingview.StarlingArt;
	
	import game.GameState;
	import game.objects.platforms.MovingPlatform;
	import game.objects.platforms.Water;
	import game.objects.player.DuckingState;
	import game.objects.player.IdleState;
	import game.objects.player.JumpState;
	import game.objects.player.PlayerState;
	import game.objects.player.WalkState;
	
	import model.Model;
	
	import nape.callbacks.InteractionCallback;
	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.shape.Polygon;
	import nape.shape.Shape;
	
	import starling.animation.DelayedCall;
	import starling.core.Starling;
	import starling.textures.TextureAtlas;
	
	import ui.windows.GameOverWindow;
	
	public class Player extends CustomHero
	{
		public var air_acceleration:Number;
		private var _oldVelocity:Vec2 = new Vec2();
		
		private var _safe_respawn:Vec2;
		
		private var _touchingWall:Boolean = false;
		private var _dead:Boolean = false;	
		
		public var texture_height:Number;
		public var texture_height_duck:Number;
		private var duck_trigger:Boolean;
		
		private var _normal_shape:Shape;
		private var _ducking_shape:Shape;
		private var _state:PlayerState;
		
		public var idleState:IdleState;
		public var jumpState:JumpState;
		public var walkState:WalkState;
		public var duckingState:PlayerState;
		public var faceRight:Boolean = true;
		public var lastWallContact:NapePhysicsObject = null;
		
		public var respawn:Boolean;
		
		
		public function Player(name:String, params:Object=null)
		{
			super(name, params);
			var ta:TextureAtlas = Main.getModel().player().gender == "Male" ? Assets.getAtlas("MaxAnimation") : Assets.getAtlas("MaxAnimation_female");
			//var seq:AnimationSequence = new AnimationSequence(ta, ["walk", "idle", "duck", "hurt", "jump"], "idle", 30, false, Config.SMOOTHING);.
			var fps:Number = Main.getModel().player().gender == "Male" ? 40 : 50;
			var seq:AnimationSequence = new AnimationSequence(ta, ["walk", "idle", "jump", "duck", "respawn"], "idle", fps, false, Config.SMOOTHING);
			view = seq;

			view.width = 40;
			view.height = 96;

			texture_height = this.height;
			texture_height_duck = seq.mcSequences["duck"].height;
			idleState = new IdleState(this);
			jumpState = new JumpState(this);
			walkState = new WalkState(this);
			duckingState = new DuckingState(this);
			
			
			StarlingArt.setLoopAnimations(["respawn"]); //Set respawn animation as a looping animation
				
			_state = idleState;
			
			air_acceleration = 10;
			maxVelocity = 150;
			acceleration = 30;
			jumpAcceleration = 10;
			jumpHeight = 450;
			
			respawn = false;
			Audio.setState("unmute_background");
				
			//Add action to use UP key for jumping
			var keyboard:Keyboard = CitrusEngine.getInstance().input.keyboard as Keyboard;
			keyboard.addKeyAction("up", Keyboard.UP);

		}

		override protected function createShape():void
		{
			super.createShape();
			normal_shape = _shape;
			ducking_shape = new Polygon(Polygon.box(_width, texture_height_duck), _material);
		}
			
		
		/**
		 * Update function is overrided to add wall-jumping. Most of the code below is a copy of the super class.
		 */
		override public function update(timeDelta:Number):void
		{
			_state.update(timeDelta, _body.velocity, _ce.input);
			super.update(timeDelta);
			
			if(respawn) {
				Starling.juggler.add(new DelayedCall(function():void {
					respawn = false;
					Audio.setState("unmute_background");
				}, 2, null));
			}
			
			if(faceRight && _body.velocity.x < 0) {
				faceRight = false;
			}
			else if(!faceRight && _body.velocity.x > 0) {
				faceRight = true;
			}
			
			// If on a safe ground tile (static), save it for possible respawns
			var groundBody:Body =  groundContacts[0] as Body;
			if(onGround && groundBody != null && groundBody.isStatic()) {
				if(Math.abs(x - groundBody.bounds.x) > 30 && Math.abs(x - (groundBody.bounds.x + groundBody.bounds.width)) > 30) {
					Starling.juggler.add(new DelayedCall(function(x:Number, y:Number):void {
						_safe_respawn = new Vec2(x, y);
					}, 1, [x, y]));
				}
			}
			
			// Handle being dead			
			if(_dead) {
				dead = false;
				Audio.setState("dead");
				Main.audio.playSound("dead");
				var m:Model = Main.getModel();

				Main.getModel().pause = true;
				velocity.x = 0;
				velocity.y = 0;
				this._body.velocity.x = 0;
				this._body.velocity.y = 0;
				//Delay before respawning
				Starling.juggler.add(new DelayedCall(function():void {
					
					if(m.lifes-- < 1) {
						(Main.getState() as GameState).openPopup(new GameOverWindow());
						return;
					}
					velocity.x = 0;
					velocity.y = 0;
					x = safe_respawn.x;
					y = safe_respawn.y;
					respawn = true;
					Main.getModel().pause = false;
					
				}, 2, null));
				
				
			}
			
			updateAnimation();
			//trace(Math.abs(_body.velocity.x));
		}
		
		/**
		 * This function is copied from the super class. It is modified to make wall jumping possible.
		 * A few changes are made to make this possible
		 */
		override public function handleBeginContact(callback:InteractionCallback):void 
		{
			var collider:NapePhysicsObject = NapeUtils.CollisionGetOther(this, callback);
			_touchingWall = false;
						
			if (callback.arbiters.length > 0 && callback.arbiters.at(0).collisionArbiter) {
				var collisionAngle:Number = callback.arbiters.at(0).collisionArbiter.normal.angle * 180 / Math.PI;

				if ((collisionAngle > 45 && collisionAngle < 135)) //|| collisionAngle == -90
				{
					if (collisionAngle > 1 || collisionAngle < -1) {
						//we don't want the Hero to be set up as onGround if it touches a cloud.
						if (collider is Platform && (collider as Platform).oneWay && collisionAngle == -90) {
							return;
						}
						_groundContacts.push(collider.body);
						_onGround = true;
					}
				}
				else if(collider is MovingPlatform) {
					_groundContacts.push(collider.body);
					var mp:MovingPlatform = collider as MovingPlatform;
					var yTopOffset:Number = y - _body.bounds.y;
					this.y = mp.body.bounds.y - _body.bounds.height + yTopOffset + 0.3;
					_onGround = true;
				}
				else if(collisionAngle == -90) {
					
				}
				else if(collider is Platform && (collisionAngle == 0 || collisionAngle == -180 || collisionAngle == 180)) {
					//If not, the collision is a wall
					_touchingWall = true;
					lastWallContact = collider;
				}
			}
		}		
		
		/**
		 * Copied from super class. Nothing is modified, but it is just copied hero for possible
		 * changes in the future.
		 */
		override protected function updateAnimation():void 
		{
			
			var prevAnimation:String = _animation;
			var walkingSpeed:Number = _body.velocity.x;
			
			if (walkingSpeed < -acceleration)
				_inverted = true;
			else if (walkingSpeed > acceleration)
				_inverted = false;
			
			_state.updateAnimation();

			if (prevAnimation != _animation) {
				onAnimationChange.dispatch();
			}
		}
		
		public function set state(state:PlayerState):void
		{
			_state = state;
			_state.init();
		}
		
		override public function get animation():String
		{
			return _animation;
		}
		
		public function set animation(animation:String):void
		{
			_animation = animation;
		}
		
		/**
		 * Check if the hero is dead
		 */
		public function get dead():Boolean
		{
			return _dead;
		}
		
		public function set dead(dead:Boolean):void
		{
			_dead = dead;
		}
		
		public function get normal_shape():Shape
		{
			return _normal_shape;
		}
		
		public function set normal_shape(value:Shape):void
		{
			_normal_shape = value;
		}
		
		public function get ducking_shape():Shape
		{
			return _ducking_shape;
		}
		
		public function set ducking_shape(value:Shape):void
		{
			_ducking_shape = value;
		}
		
		
		public function get safe_respawn():Vec2
		{
			return _safe_respawn;
		}
		
		public function set safe_respawn(value:Vec2):void
		{
			_safe_respawn = value;
		}
		
		public function get oldVelocity():Vec2
		{
			return _oldVelocity;
		}
		
		public function set oldVelocity(value:Vec2):void
		{
			_oldVelocity = value;
		}
		
		public function get touchingWall():Boolean
		{
			return _touchingWall;
		}
		
		public function set touchingWall(value:Boolean):void
		{
			_touchingWall = value;
		}
		
	}
}