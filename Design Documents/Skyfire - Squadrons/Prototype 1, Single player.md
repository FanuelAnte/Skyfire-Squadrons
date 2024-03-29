To figure out what is going to be included in this version, I'm going to divide it up into Gameplay, Tech, Level, Art, Sound and Music.
#### Gameplay
- [x] Plane Controls and Movement
- [ ] Plane Class-Dependent Evasive Maneuvers
- [x] Enemy Movement AI
- [x] G-forces
- [x] Combat Controls
- [x] Enemy Combat AI
- [x] Health and Damage
- [x] Damage Criticality
- [x] Fuel and Ammunition
- [x] Pilots
- [x] Death
- [x] Resolution and Dynamic Camera
#### Tech
- [x] Heads Up Display
	- [x] Static HUD
	- [ ] Player markers/names and attached health bars
- [ ] Menus
	- [ ] Main Menu
	- [ ] Game Mode Selection Screen
	- [ ] Mission Selection Screen
	- [ ] Plane and Loadout Selection Screen
	- [ ] Pause Menu
	- [ ] Settings Menu
- [ ] Plane and Loadout Selection Screen
- [ ] Plane Variation and Resources
- [ ] Sound and Music System
- [ ] Objective Handling and Fail States
#### Levels and Missions
- [ ] Level loading
- [ ] Base Level and Level Resources
- [ ] Ground target
- [ ] Objective and Mission Design
#### Art
- [ ] Plane Sprites and Animation
- [ ] Level Art
- [ ] Explosion and Damage
#### Sound
- [ ] In-Game Plane and Level SFX
- [ ] Menu SFX
#### Music
- [ ] Single 5 - 10 minute Cue
- [ ] Basic Dynamic Music System
# Gameplay
### Plane Controls and Movement
This involves basic forward movement, which happens at a predefined fixed speed unless you're out of fuel, and side-to-side turning at two different bank angles. The flight controls consists of three buttons: ___Left arrow___ (to turn left at the base bank angle), ___Right arrow___ (to turn right at the base bank angle), and ___Shift___ (to increase the bank angle). 
```GDScript
var turn = 0

if Input.is_action_pressed("turn_right"):
	turn += 1
elif Input.is_action_pressed("turn_left"):
	turn -= 1

if Input.is_action_pressed("increase_bank"):
	turn *= plane_details.max_bank_angle_factor

steer_angle = turn * deg2rad(plane_details.bank_angle)
velocity = Vector2.ZERO
velocity = transform.x * plane_details.speed

var rear_wheel = position - transform.x * plane_details.wingspan / 2.0
var front_wheel = position + transform.x * plane_details.wingspan / 2.0
rear_wheel += velocity * delta
front_wheel += velocity.rotated(steer_angle) * delta
var new_heading = (front_wheel - rear_wheel).normalized()
velocity = new_heading * velocity.length()
rotation = new_heading.angle()
```
I'm thinking of making the movement controller it's own component. I have two possible ways of approaching it:
1. Use get_parent() to get the plane body and apply move_and_slide() and the rotation.
2. Use an export variable to get the parent node.
##### Mobile Controls.
The buttons for movement just aren't going to cut it I need to do something more intuitive. Hear me out: free dragging on the screen. Drag left and right on any part of the screen and depending on how far away you finger is from the drag_start_position, the turn variable is set accordingly.
### Plane Class-Dependent Evasive Maneuvers (Climbing and Diving)
I have two options regarding how to handle the manueuvers
1. Figure out a way to switch the planes between the top-level scene or the base-level parallax layers.
2. Make the planes, bullets and ground targets all part of the base-level and the set them on different layers and use collision layers to separate the damage taken by bullets and payloads. If a plane is diving or climbing, switch its collision layer to something that doesn't interfere with the bullets collision.

