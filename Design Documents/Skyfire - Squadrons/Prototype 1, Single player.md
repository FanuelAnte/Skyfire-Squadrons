To figure out what is going to be included in this version, I'm going to divide it up into Gameplay, Tech, World, Art, Sound and Music.
#### Gameplay
- [x] Plane Controls and Movement
- [x] Enemy Movement AI
- [x] Combat Controls
- [x] Enemy Combat AI
- [ ] Health and Damage
- [ ] Fuel and Ammunition
#### Tech
- [x] Heads Up Display
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
#### World
- [ ] Level loading
- [ ] World Design
- [ ] Objective and Mission Design
#### Art
- [ ] Plane Sprites and Animation
- [ ] Level Art
- [ ] Explosion and Damage
#### Sound
- [ ] In-Game Plane and World SFX
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

A little modification to the targeting code. If there is an imbalance between the ally and enemy planes, there should be a a "gang up" mode. 
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
### Enemy Combat AI
This combat logic follows the __Movement__ logic I'll set above.

Add raycasts to the weapon positions to check if they are colliding and whether or not you should shoot. use the fanned out rays in the movement component to check range. Then use the individual side rays to decide if you should shoot the left side cannons or left side cannons. I need a way to separate each wing guns. Or I could just remove the fanned out rays all together and just use the per-side raycasts to detect and shoot. Each weapon has a different range, i.e. a different raycast length. If I use the independent rays per-wing, I can bring the detection and shooting code back into the artillery component. By the way, all of this only applies to the AI's shooting code. I will definitely modify the shooting function but it won't change much.
### Health and Damage
Each plane has a health variable. It has a max value of depending on the plane size and armor. Depending on the health value, smoke and fire particles will be emitted.
When a bullet hits a plane, the damage stat of that specific caliber of that bullet dictates by how much the plane's health goes down. 
Crashing the plane into another one results in an immediate explosion. Crashing completely is at the bottom of the failure spectrum. You can go back to a base or to a carrier to repair your plane but that costs time and that may lead to failure of some time-sensitive objectives.
### Fuel and Ammunition
These are also variables. Very simple. Fuel goes down at a pre-determined rate i.e. the longer you fly, the more fuel you consume. Running out of fuel results in the plane coasting and eventually crashing. Just like repairs, you can go back to bases or carriers to refuel and rearm.
# Tech
### HUD
I'm going to keep the in-game HUD as minimal as possible. The main things that need to be shown are:
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

# World
### Level Loading
### World Design
### Objective and Mission Design
# Art
### Plane Sprites and Animation
### Level Art
### Explosion and Damage
# Sound
### In-Game Plane and World SFX
### Menu SFX
# Music
### Single 5 - 10 Minute Cue
### Basic Dynamic Music System