# QBX Vehicle Features
qbx_vehiclefeatures is a FiveM resource designed to enhance vehicle-related gameplay by adding immersive and dynamic features. Built with ox_lib, it integrates radial menu and target options for vehicle interactions with visual representations of items and players placed in a vehicle's trunk with ox_inventory.

# Features
**Seat Switching**: Change seats dynamically while inside a vehicle using a radial menu.

**Vehicle Extras Management**: Toggle specific vehicle extras on or off.

**Vehicle Flipping**: Flip an overturned vehicle back onto its wheels.

**Trunk Interactions**:
- Hide inside the trunk of a vehicle.
- Place others inside the trunk.

**Realistic Trunk Positioning**: Players are positioned correctly within the trunk based on vehicle dimensions for a realistic fit.

**Dynamic Ejection**: Exiting the trunk at speeds above a threshold triggers ragdoll physics, using the vehicle's velocity divided by 6.0 (calculated from its speed in km/h).

**Visual Items in Trunk**: Visual representations of items placed in a vehicle's trunk, enhancing immersion by displaying items based on the trunk's stash contents.

# Configurations
The configuration file allows you to customize various aspects of the qbx_vehiclefeatures resource to suit your needs. Below is a breakdown of its options:

**General Settings**
- pedVisible (boolean): Determines if players hiding in the trunk remain visible.
- canCamMove (boolean): Enables camera movement around the vehicle with a small zoom radius.
- barPeeking (boolean): Adds cinematic bars at the top and bottom for a peeking effect in the trunk.
- drawText3dTrunk (boolean): Determines the drawText3d for showing how to open/close and exit the trunk.
- visualItemsInTrunk (boolean): Enables or disables visual items in the trunk when an item is added to the stash.

**Radial Menu Options**
- enableradialmenu (boolean): Enables or disables the entire radial menu functionality.
- enableSeatsMenu (boolean): Toggles the seat-switching menu.
- enableExtraMenu (boolean): Toggles the vehicle extras menu.
- enableDoorsMenu (boolean): Toggles the vehicle doors menu.
- enableFlipVehicle (boolean): Toggles the option to flip overturned vehicles.
- enableTrunkOptions (boolean): Enables hiding and kidnapping options for the trunk.

**Targeting Options**
- enableTargets (boolean): Enables target-based interactions for trunk options and vehicle flipping.

**Timing and Speed Thresholds**
- flipVehicleTime (integer): Time in milliseconds required to flip a vehicle.
- allowedSeatSpeed (float): Maximum speed (km/h) at which seat switching is allowed.
- allowedTrunkSpeed (float): Maximum speed (km/h) at which jumping out of the trunk is allowed.

**Trunk Customization**
- customOffset (table): Specifies custom trunk offsets for vehicles that require adjustments.
- trunkDisabled (table): List of vehicle models where trunk interactions are disabled.
- classDisabled (table): Disables trunk interactions based on vehicle class.

**Visual Trunk Items**
- defaultTrunkItem (string): Specifies the default visual item displayed if no specific model is defined in trunkModels.
- trunkItems (table): Defines the positions for visual items inside the trunk. Customize leftOffset, backOffset, and heightOffset for placement.
- trunkModels (table): Specifies item models to display based on the stash item and thresholds. Priority is given to these models over the default.

Threshold determines which model is displayed based on the quantity in the vehicles stash.

# Statebags
- [Player] insideTrunk (boolean): Indicates if the player is inside a trunk.
- [Player] isKidnapped (boolean): Tracks if the player is kidnapped (e.g., being carried or escorted).

isKidnapped state does have backwards compatibility for **qb-kidnapping:client:SetKidnapping** but will be deprecated in the future.

# Work-in-Progress (WIP)
This resource is currently a Work-in-Progress, as functionalities may change frequently due to ongoing updates within the Qbox framework.

- QBX Police Job
The police job system is also still in development. It includes core functionalities like: Handcuffing, Carrying, Escorting. These features may be expanded with statebags to improve functionality for this script and others.

**Currently, we do not check whether the person placing someone in the trunk is escorting or carrying them or if they are handcuffed.**