I'm liking option 2.
### Enemy Movement AI
This applies to both ___Enemy___ and ___Ally___ AI. The behavior I have so far is that once a target is set, which is set by me at the moment, the plane follows it. It utilizes the same movement logic as the player controller, the only difference being that the turn angle is set based on the angle between the heading of the plane itself and the target.
```GDScript
var target = get_node(target_node)
$Camera2D.current = false
var direction = (target.global_position - self.global_position)
var angle = self.transform.x.angle_to(direction)

var snapped_angle = stepify(rad2deg(angle), 15)
		
if abs(snapped_angle) <= 90:
	turn += sign(snapped_angle) * 1
else:
	turn += sign(snapped_angle) * plane_details.max_bank_angle_factor
```
This behavior is a good starting point to build upon and create more complex behavior which begs the question, ___what complex behavior do I want___?
##### Complex Movement AI
If target locked, follow. Else, Go into a random searching pattern. What's the random searching pattern? What I have figured out is that the hurtbox, movement and artillery components need to work together. For example, if an ___AI___ is being shot at, it needs to do some sort of evasive maneuver. It detects that it's being shot at and then it... I need a state machine. If I were to do it without a state machine, basically, I need to make the plane know if it's in chase mode, evade more or search mode. 
1. ___Search mode___ - It just picks the average global position of all enemy aircrafts and moves towards that location until the detection ray catches something.
2. ___Evade mode___ - If targeted for too long, and is being shot at, turn left at max_bank.

A little modification to the targeting code. If there is an imbalance between the ally and enemy planes, there should be a "gang up" mode. 

Add a Area 2D to the movement component to detect enemy planes. Add an export variable to exclude the detection of the parent plane(self).

Move the target angle decision code outside. It is shared by both the code that executes if a plane target is assigned and by the code that executes when the plane is targeting thin air.

New logic
1. Calculate target vector point
	1. this can either a plane's actual position,
	2. this can be a ground target or a base/carrier or
	3. this can be an average point between two planes
2. Use that point
	1. if the angle between the target point and the plane is below the lower threshold, turn slow
	2. if it is between the the lower threshold and the upper threshold, turn sharply
	4. if above the max threshold, enter search mode after timeout
		1. in search mode, set target to ""
			1. while waiting for timeout, target the midpoint
			2. after timeout, pick a random plane and target that
				1. in the future, limit the targetable planes by an area 2d or by a range vector

Little trouble here. if an enemy is behind you, it enters an infinite search loop.

Fucking Finally!!!! The AI behaves exactly as I want it to.
I can set the priority of targets.
### G-Forces
Different planes classes have different maneuverability and therefore the pilots experience  G-forces differently.
### Combat Controls
Depending on the class of the plane, a given plane might carry no weapons or at most 3 different types of weapons. This means there will be a ___primary weapon___, a ___secondary weapon___, and a ___tertiary weapon___. This is independent of positioning i.e. where the gun is physically on the plane. Bombers for instance may have the same weapon type mounted in two different positions (real and front). 
#### Artillery Component
There's going to be a custom component called ___Artillery___ that handles all shooting (bullet spawning, ammo counting, loadout swapping, and gun positioning) related logic. The component is primarily meant to house the ___Position Markers___ that act as spawning points for the bullets. Each of marker is going to be marked by ___P___, ___S___, or ___T___ for primary, secondary, or tertiary weapons respectively. In the case of ___Primary___ and ___Secondary___ weapons, they are mostly placed symmetrically on the wings and therefore there needs to be 2 position markers. In such a case, I'll use a parent ___Node2D___ to encapsulate both of them.
The structure, which applies to both symmetrical and asymmetrical placement, would be:
- Plane
	- (every other node)
	- ArtilleryComponent (Node 2D)
		- Primary (Node 2D)
			- Position2D
			- Position2D
			- ...
		- Secondary (Node 2D)
			- Position2D
			- Position2D
			- ...
