//
// Save data: [
//    ITW_Objectives  :  [playerDefendIndex, [pt1,pt2,...]
// ]

#include "defines.hpp"

ITW_SaveSem = false;

ITW_NewGameConfirmation = {
    diag_log "ITW: Checking if save game should be erased and new game crated";
    player enableSimulation false;
    ITW_NewGameFlag = nil;
    
    // ** Keypress Method **
    #define DIK_KEY_Y 21
    #define DIK_KEY_N 49    
    waitUntil {! isNull findDisplay 46 && player == player};
    cutText ["<t size='5'>ERASE SAVED GAME?</t><br/><t size='3'>Press  Y  for yes, to erase saved game<br/>Press  N  for no, to keep saved game</t>", "BLACK", 0.001,true,true];
    findDisplay 46 displayAddEventHandler ["KeyDown", 
    'params ["_displayOrControl", "_key", "_shift", "_ctrl", "_alt"];
    if (_key == DIK_KEY_Y || _key == DIK_KEY_N) then {
        if (_key == DIK_KEY_Y) then {
            ITW_NewGameFlag = 1;
        } else {
            ITW_NewGameFlag = 0;
        };
        findDisplay 46 displayRemoveEventHandler ["KeyDown",_thisEventHandler];
    };
    true'];
    waitUntil {!isNil "ITW_NewGameFlag"};
    
    // ** Commanding Menu Method **
    //ITW_CONFIRM_MENU = [
    //    ["Create New Game", false],
    //    ["NO, use saved game",   [2], "", -5, [["expression", "ITW_ParamNewGame=0"]], "1", "1"],
    //    ["Yes, ERASE SAVED GAME",[3], "", -5, [["expression", "ITW_ParamNewGame=1"]], "1", "1"]];
    //showCommandingMenu "#USER:ITW_CONFIRM_MENU";
    //sleep 1;
    //waitUntil {!isNil "ITW_ParamNewGame" || commandingMenu == ""};
    //if (isNil "ITW_ParamNewGame") then {ITW_ParamNewGame = 0};
    
    player enableSimulation true;
    publicVariable "ITW_NewGameFlag";
    cutText ["Choosing faction...", "BLACK", 0.001];
};

ITW_LoadGame = {
    if (!isServer) exitWith {diag_log "Error pos ITW_LoadGame called from client"};
    params [["_preLoad",false]];
    // returns TRUE if game was retrieved

    private _dataObj   = profileNamespace getVariable [format["ITW_SaveObj%1",worldName],[]];
    if (count _dataObj   != 4) exitWith {false};
    
    private _airfield  = profileNamespace getVariable [format["ITW_Airfield%1",worldName],[]];
    private _teammates = profileNamespace getVariable [format["ITW_Teammates%1",worldName],[]];
    ITW_StoredVehicles = profileNamespace getVariable [format["ITW_StoVeh%1",worldName],[]];
    
    // arrays must be copied so they don't get back-updated when we aren't ready
    private _zoneIndex = _dataObj#0;
    private _objectives = +(_dataObj#1);
    private _bases = +(_dataObj#2);
    private _captured = +(_dataObj#3);
    
    if (isNil "_zoneIndex" || isNil "_objectives" || isNil "_bases") exitWith {false};
    if (count _objectives < 3 || {count _objectives != count _bases}) exitWith {false};
    // check valid version
    if (count (_objectives#1) != ITW_OBJ_ARRAY_SIZE) exitWith {false};
    
    // backward compatibility
    {
        while {count (_x#ITW_OBJ_ATTACKS) < 6} do {
            _x#ITW_OBJ_ATTACKS pushBack -1;
        };
        while {count (_x#ITW_OBJ_LAND_ATK) < 4} do {
            _x#ITW_OBJ_LAND_ATK pushBack false;
        };
    } forEach _objectives;
    
    if (_preLoad) exitWith {true};
    if (ITW_ParamNewGame == 1) exitWith {false};
    
    [["Loading saved game...", "BLACK OUT", 0.001]] remoteExec ["cutText",0];
    diag_log "ITW: game loading";
    
    if (true) then {
        diag_log ["ZoneIndex",_zoneIndex];
        diag_log ["Objectives",count (_objectives)];
        diag_log ["Airfield",!(_airfield isEqualTo [])];
        diag_log ["Teammates",count _airfield];
    };
    
    private _date      = profileNamespace getVariable [format["ITW_Time%1",worldName],[]];
    
    if (count _date == 5) then {[_date] remoteExec ["setDate",0]};
    
    [_bases]                 call ITW_BaseLoad; // must be done prior to ITW_ObjLoad
    [_objectives,_zoneIndex,_captured] call ITW_ObjLoad;
    [_airfield]              call ITW_AirfieldLoad;
    [_teammates]             call ITW_TeammatesLoad;
    
    // enable auto save feature
    if (isNil "ITW_AutoSaveRunning") then {
        ITW_AutoSaveTime = time + 600; // auto save in 10 minutes
        [] spawn ITW_SaveAutoTask;
    };
    
    [] remoteExec ["ITW_LoadGameMP",0,true];
    true
};

ITW_SaveGame = {
    if (!isServer) exitWith {[] remoteExec ["ITW_SaveGame",2]};
    SEM_LOCK(ITW_SaveSem);
    
    diag_log "ITW: game saved";   
    
    // enable auto save feature
    if (isNil "ITW_AutoSaveRunning") then {
        [] spawn ITW_SaveAutoTask;
    };
    ITW_AutoSaveTime = time + 600; // auto save every 10 minutes
    
    private _airfield = call ITW_AirfieldSave;
    private _teammates = call ITW_TeammatesSave;
    
    private _objData = [ITW_ZoneIndex, +ITW_Objectives, +ITW_Bases, +ITW_ObjContestedState];
    profileNamespace setVariable [format["ITW_SaveObj%1",worldName],_objData];
    profileNamespace setVariable [format["ITW_Airfield%1",worldName],_airfield];
    profileNamespace setVariable [format["ITW_Teammates%1",worldName],_teammates];
    profileNamespace setVariable [format["ITW_StoVeh%1",worldName],ITW_StoredVehicles];
    profileNamespace setVariable [format["ITW_Time%1",worldName],date];
    
    // save a few adjustable parameters in case they were adjusted
    profileNamespace setVariable ["ITW_ParamFriendlyAiCntAdjustment",ITW_ParamFriendlyAiCntAdjustment];
    profileNamespace setVariable ["ITW_ParamVehicleSideAdjustment"  ,ITW_ParamVehicleSideAdjustment*10];
    SEM_UNLOCK(ITW_SaveSem);
    
    [] remoteExec ["ITW_SaveGameMP",0];
};

ITW_LoadGameMP = {
    // call on each client
    if (!hasInterface) exitWith {};
    SEM_LOCK(ITW_SaveSem);
    private _loadoutInfo = profileNamespace getVariable [format["ITW_Loadout%1",worldName],[]];
    if !(_loadoutInfo isEqualTo []) then {
        _loadoutInfo params ["_faction","_loadout"];
        if (ITW_PlayerFaction isEqualTo _faction) then {player setUnitLoadout _loadout};
    };
    SEM_UNLOCK(ITW_SaveSem);
};

ITW_SaveGameMP = {
    // call on each client
    if (!hasInterface) exitWith {};
    profileNamespace setVariable [format["ITW_Loadout%1",worldName],[ITW_PlayerFaction,getUnitLoadout player]];
};

ITW_EraseGame = {
    if (!isServer) exitWith {_this remoteExec ["ITW_EraseGame",2]};
    diag_log "ITW: game erased";
    ITW_AutoSaveTime = 1e10;
    profileNamespace setVariable [format["ITW_SaveObj%1",worldName],nil];
    profileNamespace setVariable [format["ITW_Airfield%1",worldName],nil];
    profileNamespace setVariable [format["ITW_Teammates%1",worldName],nil];
    profileNamespace setVariable [format["ITW_StoVeh%1",worldName],nil];
    profileNamespace setVariable [format["ITW_Time%1",worldName],nil];
    [] remoteExec ["ITW_EraseGameMP",0];
};

ITW_EraseGameMP = {
    profileNamespace setVariable [format["ITW_Roles%1",worldName],nil];
    profileNamespace setVariable [format["ITW_Loadout%1",worldName],nil];
};

ITW_SaveAutoTask = {
    scriptName "ITW_SaveAutoTask";
    if (!isServer) exitWith {diag_log "Error pos ITW_SaveAutoTask called from client"};
    ITW_AutoSaveRunning = true;
    waitUntil {!isNil "ITW_AutoSaveTime"};
    while {!ITW_GameOver} do {
        waitUntil {sleep (1 + ITW_AutoSaveTime - time); time >= ITW_AutoSaveTime};
        while {LV_PAUSE} do {sleep 5};
        ["autoSave"] call ITW_SaveGame;
    };    
};

["ITW_NewGameConfirmation"] call SKL_fnc_CompileFinal;
["ITW_LoadGame"] call SKL_fnc_CompileFinal;
["ITW_SaveGame"] call SKL_fnc_CompileFinal;
["ITW_EraseGame"] call SKL_fnc_CompileFinal;
["ITW_SaveAutoTask"] call SKL_fnc_CompileFinal;
["ITW_LoadGameMP"] call SKL_fnc_CompileFinal;
["ITW_SaveGameMP"] call SKL_fnc_CompileFinal;
["ITW_EraseGameMP"] call SKL_fnc_CompileFinal;
