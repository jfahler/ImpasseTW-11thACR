#include "defines.hpp"
#include "defines_gui.hpp"

ITW_RadioInit = {
    // called on all clients
    if (isServer) then {
        // supports availability
        missionNamespace setVariable ["casBomb",count va_pPlaneClassesAttack + count va_pPlaneClassesDual > 0,true];
        missionNamespace setVariable ["casHeli",count va_pHeliClassesAttack + count va_pHeliClassesDual > 0,true];
        SKL_CASPlane = compileFinal preprocessFileLineNumbers "scripts\Skull\SKL_CASPlane.sqf";
        SKL_CASHeli = compileFinal preprocessFileLineNumbers "scripts\Skull\SKL_CASHeli.sqf";
    };
    
    if (hasInterface) then {
        [] call ITW_RadioShowFriendlies;
        [] spawn {
            scriptName "ITW_RadioMenus";
            // Add radio menu items
            private _items = [
                "lifeSignScan",
                "showFriendlies",
                "supports",
                "transports",
                "commander"
            ];
            private _ftId = -1;
            private _asmtId = -1;
            private _landId = -1;
            private _ids = [];
            _ids resize [count _items,-1];
            while {true} do {
                while {LV_PAUSE} do {sleep 5};
                if (lifeState player == "INCAPACITATED") then {
                    // all radio items disappear if you are unconscious
                    if (_ids#0 != -1) then {
                        {[player, _x ] call BIS_fnc_removeCommMenuItem; _ids set [_forEachIndex,-1]} forEach _ids;
                        if (_ftId >= 0) then {
                            [player, _ftId] call BIS_fnc_removeCommMenuItem;
                            _ftId = -1;
                        };
                        if (_asmtId >= 0) then {
                            [player, _asmtId] call BIS_fnc_removeCommMenuItem;
                            [player, _landId] call BIS_fnc_removeCommMenuItem;
                            _asmtId = -1;
                        };
                    };
                } else {
                    if (_ids#0 == -1) then {
                        {
                            _ids set [_forEachIndex,[player, _x, nil, nil, ""] call BIS_fnc_addCommMenuItem];
                        } forEach _items;
                    };
                    // Fast travel appears/disappears with distance to a base
                    private _ftRange = 200;
                    private _playerPos = getPosATL player;
                    private _base = [_playerPos,ITW_OWNER_FRIENDLY] call ITW_BaseNearest;
                    private _basePos = _base call ITW_BaseGetCenterPt;
                    private _enabled = _playerPos distance _basePos < _ftRange;
                    if (_enabled && {_ftId == -1}) then {
                        _ftId = [player, "fastTravel", nil, nil, ""] call BIS_fnc_addCommMenuItem;
                    };
                    if (!_enabled && {_ftId != -1}) then {
                        [player, _ftId] call BIS_fnc_removeCommMenuItem;
                        _ftId = -1;
                    };
                    // Assignments is only available to the squad leader/HC
                    if (player in ITW_HcCmdr || {ITW_HcCmdr isEqualTo [] && {leader player == player}}) then {
                        if (_asmtId < 0) then {
                            _asmtId = [player, "assignments", nil, nil, ""] call BIS_fnc_addCommMenuItem;
                            _landId = [player, "landRoutes", nil, nil, ""] call BIS_fnc_addCommMenuItem;
                        };
                    } else {
                        if (_asmtId >= 0) then {
                            [player, _asmtId] call BIS_fnc_removeCommMenuItem;
                            [player, _landId] call BIS_fnc_removeCommMenuItem;
                            _asmtId = -1;
                        };
                    };
                };
                sleep 5;
            };
        };
    };
        
    SKL_HE_NEW_HELI_FN = ITW_RadioHeliTransport;
    SKL_TE_NEW_TRUCK_FN = ITW_RadioTruckTransport;
    
    // Get faction correct stuff        
    private _unitTypes = [ITW_PlayerFaction,["Crewman"],false,call FACTION_UNIT_FALLBACK_ROLE_REQ] call FactionUnits;
    if (_unitTypes isEqualTo []) then {_unitTypes = [ITW_PlayerFaction,["Rifleman"]] call FactionUnits};
    ITW_RADIO_PILOTS = _unitTypes;
    
    private _helis = va_pHeliClasses call ITW_RadioHeliCheck;
    //if (_helis isEqualTo []) then {_helis = va_cHeliClasses call ITW_RadioHeliCheck};
    if (_helis isEqualTo []) then {_helis = va_eHeliClasses call ITW_RadioHeliCheck};
    if (_helis isEqualTo []) then {_helis = ["B_Heli_Light_01_F"]};
    ITW_RADIO_HELIS = _helis;
    
    SKL_LocationSelection = compileFinal preprocessFileLineNumbers "scripts\Skull\SKL_LocationSelection.sqf";
};
  
