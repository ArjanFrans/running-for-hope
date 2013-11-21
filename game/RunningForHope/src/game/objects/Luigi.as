package game.objects
{
	import avmplus.getQualifiedClassName;
	import avmplus.getQualifiedSuperclassName;
	
	import citrus.CustomHero;
	import citrus.objects.NapePhysicsObject;
	import citrus.objects.platformer.nape.Platform;
	import citrus.objects.platformer.simple.StaticObject;
	import citrus.physics.nape.NapeUtils;
	import citrus.view.starlingview.AnimationSequence;
	
	import flash.ui.Keyboard;
	import flash.utils.describeType;
	
	import game.GameState;
	import game.PlayerStats;
	
	import nape.callbacks.InteractionCallback;
	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.shape.Polygon;
	import nape.shape.Shape;
	
	import starling.animation.DelayedCall;
	import starling.core.Starling;
	import starling.textures.TextureAtlas;
	import model.Model;
	
	public class Luigi extends CustomHero
	{
		protected static var seq:AnimationSequence;
		
		private const angular_dampening:Number = 2;
		private const linear_dampening:Number = 2;
		private var air_acceleration:Number =  8;
		private var oldVelocity:Vec2 = new Vec2();
		
		private var safe_respawn:Vec2;
		
		private var _touchingWall:Boolean = false;
		private var jump_triggered:Boolean = false;
		private var _dead:Boolean = false;		
		
		private var texture_height:Number;
		private var texture_height_duck:Number;
		private var duck_trigger:Boolean;
		
		private var normal_shape:Shape;
		private var ducking_shape:Shape;
		
		public function Luigi(name:String, params:Object=null)
		{
			super(name, params);
			var ta:TextureAtlas = Assets.getAtlas("LuigiAnimation");
			seq = new AnimationSequence(ta, ["walk", "idle", "duck", "hurt", "jump"], "idle", Config.INTERNAL_FPS);
			view = seq;
			
			texture_height = this.height;
			texture_height_duck = seq.mcSequences["duck"].height;
			
			maxVelocity = 130;
			acceleration = 20;
			jumpAcceleration = 10;
			jumpHeight = 250;
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
			super.update(timeDelta);
			var velocity:Vec2 = _body.velocity;
			
			// If on a safe ground tile (static), save it for possible respawns
			var groundBody:Body =  this._groundContacts[0] as Body;
			if(_onGround && groundBody != null && groundBody.isStatic()) {
				Starling.juggler.add(new DelayedCall(function(x:Number, y:Number):void {
					safe_respawn = new Vec2(x, y);
				}, 1, [x, y]));
			}
			
			if (controlsEnabled) {
				var moveKeyPressed:Boolean = false;
				
				_ducking = (_ce.input.isDoing("duck", inputChannel) && _onGround && canDuck);
				
				duckingResize();
				
				if(_ce.input.justDid("jump", inputChannel)) jump_triggered = false;
				
				if (_ce.input.isDoing("right", inputChannel)  && !_ducking)
				{
					velocity.x += _onGround ? acceleration : air_acceleration;
					moveKeyPressed = true;
				}
				
				if (_ce.input.isDoing("left", inputChannel) && !_ducking)
				{
					velocity.x -= _onGround ? acceleration : air_acceleration;
					moveKeyPressed = true;
				}
				
				//If player just started moving the hero this tick.
				if (moveKeyPressed && !_playerMovingHero)
				{
					_playerMovingHero = true;
					_material.dynamicFriction = 0; //Take away friction so he can accelerate.
					_material.staticFriction = 0;
				}
				//Player just stopped moving the hero this tick.
				else if (!moveKeyPressed && _playerMovingHero)
				{
					_playerMovingHero = false;
					_material.dynamicFriction = _dynamicFriction; //Add friction so that he stops running
					_material.staticFriction = _staticFriction;
				}
				
				if (_onGround && _ce.input.justDid("jump", inputChannel) && !_ducking)
				{
					velocity.y = -jumpHeight;
					onJump.dispatch();
					jump_triggered = true;
				}
				
				//Wall jumping
				if (_touchingWall && _ce.input.isDoing("jump", inputChannel) && !_onGround && velocity.y < 50 && Math.abs(oldVelocity.x) > 50 && !jump_triggered)
				{
					velocity.y = Math.max(velocity.y - 200, -jumpHeight);
					velocity.x = (oldVelocity.x > 0) ? -150 : 150;
					_touchingWall = false;
					jump_triggered = true;
				}
				
				if (_springOffEnemy != -1)
				{
					if (_ce.input.isDoing("jump", inputChannel))
						velocity.y = -enemySpringJumpHeight;
					else
						velocity.y = -enemySpringHeight;
					_springOffEnemy = -1;
				}
				
				//Cap velocities
				if (velocity.x > (maxVelocity))
					velocity.x = maxVelocity;
				else if (velocity.x < (-maxVelocity))
					velocity.x = -maxVelocity;
			}
			
			//Track previous velocity, necessary for wall jumping.
			Starling.juggler.add(new DelayedCall(function(x:Number, y:Number):void {
				oldVelocity.x = x;
				oldVelocity.y = y;
			}, 0.3, [_body.velocity.x, _body.velocity.y]));
			
			if(_dead) {
				var m:Model = Main.getModel();
				m.lifes--;
				velocity.x = 0;
				velocity.y = 0;
				x = safe_respawn.x;
				y = safe_respawn.y;
				dead = false;
			}
			
			updateAnimation();
		}
		
		/**
		 * Change the hero's shape size when ducking, and change it back when done ducking.
		 */
		private function duckingResize():void
		{
			if(canDuck) {
				if(_ce.input.isDoing("duck", inputChannel) && _onGround 
					&& Math.round(_shape.bounds.height) == texture_height) {
					_shape.scale(1, texture_height_duck / texture_height);
					this.view.y += texture_height_duck * 0.25;
				}
				else if(_ce.input.hasDone("duck", inputChannel)) {
					if(Math.round(_shape.bounds.height) != texture_height) {
						_shape.scale(1, texture_height / texture_height_duck);
						this.view.y -= texture_height_duck * 0.25;
					}
				}
			}
			//TODO the visual appearance of ducking doesn't look very smooth, some animation 'glitching' occurs
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
		
				if ((collisionAngle > 45 && collisionAngle < 135) || collisionAngle == -90)
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
				else {
					//If not, the collision is a wall
					_touchingWall = true;
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
			
			if(_hurt) {
				_animation = "hurt";
			}
			else if (!_onGround) {
				_animation = "jump";
				
				if (walkingSpeed < -acceleration) {
					_inverted = true;
				}
				else if (walkingSpeed > acceleration) {
					_inverted = false;
				}
			} else if (_ducking && _onGround) {
				_animation = "duck";
			}
			else {
				if (walkingSpeed < -acceleration) {
					_inverted = true;
					_animation = "walk";
				} else if (walkingSpeed > acceleration) {
					_inverted = false;
					_animation = "walk";
					
				}
				else {
					_animation = "idle";
				}
			}
			
			if (prevAnimation != _animation) {
				onAnimationChange.dispatch();
			}
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
	}
}