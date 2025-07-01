#include "defines.hpp"

diag_log "ITW: Start";

ITW_PlayerFaction = [
  "CWR_B_US85_SquadLeader",
  "CWR_B_US85_TeamLeader",
  "CWR_B_US85_Rifleman",
  "CWR_B_US85_Grenadier",
  "CWR_B_US85_MachineGunner",
  "CWR_B_US85_Engineer",
  "CWR_B_US85_AT",
  "CWR_B_US85_AA",
  "CWR_B_US85_Marksman",
  "CWR_B_US85_Medic", 
  "US85_mcM16",
  "US85_mcM16GL",
  "US85_mcM136",
  "US85_mcM47"
];
ITW_EnemyFaction  = ["CWR_VDV", "CUP_O_SLA"];
ITW_CivFaction    = ["CIV_F"];
ITW_ParamNewGame  = 0;


LV_PAUSE = false;
if (hasInterface) then {cutText ["Choosing faction...", "BLACK OUT", 0.001];};

[false] call FactionSelection_CollectFactions;
    
// determine factions first thing
if (isServer) then {
    west setFriend [resistance,0];
    resistance setFriend [west,0];
    
    private _defFactionsP = profileNamespace getVariable [format["ITW_FactionsP%1",worldName],["BLU_F"]];
    private _defFactionsE = profileNamespace getVariable [format["ITW_FactionsE%1",worldName],["OPF_F"]];
    private _defFactionsC = profileNamespace getVariable [format["ITW_FactionsC%1",worldName],["CIV_F"]];
    
    private _loadGame = [true] call ITW_LoadGame;

    if (_loadGame && {ITW_ParamNewGame == 1}) then {
        private _client = if (hasInterface) then {2} else {0};
        if (_client == 0) then {
            private _players = [];
            while {count _players == 0} do {_players = (allPlayers - entities "HeadlessClient_F")};
            _client = _players#0;
        };
        ITW_NewGameFlag = nil;
        [] remoteExec ["ITW_NewGameConfirmation",_client];
        waitUntil {!isNil "ITW_NewGameFlag"};     
        if (ITW_NewGameFlag == 0) then {
            diag_log "ITW: User selected to keep saved game";
            ITW_ParamNewGame = 0;
        } else {
            diag_log "ITW: User selected to erase saved game";
            _loadGame = false;
        };
    };
    
    ITW_PlayerVehicles = [];
    ITW_EnemyVehicles = [];
    ITW_VehicleDlcs = profileNamespace getVariable [format["ITW_Dlcs%1",worldName],[]];
    if (_loadGame) then {        
        if ([[_defFactionsP,_defFactionsE,_defFactionsC]] call FactionCheck) then {
            diag_log "ITW: Loading saved game";
            ITW_PlayerFaction = _defFactionsP;
            ITW_EnemyFaction =  _defFactionsE;
            ITW_CivFaction =  _defFactionsC;
            ITW_EnemySide = if ([ITW_EnemyFaction] call FactionSide == east) then {east} else {independent};
            ESC_FactionMultiIsAll = false;
            
            if (ITW_ParamVehicles == 2) then {
                if (typeName ITW_VehicleDlcs == "SCALAR") then {
                    ([] call FactionDlcId) params ["_onlyDlcs","_removeDlcs"];
                    ITW_VehicleDlcs = [ITW_VehicleDlcs,_onlyDlcs] call DlcSelect;
                    profileNamespace setVariable [format["ITW_Dlcs%1",worldName],ITW_VehicleDlcs];
                };
                diag_log format ["ITW: Using dlcs %1",ITW_VehicleDlcs];
            };
            if (typeName ITW_VehicleDlcs == "SCALAR") then {ITW_VehicleDlcs = []};
            
            if (ITW_ParamVehicleChooser == 1 || {ITW_ParamVehicleChooser == 3}) then {
                ITW_EnemyVehicles  = profileNamespace getVariable [format["ITW_EnemyVehicles%1",worldName] ,[]];
                diag_log format ["ITW: enemy vehicles override, %1 vehicles",count (ITW_EnemyVehicles select {!(_x isEqualTo [])})];
            };
            if (ITW_ParamVehicleChooser == 2 || {ITW_ParamVehicleChooser == 3}) then {
                ITW_PlayerVehicles = profileNamespace getVariable [format["ITW_PlayerVehicles%1",worldName],[]]; 
                diag_log format ["ITW: player vehicles override, %1 vehicles",count (ITW_PlayerVehicles select {!(_x isEqualTo [])})];
            };  
        } else {
            _loadGame = false;
        };
    };
    if (!_loadGame) then {
        private _checkBoxes = profileNamespace getVariable [format["ITW_FactionsCkBox%1",worldName],[true,false,false]];
        _factionInfo = [_defFactionsP,_defFactionsE,objNull,_defFactionsC,true,_checkBoxes] call FactionSelect;
        
        profileNamespace setVariable [format["ITW_FactionsCkBox%1",worldName],call FactionGetCheckBoxStates];
        profileNamespace setVariable [format["ITW_FactionsP%1",worldName],_factionInfo#0];
        profileNamespace setVariable [format["ITW_FactionsE%1",worldName],_factionInfo#1];
        profileNamespace setVariable [format["ITW_FactionsC%1",worldName],_factionInfo#2];
        
        ESC_FactionMultiIsAll = _factionInfo#4;
        if (ESC_FactionMultiIsAll) then {
            ITW_PlayerFaction = _factionInfo#0;
            ITW_EnemyFaction  = _factionInfo#1;
            ITW_CivFaction    = _factionInfo#2;
        } else {
            ITW_PlayerFaction = selectRandom (_factionInfo#0);
            ITW_EnemyFaction  = selectRandom (_factionInfo#1);
            ITW_CivFaction    = _factionInfo#2; // we always want civ to use all the selected factions
        };
        ITW_EnemySide = if ([ITW_EnemyFaction] call FactionSide == east) then {east} else {independent};
        
        // If vehicles is 'Side/Map/DLC' and this is a not a BIS or CDLC, then choose the DLCs to use
        if (ITW_ParamVehicles == 2) then {
            ([] call FactionDlcId) params ["_onlyDlcs","_removeDlcs"];
            ITW_VehicleDlcs = [ITW_VehicleDlcs,_onlyDlcs] call DlcSelect;
            diag_log format ["ITW: Using dlcs %1",ITW_VehicleDlcs];
            profileNamespace setVariable [format["ITW_Dlcs%1",worldName],ITW_VehicleDlcs];
        } else {
            profileNamespace setVariable [format["ITW_Dlcs%1",worldName],nil];
        };
        profileNamespace setVariable [format["ITW_DlcsOpt%1",worldName],ITW_ParamVehicles];
    
        if (ITW_ParamVehicleChooser == 1 || {ITW_ParamVehicleChooser == 3}) then {
            ITW_EnemyVehicles = [true,"Choose ENEMY vehicles"] call VehicleChooser;
            diag_log format ["ITW: enemy vehicles override, %1 vehicles",count (ITW_EnemyVehicles select {!(_x isEqualTo [])})];
        };
        if (ITW_ParamVehicleChooser == 2 || {ITW_ParamVehicleChooser == 3}) then {
            ITW_PlayerVehicles = [true,"Choose PLAYER vehicles"] call VehicleChooser;
            diag_log format ["ITW: player vehicles override, %1 vehicles",count (ITW_PlayerVehicles select {!(_x isEqualTo [])})];
        }; 
        profileNamespace setVariable [format["ITW_EnemyVehicles%1",worldName],ITW_EnemyVehicles];
        profileNamespace setVariable [format["ITW_PlayerVehicles%1",worldName],ITW_PlayerVehicles];  
    };
        
    publicVariable "ESC_FactionMultiIsAll";
    publicVariable "ITW_EnemySide";
    publicVariable "ITW_PlayerFaction";
    publicVariable "ITW_EnemyFaction";
    publicVariable "ITW_CivFaction";
    publicVariable "ITW_VehicleDlcs";
    publicVariable "ITW_EnemyVehicles";
    publicVariable "ITW_PlayerVehicles";
} else {
    waitUntil {!isNil "ITW_EnemySide"};
    waitUntil {!isNil "ITW_PlayerFaction"};
    waitUntil {!isNil "ITW_EnemyFaction"};
    waitUntil {!isNil "ITW_CivFaction"};
    waitUntil {!isNil "ITW_EnemyVehicles"};
    waitUntil {!isNil "ITW_PlayerVehicles"};
};
ITW_PlayerSide = west;

ITW_AIEnemyName = [ITW_EnemyFaction] call FactionName;
diag_log format ["ITW: Factions: player %1  enemy %2 (%3)  civ %4",
    ITW_PlayerFaction,ITW_EnemyFaction,ITW_EnemySide,if (ITW_ParamCivilians==0) then [{"none"},{ITW_CivFaction}]];
    
ITW_AllyUnitTypes = [ITW_PlayerFaction,["SpecialOperative","Crewman"],true,call FACTION_UNIT_FALLBACK_SUBF_BLU] call FactionUnits;

call CustomArsenal_Init;

[ITW_ParamVirtualArsenal] call CustomArsenal_Setup;

if (hasInterface) then {
    // --- PLAYERS ---    
    profileNamespace getVariable [format["ITW_Roles%1",worldName],[0,1]] call ITW_BaseResetRoles;

    if (ITW_ParamFriendlyRevive == -1) then {bis_revive_bleedOutDuration = 0.1};
    
    enableTeamSwitch false;
    enableSentences true;  
    
    // if hosting, we need to spawn this stuff, so the server stuff can be setup
    [] spawn { 
        
        sleep 2;       
        
        waitUntil{! isNil "VEHICLE_ARRAYS_COMPLETE"};
        waitUntil{! isNil "ITW_GameReady"};
        sleep 1;
        
        // if nighttime, don NVGs
        if (call ITW_FncIsNight) then {
            private _nvgs = [player] call ITW_FncGetNVGs;
            if (_nvgs isEqualTo []) then {
                if (ITW_ParamForceNVGs) then {
                    player linkItem "NVGoggles";
                };
            } else {
                player assignItem (_nvgs#0);
            };
        };
        
        player enableAI "MOVE";
        player switchMove "";
        ([] call ITW_ObjGetPlayerSpawnPtDir) params ["_spawnPos","_spawnDir"];
        player setPosATL _spawnPos;
        player setDir _spawnDir;
        
        if (isNil "ITW_PlayersSpawnedIn") then {
            ITW_PlayersSpawnedIn = true;
            publicVariable "ITW_PlayersSpawnedIn";
        };
        
        cutText [format ["Enemy Faction: %1",ITW_AIEnemyName],"BLACK IN",5];
        
        call ITW_RadioInit;
        0 spawn ITW_ObjFlagHud;
        0 spawn ITW_ObjRedOut;
    
        execVM "briefing.sqf"; // call after player moved to AO
        
        // zoom the map to the AO and disable textures by default first time map is opened
        addMissionEventHandler [ "Map",
            {	
                params ["_isOpened","_isForced"];
                if (_isOpened) then {
                    if (isNil "ITW_MAP_OPENED") then {
                        ctrlActivate ((findDisplay 12) displayCtrl 107); // Auto activate the textures button
                        ITW_MAP_OPENED = true;
                    };
                    private _objs = [] call ITW_ObjGetContestedObjs;
                    if (_objs isEqualTo []) exitWith {};
                    if (count _objs == 1) then {_objs = _objs + [ITW_Objectives#0]};
                    private _ptX = 0;
                    private _ptY = 0;
                    private _ptCnt = 0;
                    private _minX = 1e10;
                    private _minY = 1e10;
                    private _maxX = -1e10;
                    private _maxY = -1e10;           
                    {
                        private _pt = _x#ITW_OBJ_POS;
                        private _i = _pt#0;
                        private _j = _pt#1;
                        _ptX = _ptX + _i;
                        _ptY = _ptY + _j; 
                        _ptCnt = _ptCnt + 1;
                        if (_i < _minX) then {_minX = _i};
                        if (_j < _minY) then {_minY = _i};
                        if (_i > _maxX) then {_maxX = _i};
                        if (_j > _maxY) then {_maxY = _i};
                    } forEach _objs;
                    _ptX = _ptX / _ptCnt;
                    _ptY = _ptY / _ptCnt;
                    private _verticalSizeInMeters = 2 * ((_maxY - _minY) max (_maxX - _minX));
                    private _scale = 1.8 * _verticalSizeInMeters / worldsize;
                    mapAnimAdd [0,_scale,[_ptX,_ptY]]; 
                    mapAnimCommit;
                    removeMissionEventHandler ["Map",_thisEventHandler];
                };
            }
        ];
        
        private _addPlayerActions = {
            private _actionNames = actionIDs player apply {(player actionParams _x) #0};
            if !("Eject" in _actionNames) then {
                player addAction ["Eject",{moveOut player},nil,100,false,true,"",
                "vehicle _this == _target && {vehicle _this != _this && {getPosATL _this #2 > 50 && {getPosASL _this #2 > 50 && {incapacitatedState _this == ''}}}}",-1];
            };
            if !("Fast travel in vehicle" in _actionNames) then {
                // add vehicle fast travel from repair points
                player addAction ["Fast travel in vehicle",{
                    params ["_target", "_caller", "_actionId", "_arguments"];
                    [] spawn ITW_RadioFastTravel;
                },nil,10,false,true,"","_this != _target && {!(_target isKindOf 'Air') && {speed _target < 2 && {
                    !isNil 'ITW_VehFTPoints' && {!([] isEqualTo (ITW_VehFTPoints select {_x distance _this < 15})) || { 
                    !isNil 'ITW_VehRepairArray' && {!([] isEqualTo (ITW_VehRepairArray select {(_x#0) distance _this < (_x#1)} select {(_x#3) call (_x#2)} )) }}}}}}",0];
            };
        };
        call _addPlayerActions;
        player addEventHandler ["Respawn", _addPlayerActions];         
        [ missionNamespace, "reviveRevived",_addPlayerActions] call BIS_fnc_addScriptedEventHandler;
        
        player addEventHandler ["GetOutMan", {
            params ["_unit", "_role", "_vehicle", "_turret", "_isEject"];
            if (!local _unit || {vehicle _unit == _vehicle || {!alive _unit}}) exitWith {};
            private _pos = getPosATL _unit;
            if (surfaceIsWater _pos) then {_pos = getPosASL _unit};
            if (_pos #2 > 50) then {  
                (_pos) spawn {
                    private _pos = _this;
                    if (_pos#2 > 70) then {
                        waitUntil {(getPos player) #2 < 50}; // getPos to handle land or sea 
                    };             
                    [player] call BIS_fnc_halo; 
                };
                
                // if last player ejected, then teammates should eject too
                private _crew = crew _vehicle;
                private _teammatesInCrew = ITW_AI_UNITS select {vehicle _x == _vehicle};
                if !(_teammatesInCrew isEqualTo []) then {
                    private _remainingPlayersInCrew = playableUnits select {vehicle _x == _vehicle};
                    if (_remainingPlayersInCrew isEqualTo []) then {
                        private _groups = ITW_AI_UNITS apply {group _x};
                        _groups = _groups arrayIntersect _groups;
                        [_vehicle,grpNull,_groups,[]] spawn ITW_AtkUnloadAirplane;
                    };
                };
            };
        }];
        
        ITW_ArsenalCheck = {
            params ["_display"];
            private _okay = true;
            private _flag = nearestObject [getPos player,FLAG_TYPE];
            if (!isNull _flag) then {
                if (_flag distance player < 10 && 
                {!(_flag getVariable ["ITW_FlagIsPlayer",true]) ||
                {_flag getVariable ["ITW_FlagPhase",1] < 1}}) then {_okay = false};
            };
            if (!_okay) then {
                hint "Flag is not captured, arsenal blocked";
                _display closeDisplay 0;
            };
        };
        
        if (!isNil "CBA_fnc_addEventHandler" && {!isNil "ace_arsenal_fnc_removeVirtualItems"}) then {
            ["ace_arsenal_displayClosed", {player setDamage 0;player call ITW_FncAceHeal;call ITW_TeammatesHeal; 
                    [] call ITW_TeammateArsenalExit;}] call CBA_fnc_addEventHandler;
            ["ace_arsenal_displayOpened", { [] spawn {sleep 0.5; [findDisplay 1127001] call ITW_ArsenalCheck}}] call CBA_fnc_addEventHandler;
        }; 
        [missionNamespace, "arsenalOpened", {
            [uiNamespace getVariable 'RscDisplayArsenal'] call ITW_ArsenalCheck;
        }] call BIS_fnc_addScriptedEventHandler;         	
           
        [missionNamespace, "arsenalClosed", {
            private _restocked = "";
            private _healed = "";
            [] call ITW_TeammateArsenalExit;
            
            // add full heal on entering arsenal
            if (damage player > 0.1) then {
                _healed = "You've been healed";
            };
            player setDamage 0;
            player call ITW_FncAceHeal;
            call ITW_TeammatesHeal;
            
            // if leader restocked, then restock AI teammates
            if (leader player == player) then {
                {
                    private _unit = _x;
                    if (!isPlayer _unit) then {
                        private _loadout = _unit getVariable ["ITW_loadout",[]];
                        if !(_loadout isEqualTo []) then {
                            _unit setUnitLoadout _loadout;
                            _restocked = "AI teammates restocked";
                        };
                    };
                } forEach units player;
            };
            
            // notifications
            if !(_restocked isEqualTo "" && {_healed isEqualTo ""}) then {
                [format ["\n\n\n\n%1\n%2",_healed,_restocked],!(_healed isEqualTo "")] spawn {
                    params ["_msg","_flashWhite"];
                    if (_flashWhite) then {
                        cutText ["","WHITE OUT",0.3]; 
                        sleep 0.3;
                        cutText ["","WHITE IN",0.3];
                    };
                    "arsenalClosed" cutText [_msg,"PLAIN"];
                    sleep 4;
                    "arsenalClosed" cutText ["","PLAIN"];
                };
            };
        }] call BIS_fnc_addScriptedEventHandler;         	
        
        addMissionEventHandler ["CommandModeChanged", { 
            params ["_isHighCommand", "_isForced"]; 
            if (_isHighCommand && {!(player in ITW_HcCmdr)}) exitWith {hcShowBar false}; // if not high commander, don't allow entering high command
            setGroupIconsVisible [_isHighCommand,false]; // only show icons on map while in high command
        }];
        
        [missionNamespace, "garageClosed", 
            {
                if (!local BIS_fnc_garage_center) exitWith {diag_log "Error pos: garageClosed EH called on non local machine"};        
                private _veh = BIS_fnc_garage_center;
                private _pos = getPosATL _veh;
                _pos set [2,_pos#2 + 0.2];
                private _dir = [vectorDir _veh, vectorUp _veh];
                
                // save crew we want in vehicle
                _crew = [];
                {
                	_x params ["_unit","_role","_cargoIndex","_turretPath"];
                    _role = toLowerANSI _role;
                	_role = switch (_role) do {
                		case "driver": {[_role,0];};
                		case "cargo": {[_role,_cargoIndex];};
                		case "gunner";
                		case "commander";
                		case "turret": {[_role,_turretPath];};
                		default {[]};
                	};
                	_crew pushback _role;
                    deleteVehicleCrew _unit; // remove the virtual unit
                } foreach (fullcrew _veh);              
                deleteVehicleCrew _veh;  
                private _init = [_veh,""] call BIS_fnc_exportVehicle; // needs an empty crew
                private _type = typeOf _veh; 
                deleteVehicle _veh;
                if !(ITW_GARAGE_CANCEL) then {
                    [_type,_pos,_dir,_init,_crew] spawn {
                        params ["_type","_pos","_dir","_init","_crew"];
                        sleep 0.5;  
                        private _veh = objNull;
                        if (_type isKindOf "Ship") then {
                            _pos = call ITW_BaseShipSpawnPt; 
                            if !(_pos isEqualTo []) then {
                                _veh = [_type,_pos,_dir,1,false] call ITW_VehSpawn;
                                private _mrkr = createMarkerLocal ["ship"+(str time),_pos];
                                _mrkr setMarkerTypeLocal "loc_boat";
                                _mrkr setMarkerColorLocal "colorBLUFOR";
                                _mrkr setMarkerAlpha 1;
                                _veh setVariable ["ShipMarker",_mrkr];
                                
                                _veh addEventHandler ["GetIn", {
                                    params ["_vehicle", "_role", "_unit", "_turret"];
                                    private _mrkr = _vehicle getVariable ["ShipMarker",""];
                                    deleteMarker _mrkr;
                                    _vehicle removeEventHandler [_thisEvent,_thisEventHandler]
                                    }];
                            };
                        } else {         
                            _veh = [_type,_pos,_dir,1,false] call ITW_VehSpawn;
                        };
                        if (!isNull _veh) then {
                            _veh call compile _init;
                            // now add teammates to crew positions
                            private _driver = objNull;
                            {                             
                                _x params ["_role","_index"];
                                private _aiCnt = {!isPlayer _x && {alive _x}} count units group player;
                                if (_aiCnt >= ITW_ParamFriendlySquadSize) exitWith {cutText ["CREW LIMITED: Max squad size reached.","PLAIN",1]};
                                private _units = units group player;
                                [player] remoteExec ["ITW_AllyRecruit",2];
                                waitUntil {sleep 0.1;count units group player > count _units};
                                sleep 1; // short sleep (0.2) had units hopping back out of vehicle
                                private _unit = (units group player - _units)#0;
                                private _timeout = time + 2.6;
                                switch (_role) do {
                                    case "driver":   {[_unit,_veh]          remoteExec ["moveInDriver",_unit]}; 
                                    case "cargo":    {[_unit,[_veh,_index]] remoteExec ["moveInCargo" ,_unit]};
                                    case "gunner";    
                                    case "commander"; 
                                    case "turret":   {[_unit,[_veh,_index]] remoteExec ["moveInTurret",_unit]};
                                    default {[]};
                                };
                            } forEach _crew;
                            if (!isNull _driver) then {sleep 2; doStop _driver};
                        };
                    };
                };
            }] call BIS_fnc_addScriptedEventHandler;
            
            
        // hide the uss liberty that the player initially spawned on (only hides locally)
        {
            if (_x isKindOf "Land_Destroyer_01_hull_base_F") then {_x hideObject true};
        } forEach (DESTROYER nearObjects 100);
        
        // Changes to work with various mods
        // HCC (High Command Changer)
        if (!isNil "IGIT_HCC_HC_Groups_Array") then {IGIT_HCC_HC_Groups_Array = []}; // hack for HCC (High Command Converter)
        // UVO (Unit Voice Overs)
        if (!isNil "uvo_main_customVoices") then {
            private _faction = if (typeName ITW_PlayerFaction isEqualTo "STRING") then {ITW_PlayerFaction} else {ITW_PlayerFaction#0};
            private _index = uvo_main_customVoices findIf {_x # 0 == _faction};

            if (_index != -1) then {
                private _voices = (uvo_main_customVoices # _index # 1) select {missionNamespace getVariable ["uvo_main_UVO" + _x,true]};

                if !(_voices isEqualTo []) then {
                    _voices spawn {
                        scriptName "UvoAdjuster";
                        private _voices = _this;
                        private _adjustedPlayers = [];
                        while {true} do {
                            private _allPlayers = allPlayers;
                            {                          
                                private _unit = _x;
                                _voice = selectRandom _voices;
                                _unit setVariable ["UVO_voice",_voice,true];
                                _unit setVariable ["UVO_suppressBuffer",0,true];
                                _unit setVariable ["UVO_allowDeathShouts",missionNamespace getVariable ["uvo_main_UVO" + _voice,true],true];
                                _adjustedPlayers = _allPlayers;
                            } forEach (_allPlayers - _adjustedPlayers);
                            sleep 30;
                        };
                    };
                };
            };
        };
    
        // if player is squad leader, add saved teammates to team (multiple saved teams get lost)
        if (leader player == player) then {[player] remoteExec ["ITW_TeammatesLoad",2]};
    };
};

if (hasInterface) then {cutText ["Parsing vehicles...", "BLACK OUT", 0.001];};
[ITW_EnemyFaction,ITW_PlayerFaction] execVM "VehicleArrays.sqf";

if (ITW_ParamViewDistance > 0) then {setViewDistance ITW_ParamViewDistance; setObjectViewDistance (ITW_ParamViewDistance/2)};

call ITW_TeammatesInit; // needs to be called on all clients & server

if (isServer) then {
    // --- SERVER ---
    // spawn so the player on the server gets black screen
        
    [] spawn {
        private _timeSpeedDay = ITW_ParamTimeMultiplier;
        [ITW_ParamTimeOfDay,_timeSpeedDay/2,_timeSpeedDay] call ITW_FncSetTime;
        [ITW_ParamWeather] call ITW_FncSetWeather;
                
        call ITW_VehiclesInit;
        
        if !(call ITW_LoadGame) then {
            false call ITW_ObjectivesSetup;
        };  
        call ITW_EnemyInit;   
        call ITW_AllyInit;
        0 spawn ITW_FncCleanup;
        
        { _x addCuratorEditableObjects [allPlayers,true]; } forEach allCurators;
                
        if (!hasInterface) then {call ITW_RadioInit};
        ITW_GameReady = true; // indicates enemy/friendly/objectives are setup and ready to play
        publicVariable "ITW_GameReady";
        
        [{LV_PAUSE = true},{LV_PAUSE = false},true] execVM "scripts\skull\SKL_Pause.sqf";
        
        diag_log "ITW: Game started";
        0 call ITW_SaveGame; 
        
        if (isDedicated) then {
            addMissionEventHandler ["PlayerDisconnected", { 
                [] spawn {
                    sleep 1; // BIS_fnc_listPlayers still shows the disconnecting player for a bit
                    if ([] call BIS_fnc_listPlayers isEqualTo []) then {
                        diag_log "ITW: Game paused with no players in game";
                        LV_Pause = true;
                        private _damageAbleUnits = [];
                        private _simulatedUnits = [];
                        {
                            if (simulationEnabled _x) then {
                                _simulatedUnits pushBack _x;
                                _x enableSimulation false;
                            };
                            if (isDamageAllowed _x) then {
                                _damageAbleUnits pushBack _x;
                                _x allowDamage false;
                            };
                        } forEach (allUnits + vehicles);
                        
                        while {[] call BIS_fnc_listPlayers isEqualTo []} do {sleep 1};
                                            
                        {_x enableSimulation true} forEach _simulatedUnits;
                        {_x allowDamage true} forEach _damageAbleUnits;
                        LV_Pause = false;
                        diag_log "ITW: Game resumed with some players in game";
                    };
                };
            }];
        };
    };
};