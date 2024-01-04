___
#### Questions To Ask.
> *How long will it take to prototype?
> How much value will it add to gameplay?
> Does it support the core gameplay mechanics?*
#### How Much of this game do I need to make before I know it is fun?
What elements need to be in place to see if this works? __Flight__ and __Combat__.
But saying flight and combat is a bit too broad. To answer the question, I guess all the core mechanics need to be in place to figure out if this game is going to be fun or not. It will be in a place where I can playtest it and gather feedback.
# Core Mechanics
### Flight
 - [ ] Basic Steering
 - [ ] Diving
 - [ ] Climbing
 - [ ] Evasive Maneuvers 
### Combat
- [ ] Shooting 
- [ ] Taking Damage
- [ ] Layer-based Collision Detection (Above and Below Clouds.)
- [ ] Dogfighting
- [ ] Ground Unit Attacks
### Plane Status
- [ ] Health (May or May Not Be Divided Up Into Specific Equipment and Part Health.)
- [ ] Ammo Count
- [ ] Fuel Amount
# Support Mechanics
### AI
- [ ] Enemy AI
- [ ] Ally AI
### HUD
- [ ] Radar
- [ ] Touch Controls (Mobile Only)
- [ ] Score Display
- [ ] Ammo Counter
### Game Loop Management
- [ ] Score Handling
- [ ] Multiplayer Management
- [ ] Player Spawning and Respawning
# Planes
What do all planes share?
- General Movement
- Shooting
- Health
- Weapon Slots
- Radar
### General Movement
What are the core movement mechanics? 
- Basic forward motion
- Steering left and right.
- Diving.
- Climbing.
- Evasive maneuvers.
The base plane is going to be a __KinematicBody2D__. Planes can be either controlled by the player or an AI agent. If it is controlled by a player, it must accept and handle user input. If it is controlled by an AI agent, it receives targets instead of inputs. Whether it accepts user input or a target, the goal is to move and maneuver the plane. 
Thinking about it more technically, if we consider components, if it is a user controlled plane, there will be a component that accepts inputs and modifies the plane's rotation, velocity, and animations accordingly. For instance, if we press the left button, the velocity component calculates the modified velocity and returns it and that return value is captured by the plane root and then passed to the __move and slide()__ function.
When we come to the AI agent, we accept a target to follow, and then we modify the heading of the plane to align with the target, and the we return the new velocity vector to the plane root to pass it to the __move and slide()__ function.
I can use the same component for velocity for both player and AI controlled planes. I can just add a flag to signify who is controlling it; if the flag is true, the user input is captured and if it is false, the targeting function is called and used.
I think I'm in a good position to start prototyping the basic plane locomotion.
#### Scene Structure
- Plane(KinematicBody2D)
	- Sprite
	- CollisionShape2D
	- Camera2D
	- AnimationPlayer
	- PlaneMovementComponent(Separate Scene, Component, Node2D)
##### Plane Movement Component
I'm going to add the velocity manipulation and input handling code here. This Component requires a resource which contains variables for:
- Plane Speed.
- Bank Angle.
- Wingspan.

> I am not aiming for realism with this project. __Game Feel__. That's what comes first.

How am I going to do the movement? The plane's velocity is going to be constant in the forward direction. I'll set a roughly arbitrary value for the forward speed depending on the actual real speed specs of the plane. The wingspan is also going to be set for every plane accordingly. The only value the player changes during flight is the bank angle. There's going to be a basic 15 degree bank while pressing the ___arrow keys___ alone and then a more pronounced 30 degree bank angle when pressing ___shift___.
I'm going to start by separating the movement function I have in the main plane script out into a component. The component's layout is going to be simple: It's going to have two primary functions; the first to accept input and the second to steer the plane and the second one to calculate the steering.