##### Primary Weapons
These are small caliber machine guns with quicker fire rate, larger magazine capacity, but relatively lower damage. On PC, the ___Z___ key is used to shoot. There are two different firing modes: ___Automatic___ which shoots continuously as long as the key is pressed, and ___Semi-Automatic___ which shoots a burst of 5 rounds every time the key is pressed. 
##### Secondary Weapons
These are slightly larger guns and cannons with slower fire rate, lower magazine capacity but higher damage. On PC, the ___X___ key is used to shoot. This has only one mode of firing and it is basically a manual; repeated key presses are required in order to shoot.
##### Tertiary Weapons
This is mostly reserved for bombers and larger fighter and includes bombs and other large explosive payloads. On PC, the ___C___ key is used to drop the payload.
#### Shooting, Actually
The artillery component has 3 parameters that it accepts:
- Primary Weapon Path
- Secondary Weapon Path
- Tertiary Weapon Path
Each path leads to a bullet scene. Each bullet scene has the following structure. A bullet knows how fast it is, and how much damage it does.
- Bullet (Area2D)
	- Sprite
	- SFXComponent
Whenever one of the fire keys is pressed, a spawn bullet method is called.
#### Bullets and Payloads
Weapons like the Browning M2 and other mounted machine guns fire projectiles bullets that do damage on the same layer that they are spawned on. 
Payload like bombs get spawned on one level and then move down the layer list until they collide with a ground unit or the ground/water and explode.

Bullets, Payloads and Flak rounds. What makes them different? Movement and damage behavior

|                      | Bullets                                                   | Flak                                                                                                                                                                                                                                                                                                                                                            | Payloads                                                                                                                  |
| -------------------- | --------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| Movement             | Move in a straight line from source to target.            | Move from the ground layer to the sky layer.                                                                                                                                                                                                                                                                                                                    | Move from the sky layer to the ground layer.                                                                              |
| End-of-life Behavior | Do damage and queue free when they collide with a target. | Has 2 parts: the part that goes up from the ground to sky layer and the part that gets spawned on the sky layer with a AOE indicator. The second part is the one that actually does damage and is spawned at the same time as the traveling component and does damage and plays the explosion animation and does damage in the AOE circle and then queue frees. | Do damage in a circular area and an explosion animation is played and then is queue freed when the animation is finished. |

#### Dive-bombing
To dive or not to dive, what's the point anymore.
### Enemy Combat AI
This combat logic follows the __Movement__ logic I'll set above.

Add raycasts to the weapon positions to check if they are colliding and whether or not you should shoot. use the fanned out rays in the movement component to check range. Then use the individual side rays to decide if you should shoot the left side cannons or left side cannons. I need a way to separate each wing guns. Or I could just remove the fanned out rays all together and just use the per-side raycasts to detect and shoot. Each weapon has a different range, i.e. a different raycast length. If I use the independent rays per-wing, I can bring the detection and shooting code back into the artillery component. By the way, all of this only applies to the AI's shooting code. I will definitely modify the shooting function but it won't change much.
### Health and Damage
Each plane has a health variable. It has a max value of depending on the plane size and armor. Depending on the health value, smoke and fire particles will be emitted.
When a bullet hits a plane, the damage stat of that specific caliber of that bullet dictates by how much the plane's health goes down. 
Crashing the plane into another one results in an immediate explosion. Crashing completely is at the bottom of the failure spectrum. You can go back to a base or to a carrier to repair your plane but that costs time and that may lead to failure of some time-sensitive objectives.
### Damage Criticality
Bullet's, when instanced, are assigned a damage value. This damage value is dictated by a function inside of the bullet script. How is it decided?  very good question.

Each weapon resource has:
- base damage
- max damage
- criticality curve
The criticality function:
- picks a random number from 0 - 1
- samples the criticality curve at that random number
- maps the sample from 1 to max damage
- multiplies the mapped value with base damage
- then finally returns final damage.
If the criticality curve is, for instance, a logarithmic curve, most hits are critical, meaning the probability of a high criticality shot is high. On the contrary, if it is an exponential curve, most hits are not that critical. 

