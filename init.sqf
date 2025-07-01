diag_log "ITW: init start";

if (!isDedicated) then { waitUntil { player == player }; };
if ((!isServer) && (player != player)) then { waitUntil { player == player }; };
waitUntil { !isNil "ITW_PreInitComplete" }; // wait for the server to catch up

// Run cleanup script on server only
if (isServer) then {
    [] execVM "ITW_Cleanup.sqf";
};

execVM "params.sqf";

if (!isServer && !hasInterface) exitWith {}; // headless clients don't need to proceed any further

waitUntil { !isNil "ITW_Params_complete" };
waitUntil { !isNil "ITW_ParamRadioVolume" };
0 fadeRadio ITW_ParamRadioVolume / 10;

waitUntil { !isNil "ITW_ParamStamina" };
if (hasInterface && { ITW_ParamStamina < 2 }) then {
    player enableStamina (ITW_ParamStamina == 1);
};

execVM "scripts\SKULL\SKL_RatingMinimum.sqf"; // Reset player rating if it gets too low

waitUntil { !isNil "ITW_ParamHeadlessClient" };
HeadlessClients = []; 
if (isServer && ITW_ParamHeadlessClient == 1) then {
    execVM "scripts\SKULL\SKL_HeadlessClient.sqf";
};

// Change arsenal camera
if (isNil "BIS_fnc_arsenal_campos_0") then {
    BIS_fnc_arsenal_campos_0 = [4,159,16.6,[0,0,0.85]];
};

[] execVM "ITW_Start.sqf";

diag_lo_