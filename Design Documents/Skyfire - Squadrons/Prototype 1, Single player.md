To figure out what is going to be included in this version, I'm going to divide it up into Gameplay, Tech, Level, Art, Sound and Music.
#### Gameplay
- [x] Plane Controls and Movement
- [ ] Plane Class-Dependent Evasive Maneuvers
- [x] Enemy Movement AI
- [x] G-forces
- [ ] Squad tactics and hot-swapping
- [x] Combat Controls
- [x] Enemy Combat AI
- [x] Health and Damage
- [x] Damage Criticality
- [x] Fuel and Ammunition
- [x] Pilots
- [x] Death
- [x] Resolution and Dynamic Camera
- [ ] Plane Classification
- [ ] Economy
#### Tech
- [x] Heads Up Display
	- [x] Static HUD
	- [ ] (Unnecessary) Player markers/names and attached health bars
	- [ ] Target indicators
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
- [ ] Story, Setting and Themes
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
2. ___Evade mode___ - If targeted for too long, and is being shot at, turn left at max_bank. Evades only when hit by critical shots.

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
### Squads, Squad Tactics, and Hot-swapping
##### Squads
Fighter planes have one-man crews. Bombers have 3 - 5 man crews. Each member of the crew can fly the plane in the rare case the pilot and copilot were both shot.
##### Tactics
I don't want the AI doing it's own thing. The AI is in charge of what happens moment to moment when it's being attacked but I still want to have a larger, overarching objective. For instance, fighters could be tasked with protecting the bombers. I want there to be squad tactics and planning. Things like formations, targeting commands, routes, and so on.
The closer you are together, light fighters don't get to you but you are prone to flak and AA damage.
##### Hot-swapping
I don't want the player to be locked in into a single pilot throughout the game. I want to allow the player to:
1. Either switch freely between planes and pilots mid-game.
	1. I think this is going to hurt the gameplay and make it too much to handle but I'm still going to try it.
2. Or to switch to another plane and pilot once the lead/player plane/pilot is downed.
	1. I think this is the way to go. It allows for a wider failure spectrum while also giving the gameplay some focus. 
Basically Battlefield 2 Modern Combat's hot-swapping mechanic. 
How is it going to work? Simple: when you want to swap, the game pauses, and you select a pilot from the list of pilots. In the case of bomber crews, you can only select either the main pilot or the bombardier.  
### Combat Controls
Depending on the class of the plane, a given plane might carry no weapons or at most 3 different types of weapons. This means there will be a ___primary weapon___, a ___secondary weapon___, and a ___tertiary weapon___. This is independent of positioning i.e. where the gun is physically on the plane. Bombers for instance may have the same weapon type mounted in two different positions (real and front). 
##### Weapon overheating and degradation
Don't overheat your weapons!!! Shooting constantly degrades the health of the weapons which affects it's accuracy and which is persistent from mission to mission if not repaired or replaced. Same thing goes for planes. Planes that have taken damage during combat need to be repaired.
I want players to play with intentionality and discipline; I don't want them to spam the shoot buttons and spray bullets wildly. I want them to line up a shot perfectly and then shoot in bursts. This has various benefits.
1. You don't run out of ammunition quickly - ammunition also costs money. So does fuel.
2. I can make damage criticality much more aggressive.
3. Performance boost; no more thousands of bullets painting the screen.
4. More interesting combat.
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
##### Payloads
How does a payload come into existence? Well, when the ___C___ button is pressed, just as with the bullets, a new payload instance is created, a payload resource file is assigned to it, and then it is made a child on the first payload layer.
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
I want to push the criticality even further. I want to make every hit location count. Wing and tail hits decrease maneuverability, engine hits may explode the plane totally and so on. ***BUT*** since the planes are so small, and movement is so quick and since there isn't a dedicated aim button, it's not a question of skill, but rather, a question of RNG. Maybe have different hitboxes for different parts of the plane.
I want to really rework the health and damage system.
Maybe setup the criticality assignment of the bullets so that the attributes in the pilot and the bullet resources define the criticality. Maybe the pilot determines if the shot is critical or not and the bullet's criticality curve determines the damage value. More experienced pilots hit more critical shots.
The pilot criticality values are as follows:
1. Criticality value range - is a value ranging from 5 - 25, experienced pilots have lower range values while rookies have larger values.
2. Criticality threshold - is a value ranging from 2 - maximum range -2. This is the value that determines if a shot is critical or not. Experienced pilots have higher values while rookies have lower values.
How it to works:
1. Pick a random number from the criticality values range.
2. Compare that selected number with the criticality threshold.
	1. If it is greater than the threshold, the shot is not critical
	2. If it is equal or less than the threshold, the shot is critical.
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
##### Pilot Specialty (Perks)
Each pilot has a unique perk like more damage when fighting in a heavy fighter or more maneuverability when in a light fighter.
In order to avoid completely useless pilots, every rookie pilot is good at at least one thing; Either
1. high G-force tolerance
2. good accuracy
3. high targeting and turning thresholds
4. good dodge and swerve timers
5. good zoom
I feel like there should be more values to be tweaked.
The things I want to avoid are:
1. Samey pilots.
2. Pilots that are completely useless from the get-go
##### Pilot progression
If a pilot scores a kill, his accuracy increases. If a pilot returns home with minimal damage to the plane, he gains maneuver points. The swerve and dodge timers increase steadily every time the pilot returns from a mission.
##### Multiple Pilots
VOID BASTARDS!!! What if there was a revolving door of pilots, each with a randomized set of resource values. Whenever you decide to play a mission, you select a squadron. After the mission, the members of the squadron who have made it back alive get XP points, upgrades to their resource values and they get one flight mission knocked off of their total flight cap. Once the flight cap is reached, you can no longer use that pilot (Pyre meets Catch 22). 
There is a list of possible first names and surnames along with a title (Maj., Sgt.).
1. Create a new pilot resource based on the pilot class from within the script.
2. pick a random name by combining first and last names.
3. randomize the values.
4. assign perk
5. assign rank/title
I think that this selection process should happen once the game starts. Each player gets a random pilot set. 100 pilots for instance. 
Each pilot has flight training as well as mounted gun and bombing training. 
OOOOOOOOOR.
What if instead of being given 100 similar pilots, you're given, say 50 fighter pilots, 5 crews of 3 for light bombers, and 10 crews of 5 for heavy bombers. Each pilot has a specialization and using them outside of their specialization results in them performing poorly and gaining less XP at the end of a mission. For instance, If you make a light fighter pilot fly a heavy bomber, the maneuverability is significantly affected. Placing pilots as bomber gunners results in less shot accuracy for defensive purposes. I think this is the way to go. I'm not sure about the exact number of pilots you're given but I know it's going to follow this structure.
What if you could train fresh recruits if you have enough money instead of failing the entire campaign if you loose your entire pilot allotment.
This means that every pilot starts out with the same stats but as soon as a specialization is assigned, certain attributes are boosted and nerfed accordingly. For instance, a gunner has more accuracy with mounted guns that a pilot and conversely, a pilot has better maneuvering skills than the gunner. I don't know exactly how these values for differentiation are going to be manifested yet but I have a good idea of how I want it to be.
##### Pilot health
Both physical and mental??? Maybe. What if fully critical shots did damage to the pilots? Especially in bombers? Based on the type of damage model I implement, what if there was damage done to pilots' health, both physically and mentally? If a pilot gets wounded, he is unavailable for 2-5 missions depending on the severity. I don't know about mental health effects. Do I really what that in the game?
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
### Plane Classification