To make things even more interesting, I could use another RNG check to decide if the base damage is applied as is or if I should pick a criticality value. Meaning:
- pick a random number from 0 - 5
- if the number is greater that 3
	- picks a random number from 0 - 1
	- samples the criticality curve at that random number
	- maps the sample from 1 to max damage
	- multiplies the mapped value with base damage
	- then finally returns final damage.
- else
	- final damage = base damage
### Fuel and Ammunition
These are also variables. Very simple. Fuel goes down at a pre-determined rate i.e. the longer you fly, the more fuel you consume. Running out of fuel results in the plane coasting and eventually crashing. Just like repairs, you can go back to bases or carriers to refuel and rearm.
### Pilots
The pilot you choose dictates (Gameplay-wise):
1. ___The "passing-out resistance"___ - Time it takes for the pilot to lose consciousness after experiencing max G-forces. This is called ___time_to_unconsciousness___.
2. ___Consciousness recovery time___ - Time it takes for the pilot to regain consciousness after G-force stabilization. This is called ___time_to_consciousness___.
How are G-forces going to affect gameplay? After max G-forces are sustained, a timer starts with the duration of ___time_to_unconsciousness___. If the G-forces don't level out by the time the timer times out, a Boolean value called ___passed_out___. If G-forces do level out before the timer runs out, ___consciousness___ levels back out.
##### Vision
Pilots also dictate how much you can zoom out. Also, zoom level of the camera is reset back to 1 if you pass out.
##### Shot Criticality
Pilots also dictate the criticality percentage alongside the weapon resource's criticality values.
### Fuel and Coasting
The standard fuel burning is working fine.
### Resolution
The games resolution and the plane sprite scale in relation to that resolution is becoming a real problem. The problems specifically are 
1. If the plane sprites are in the 32 - 64 px range and the game is set to a 640 base resolution,
	1. The planes are too big and therefore you can't see forward.
	2. Their movement speed is too quick meaning they go in and out of view very quickly. This results in you not being able to lock on to a target accurately.
2. If the plane sprites are at 32 - 64 px range and the game is at 1280 base resolution.
	1. It is no longer pixel art

Solution: dynamic camera zoom. Player controlled. There are going to be 5 different zoom levels:

| Name      | Value | Key binding |
| --------- | ----- | ----------- |
| zoom_min  | 2.0   | num 1       |
| zoom_two  | 1.75  | num 2       |
| zoom_mid  | 1.5   | num 3       |
| zoom_four | 1.25  | num 4       |
| zoom_max  | 1     | num 5       |
# Tech
### HUD
I'm going to keep the in-game HUD as minimal as possible.
##### PC
-  Plane Heath
- Ammo Count
- Fuel Amount
- Radar
- Objective Text
- Player Names
##### Android
- Everything on the PC Version
- On-Screen Controls
- Pause Button
### Menus
##### Main Menu
Standard main menu. Buttons:
- Start Game -> Game Mode Selection Screen 
- Settings -> Settings Menu
- Exit
##### Game Mode Selection Screen
For the time being, there is only one game mode: Single player. This takes you to the Mission Selection Screen.
##### Mission Selection Screen
There will be a list of missions/scenarios. You can pick one to play. Selecting a mission takes you to the plane and loadout selection screen. 
##### Plane and Loadout Selection Screen
Depending on the mission and on the scenario, you're only allowed to pick the appropriate planes and gear. For instance, if you pick a bombing mission where the RAF is bombing the Germans, you can only pick British planes.
##### Pause Menu
Resume, Restart, Settings, Quit.
##### Settings Menu
Adjust sound, music, and whatnot.
### Plane Variation and Resources
What needs to change from plane to plane?
- Sprite and Animation
- Resource values
	- Max Speed
	- Base Bank Angle
	- Max Bank Angle Factor
	- Wingspan
	- Max Fuel Capacity
	- Possible Weapon Types
	- Classification
