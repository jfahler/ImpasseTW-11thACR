/*
    ITW Cold War Init
    Runs cleanup and initializes all core scripts safely.
*/

diag_log "ITW: init start";

// Wait for player identity to exist on clients
if (!isDedicated) then { waitUntil { !isNull player && player == player }; };
if ((!isServer) && (player != player)) then { waitUntil { player == player }; };

// Wait for pre-init to finish
waitUntil { !isNil "ITW_PreInitComplete" };

// Run mission params setup
execVM "params.sqf";

// Stop headless clients here
if (!isServer && !hasInterface) exitWith {};

// Wait for core mission params to initialize
waitUntil { !isNil "ITW_Params_complete" };
waitUntil { !isNil "ITW_ParamRadioVolume" };
waitUntil { !isNil "ITW_ParamStamina" };

// Adjust radio volume on clients
if (hasInterface) then {
    0 fadeRadio (ITW_ParamRadioVolume / 10);
    if (ITW_ParamStamina < 2) then {
        player enableStamina (ITW_ParamStamina == 1);
    };
};

// Reset player rating if needed
execVM "scripts\SKULL\SKL_RatingMinimum.sqf";

// Setup headless client handler if enabled
waitUntil { !isNil "ITW_ParamHeadlessClient" };
if (isServer && ITW_ParamHeadlessClient == 1) then {
    HeadlessClients = [];
    execVM "scripts\SKULL\SKL_HeadlessClient.sqf";
};

// Deprecated in favor of slaving away in 3den - bullet magnet
// Run cold war cleanup on server only
// if (isServer) then {
//     [] execVM "ITW_Cleanup.sqf";
// };

// Improve arsenal view
if (isNil "BIS_fnc_arsenal_campos_0") then {
    BIS_fnc_arsenal_campos_0 = [4,159,16.6,[0,0,0.85]];
};

// Start the main ITW script
[] execVM "ITW_Start.sqf";

diag_log "ITW: init complete";