|                     | Light Fighters                                                      | Heavy Fighters                                                                                         | Light Bombers                                                                                                    | Heavy Bombers                                                                                                    |
| ------------------- | ------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| **Health**          | Low                                                                 | Medium                                                                                                 | Medium                                                                                                           | High                                                                                                             |
| **Artillery**       | ***primary*** - low caliber.<br><br>***secondary*** - high caliber. | ***primary*** - low caliber.<br><br>***secondary*** - high caliber.<br><br>***tertiary*** - torpedoes. | ***primary*** - low caliber.<br><br>***secondary*** - high caliber.<br><br>***tertiary*** - light bomb payloads. | ***primary*** - low caliber.<br><br>***secondary*** - high caliber.<br><br>***tertiary*** - heavy bomb payloads. |
| **Speed**           |                                                                     |                                                                                                        |                                                                                                                  |                                                                                                                  |
| **Fuel**            | Small tank                                                          | Medium tank                                                                                            | Medium tank                                                                                                      | Large tank                                                                                                       |
| **Maneuverability** | Very high                                                           | Moderate                                                                                               | Low                                                                                                              | Low                                                                                                              |
| **Size**            | Small                                                               | Medium                                                                                                 | Medium                                                                                                           | Large                                                                                                            |

##### Light Fighters
These are very small and very maneuverable. Have a lower fuel tank capacity and carry less ammunition. Don't carry payloads and secondary weapons. They only have primary weapons. They make up for the lack of artillery in their maneuverability and their speed. Also have lower health
##### Heavy Fighters
These are large and are moderately maneuverable. Have both primary and secondary weapons. Are slower and therefore less maneuverable than small fighters but they have a larger fuel tank and carry more ammo. They have higher health and are the perfect all-rounders.
##### Light Bombers
Quicker, carry less payload. More health than HF, less that HB. Automated primary and secondary weapon firing.
##### Heavy Bombers
Slower, carry more payload. Basically fortresses. Have multiple side cannons and tail guns. Automated primary and secondary weapon firing.
### Economy
Buying and repairing planes cost money. So do bullets and payloads. So does fuel. And so do weapons. 
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
### Player markers/names and attached health bars
This is unnecessary. Refer to Whitelight's video on Far Cry 6 35:00 - 37:00.  
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
#### Types of ground targets
There are two types of ground targets classified based on whether or not they attack.
###### Static
###### Offensive

