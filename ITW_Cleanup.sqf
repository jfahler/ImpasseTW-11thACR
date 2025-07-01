/*
    ITW_Cleanup.sqf - Full map deletion of futuristic/modern objects.
*/

private _cleanupClasses = [
    "Land_spp_Tower_F",
    "Land_spp_Mirror_F",
    "Land_Radar_F",
    "Land_Radar_Small_F",
    "Land_Dome_Big_F",
    "Land_Research_HQ_F",
    "Land_Research_house_V1_F",
    "Land_wpp_Turbine_V1_F",
    "Land_Cargo_Tower_V1_F",
    "Land_dp_smallFactory_F",
    "Land_Cargo_Patrol_V1_F",
    "Land_HBarrierBig_F"
];

{
    {
        deleteVehicle _x;
    } forEach (allMissionObjects _x);
} forEach _cleanupClasses;

hint "Cold War cleanup complete.";
