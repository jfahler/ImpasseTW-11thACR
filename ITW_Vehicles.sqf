
ITW_VehiclesInit = {
    if (! isServer) exitWith {diag_log "Error pos ITW_VehiclesInit: called from client"};
    waitUntil {! isNil "VEHICLE_ARRAYS_COMPLETE"};
    0 spawn ITW_VehManager
};

ITW_PlayerVehiclesList = [];

// move vehicles to simulated state if no one is around, respawn as needed, etc
ITW_VehManager = {
    scriptName "ITW_VehManager";
    while {isNil "ITW_PlayersSpawnedIn"} do {sleep 10};
    while {true} do {
        while {LV_PAUSE} do {sleep 5};
        sleep 30;
        private _removeList = [];
        private _vehList = +ITW_PlayerVehiclesList; // make copy in case items are added while iterating
        {
            _x params ["_veh", "_vehType", "_vehSpawnPt", "_vehSpawnDir", "_vehSpawnCnt", "_vehSpawnTime"];
            
            // Handle disabling simulation if players aren't around the vehicle
            if (simulationEnabled _veh && {alive _veh && {isDamageAllowed _veh && {isTouchingGround _veh}}}) then {
                private _disableSim = {alive _x} count crew _veh == 0;
                if (_disableSim) then {
                    {
                        if (alive _x && _veh distanceSqr _x < 90000) exitWith {_disableSim = false}; // 300 squared = 90000
                    } forEach call BIS_fnc_listPlayers;
                };
                if (_disableSim) then {_veh enableSimulationGlobal false};
            };
            
            
            // Handle dead vehicles
            if (!alive _veh) then {
                private _remove = true;
                {
                    if (alive _x && _veh distance _x < 2500) exitWith {_remove = false};
                } forEach call BIS_fnc_listPlayers;
                if (_remove) then {_removeList pushBack _veh};
            };
            
            // Handle respawn if vehicle leaves base
            if (!isNil "_vehType" && isNil "TEST") then {
                private _dist = getPosATL _veh distance _vehSpawnPt;
                if (((!canMove _veh || {fuel _veh == 0}) && {{vehicle _x == _veh} count allPlayers == 0}) || 
                   {_dist > 150} ) then {
                    if (_dist < 20) then {deleteVehicle _veh};
                    // remove previous entry and add new one without respawn info
                    _removeList pushBack _veh;
                    if (alive _veh) then {ITW_PlayerVehiclesList pushBack [_veh]};
                    if (time - 45 > _vehSpawnTime) then {_vehSpawnCnt = 0} else {_vehSpawnCnt = _vehSpawnCnt + 1};
                    [_vehType,_vehSpawnPt,_vehSpawnDir,_vehSpawnCnt,true] call ITW_VehSpawn;
                };
            };            
        } forEach _vehList;
        
        if !(_removeList isEqualTo []) then {
            ITW_PlayerVehiclesList = ITW_PlayerVehiclesList select {!(_x#0 in _removeList)};
        };
    };
};

ITW_VehCreateVehicle = {
    params ["_type","_pos",["_option",""],["_driver",objNull]];
    // _option:  "FLY","CAN_COLLIDE",etc
    private "_veh";
    private _texture = false;
    private _anim = false;
    if (typeName _type == "ARRAY") then {
        _texture = _type#1;
        if (count _type > 2) then {_anim = _type#2};
        _type = _type#0;
    };
    private _veh = if (_option isEqualTo "") then {
                _type createVehicle _pos;
            } else {
                createVehicle [_type,_pos,[],0,_option];
            };
    [_veh,_texture,_anim] call BIS_fnc_initVehicle;
    if !(isNull _driver) then {_driver moveInDriver _veh};
    _veh
};

ITW_VehSpawn = {
    params ["_type","_pos","_dir","_spawnCnt","_allowRespawn"];
    private _texture = false;
    private _anim = false;
    if (typeName _type == "ARRAY") then {
        _texture = _type#1;
        if (count _type > 2) then {_anim = _type#2};
        _type = _type#0;
    };
    _pos set [2,_pos#2+0.2];
    private _posHigh = +_pos;
    _posHigh set [2, _pos#2+20];
    private _veh = [_type,_posHigh,"CAN_COLLIDE"] call ITW_VehCreateVehicle;
    _veh setPosATL _posHigh;
    _veh allowDamage false;
    if (typeName _dir == "SCALAR") then {
        _veh setDir _dir;
    } else {
        _veh setVectorDirAndUp _dir;
    };
    _veh setPosATL _pos;
    _veh spawn {
        private _veh = _this;
        sleep 5; 
        _this allowDamage true;
    };
    _veh addItemCargoGlobal ["ToolKit",1];
    [_veh,_texture,_anim] call BIS_fnc_initVehicle;
    [_veh] remoteExec ["ITW_VehSpawnMP",0,true];
    [_veh,[_type,_texture,_anim],_pos,_dir,_spawnCnt,_allowRespawn] remoteExec ["ITW_VehSpawnServer",2];

    // set default value to allowing allies in crew seats
    private _blockAllyInCrewSeats = true;
    private _vehType = typeOf _veh;
    if (_vehType isKindOf "Air" && {_veh emptyPositions "Cargo" > 0}) then {
        // Helicopters w/ cargo seats allow allies in turrets
        _blockAllyInCrewSeats = false; 
    } else {
        if (_vehType isKindOf "Car") then {
            // cars (not aps) allow allies in turrets		
            _edSubcat = ((configFile >> "CfgVehicles" >> _vehType >> "editorSubcategory") call BIS_fnc_getCfgData);
            if (!isNil "_edSubcat") then {
                if !(["apc", _edSubcat, false] call BIS_fnc_inString) then {
                    _blockAllyInCrewSeats = false;
                };
            };
        };
    };
    if (_blockAllyInCrewSeats == false) then {_veh setVariable ["ITW_BlockAllyCrew",false,true]};
    
    private _settleTime = 10; // number of seconds a vehicle needs to 'settle' to the ground on all the clients before we can disable simulation
    _veh setVariable ["ITW_SpawnedTime",time + _settleTime];
    
    // set if veh has crew & turret positions
    private _fullCrew = fullCrew [_veh,'',true];
    _veh setVariable ["ITW_VehCrewAndTurret", {_x#2 >= 0} count _fullCrew > 0 && {{!(_x#3 isEqualTo []) && {_x#2 < 0}} count _fullCrew > 0},true];
    _veh
};

ITW_VehSpawnServer = {
    // call on server
    params ["_veh","_vehType","_pos","_dir","_spawnCnt","_allowRespawn"];
    if (_spawnCnt > 4) then {_allowRespawn = false}; // limit respawns in case they are dieing immediately 
    if (_allowRespawn) then {
        ITW_PlayerVehiclesList pushBack [_veh, _vehType, _pos, _dir, _spawnCnt, time];
    } else {
        ITW_PlayerVehiclesList pushBack [_veh];
    };
    _veh setVariable ["ITW_spawnPos",_pos];
    _veh addMPEventHandler ["MPKilled",{
                if (!isServer) exitWith {};
                private _veh = _this#0;
                private _spawnPos = _veh getVariable ["ITW_spawnPos",[0,0,0]];
                if (_veh distance _spawnPos > 100) then {
                    typeOf _veh call ITW_ObjAllyVehDead;
                };
            }];
    { _x addCuratorEditableObjects [[_veh], true] } forEach allCurators;
};

ITW_VehSpawnMP = {
    // call on all clients
    params ["_veh"];
    if (!hasInterface) exitWith {};
    _veh addAction ["<t color='#00ff00'>Unlock vehicle</t>",{
        params ["_veh", "_caller", "_actionId", "_arguments"];
        [_veh,true] remoteExec ["enableSimulationGlobal",2];
        [_veh,true] remoteExec ["allowDamage",_veh];
        },nil,10,true,true,"","! simulationEnabled _target && {_this == vehicle _this}",10,false];
    _veh addAction ["<t color='#0000ff'>Request nearby troops get in</t>",{
        params ["_veh", "_caller", "_actionId", "_arguments"];
        _veh setVariable ["ITW_ForceAllyEntry",true,true];
        },nil,1.4,false,true,"","_this == currentPilot _target && {speed _target < 5 && {!(_target getVariable ['ITW_BlockAllyEntry',false]) && !(_target getVariable ['ITW_ForceAllyEntry',false]) && {count fullCrew [_target,'cargo',true] > 0 && {_p=getPosATL _target;if (surfaceIsWater _p) then {(_p#2)-(getTerrainHeightASL _p)} else {_p#2} < 5 && {_target call ITW_ObjIsNearestFriendly}}}}}",15,false];
    _veh addAction ["<t color='#ff0000'>Don't allow ally in vehicle</t>",{
        params ["_veh", "_caller", "_actionId", "_arguments"];
        _veh setVariable ["ITW_BlockAllyEntry",true,true];
        },nil,1.4,false,true,"","_this == currentPilot _target && {!(_target getVariable ['ITW_BlockAllyEntry',false]) && {count fullCrew [_target,'cargo',true] > 0}}",15,false];
    _veh addAction ["<t color='#00ff00'>Allow ally in vehicle</t>",{
        params ["_veh", "_caller", "_actionId", "_arguments"];
        _veh setVariable ["ITW_BlockAllyEntry",false,true];
        },nil,1.4,false,true,"","_this == currentPilot _target && {_target getVariable ['ITW_BlockAllyEntry',false] && {count fullCrew [_target,'cargo',true] > 0}}",15,false];
    _veh addAction ["<t color='#aaffaa'>Allow ally in crew seats</t>",{
        params ["_veh", "_caller", "_actionId", "_arguments"];
        _veh setVariable ["ITW_BlockAllyCrew",false,false];
        },nil,1.4,false,true,"","_this == currentPilot _target && {(_target getVariable ['ITW_BlockAllyCrew',true]) && {_target getVariable ['ITW_VehCrewAndTurret',false]}}",15,false];
    _veh addAction ["<t color='#ffaaaa'>Don't allow ally in crew seats</t>",{
        params ["_veh", "_caller", "_actionId", "_arguments"];
        _veh setVariable ["ITW_BlockAllyCrew",true,true];
        },nil,1.4,false,true,"","_this == currentPilot _target && {!(_target getVariable ['ITW_BlockAllyCrew',true]) && {_target getVariable ['ITW_VehCrewAndTurret',false]}}",15,false];
};

ITW_SelectRandomTank = {
    // returns nil if no tanks or apcs are found
    params["_side"]; // _side = "P" or "E"
    private ["_tanks","_apcs"];
    if (toUpperANSI _side == "P") then {
        _tanks = va_pTankClasses;
        _apcs  = va_pApcClasses;
    } else {    
        _tanks = va_eTankClasses;
        _apcs  = va_eApcClasses;
    };
    if (_tanks isEqualTo []) exitWith {selectRandom _apcs};
    if (_apcs isEqualTo []) exitWith {selectRandom _tanks};
    if (random 1 < 0.33) then {
        selectRandom _apcs
    } else {
        selectRandom _tanks
    };
};

ITW_VehDebug = {
    // will put vehicles in the desert on altis
    private _pos =[23122,17278,0];
    private _divider = ["Land_Communication_F"];
    if (isNil "TEST_VEHS") then {TEST_VEHS = []} else {{deleteVehicle _x} forEach TEST_VEHS};
    {
        TEST_VEHS pushBack ([_x,_pos] call ITW_VehCreateVehicle);
        _pos set [1,_pos#1 + 12];
        if (_pos#1 > 18119) then {
            _pos set [1,17278];
            _pos set [0,_pos#0 + 12];
        };
    } forEach va_pTankAndApcClasses + _divider + va_eTankAndApcClasses + _divider + va_pStaticClasses + _divider + va_eStaticClasses;
};

["ITW_VehiclesInit"] call SKL_fnc_CompileFinal;
["ITW_VehSpawn"] call SKL_fnc_CompileFinal;
["ITW_VehManager"] call SKL_fnc_CompileFinal;
["ITW_VehSpawnServer"] call SKL_fnc_CompileFinal;
["ITW_VehSpawnMP"] call SKL_fnc_CompileFinal;
["ITW_SelectRandomTank"] call SKL_fnc_CompileFinal;
["ITW_VehDebug"] call SKL_fnc_CompileFinal;
["ITW_VehCreateVehicle"] call SKL_fnc_CompileFinal;