- Gun Placement
- Wing Trails Position
### Sound and Music System
The SFX for each plane will be handled by a SFX Component attached to each plane. It receives a signal from the plane and it plays the appropriate sounds. I can either call the signals from code or I can attach method calls to the animations to trigger sounds that are a children of the SFX Component. Or I could just have the SFX Component have multiple methods each responsible for playing a random sound effect from a library whenever the function is called. For Instance, the ___turn plane___ method picks from a few audio player 2D nodes and plays one of them.
Now I need to decide what SFX a plane needs and that will be covered in the Sound section.
### Objective Handling and Fail States
Objective completion and failure will be handled differently for each mission type. The lowest level of the failure spectrum is death of the plane. Therefore, I need to figure out how to handle death.
#### Death
To death or not to death, fuuuuuck. When a plane's health gets depleted, the is_dead Boolean is flagged as true and everything from movement to shooting to being targeted to showing up on the radar is disabled. 
# Levels and Missions
### Level Loading
##### Levels
Each level is going to have the following structure.
- Level name (Node2D)
	- parallax background (layer index = -100)
		- parallax layer 1 (water)
			- sprite
		- parallax layer 2 (water)
			- sprite
		- parallax layer 3 (Clouds 1)
			- sprite
		- parallax layer 4 (Clouds 2)
			- sprite
	- parallax background (layer index = 1)
		- parallax layer 5 (Clouds 3 above)
			- sprite
I'm no longer doing foreground clouds. Too Confusing.

| Layer | Name | Scale | Mirroring |
| ---- | ---- | ---- | ---- |
| layer 1 | Water | 0.2 | true |
| layer 2 | Ground | 0.2 | false |
| layer 3 | Clouds 1 | 0.6 | true |
| layer 4 | Clouds 2 | 0.8 | true |
| layer 5 | Clouds 4 above | 1.2 | true |
The things that change from level to level are
- All the textures
- The ground target types
- The ground target locations
A single location might host various missions and therefore it's visuals and target placements needs to change on a mission to mission basis. This is going to be a nightmare to implement. Not to worry, COMPOSITION to the rescue.
- level
	- Level (separate scene that accepts a resource file containing references to all the ground and cloud textures. it basically contains the parallax layers responsible).
	- Ground Units
		- Parallax background.
			- Parallax Layer (same motion scale as layers 1 and 2, water and ground respectively, no mirroring.)
				- List of ground units.
Things like limits, map name and other location specific details are kept in the level_resource.
The level resource contains mission specific details.

So to summarize. the level is going to be built based on a singe static scene that accepts a resource to load sprite textures, the levels(missions) are all unique scenes i.e. each mission has it's own scene.
### Base Level and Level Resources
The base level scene contains the basic parallax scenes and the sprites.
### Ground target
These ground targets will be on the same level as the ground or the water.
##### Damage of ground targets
When the player presses the tertiary bombing button, a payload scene is instanced as a child of the base level. The payload scene has a timer on it that counts down and when it times out, it emits a signal to tell the base level to relocate it to the next parallax layer. It has a variable that holds the current level it is at and whenever it is relocated, that variable is changed. Relocation stops when the current_level variable is equal to "ground". Once it reaches ground, it plays the explosion animation and if it is overlapping with any ground targets, the ground targets take damage. I need to add a few more parallax layers to make the transition of the payload smoother and I also need to scale the sprite of the payload as it goes further down.

So the core loop is as follows.
1. Press ___C___
2. Instance payload as a child of the base level
3. Play the shrinking animation of the payload based on the level it is at
4. When the animation finishes playing
	1. If it is not at the ground level
		1. Emit a signal to the base level to tell it to relocate it
	2. If it is at the ground level
		1. It'll play the explode animation and check for collisions and then queue free itself.
### Objective and Mission Design 
# Art
### Plane Sprites and Animation
### Level Art
### Explosion and Damage
# Sound
### In-Game Plane and Level SFX
### Menu SFX
# Music
### Single 5 - 10 Minute Cue
### Basic Dynamic Music System