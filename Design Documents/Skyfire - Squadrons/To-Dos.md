These are to be added in the first playable prototype.
- [ ] Fuel.
	- [x] burn rates
	- [x] throttle toggle PC
	- [x] throttle toggle Android
	- [ ] flight disable and coasting (this comes after death is implemented.)
		- [ ] If coasting, turning costs you speed. Therefore you need to be frugal with the maneuvers you make. coasting speed starts off at the base speed, if coasting, there is no throttling, and coasting speed gradually decreases if just flying in a straight line, and dramatically if maneuvering and turning, If coasting speed reaches zero, you either crash into the ocean on on land or somewhere. 
	- [x] UI indicator for time and fuel
- [x] Make the enemies not target the same player. The is_targeted flag did nothing.
- [ ] Either multi-targeting or random flight pattern towards action zones.
- [x] Gs.
- [x] G-Force Effects
	- [ ] Zoom in camera when passing out or just reset it to 1.
- [x] Pilot consciousness bar
- [x] Death.
	- [x] radar icon removal
	- [x] not targeting the dead
- [ ] Map coordinates HUD
- [ ] Climbing and diving maneuvers
	- [ ] Class dependent maneuvers
- [ ] Add a new targeting system. Each plane has a circular area around it and it can only target the planes that are intersecting with the area. If no bodies are intersecting with the area, it picks a random target.
- [x] Plane Classes.
- [ ] Flak rounds for bombers and ground units
- [x] add owners to bullets.
- [ ] Bound the playable area.
	- [ ] Add world
	- [ ] Add world limits
	- [ ] Add world art.
- [x] Add throttling for enemies if their target is too far away.
- [ ] Shot criticality
	- [x] Not all bullet hits do the same amount of damage
		- [x] Based on RNG, make some shots do more damage
	- [ ] Consecutive shots do more damage.
	- [ ] Glass breaking effects after critical hits
	- [ ] Smoke effects after critical hits
- [ ] Fan out bullets a little bit. Give them travel angle variation.
- [ ] ~~1280 asset port.~~
	- [ ] ~~Minimap~~
	- [ ] ~~Android Controls~~
	- [ ] ~~Bars~~
	- [ ] ~~Text~~
	- [ ] ~~Guides~~
- [ ] The AI doesn't know how to pace itself when it comes to using the throttle. They keep passing out too quickly.
- [ ] Menus
	- [ ] main menu
	- [ ] Settings
	- [ ] ...
- [ ] Divebombing
- [ ] Bomber behavior
	- [ ] targeting (ground)
	- [ ] defense artillery
- [ ] Tween when throttling
- [ ] Avoid pane overlaps by checking proximity
	- [ ] If within 100 pixels of your target, move away randomly.
- [ ] Small fighters should do evasive maneuvers instead of turning at max_bank when being shot at.
- [ ] The pilot you pick dictates how far out you can zoom. Meaning the pilot resource sets the max_zoom level.
- [ ] dithering for pass-out shader 
- [x] drag indicators for android
	- [x] don't lock turn amount to certain thresholds 
		- [x] turn amount should be finessed but the effects and turn animations should stay the same.
		- [x] if dragging, multiply the turn amount by a range_lerp value set between 0 and max_turn angle.
			- [ ] Experiment more with this.
			- [ ] maybe make it an option to go back and forth between fixed snapping and a gradient.
``` GDScript
var drag_clampped_min = range_lerp(abs(drag_distance), drag_values["lower_limit"], drag_values["upper_limit"], 0, 1)

or

var drag_clampped_min = 1
```
		- [ ] add a buffer between the upper limit for the normal turn and the lower limit for the maximum turn. and make the variables into one dictionary. 
		- [x] maybe fix the drag start position along the x axis to the (get_viewport().rect().x/3)/2. It's all over the place. It needs to be more consistent.
			- [ ] maybe make it an option in the controls settings to go back and forth between the fixed and floating option.
		- [ ] refine and tweak the min/max values. Movement is a nightmare.
- [ ] Settings globals.
- [ ] Sound Effects.
- [ ] Hit effects
	- [x] vibration
	- [ ] smoke
# For Saturday
- [x] Dedicated throttle toggle for android
- [x] Zoom buttons for android
- [ ] Simple tutorial screen (for controls)
- [x] Placeholder world art
	- [ ] limits
- [ ] main menu
- [ ] objectives
- [x] Hide tertiary action button accordingly.