#### Damage of ground targets
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
### Story, Setting and Themes
I think I want to set this thing in Britain and Italy as a series of RAF-USAF joint operations. Or maybe you just play as the USAF.
### Objective and Mission Design 
As mentioned above, missions revolve around a specific objective (or set of objectives) that needs to be completed by your selected squadron.
You aren't locked into a mission once you start it. You can issue a retreat command if you wish to abandon the mission and return home with the pilots and the planes intact.
Losing planes costs money and losing experienced pilots is infuriating and has an effect of gameplay. In order to avoid the terrible X-COM snowballing issue, there are going to be occasional enemy raids and small scale bombing runs that can be used to train rookie pilots.
You truly fail at the game when you either run out of money or when you exhaust your pilot reserves. So that's a pretty wide failure spectrum.
Missions have a plane requirement but it's not that strict. You always take 5 - 10 planes and out of those, you can chose 4 - 8 of them. Meaning, on bombing runs, for instance, you always have to have at least 1 bomber in your squadron, with the option of taking more that that (until the plane requirement is reached, 5 usually).
I also don't want 5 AI fighters at all time on the screen. Most of the work could be done by defensive ground targets.
Mission objectives are one of very few (Bombing, Interception, yada yada...). The placement of targets, the combination of enemy planes, and the sequence of the objectives changes on each playthrough (essentially a single save file).
What if you had a set of missions at a given time. Like you have a set of races in NFS:MW that you had to complete in order to progress, what if you had a handful of missions to pick and choose at a time? For instance, the first 5 mission might be sinking of battleships over the coast or maybe you have to neutralize ground defenses at a seaside town and neutralizing the ground targets unlocks more missions further inland and so on. What if the ultimate goal of the game is to do as much damage to "mainland Europe" before you exhaust your capital, resources and pilot reserves. maybe I could make some missions one-offs, aborting them or failing them locks you out of attempting them forever, and succeeding grants mega XP and cash bonuses as well as weaking the enemy, making further progress towards the defeat of the enemy.

What if you could repurpose captured enemy fighters? just repaint them and get them for no cash. Missions set in towns with plane factories in them grant you a handful of extra planes if you leave the factory undamaged (The main objective being the destruction of ground targets and military strongholds).

Almost all missions can be retried. The ones that can't be retried are the one-offs, time sensitive ones and defensive/interception missions.

I don't want the campaign to be rigid. However I don't want it to be a random and messy stich-up-job. It's going to be Masters of the Air. A progressive and tactical ingress into mainland Europe. The progression is going to be predefined; the sequence of locations unlocked. However, the nature of the missions at those specific locations and the order in which you choose to approach a given set of missions is up to the RNG and you respectively. Random surprise missions (such as time sensitive missions, one-offs and missions where you play defense) will pop up occasionally depending on your progress.

During defensive missions (interceptions), failure results in both pilot casualties and loss of property and consequently loss of money.

Depending on how things turn out, I may or may not eliminate the whole money management and marker/economy and just focus on the pilots exclusively.

Missions that emanate from land-based bases have a time limit in the from of the fuel timer. Meaning, no refueling. You must finish the objective and return to the exit point before you run out of fuel. On the other hand, naval carrier based battles allow for refueling but only for fighters, not bombers.
Naval battles are a bit of a tricky one. They can be either offensive or defensive, bombing runs, interceptions or reconnaissance, can be fully naval or have some planes launch from land. For instance, a naval bombing run may have the fighters (basically the escorts) launching from the carriers but the bombers themselves launch from land-based bases.
Or maybe I just make naval missions a game of battleship; no bombers, just light and heavy fighters launching from naval carriers, attacking the enemies carriers and planes by using torpedoes. Simpler to construct and easier to manage. 

One possible type of one-off interception mission is a defense of cargo ships carrying valuable resources. If the mission is lost, you pay a premium to get the resources. If you win, you pay nothing at all.... Something like that...refine it further.

Interception missions mostly occur after you endure a heavy mission failure or once every 3 - 5 missions.

What if there were chained missions? Meaning missions where you have to attack multiple targets in multiple locations. Or rather, some missions have a chaining option in order to remove the threat of an immediate response (in the form of an interception mission) from the enemy. For instance, the main objective may be to hit an engine factory in one town but as a chained mission, you have to hit two other locations adjacent to it to destroy the air bases to avoid retaliation.
##### Campaigns
1. RAF-USAF British campaign
2. USAF Italian campaign
3. USAF Pacific naval campaign
##### Mission Types
Different mission types have different plane requirements

|                | Plane Requirement | Objective(s) | Offensive or Defensive       |
| -------------- | ----------------- | ------------ | ---------------------------- |
| Bombing runs   |                   |              | Offensive                    |
| Interception   |                   |              | Defensive                    |
| Reconnaissance |                   |              | Offensive                    |
| Naval battles  |                   |              | Both Offensive and Defensive |
|                |                   |              |                              |
### Campaign progress
AGE OF EMPIRES!!! What if I also kept track of the enemy details as well? Things like pilot count and progress, plane and artillery health, money, plane count and so on.

You're given a certain amount of planes at the beginning of your campaign just like pilots.
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