ITW_RadioHeliCheck = {
    private _helis = [];
    {
        private _vehCfgName = if (typeName _x == "ARRAY") then {_x#0} else {_x};
        private _totalSeats = [_vehCfgName, true] call BIS_fnc_crewCount; // Number of total seats: crew + cargo/passengers
        private _crewSeats = [_vehCfgName, false] call BIS_fnc_crewCount; // Number of crew seats only
        private _cargoSeats = _totalSeats - _crewSeats; // Number of total cargo/passenger seats      
        if (_cargoSeats >= 4) then {
            _helis pushBack _vehCfgName;
        };
    } forEach _this;
    _helis
};

ITW_RadioFastTravel = {
    scopeName "ITW_RadioFastTravel";
    private _pos = ["Select a location to fast travel to",false,true] call ITW_RadioChooseOnMap;
    if !(_pos isEqualTo []) then {
        private _bringUnits = [];
        if (leader player == player) then {
            private _aiUnits = units group player select {!isPlayer _x && {vehicle _x != vehicle player}}; // ai in our group not in player's vehicle
            if !(_aiUnits isEqualTo []) then {
                ITW_YesNoMenu1Answer = false;
                ITW_YesNoMenu1 = [
                    ["Bring AI with you?", true],
                    ["Yes", [], "", -5, [["expression","ITW_YesNoMenu1Answer = true"]], "1", "1"],
                    ["No",  [], "", -5, [["expression", "ITW_YesNoMenu1Answer = false"]], "1", "1"]
                ];
                showCommandingMenu "#USER:ITW_YesNoMenu1";
                waitUntil {!(commandingMenu isEqualTo "")};
                waitUntil {commandingMenu isEqualTo ""};   
                if (ITW_YesNoMenu1Answer) then {
                    _bringUnits = _aiUnits;  
                    {
                        _x setDamage 0;
                        _x call ITW_FncAceHeal;
                        [_x, false] remoteExec ["setUnconscious",_x];
                        [_x, false] remoteExec ["setCaptive",_x];
                    } forEach _bringUnits;
                };
            };
        };
        private _base = [_pos,ITW_OWNER_FRIENDLY,true] call ITW_BaseNearest;
        private _travelPos = _base call ITW_BaseGetCenterPt;
        private _travelDir = 0;
        if (_travelPos distance _pos <= 800) then {
            [_base] call ITW_BaseEnsure;
            _travelPos = _base call ITW_BaseGetPlayerSpawnPt;
            _travelDir = (_base call ITW_BaseGetDir) - 90;
        } else {
            if (ITW_ParamFastTravel > 0) then {
                private _obj = [_pos,ITW_OWNER_CONTESTED,ITW_OWNER_CONTESTED] call ITW_ObjGetNearest;
                _travelPos = _obj#ITW_OBJ_POS getPos [3,180];
                if (_travelPos distance _pos <= 800) then {
                    private _flag = _obj#ITW_OBJ_FLAG;
                    private _captured = flagTexture _flag isEqualTo 'a3\data_f\flags\flag_blue_co.paa' && {flagAnimationPhase _flag > 0.9};
                    if (!_captured) then {
                        if (ITW_ParamFastTravel == 2) then {
                            private _bringAI = [];
                            private _bringVeh = [];
                            {
                                private _ai = _x;  
                                if (vehicle _ai == _ai) then {
                                    _bringAI pushBack _ai;
                                } else {
                                    _bringVeh pushBackUnique vehicle _ai;
                                };
                            } forEach _bringUnits;
                            // use para drop to un-captured territory
                            private _veh = vehicle player;
                            private _dist = ITW_ParamObjectiveSize + 200 + random 200;
                            private _dir = (_travelPos getDir _veh) - 45 + random 90;
                            private _dropPos = _travelPos getPos [_dist,_dir];
                            if (surfaceIsWater _dropPos) then {
                                while {surfaceIsWater _dropPos} do {
                                    for "_d" from 0 to 350 step 10 do {
                                        _dropPos = _travelPos getPos [_dist,_dir + _d];
                                        if (surfaceIsWater _dropPos) exitWith {};
                                    };
                                    _dist = _dist - 10;
                                };
                            };     
                            // ensure dropPos is away from water
                            for "_r" from 10 to 50 step 10 do {
                                for "_d" from 0 to 350 step 45 do {
                                    private _testPos = _dropPos getPos [_r,_d];
                                    if (surfaceIsWater _testPos) then {
                                        _dropPos = _dropPos getPos [-60 + _r,_d];
                                    };
                                };
                            };

                            _dropPos set [2,400];
                            _veh setDir (_dropPos getDir _travelPos);
                            _veh setPosATL _dropPos;
                            if (_veh == player) then {
                                waitUntil {((getPosATL _veh) select 2) < 60 or ((getPosASL _veh) select 2) < 60}; 
                                [_veh] spawn BIS_fnc_halo; 
                            } else {
                                waitUntil {((getPosATL _veh) select 2) < 100 or ((getPosASL _veh) select 2) < 100};
                                [_veh] spawn ITW_FncVehicleHalo;
                            };
                            private _pos = getPosATL _veh;
                            private _dir = getDir _veh - 180;
                            {
                                _pos = _pos getPos [20,_dir];
                                _pos set [2,60];
                                _x setPosATL _pos;
                                [_x] call ITW_FncAiHalo;
                            } forEach _bringAI; 
                            {
                                _pos = _pos getPos [40,_dir];
                                _pos set [2,150];
                                _x setPosATL _pos;
                                [_x] spawn ITW_FncVehicleHalo;
                            } forEach _bringVeh;
                            breakOut "ITW_RadioFastTravel"; 
                        };
                        _travelPos = []; // fail the distance check later as we're not fast traveling
                    };
                } else {
                    _travelPos = [];
                };
            } else {
                _travelPos = [];
            };
        };
        if !(_travelPos isEqualTo []) then {
            private _blacklist = ["water"];
            private _units = [player] + _bringUnits;
            _units = _units apply {vehicle _x}; // switch to vehicles
            _units = _units arrayIntersect _units; // remove duplicates
            {           
                private _object = _x;
                if (_object isKindOf "CAManBase") then {
                    _object setDir _travelDir;
                    _object setPosATL _travelPos;
                } else {
                    private _ftPos = [0,0,0];
                    private _range = 200;
                    private _size = (sizeOf typeOf _object) + 1;
                    while {count _ftPos == 3} do {
                        _ftPos = [_travelPos,100,_range,_size,0,0,0,_blacklist] call BIS_fnc_findSafePos; 
                        _range = _range + 50;
                    };
                    _blacklist pushBack [_ftPos,_size];
                    _ftPos pushBack 0;
                    _object allowDamage false;
                    _object setDir (_ftPos getDir _travelPos);
                    _object setPosATL _ftPos;
                    _object spawn {sleep 8;_this allowDamage true};
                };
            } forEach _units;
        } else {
            private _msg = switch (ITW_ParamFastTravel) do {
                case 1: {"Fast Travel Canceled\nClick near a base, or captured flag"};
                case 2: {"Fast Travel Canceled\nClick near a base, or contested flag"};
                default {"Fast Travel Canceled\nClick near a base"};
            };
            if (ITW_AirfieldBase getVariable ['Deployed',false]) then {
                _msg = _msg + ", or deployed airfield";
            };
            hint _msg;
        };
    };
};
    
ITW_RadioVehicleDrop = {
    params ["_pos"];
    scriptName "ITW_RadioVehicleDrop";
    params ["_pos"];
    private ["_vehs","_alt"];
    if (getTerrainHeightASL _pos <= -1) then {
        _alt = 30;
        _vehs = va_pShipClasses;
        //if (_vehs isEqualTo []) then { _vehs = va_cShipClasses};
        if (_vehs isEqualTo []) then { _vehs = va_eShipClasses};
        if (_vehs isEqualTo []) then { _vehs = ["C_Rubberboat"]};
    } else {
        _alt = 100;
        _vehs = va_pCarClassesTransport;
        if (_vehs isEqualTo []) then { _vehs = va_pCarClasses};
        if (_vehs isEqualTo []) then { _vehs = va_eCarClassesTransport};
        //if (_vehs isEqualTo []) then { _vehs = va_cCarClasses};
        if (_vehs isEqualTo []) then { _vehs = va_pQuadBikeClasses};
        //if (_vehs isEqualTo []) then { _vehs = va_cQuadBikeClasses};
        if (_vehs isEqualTo []) then { _vehs = va_eQuadBikeClasses};
        if (_vehs isEqualTo []) then { _vehs = va_pApcClasses};
        if (_vehs isEqualTo []) then { _vehs = ["B_G_Offroad_01_F"]};
    };
    private _vehTypeTxtr = selectRandom _vehs;
    private _vehType = if (typeName _vehTypeTxtr == "ARRAY") then {_vehTypeTxtr#0} else {_vehTypeTxtr};
    
    private _vehDesc = getText (configFile >> "cfgVehicles" >> _vehType >> "displayName");
    if (isNil "_vehDesc" || {_vehDesc == ""}) then {_vehDesc = "Vehicle"};
    ["HQ",format ["Rodger, %1 dispatched.",_vehDesc]] call ITW_RadioSendMessage;
    ["SentRequestAcknowledgedTransport"] call ITW_RadioPlayMessage;
    sleep 20;
    // add a jet sound
    private _hp = "Land_HelipadEmpty_F" createVehicle _pos;
    sleep 0.5;
    _soundFlyover = ["BattlefieldJet1","BattlefieldJet2"] call bis_fnc_selectrandom;
    [_hp,_soundFlyover,"say3d"] remoteExec ["bis_fnc_sayMessage",0];
    sleep 3;
    _pos set [2,300];
    private _veh = [_vehTypeTxtr,_pos] call ITW_VehCreateVehicle;
    _veh allowDamage false;
    private _dir = random 360;
    _veh setDir _dir;
    _veh setPosATL _pos;

    // add parachute at correct altitude 
    waitUntil {((getPosATL _veh) select 2) < 100}; 
    
    private _objectPos = getPosATL _veh;
    private _para = createvehicle ["B_Parachute_02_F",_objectPos,[],0,"none"];
    _veh attachto [_para,[0,0,1]];
    _para setDir _dir;
    _para setPosATL _objectPos;
    _para setvelocity [0,0,-1];
    
    private _timeout = time + 30;
    waitUntil {sleep 1;isNull _para || isTouchingGround _veh || time > _timeout};
    deleteVehicle _para;
    deleteVehicle _hp;
    sleep 10;
    _pos = getPosATL _veh;
    _pos set [2,0.05];
    if (surfaceIsWater _pos) then {
        _veh setPosASLW _pos;
        _veh setVectorUp [0,0,1];
    } else {
        _veh setPosATL _pos;
        _veh setVectorUp surfaceNormal _pos;
    };
    sleep 5;
    _veh allowDamage true;
    
    // setup vehicle for other systems
    _veh addItemCargoGlobal ["ToolKit",1];
    [_veh] remoteExec ["ITW_VehSpawnMP",0,true];

    // set default value to allowing allies in crew seats
    private _blockAllyInCrewSeats = true;
    private _vehType = typeOf _veh;
    if (_vehType isKindOf "Car") then {
        // cars (not aps) allow allies in turrets		
        _edSubcat = ((configFile >> "CfgVehicles" >> _vehType >> "editorSubcategory") call BIS_fnc_getCfgData);
        if (!isNil "_edSubcat") then {
            if !(["apc", _edSubcat, false] call BIS_fnc_inString) then {
                _blockAllyInCrewSeats = false;
            };
        };
    };
    if (_blockAllyInCrewSeats == false) then {_veh setVariable ["ITW_BlockAllyCrew",false,true]};
};
    
ITW_RadioSupplyDrop = {
    params ["_pos"];
    scriptName "ITW_RadioSupplyDrop";
    params ["_pos"];
    private _vehType = "B_supplyCrate_F";
    ["HQ","Supplies on route"] call ITW_RadioSendMessage;
    ["SentRequestAcknowledgedSGSupplyDrop"] call ITW_RadioPlayMessage;
    _pos set [2,300];
    sleep 20;
    // add a jet sound
    private _hp = "Land_HelipadEmpty_F" createVehicle _pos;
    sleep 0.5;
    _soundFlyover = ["BattlefieldJet1","BattlefieldJet2"] call bis_fnc_selectrandom;
    [_hp,_soundFlyover,"say3d"] remoteExec ["bis_fnc_sayMessage",0];
    sleep 3;
    private _ammoBox = _vehType createVehicle _pos;
    _ammoBox setPosATL _pos;
    _ammoBox allowDamage false;
    // add parachute at correct altitude 
    waitUntil {((getPosATL _ammoBox) select 2) < 80}; 
    
    _pos = getPosATL _ammoBox;
    private _para = createvehicle ["B_Parachute_02_F",_pos,[],0,"none"];
    _ammoBox attachto [_para,[0,0,1]];
    _para setPosATL _pos;
    _para setdir direction _ammoBox;
    _para setvelocity [0,0,-1];
    private _smoke = "SmokeshellRed" createVehicle getPosATL _ammoBox;
    private _chem = "Chemlight_yellow_Infinite" createVehicle getPosATL _ammoBox;
    _smoke attachTo [_ammoBox,[0,0,0]];
    _chem attachTo [_ammoBox,[0,0,0]];
    
    clearItemCargoGlobal _ammoBox;
    clearWeaponCargoGlobal _ammoBox;
    clearBackpackCargoGlobal _ammoBox;
    clearMagazineCargoGlobal _ammoBox;
    _ammoBox remoteExec ["CustomArsenal_AddVAs",0,true];
    
    private _timeout = time + 30;
    waitUntil {sleep 1;isNull _para || isTouchingGround _ammoBox || time > _timeout};
    deleteVehicle _para;
    deleteVehicle _smoke;
    _smoke = "SmokeshellRed" createVehicle getPosATL _ammoBox;
    _smoke attachTo [_ammoBox,[0,0,0]];
    deleteVehicle _hp;
    [_ammoBox] remoteExec ["ITW_RadioSupplyDropMoveMP",0,_ammoBox];
    sleep 10;
    _ammoBox allowDamage true;
};

ITW_RadioSupplyDropMoveMP = {
    params ["_crate"];
    if (!hasInterface) exitWith {};
    _crate addAction ["<t color='#aaaadd'>Carry crate</t>", {
            params ["_crate", "_caller", "_actionId", "_arguments"];
            _crate attachTo [_caller, [0, 2, 1]];
            _caller setAnimSpeedCoef 0.5;
            _caller playAction "PlayerStand";
            _caller action ["SwitchWeapon",_caller,_caller,-1];
            
            player addAction ["<t color='#aaaadd'>Drop crate</t>", {
                params ["_player", "_caller", "_actionId", "_crate"];
                _player setVelocity [0,0,0];
                _crate setVelocity [0,0,0];
                detach _crate;
                _player setAnimSpeedCoef 1;
                _player removeAction _actionId;
            },_crate,10,false,true,"",""];
        },nil,1.5,false,true,"","(isPlayer _this) && {isNull attachedTo _target}",4];  
};

ITW_RadioFlareDrop = {
    params ["_pos"];
    private _text = format ["<t size='1.25'>Flare barrage inbound to %1.<br />ETA 30 seconds.</t>",mapGridPosition _pos];  
    ["HQ",_text] call ITW_RadioSendMessage;
    ["SentRequestAcknowledgedSGArty"] call ITW_RadioPlayMessage;
        
    private _timeOut = time + 30; // delay before flares start
    waitUntil {sleep 1; time > _timeOut };
    
    private _aliveTime = 40; // how long flare are alive for            
    private _flareCnt = selectRandom [6,7,8];
    private _totalFlareTime = 1200; // flares run for 20 minutes
    
    private _flareSequence = []; // array of [_pos,_nextDropTime,_maxTime]
    private _flares = [[0,objNull]];        // array of [deathTime,flareObject]
    
    private _positionOrigin = _pos;
    private _startDropTime = time;
    private _flareMaxTime = 0;
    for "_i" from 1 to _flareCnt do {
        _pos = _positionOrigin getPos [_i * 35, random 360];
        _flareMaxTime = _startDropTime + _totalFlareTime; // 20 minutes
        _flareSequence pushBack [_pos,_startDropTime, _flareMaxTime];
        _startDropTime = _startDropTime + 5 + random 10;
    };         
    while {!(_flares isEqualTo [])} do {
        // create flares
        {
            private _maxTime = _x#2;
            if (time > _maxTime) then {continue}; // done this column of flares
            private _nextDropTime = _x#1;
            if (time < _nextDropTime) then {continue}; // not time for next drop
            private _pos = _x#0;
            private _fpos = _pos getPos [random 80,random 360];
            _fpos set [2,240];
            private _flare = createVehicle ["F_40mm_White_Infinite", _fpos, [], 0, "none"]; 
            _flare setVelocity [wind select 0, wind select 1, 30];
            [_flare,_aliveTime] remoteExec ["ITW_RadioFlareMP",0];
            _flares pushBack [time + _aliveTime,_flare];
            _x set [1,time + 25 + random 15]; // set the next drop time for this column
        } count _flareSequence;
        
        // delete flares
        {
            private _deleteTime = _x#0;
            if (time < _deleteTime) then {continue}; // not time yet
            private _flare = _x#1;
            deleteVehicle _flare;
            _flares deleteAt _forEachIndex;
        } forEachReversed _flares;
        
        sleep 2;
    };
};

ITW_RadioFlareMP = {
    // run on all clients
    if (!hasInterface) exitWith {};
    params ["_flare","_delay"];
    private _light = "#lightpoint" createVehicle (getPosASL _flare);
    _light attachTo [_flare, [0, 0, 0]];
    _light setLightColor [0.5, 0.5, 0.5];
    _light setLightAmbient [1, 1, 1];
    _light setLightIntensity 100000;
    _light setLightUseFlare true;
    _light setLightFlareSize 3;
    _light setLightFlareMaxDistance 600;
    _light setLightDayLight true;
    _light setLightAttenuation [4, 0, 0, 0.3, 200, 500];
    sleep (_delay-2);
    waitUntil {
        sleep 0.1;
        !alive _flare;
    };
    deletevehicle _light;
};

ITW_RadioHeliTransport = {
    // called on server
    params ["_pos","_caller"];
    private _heli = selectRandom ITW_RADIO_HELIS;
    private _pilot = selectRandom ITW_RADIO_PILOTS;
    
    private _base = [_pos,ITW_OWNER_FRIENDLY] call ITW_BaseNearest;
    private _basePos = _base call ITW_BaseGetCenterPt;
    [_pos, _caller, _heli, _pilot, side _caller, _basePos, {group driver _this setVariable ["itw_hideOnMap",true]}] spawn SKL_HeliExtract;
};

ITW_RadioChooseOnMap = {
    params [["_hint","",[""]],["_public",false],["_mapOnly",false]];
    private _pos = [0,0,0];
    if (!_mapOnly && !visibleMap) then {
        private _beg = eyePos player;
        private _end = _beg vectorAdd (player weaponDirection currentWeapon player vectorMultiply 3000);
        _pos = terrainIntersectAtASL [_beg,_end];
    };
    if !(_pos isEqualTo [0,0,0]) then {
        _pos set [2,0];
    } else {
        ITW_RadioPos = nil;
        
        // get user selected position   
        private _ehId = addMissionEventHandler ["MapSingleClick", {
            params ["_units", "_pos", "_alt", "_shift"];
            if (!_alt && !_shift) then {
                ITW_RadioPos = _pos;
                openMap false; 
            };
        }];         
        
        showMap true; 
        openMap true;
        waitUntil {visibleMap};
        _hintTime = -100;
        while {visibleMap} do {
            if (time - _hintTime > 25) then {
                _hintTime = time;
                hintSilent _hint; 
            };
        };
        removeMissionEventHandler ["MapSingleClick", _ehId];
        hintSilent "";
        if (isNil "ITW_RadioPos") then {ITW_RadioPos = []};
        if (_public) then {publicVariable "ITW_RadioPos"};
        _pos = ITW_RadioPos;
    };
    _pos
};

ITW_RadioLeaderRequest = {
    // called on requesting client
    if (isNil "ITW_REQ_LEADER_TIME") then {ITW_REQ_LEADER_TIME = 0};
    if (ITW_REQ_LEADER_TIME > time) exitWith {
        cutText ["<t size='3'>Leader request in cool down.  Try again in a minute.</t>","PLAIN",-1,true,true];
    };
    ITW_REQ_LEADER_TIME = time + 60; // only able to request every 60 seconds
    private _leader = leader player;
    if (player == _leader) exitWith {};
    if (isPlayer _leader) then {
        [player] remoteExec ["ITW_RadioLeaderAuthorize",_leader];
    } else {
        [[group player, player],"selectLeader",group player] call ITW_FncRemoteLocalGroup;
    };
};

ITW_RadioLeaderAuthorize = {
    // called on current leader client
    params ["_newLeader"];
    ITW_NewLeader = _newLeader;
    CreateDialog "ITWAuthorizationDisplay";
    ctrlSetText [ITW_DIALOG_TEXT1_ID, format ['Relinquish group leadership to %1',name _newLeader] ];
};

ITW_RadioLeaderRelinquish = {
    // called on current leader client
    private _units = units group player - [player];
    if (_units isEqualTo []) exitWith {
        cutText ["<t size='3'>There are no units for you to relinquish leadership to.</t>","PLAIN",-1,true,true];
    };
    ITW_NewLeaderUnits = _units;
    CreateDialog "ITWRelinquishDisplay";
    {      
        private _index = lbAdd [ITW_DIALOG_LISTBOX_ID, name _x];
        lbSetData [ITW_DIALOG_LISTBOX_ID, _index, str _forEachIndex];
    } forEach _units;
};

ITW_RadioLeaderProcess = {
    // called on current leader's client
    params ["_code"];
    private _newLeader = objNull;
    switch (_code) do {
        case 'ok': {_newLeader = ITW_NewLeader};
        case 'relinquish': {               
            if !(isNil "ITW_NewLeaderUnits") then {
                private _display = findDisplay ITW_DISPLAY_LIST_ID;
                private _indexes = lbSelection (_display displayCtrl ITW_DIALOG_LISTBOX_ID);
                if !(_indexes isEqualTo []) then {
                    private _index = _indexes#0;  
                    if (_index >= 0 && {_index < count ITW_NewLeaderUnits}) then {
                        _newLeader = ITW_NewLeaderUnits # _index;
                    };
                };
            };
            ITW_NewLeaderUnits = nil;
        };
        case 'cancel': {
            [["<t size='3'>Leader request denied</t>","PLAIN",-1,true,true]] remoteExec ["cutText",ITW_NewLeader];
        };
    };
    ITW_NewLeader = objNull;
    if !(isNull _newLeader) then {
        [[group _newLeader, _newLeader],"selectLeader",group _newLeader] call ITW_FncRemoteLocalGroup;
    };
};

ITW_RadioSquadMenu = {
    params ["_msg","_function"];
	ITW_Squad_Menu = [[_msg, false]];
    private _groups = call BIS_fnc_listPlayers apply {group _x};
    _groups = _groups arrayIntersect _groups; // remove duplicates
 //   _groups = _groups - [group player];
    if (_groups isEqualTo []) exitWith {hint "No other player groups"};
    {
        private _grp = _x;
        if (_grp != group player) then {
            ITW_Squad_Menu pushBack [name leader _grp, [_forEachIndex + 2], "", -5, [["expression",format ["[ITW_Squad_Menu_Groups#%1] spawn %2",_forEachIndex,str _function]]],"1","1"];
        };
    } forEach _groups;
    ITW_Squad_Menu_Groups = _groups;
    showCommandingMenu "#USER:ITW_Squad_Menu";
};

ITW_RadioSquadJoin = {
    ["Join squad", {
        params ["_group"];
        [player] joinSilent _group;
    }] call ITW_RadioSquadMenu;
};

ITW_RadioSquadMerge = {
    ["Merge to squad", {
        params ["_group"];
        private _oldGroup = group player;
        units _oldGroup joinSilent _group;
        [[_oldGroup],"deleteGroup",_oldGroup] call ITW_FncRemoteLocalGroup; 
    }] call ITW_RadioSquadMenu;
};

ITW_ShowFriendlyEnabled = false;  // used to determine if currently showing friendlies or not
ITW_ShowFriendlyPaused = false;
ITW_SF_SubMenu = [
	["Show squads on map", false],
	["Yes", [2], "", -5, [["expression", "[true]  spawn ITW_RadioShowFriendlies;"]], "1", "1"],
    ["No" , [3], "", -5, [["expression", "[false] spawn ITW_RadioShowFriendlies;"]], "1", "1"]
];

ITW_RadioShowFriendlies = {
    //  show/hide of friendly group icons    
    params [["_showIcons",profileNamespace getVariable ["ITWShowAllyIcons",false]]];
    if (ITW_ShowFriendlyEnabled == _showIcons && {}) exitWith {};
    if (_showIcons) then {
        ITW_ShowFriendlyEnabled = true;
        0 spawn {
            scriptName "ITW_RadioShowFriendlies";
            private _enemySide = ITW_EnemySide;
            private _prevMrkCount = -1;
            while {ITW_ShowFriendlyEnabled} do {
                private _mrksShown = 0;
                if (!hcShownBar) then {
                    private _vehs = [];
                    {
                        private _unit = _x;
                        if (!alive _unit || {side _unit == civilian || {_unit isKindOf "Logic"}}) then {continue};
                        private _veh = vehicle _unit;
                        if (!(leader _unit isEqualTo _unit) && {_veh isEqualTo _unit || {_veh isKindOf "ParachuteBase"}}) then {continue};
                        if (group _unit getVariable ["itw_hideOnMap",false]) then {continue};
                        private _isFriendly = side _unit == west;
                        private ["_icon","_color"];
                        private _size = 0.9;
                        if (_isFriendly) then {
                            _icon = "b_inf";
                            _color = "ColorBLUFOR";
                        } else {
                            if (ITW_ParamShowEnemyOnMap == 0 || {west knowsAbout _veh < 1}) then {continue};
                            _icon = "o_inf";
                            _color = "ColorOPFOR";
                        };
                        if (_unit != _veh) then {
                            if (_veh in _vehs) then {continue};
                            _vehs pushBack _veh;
                            _icon =_veh getVariable ["itw_icon",""];
                            if (_icon isEqualTo "") then {
                                private _icon = if (_veh isKindOf "Car") then {
                                    private _armor = getNumber (configFile >> "cfgVehicles" >> typeOf _veh >> "armor");
                                    if (_armor < 250) then {"motor_inf"} else {"mech_inf"};
                                } else {
                                    if (_veh isKindOf "Tank")          then {"armor"} else {
                                    if (_veh isKindOf "Plane")         then {"plane"} else {
                                    if (_veh isKindOf "ParachuteBase") then {"inf"} else {
                                    if (_veh isKindOf "StaticWeapon")  then {"Ordnance"} else {
                                    if (_veh isKindOf "Ship")          then {"naval"} else {
                                    if (_veh isKindOf "Air")           then {"air"} else {"inf"}}}}}};
                                };
                                _icon = (if (_isFriendly) then {"b_"} else {"o_"}) + _icon;
                                _veh setVariable ["itw_icon",_icon];
                            };
                            _size = 1; // vehicles are slightly larger
                        };
                        private _mrkr = "ITW_RSF_" + str _mrksShown;
                        if (getMarkerColor _mrkr isEqualTo "") then {
                            _mrkr = createMarkerLocal [_mrkr, getPosATL _unit];
                        } else {
                            _mrkr setMarkerPosLocal getPosATL _unit;
                        };
                        _mrkr setMarkerColorLocal _color;
                        _mrkr setMarkerTypeLocal _icon;
                        _mrkr setMarkerSizeLocal [_size,_size];
                        _mrksShown = _mrksShown + 1;
                    } forEach allUnits;
                };
                for "_i" from _mrksShown to _prevMrkCount do {
                    deleteMarkerLocal ("ITW_RSF_" + str _i);
                };
                _prevMrkCount = _mrksShown - 1;
                sleep (if (shownMap && {!hcShownBar}) then {0.1} else {1});
                
                if (ITW_ShowFriendlyPaused) then {
                    for "_i" from 0 to _prevMrkCount do {
                        deleteMarkerLocal ("ITW_RSF_" + str _i);
                    };
                    _prevMrkCount = -1;
                    while {ITW_ShowFriendlyPaused} do {sleep 1};
                };
            };
            for "_i" from 0 to _prevMrkCount do {
                deleteMarkerLocal ("ITW_RSF_" + str _i);
            };
        };
    } else {
        ITW_ShowFriendlyEnabled = false;
    };
    profileNamespace setVariable ["ITWShowAllyIcons",_showIcons];
};

ITW_RadioLifeSignScan = {
    if (assignedItems player select {_x isKindOf ["ItemMap",configFile >> "cfgWeapons"]} isEqualTo []) then {
        player linkItem "ItemMap";
    };  
    if (isNil "ITW_THREMAL_SCAN") then {ITW_THREMAL_SCAN = 0};
    if (time < ITW_THREMAL_SCAN) exitWIth {hint format ["Scan recharging, available in %1 sec",round (ITW_THREMAL_SCAN - time)]};
    
    private _timeout  = 90; // time between scans
    private _duration = 30; // how long life signs show as they fade out
    private _range = ITW_ParamObjectiveSize + 20;
    
    private _pos = ([getPosATL player] call ITW_ObjGetNearest)#ITW_OBJ_POS;
    if (_pos distance player > 1000) exitWith {hint "You need to be closer to a contested objective"};
    
    ITW_THREMAL_SCAN = time + _timeout; 
    
    private _markers = []; 
    private _size = 4; 
    private _alpha = 1; 
    
    {
        if (_x isKindOf "LOGIC") then {continue};
        private _unitPos = getPosATL _x;
        if (_unitPos#2 < 15 && {_unitPos distance _pos < _range}) then {
            private _mrk = createMarkerLocal [format ["ITWLS_%1",_forEachIndex],getPosATL _x]; 
            _mrk setMarkerShapeLocal "ELLIPSE"; 
            _mrk setMarkerBrushLocal "SolidFull"; 
            _mrk setMarkerSizeLocal [_size,_size]; 
            _mrk setMarkerAlphaLocal _alpha; 
            _mrk setMarkerColorLocal "ColorOrange"; 
            _markers pushBack [_mrk,_x]; 
        };
    } forEach allUnits; 
    
    openMap true;
    mapAnimAdd [0,0.015,_pos]; 
    mapAnimCommit;  
    
    if !(_markers isEqualTo []) then { 
        private _timeout = time + _duration; 
        private _tick = 0.3; 
        private _deltaAlpha = _alpha / _duration * _tick; 
        while {time < _timeout} do { 
            sleep _tick; 
            _alpha = _alpha - _deltaAlpha; 
            { 
                _x params ["_mrk","_unit"]; 
                _mrk setMarkerPosLocal getPosATL _unit;  
                _mrk setMarkerAlphaLocal _alpha;           
            } forEach _markers; 
        }; 
        { 
            deleteMarkerLocal (_x#0); 
        } forEach _markers; 
    }; 
};

ITW_RadioCommanderMenu = [
    ["Commander Menu", false],
    ["Adjust objective priorities" , [2], "", -5, [["expression", "0 spawn ITW_AllyShowAssignmentsDisplay"]], "1", "1"],
    ["Adjust land attack routes"   , [3], "", -5, [["expression", "0 spawn ITW_AllyChooseLandRoutes"]], "1", "1"],
    ["Cancel"                      ,[16], "", -3, [["expression", ""]], "1", "1"]
];

ITW_RadioCommsMenu = {
    params ["_supportType"];
    private _subType = "";
    private _locationType = "";
    private _pos = [];
    ITW_RadioCall = nil;
    private _menuST = switch (_supportType) do {
        case "SUPPORT": { 
            private _casAvailB = "1"; 
            private _casAvailH = "1";  
            private _mortarAvail = "1";
            private _casExB = ""; 
            private _casExH = "";
            private _mrtEx = "";
            private _casTime = missionNamespace getVariable ["ITW_CasTime",0];
            private _mrtTime = missionNamespace getVariable ["ITW_MortarTime",0];
            if (serverTime < _casTime) then {
                _casAvailB = "0";
                _casAvailH = "0";
                _casExB = "(avail in " + str round ((_casTime - serverTime)/60) + "min)";
                _casExH = _casExB;
            };
            if !(true call ITW_ObjOwnsAirport)                  then {_casAvailB = "0";_casExB = "(no captured airport)"};
            if !(missionNamespace getVariable ["casBomb",true]) then {_casAvailB = "0";_casExB = "(no attack planes)"};
            if !(missionNamespace getVariable ["casHeli",true]) then {_casAvailH = "0";_casExH = "(no attack helis)"};
            if (serverTime < _mrtTime) then {
                _mortarAvail = "0";
                private _mtrTime = round (_mrtTime - serverTime);
                _mrtEx = "(avail in " + (if (_mtrTime < 45) then {str _mtrTime + "sec)"} else {str round (_mtrTime/60) + "min)"});
            };
            private _casVisible = if (ITW_ParamPlayerCAS > 0 ) then {"1"} else {"0"};
            private _mrtVisible = if (ITW_ParamPlayerArtillery > 0) then {"1"} else {"0"};
            [
                ["Supports", false],
                ["Supply drop"       , [2], "", -5, [["expression", "ITW_RadioCall = 'SUPPLY'"]], "1", "1"],
                ["Flares"            , [3], "", -5, [["expression", "ITW_RadioCall = 'FLARE' "]], "1", "1"],
                ["Artillery"+_mrtEx  , [4], "", -5, [["expression", "ITW_RadioCall = 'MORTAR'"]], _mrtVisible, _mortarAvail],
                ["CAS bomber"+_casExB, [5], "", -5, [["expression", "ITW_RadioCall = 'CAS-B' "]], _casVisible, _casAvailB],
                ["CAS heli"+_casExH  , [6], "", -5, [["expression", "ITW_RadioCall = 'CAS-H' "]], _casVisible, _casAvailH],
                [""                  ,[], "", -1, [["expression", ""]], "1", "1"],
                ["Back"              ,[48], "#User:BIS_fnc_addCommMenuItem_menu", -2, [["expression", ""]], "1", "1"],
                ["Cancel"            ,[16], "", -3, [["expression", ""]], "1", "1"]
            ];
        };
        case "TRANSPORT": {
            [
                ["Transports", false],
                ["Heli extract"     , [2], "#USER:SKL_HE_SubMenu", -5, [["expression", ""]], "1", "1"],
                ["Transport truck"  , [3], "#USER:SKL_TE_SubMenu", -5, [["expression", ""]], "1", "1"],
                ["Air drop vehicle" , [4], "", -5, [["expression", "ITW_RadioCall = 'AIR-DROP'"]], "1", "1"],
                [""                  ,[], "", -1, [["expression", ""]], "1", "1"],
                ["Back"              ,[48], "#User:BIS_fnc_addCommMenuItem_menu", -2, [["expression", ""]], "1", "1"],
                ["Cancel"           ,[16], "", -3, [["expression", ""]], "1", "1"]
            ];
        };
        default {[]};
    };
    if !(_menuST isEqualTo []) then {
        showCommandingMenu "#USER:_menuST";
        waitUntil {commandingMenu == ""};
        if (!isNil "ITW_RadioCall") then {_subType = ITW_RadioCall};
        ITW_RadioCall = nil;
    };
    
    if !(_subType isEqualTo "") then {
        _pos = [] call SKL_LocationSelection;
    };
        
    if !(_pos isEqualTo []) then {
        switch (_subType) do {
            case 'SUPPLY':   {[_pos] spawn ITW_RadioSupplyDrop};
            case 'FLARE' :   {[_pos] spawn ITW_RadioFlareDrop};
            case 'CAS-B' :   {[_pos] spawn ITW_RadioCasPlane};
            case 'CAS-H' :   {[_pos] spawn ITW_RadioCasHeli};
            case 'MORTAR':   {[_pos] spawn ITW_RadioMortar};
            case "AIR-DROP": {[_pos] spawn ITW_RadioVehicleDrop};
        };
        ITW_RadioCall = nil;
    };
};    

ITW_RadioTeammateMenu = {
    private _menu = [
        ["Deliver teammates", false],
        ["None"        ,[11], "", -5, [["expression", "ITW_RadioTmCount = 0"]], "1", "1"],
        ["1 Teammate"  , [2], "", -5, [["expression", "ITW_RadioTmCount = 1"]], "1", "1"],
        ["2 Teammates" , [3], "", -5, [["expression", "ITW_RadioTmCount = 2"]], "1", "1"],
        ["3 Teammates" , [4], "", -5, [["expression", "ITW_RadioTmCount = 3"]], "1", "1"],
        ["4 Teammates" , [5], "", -5, [["expression", "ITW_RadioTmCount = 4"]], "1", "1"],
        ["5 Teammate"  , [2], "", -5, [["expression", "ITW_RadioTmCount = 5"]], "1", "1"],
        ["6 Teammates" , [3], "", -5, [["expression", "ITW_RadioTmCount = 6"]], "1", "1"],
        ["Cancel"      ,[16], "", -3, [["expression", ""]], "1", "1"]
    ];
    ITW_RadioTmCount = nil;
    showCommandingMenu "#USER:_menu";
    waitUntil {commandingMenu == ""};
    if (isNil "ITW_RadioTmCount") then {ITW_RadioTmCount = 0};
    publicVariableServer "ITW_RadioTmCount";
};

ITW_RadioTruckTransport = {
    // truck transport setup function - run on server
    params ["_lzPos","_player"];
    private _truckType = selectRandom va_pCarClassesTransport;
    if (isNil "_truckType") then {_truckType = "C_Van_02_transport_F"};
    private _fromObj = [_lzPos,ITW_OWNER_FRIENDLY] call ITW_ObjGetNearest;
    private _spawnPt = _fromObj#ITW_OBJ_V_SPAWN;
    private _crewGrp = createGroup [civilian,false];
    private _driver = [_crewGrp,ITW_AllyUnitTypes,_spawnPt,true] call ITW_AtkUnitToGroup;
    _crewGrp deleteGroupWhenEmpty true;
    group _driver setVariable ["itw_hideOnMap",true];
    
    private _cargoUnits = [];
    if (leader _player == _player) then {
        ITW_RadioTmCount = nil;
        [] remoteExec ["ITW_RadioTeammateMenu",_player];
        waitUntil {sleep 0.001;!isNil "ITW_RadioTmCount"};
        private _cargoCount = ITW_RadioTmCount;
        ITW_RadioTmCount = nil;
        private _cargoGrp = grpNull;
        for "_i" from 1 to _cargoCount do {
            private _aiCnt = {!isPlayer _x && {alive _x}} count units group _player;
            if (_aiCnt >= ITW_ParamFriendlySquadSize) exitWith {
                hint "Cargo Troops Limited\nMax squad size reached.";
            };    
            if (isNull _cargoGrp) then {_cargoGrp = createGroup [playerSide,false]};
            private _unit = [_cargoGrp,ITW_AllyUnitTypes,_spawnPt,true] call ITW_AtkUnitToGroup;
            _cargoUnits pushBack _unit;
        };
        if (!isNull _cargoGrp) then {_cargoGrp deleteGroupWhenEmpty true};
    };
    [_lzPos, _player, _truckType, [_driver], playerSide, _spawnPt, _cargoUnits] call SKL_TruckExtract;
};

ITW_RadioCasServer = {
    params ["_args","_type"];
    private _success = 
        if (_type == "heli") then {_args call SKL_CASHeli}
        else { _args call SKL_CASPlane };
    // if cas not successfully launched, allow another right away
    if (!_success) then {missionNamespace setVariable ["ITW_CasTime",serverTime,true]}; 
};

ITW_RadioCasPlane = {
    params ["_pos"];
    missionNamespace setVariable ["ITW_CasTime",serverTime + ITW_ParamPlayerCAS,true]; 
    private _vehType = selectRandom va_pPlaneClassesAttack;
    if (isNil "_vehType") then {_vehType = selectRandom va_pPlaneClassesDual};
    if (isNil "_vehType") exitWith {hint "Attack planes not available to your faction"};
    private _airportPos = [true,_pos] call ITW_ObjClosestOwnedAirport;
    if (isNil "_airportPos" || {!(typeName _airportPos isEqualTo "ARRAY")}) exitWith {hint "No airports available"};
    private _dir = _airportPos getDir _pos;
    [[player,_pos,_dir,west,_vehType],"bomb"] remoteExec ["ITW_RadioCasServer",2];
};

ITW_RadioCasHeli = {
    params ["_pos"];
    missionNamespace setVariable ["ITW_CasTime",serverTime + ITW_ParamPlayerCAS,true];
    missionNamespace setVariable ["ITW_CasTime",serverTime + ITW_ParamPlayerCAS,true]; 
    private _vehType = selectRandom va_pHeliClassesAttack;
    if (isNil "_vehType") then {_vehType = selectRandom va_pHeliClassesDual};
    if (isNil "_vehType") exitWith {hint "Attack helicopters not available to your faction"}; 
    // prioritize the basic nato/cscat attack helis
    private _allHelis = va_pHeliClassesAttack + va_pHeliClassesDual;
    {if (_x in _allHelis) exitWith {_vehType = _x}} forEach ["B_Heli_Attack_01_dynamicLoadout_F","O_Heli_Attack_02_dynamicLoadout_F"]; 
    private _basePos = ([_pos] call ITW_BaseNearest)#ITW_BASE_POS;
    private _dir = _basePos getDir _pos;
    [[player,_pos,_dir,west,_vehType],"heli"] remoteExec ["ITW_RadioCasServer",2];
};

ITW_RadioMortar = {
    params ["_pos"];
    private _travelTime = 40;  // time in sec between call and first round landing
    private _mortarRounds = 4; // number of rounds in a volley
    private _accuracy = 50;    // how close to the target the round will land
    missionNamespace setVariable ["ITW_MortarTime",serverTime + ITW_ParamPlayerArtillery,true]; 
    ["SentRequestAcknowledgedSGArty"] call ITW_RadioPlayMessage;
    ["Command","Ordinance in bound. ETA "+str _travelTime+" seconds",false] call ITW_RadioSendMessage;
    sleep _travelTime;
    for "_i" from 1 to _mortarRounds do {
        private _posToFireAt = _pos getPos [random _accuracy, random 360];
        _posToFireAt set [2,600];
        private _shell = "Sh_82mm_AMOS" createVehicle _posToFireAt;
        _shell setPosATL _posToFireAt;
        _shell setVelocity [0,0,-50];  
        sleep 4;
    };
};

ITW_RadioSendMessage = {
    // call on each client
    params ["_sender","_message",["_playAudio",false]];
    [_sender, format ["%1<br /><br /><br /><br /><br /><br />",_message]] call BIS_fnc_showSubtitle;
    
    if (_playAudio && (getSubtitleOptions select 0)) then {
        _radioArray = [		
            "RadioAmbient2",
            "RadioAmbient6",
            "RadioAmbient8"
        ];
        0 fadeSpeech 1;
        playSound [selectRandom _radioArray, true];
    };
};

ITW_RadioPlayMessage = {
    params ["_sentence"];
	private _speaker = west call bis_fnc_moduleHQ;
	if (isnull _speaker) then { isNil {_speaker = (createGroup west) createunit ["ModuleHQ_F",[10,10,10],[],0,"none"]}};
	_speaker setspeaker speaker _speaker;
	_speaker setpitch 1;
	_speaker setbehaviour behaviour _speaker;
	_speaker globalradio _sentence;
};

["ITW_RadioInit"] call SKL_fnc_CompileFinal;
["ITW_RadioHeliCheck"] call SKL_fnc_CompileFinal;
["ITW_RadioFastTravel"] call SKL_fnc_CompileFinal;
["ITW_RadioVehicleDrop"] call SKL_fnc_CompileFinal;
["ITW_RadioHeliTransport"] call SKL_fnc_CompileFinal;
["ITW_RadioChooseOnMap"] call SKL_fnc_CompileFinal;
["ITW_RadioSupplyDrop"] call SKL_fnc_CompileFinal;
["ITW_RadioFlareDrop"] call SKL_fnc_CompileFinal;
["ITW_RadioLeaderAuthorize"] call SKL_fnc_CompileFinal;
["ITW_RadioLeaderRelinquish"] call SKL_fnc_CompileFinal;
["ITW_RadioLeaderProcess"] call SKL_fnc_CompileFinal;
["ITW_RadioFlareMP"] call SKL_fnc_CompileFinal;
["ITW_RadioLeaderRequest"] call SKL_fnc_CompileFinal;
["ITW_RadioShowFriendlies"] call SKL_fnc_CompileFinal;
["ITW_RadioSupplyDropMoveMP"] call SKL_fnc_CompileFinal;
["ITW_RadioLifeSignScan"] call SKL_fnc_CompileFinal;
["ITW_RadioSquadMenu"] call SKL_fnc_CompileFinal;
["ITW_RadioSquadJoin"] call SKL_fnc_CompileFinal;
["ITW_RadioSquadMerge"] call SKL_fnc_CompileFinal;
["ITW_RadioCasPlane"] call SKL_fnc_CompileFinal;
["ITW_RadioCasHeli"] call SKL_fnc_CompileFinal;
["ITW_RadioMortar"] call SKL_fnc_CompileFinal;
["ITW_RadioSendMessage"] call SKL_fnc_CompileFinal;
["ITW_RadioPlayMessage"] call SKL_fnc_CompileFinal;
["ITW_RadioCommsMenu"] call SKL_fnc_CompileFinal;
["ITW_RadioTeammateMenu"] call SKL_fnc_CompileFinal;
["ITW_RadioTruckTransport"] call SKL_fnc_CompileFinal;
["ITW_RadioCasServer"] call SKL_fnc_CompileFinal;
