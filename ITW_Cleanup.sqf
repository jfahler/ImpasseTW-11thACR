/*
    ITW_Cleanup.sqf - Deletes futuristic and modern objects not suitable for Cold War setting.
*/

private _cleanupClasses = [
    "Land_spp_Tower_F",         // Solar tower
    "Land_spp_Mirror_F",        // Solar panel
    "Land_Radar_F",             // NATO radar tower
    "Land_Radar_Small_F",       // Small radar
    "Land_Dome_Big_F",          // Futuristic dome
    "Land_Research_HQ_F",       // NATO command center
    "Land_Research_house_V1_F", // Research facility
    "Land_wpp_Turbine_V1_F",    // Wind turbine
    "Land_Cargo_Tower_V1_F",    // Tall cargo tower
    "Land_dp_smallFactory_F",   // Futuristic factory
    "Land_Cargo_Patrol_V1_F",   // Modern watchtower
    "Land_HBarrierBig_F"        // Optional: HESCOs (replace with sandbags manually)
];

{
    private _toDelete = nearestObjects [position player, [_x], 50000];  // radius covers most of map
    { deleteVehicle _x } forEach _toDelete;
} forEach _cleanupClasses;

hint "Cold War cleanup complete.";
