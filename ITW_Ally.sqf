
#include "defines.hpp"
#include "defines_gui.hpp"

#define ALLY_DEBUG(msg1,msg2,msg3) //if (true) then {diag_log format ["ITW: Ally: %1 %2 %3",msg1,msg2,msg3]} 
#define PLAYER_SIDE west

ITW_AllyGroups = [];
ITW_AllyAssignmentWeights = [];
ITW_AllyAttackVectorsBusy = false;
ITW_AllyPriority = []; // [obj1Pri, obj2Pri, ...]
ITW_AllyReassignTime = -1;

ITW_AllyInit = {
    waitUntil {! isNil "VEHICLE_ARRAYS_COMPLETE"};
    private _isFriendly = true;
    private _factions = ITW_PlayerFaction;
    private _variablesArray = [300,25]; // [_reloadRocketsGrenadesTime,_onFootTeleportChance]
    
    // zonesOwned goes from 0 to # of zones minus 1.  So players start at 0, enemies end at 0 (unless ITW_ParamVehicleEscalation=1 then player and enemy are the same).
    private _zoneCnt = count ITW_Zones - 1;
    private _1st = 1 min _zoneCnt;
    private _2nd = 2 min _zoneCnt;
    private _3rd = 3 min _zoneCnt;
    private _4th = 4 min _zoneCnt;
    
    if (ITW_ParamVehicleEscalation == 0) then {
        _1st = 0; 
        _2nd = 0; 
        _3rd = 0; 
        _4th = 0; 
    };
    
    // We require the vehicle arrays to be filled.  This is to balance the vehicle spawning.
    // For instance, if a faction only has 1 vehicle, the tickets will keep it from being spawned very often, and almost no vehicles will spawn
    private _ensure = {
        params ["_array","_fallbacks"];
        {
            if !(_array isEqualTo []) exitWith {};
            _array = _x;
        } count _fallbacks;
        _array
    };
    private _pd = [va_pPlaneClassesDual     ,[va_pHeliClassesDual,va_pPlaneClassesTransport,va_pHeliClassesTransport]] call _ensure;
    private _pa = [va_pPlaneClassesAttack   ,[va_pPlaneClassesDual,va_pHeliClassesAttack,va_pHeliClassesDual]] call _ensure;
    private _pt = [va_pPlaneClassesTransport,[va_cPlaneClassesTransport,va_pHeliClassesTransport,va_cHeliClassesTransport]] call _ensure;
    
    private _hd = [va_pHeliClassesDual      ,[va_pPlaneClassesDual,va_pHeliClassesTransport,va_pPlaneClassesTransport]] call _ensure;
    private _ha = [va_pHeliClassesAttack    ,[va_pHeliClassesDual,va_pPlaneClassesAttack,va_pPlaneClassesDual]] call _ensure;
    private _ht = [va_pHeliClassesTransport ,[va_cHeliClassesTransport,va_pPlaneClassesTransport,va_cPlaneClassesTransport]] call _ensure;
      
    private _td = [va_pTankClassesDual      ,[va_pApcClassesDual,va_pTankClassesTransport]] call _ensure;
    private _ta = [va_pTankClassesAttack    ,[va_pTankClassesDual,va_pApcClassesAttack,va_pApcClassesDual,va_pApcClassesTransport]] call _ensure;
    private _tt = [va_pTankClassesTransport ,[va_pApcClassesTransport,va_pHeliClassesTransport,va_pPlaneClassesTransport]] call _ensure;
      
    private _ad = [va_pApcClassesDual       ,[va_pCarClassesDual,va_pApcClassesTransport,va_pTankClassesDual,va_pCarClassesTransport]] call _ensure;
    private _aa = [va_pApcClassesAttack     ,[va_pApcClassesDual,va_pTankClassesDual,va_pTankClassesAttack,va_pCarClassesDual,va_pCarClassesAttack]] call _ensure;
    private _at = [va_pApcClassesTransport  ,[va_pHeliClassesTransport,va_pPlaneClassesTransport,va_pCarClassesTransport,va_cCarClassesTransport,va_cHeliClassesTransport,va_cPlaneClassesTransport]] call _ensure;
      
    private _cd = [va_pCarClassesDual       ,[va_pApcClassesDual,va_pCarClassesTransport]] call _ensure;
    private _ca = [va_pCarClassesAttack     ,[va_pCarClassesDual,va_pApcClassesAttack,va_pCarClassesTransport]] call _ensure;
    private _ct = [va_pCarClassesTransport  ,[va_cCarClassesTransport,va_pApcClassesTransport,va_pHeliClassesTransport,va_cHeliClassesTransport,va_cPlaneClassesTransport,va_pTankClassesTransport,va_pPlaneClassesTransport,va_pApcClassesTransport]] call _ensure;
      
    private _sd = va_pShipClassesDual;
    private _sa = va_pShipClassesAttack;
    private _st = [va_pShipClassesTransport ,[va_cShipClassesTransport]] call _ensure;
    
    // the tickets will scale with ITW_ParamEnemyAiCnt                                           zones tickets  tickets                veh     is
    private _vehArray = []; // array of              type                  role                  owned required current  allowed count classes friendly
    if !(_pa isEqualTo []) then {_vehArray pushBack [ITW_TYPE_VEH_AIRPLANE,ITW_VEH_ROLE_ATTACK   ,_3rd, 40,     random 43,   2,   0,   _pa,    true]};
    if !(_pd isEqualTo []) then {_vehArray pushBack [ITW_TYPE_VEH_AIRPLANE,ITW_VEH_ROLE_DUAL     ,_3rd, 38,     random 40,   2,   0,   _pd,    true]};
    if !(_pt isEqualTo []) then {_vehArray pushBack [ITW_TYPE_VEH_AIRPLANE,ITW_VEH_ROLE_TRANSPORT,_1st, 12,     random 15,   3,   0,   _pt,    true]};
                                                                                                                                               
    if !(_ha isEqualTo []) then {_vehArray pushBack [ITW_TYPE_VEH_HELI    ,ITW_VEH_ROLE_ATTACK   ,_2nd, 42,     random 42,   2,   0,   _ha,    true]};
    if !(_hd isEqualTo []) then {_vehArray pushBack [ITW_TYPE_VEH_HELI    ,ITW_VEH_ROLE_DUAL     ,_3rd, 39,     random 39,   2,   0,   _hd,    true]};
    if !(_ht isEqualTo []) then {_vehArray pushBack [ITW_TYPE_VEH_HELI    ,ITW_VEH_ROLE_TRANSPORT,   0,  2,   2+random  3,   8,   0,   _ht,    true]};
                                                                                                                                               
    if !(_ta isEqualTo []) then {_vehArray pushBack [ITW_TYPE_VEH_TANK    ,ITW_VEH_ROLE_ATTACK   ,_2nd, 30,     random 30,   4,   0,   _ta,    true]};
    if !(_td isEqualTo []) then {_vehArray pushBack [ITW_TYPE_VEH_TANK    ,ITW_VEH_ROLE_DUAL     ,_2nd, 36,     random 41,   4,   0,   _td,    true]};
    if !(_tt isEqualTo []) then {_vehArray pushBack [ITW_TYPE_VEH_TANK    ,ITW_VEH_ROLE_TRANSPORT,_2nd, 10,     random 10,  10,   0,   _tt,    true]};
                                                                                                                                               
    if !(_aa isEqualTo []) then {_vehArray pushBack [ITW_TYPE_VEH_APC     ,ITW_VEH_ROLE_ATTACK   ,_1st, 16,     random 16,   5,   0,   _aa,    true]};
    if !(_ad isEqualTo []) then {_vehArray pushBack [ITW_TYPE_VEH_APC     ,ITW_VEH_ROLE_DUAL     ,_1st, 20,     random 20,   5,   0,   _ad,    true]};
    if !(_at isEqualTo []) then {_vehArray pushBack [ITW_TYPE_VEH_APC     ,ITW_VEH_ROLE_TRANSPORT,_1st,  9,     random  9,  13,   0,   _at,    true]};
                                                                                                                                               
    if !(_ca isEqualTo []) then {_vehArray pushBack [ITW_TYPE_VEH_CAR     ,ITW_VEH_ROLE_ATTACK   ,   0,  4,     10       ,   7,   0,   _ca,    true]};
    if !(_cd isEqualTo []) then {_vehArray pushBack [ITW_TYPE_VEH_CAR     ,ITW_VEH_ROLE_DUAL     ,   0,  6,     12       ,   7,   0,   _cd,    true]};
    if !(_ct isEqualTo []) then {_vehArray pushBack [ITW_TYPE_VEH_CAR     ,ITW_VEH_ROLE_TRANSPORT,   0,  1,     10       ,  99,   0,   _ct,    true]};
                                                                                                                                               
    if !(_sa isEqualTo []) then {_vehArray pushBack [ITW_TYPE_VEH_SHIP    ,ITW_VEH_ROLE_ATTACK   ,   0, 12,     random 10,   7,   0,   _sa,    true]};
    if !(_sd isEqualTo []) then {_vehArray pushBack [ITW_TYPE_VEH_SHIP    ,ITW_VEH_ROLE_DUAL     ,   0, 15,     random 20,   7,   0,   _sd,    true]};
    if !(_st isEqualTo []) then {_vehArray pushBack [ITW_TYPE_VEH_SHIP    ,ITW_VEH_ROLE_TRANSPORT,   0,  1,     10       ,  99,   0,   _st,    true]};
    
    [_isFriendly,_factions,_vehArray,_variablesArray,ITW_AllyAttackVectors,ITW_AllyGroupCallback] spawn ITW_AtkManager; 
    
    //ITW_AllyVehArray = _vehArray; // use for debugging
    
    0 spawn ITW_AllyLoadIntoVehManager;
    
    // manage HC role = [];
    0 spawn {
        scriptName "ITW_AllyHcManager";
        private _currentHCs = [];
        while {true} do {
            if !(_currentHCs isEqualTo ITW_HcCmdr) then {
                {
                    private _hc = _x;
                    if !(_hc in ITW_HcCmdr) then {
                        hcRemoveAllGroups _hc;
                    };
                } forEach _currentHCs;
                {
                    private _hc = _x;
                    if !(_hc in _currentHCs) then {
                        {
                            private _grp = _x;
                            _hc hcSetGroup [_grp];
                        } count ITW_AllyGroups;
                    };
                } forEach ITW_HcCmdr;
                _currentHCs = +ITW_HcCmdr;
                ITW_Hc setVariable ["commanders", ITW_HcCmdr, true];
            };
            sleep 5;
        };
    };
};

ITW_AllyGroupCallback = {
    params ["_group"];
    ITW_AllyGroups pushBack _group; // add to groups able to revive players
    {_x hcSetGroup [_group]} forEach ITW_HcCmdr;
    
    // we want to make ITW_AllyGroups public, but it only needs to be updated slowly to keep from pushing lots
    // of changes over the network
    if (isNil "ITW_AGVarUpdateRunning") then {ITW_AGVarUpdateRunning = false};
    isNil {
        if (!ITW_AGVarUpdateRunning) then {
            ITW_AGVarUpdateRunning = true;
            0 spawn {
                scriptName "ITW_AGVarUpdate";
                sleep 5;
                ITW_AGVarUpdateRunning = false;
                publicVariable "ITW_AllyGroups";
            };
        };
    };
};

ITW_AllyAttackVectors = {
    // _type is AV_VEHICLE or AV_INFANTRY
    // returns [_objectiveToAttack,_baseAttackingFrom]
    params ["_type",["_group",objNull],["_cargoGroups",[]]];
    
    // only let one thread run this routine at a time
    SEM_LOCK(ITW_AllyAttackVectorsBusy);
    
    private _objIndexes = ITW_Zones#ITW_ZoneIndex;
    
    // Initializations
    if (ITW_AllyAssignmentWeights isEqualTo []) then {
        private _cntZones = count _objIndexes;
        private _empty = [];
        _empty resize [_cntZones,1/_cntZones]; // default to equal units to all contested objectives
        ITW_AllyAssignmentWeights = _empty;
    };
    
    private _atkType = ITW_ATTACK_LAND_F;
    if (_type == AV_VEHICLE) then {
        private _veh = vehicle (leader _group);
        if (_veh isKindOf "Air") then {_atkType = ITW_ATTACK_AIR_F};
        if (_veh isKindOf "Ship") then {_atkType = ITW_ATTACK_SEA_F};
    };
    
    // create array of under/over staffing for each objective
    private _assignments = (0 call ITW_AllyGetAssignedGroups)#AG_COUNTS;
    private _asnGoals = ITW_AllyAssignmentWeights;
    
    // get the total number of units assigned so far
    private _totalAssigned = 0;
    {_totalAssigned = _totalAssigned + _x} count _assignments;
    _totalAssigned = 1 max _totalAssigned; // make sure it's not zero

    private _deltas = []; // how far the obj is from being staffed (negative = overstaffed, value is % under/over staffed)
    {_deltas pushBack ((_asnGoals#_forEachIndex) - (_x/_totalAssigned))} forEach _assignments;

    // find most understaffed objective
    private _objIndex = _objIndexes#0;
    private _deltaMax = -1;  
    {
        private _objIdx = _x;
        private _delta = _deltas#_forEachIndex;
        if (_atkType == ITW_ATTACK_SEA_F) then {
            // if ship, skip objs w/o water access
            private _seaPts = ITW_SeaPoints#_objIdx;
            if (_seaPts isEqualTo []) then {_delta = -100};
        };
        if (_delta > _deltaMax) then {
            _objIndex = _objIdx;
            _deltaMax = _delta;
        };
    } forEach _objIndexes;
    
    VAR_SET_OBJ_IDX(_group,_objIndex);
    _cargoGroups apply {VAR_SET_OBJ_IDX(_x,_objIndex)};
    
    private _objTo = ITW_Objectives#_objIndex;
    
    SEM_UNLOCK(ITW_AllyAttackVectorsBusy);
    while {_objTo#ITW_OBJ_ATTACKS isEqualTo []} do {sleep 1};
    private _baseFromIdx = _objTo#ITW_OBJ_ATTACKS#_atkType;
    
    // if no route, just use the air route
    if (_baseFromIdx == -1) then {_baseFromIdx = _objTo#ITW_OBJ_ATTACKS#ITW_ATTACK_AIR_F};

    [_objTo,_baseFromIdx]
};
    
ITW_AllyReassign = {
    params ["_priorities"];
    // call on server - check if correct number of units assigned to each objective and update as needed
    while {ITW_ObjZonesUpdating} do {sleep 0.5};
    
    _priorities call ITW_AllyCalculateWeights;
    
    // we want to wait a bit before re-assigning in case user changes assignments again
    private _timeout = 15;
    if (ITW_AllyReassignTime > 0) exitWith {ITW_AllyReassignTime = time + _timeout};
    ITW_AllyReassignTime = time + _timeout;    
    waitUntil {sleep 2;time > ITW_AllyReassignTime};
    
    private _assignments = 0 call ITW_AllyGetAssignedGroups;
    
    // create array of under/over staffing for each objective
    private _assignmentCounts = _assignments#AG_COUNTS;
    private _assignedGroups = _assignments#AG_GROUPS;
    private _asnGoals = ITW_AllyAssignmentWeights;
    
    // get the total number of units assigned so far
    private _totalAssigned = 0;
    {_totalAssigned = _totalAssigned + _x} count _assignmentCounts;
    _totalAssigned = 1 max _totalAssigned; // make sure it's not zero

    private _deltaUnits = []; // how far the obj is from being staffed (negative = overstaffed, value is #units under/over staffed)
    {_deltaUnits pushBack (_totalAssigned * ((_asnGoals#_forEachIndex) - (_x/_totalAssigned)))} forEach _assignmentCounts;

    // search through overstaffed objectives and remove groups to get the count down closer to desired staffing
    private _objectives = ITW_Zones#ITW_ZoneIndex;
    {
        private _overstaff = -_x;
        if (_overstaff > 0) then {
            private _index = _forEachIndex;
            private _objIdx = _objectives#_index;
            _groups = _assignedGroups#_index;
            private _found = true;
            while {_found} do {
                {
                    private _group = _x;
                    private _unitCnt = {alive _x} count units _group;
                    if (_unitCnt <= _overstaff) exitWith {
                        // reassign group
                        _found = true;
                        _groups deleteAt _forEachIndex;
                        VAR_SET_OBJ_IDX(_group,-1);
                    };
                } forEach _groups;
            } 
        };
    } forEach _deltaUnits;
};

ITW_AllyGetAssignedGroups = {
    // returns array of groups assigned to each current objective and counts (in same order as ITW_Zones#ITW_ZoneIndex)
    // result#AG_GROUPS is groups, result#AG_COUNTS is counts
    // ex: vehGroups = _result#AG_GROUPS#_zoneObjIdx)
    // ex: infCount  = _result#AG_COUNTS#_zoneObjIdx)
    private _objectives = ITW_Zones#ITW_ZoneIndex;
    private _objCount = count _objectives;
    private _assignedGroups = [];
    _assignedGroups resize [_objCount,[]];
    {
        private _group = _x;
        if ({ALIVE(_x) && {_x isKindOf "CAManBase"}} count units _group < 1) then {continue};
        private _leader = leader _group;
        private _assignment = VAR_GET_OBJ_IDX(_group);
        if (_assignment >= 0) then {
            private _idx = _objectives find _assignment;
            if (_idx >= 0) then { 
                (_assignedGroups#_idx) pushBack _group;
            };
        };
        false
    } count groups PLAYER_SIDE;
    
    private _counts = [];
    _counts resize [_objCount,0];
    {
        private _objGroups = _x;
        private _objIdx = _forEachIndex;
        private _cnt = 0;
        {
            private _grp = _x;
            _cnt = _cnt  + (count units _grp);
        } count _objGroups;
        _counts set [_objIdx,_cnt];
    } forEach _assignedGroups;  
    [_assignedGroups,_counts]
};

ITW_AllyCalculateWeights = {
    // call on server - reset the assignment weights based on priorities
    private _priorities = _this;
    private _sum = 0;
    {_sum = _sum + _x} count _priorities;
    private _values = _priorities apply {_x/_sum};
    ITW_AllyAssignmentWeights = _values;
    ITW_AllyPriority = _priorities;
    publicVariable "ITW_AllyPriority";
};

ITW_AllyNext = {
    SEM_LOCK(ITW_AllyAttackVectorsBusy);
    private _objectives = ITW_Zones#ITW_ZoneIndex;
    private _priorities = [];
    _priorities resize [count _objectives,3];
    _priorities call ITW_AllyCalculateWeights;
    SEM_UNLOCK(ITW_AllyAttackVectorsBusy);
};

ITW_AllyDismiss = {
    params ["_player"];        
    private _grp = group _player;
    private _units = units _grp select {ALIVE(_x) && !(isPlayer _x)};
    private _cnt = count _units;
    
    
    private _teammates = units group player select {!isPlayer _x};
    if (count _teammates == 0) exitWith {hint "No teammates available"};
    private _unitIdx = 0;
    if (count _teammates > 1) then {
        ITW_TA_Index = -1;
        private _menu = [["Select Teammate", false]];
        {
            _menu pushBack [name _x,[_forEachIndex+3], "", -5, [["expression",format ["ITW_TA_Index = %1;",_forEachIndex]]], "1", "1"];
        } forEach _teammates;
        showCommandingMenu "#USER:_menu";
        waitUntil {commandingMenu == ""};
        _unitIdx = ITW_TA_Index;
    };
    if (_unitIdx < 0) exitWith {};
    
    private _unit = _teammates#_unitIdx;
    if (vehicle _unit == _unit) then {
        deleteVehicle _unit;
    } else {
        vehicle _unit deleteVehicleCrew _unit;
    };
};

ITW_AllyRecruit = {
    // call on server
    params ["_player",["_loadout",[]]];
    if (!isServer) exitWith {diag_log "Error pos ITW_AllyRecruit called from client"};
    private _grp = group _player;
    waitUntil {!isNil "ITW_AllyUnitTypes"};
    private _unit = [_grp, ITW_AllyUnitTypes, getPosATL _player, true] call ITW_AtkUnitToGroup;
    if !(_loadout isEqualTo []) then {[_unit,_loadout] call ITW_FncSetUnitLoadout};
    [_unit] remoteExec ["ITW_TeammateCreated",0,_unit];
};

ITW_AllyRecall = {
    // call on server
    params ["_name"];
    {
        private _group = _x;            
        if (str _group isEqualTo _name) then {
            private _vehicles = [];
            {
                private _unit = _x;
                private _veh = vehicle _unit;
                if (_veh == _unit) then {
                    deleteVehicle _unit;
                } else {
                    _veh deleteVehicleCrew _unit;
                    _vehicles pushBackUnique _veh;
                };
            } forEach units _group;
            {
                private _veh = _x;
                if ({alive _x} count crew _veh == 0) then {deleteVehicle _veh};
            } forEach _vehicles;
        };
    } forEach ITW_AllyGroups;
};

ITW_HcCmdr = []; 
ITW_AllyHighCmdr = {
    // call on server    
    params ["_player","_enable"];
    if (_enable) then {
        ITW_HcCmdr pushBackUnique _player;
    } else {
        ITW_HcCmdr = ITW_HcCmdr - [_player];
    };
    publicVariable "ITW_HcCmdr";
}; 

ITW_AllyHcRespawn = {
    // call on server when a unit respawns
    params ["_unit","_corpse"];
    if (_corpse in ITW_HcCmdr) then {
        ITW_HcCmdr = ITW_HcCmdr - [_corpse];
        ITW_HcCmdr pushBackUnique _unit;
    };
    publicVariable "ITW_HcCmdr";
};

ITW_AllyLoadIntoVehManager = {
    // spawn on server
    scriptName "ITW_AllyLoadIntoVehManager";
    while {!ITW_GameOver} do {
        {
            private _veh = _x;
            if (side currentPilot _veh != PLAYER_SIDE) then {continue};
            if (speed _veh > 5) then {continue};
            private _vPos = getPosATL _veh;
            private _isWater = surfaceIsWater _vPos;
            if (_isWater && {_vPos#2 > 4.5}) then {continue};
            if (!_isWater && {_vPos#2 > 2}) then {continue};
            if (!canMove _veh || {fuel _veh == 0}) then {continue};      
            if (isPlayer currentPilot _veh && {_veh getVariable ["ITW_BlockAllyEntry",false]}) then {continue};
            if !(_veh getVariable ["ITW_reservedGroups",[]] isEqualTo []) then {continue};
            
            private _emptySeats = 
                    if (_veh getVariable ['ITW_BlockAllyCrew',true]) then {
                        {isNull (_x#5) && {_x#2 >= 0}} count fullCrew [_veh,"",true]; 
                    } else {
                        {isNull (_x#5) && {_x#2 >= 0 || {!(_x#3 isEqualTo [])}}} count fullCrew [_veh,"",true]; 
                    };
            if (_emptySeats == 0) then {continue};

            if (isPlayer currentPilot _veh && {speed _veh > 6 && {_veh getVariable ["ITW_ForceAllyEntry",false] && {ITW_ELEVATION(_vPos) > 6}}}) then {
                _veh setVariable ["ITW_ForceAllyEntry",false,true];
            };

            private _objType = if (isPlayer currentPilot _veh && {_veh getVariable ["ITW_ForceAllyEntry",false]}) then {ITW_OWNER_ENEMY} else {ITW_OWNER_CONTESTED};
            private _closestObj = [_vPos, ITW_OWNER_CONTESTED, _objType] call ITW_ObjGetNearest;
            if (_closestObj#ITW_OBJ_POS distance _veh < 1000) then {continue};

            private _onFootAllies = ITW_AllyGroups select {
                    private _grp = _x;
                    private _leader = leader _grp;
                    !(_grp getVariable ["ITW_Garrison",false]) && 
                    {!(_grp getVariable ["itwInit",false]) && 
                    {vehicle _leader == _leader && 
                    {_leader distance _veh < 250 && 
                    {isNull getAttackTarget _leader && 
                    {!fleeing _leader && 
                    {_grp getVariable ["ITW_getInState",-1] == -1}}}}}}
                } apply {[leader _x distance _veh,_x]};
            if (_onFootAllies isEqualTo []) then {continue};
            
            _onFootAllies sort true;
            private _groupsToLoad = [];
            {
                private _grp = _x#1;
                private _grpSize = count units _grp;
                if (_grpSize <= _emptySeats) then {
                    _emptySeats = _emptySeats - _grpSize;
                    _groupsToLoad pushBack _grp;
                    VAR_SET_OBJ_IDX(_grp,_closestObj#ITW_OBJ_INDEX);
                    _grp setVariable ["ITW_getInState",0];
                    ITW_DELETE_WAYPOINTS(_grp);
                };
            } count _onFootAllies;
            if !(_groupsToLoad isEqualTo []) then {
                _veh setVariable ["ITW_reservedGroups",_groupsToLoad];
                [_veh,_groupsToLoad] spawn ITW_AllyLoadGrpIntoVeh;
            };
        } forEach vehicles;
        sleep 8;
        while {LV_PAUSE} do {sleep 5};
    };
};

ITW_AllyLoadGrpIntoVeh = {
    params ["_veh","_groupsToLoad"];

    private _grpCntInVeh = _veh getVariable ["ITW_groupCntActive",0];
    _veh setVariable ["ITW_groupCntActive",_grpCntInVeh + count _groupsToLoad];
    private _groupsInState1 = false;
    private _doGetOut = false;
    private _wrongBaseWarning = false;
    private _reportProgress = isPlayer currentPilot _veh;
    private _wrongWarningShown = false;
    
    while {_veh getVariable ["ITW_groupCntActive",0] > 0} do {
        
        if (_groupsInState1) then {
            // do some calculations once instead of doing it for each group
            private _check =  _veh getVariable ["ITW_BlockAllyEntry",false] ||
                             {(!canMove _veh) ||
                             {(fuel _veh == 0) ||
                             {isNull currentPilot _veh}}};
            private _distF = 1e5;
            private _distE = 1e5;                
            if (!_check) then {
                private _contestedObjs = [] call ITW_ObjGetContestedObjs;
                private _friendlyObjs = _contestedObjs select {
                                            private _flag = _x#ITW_OBJ_FLAG;                                          
                                            flagAnimationPhase _flag == 1 && {flagTexture _flag isEqualTo FLAG_PLAYER}
                                        };
                private _enemyObjs = _contestedObjs - _friendlyObjs;
                {private _d = _x#ITW_OBJ_POS distance _veh;if (_d < _distF) then {_distF = _d}} forEach _friendlyObjs;
                {private _d = _x#ITW_OBJ_POS distance _veh;if (_d < _distE) then {_distE = _d}} forEach _enemyObjs;
            };
            _doGetOut = _check || {_distE < TRANSPORT_DROP_MAX_DIST};
            _wrongBaseWarning = !(_doGetOut) && {_distF < TRANSPORT_DROP_MAX_DIST};  
            if (!_wrongBaseWarning) then {_wrongWarningShown = false};
        };
        
        {
            private _grp = _x;
            
            // Get in transport
            if (_grp getVariable ["ITW_getInState",-1] == 0) then {
                if (_reportProgress) then {
                    if !(_veh getVariable ["reported",false]) then {
                        _veh setVariable ["reported",true];
                        private _nearbyPlayers = allPlayers select {_veh distance _x < 20};
                        ["bStart",_veh] remoteExec ["ITW_AllyRadioMsg",_nearbyPlayers];
                    };
                    [leader _grp,"We're boarding your vehicle."] remoteExec ["sideChat",currentPilot _veh];
                };
                ITW_DELETE_WAYPOINTS(_grp);        
                                
                private _units = units _grp select {ALIVE(_x)};
                private _leader = leader _grp;
                private _vPos = getPosATL _veh;
                {
                    if (_x distance _leader > 200) then {_x setPosATL (getPosATL _leader)};
                    _x setDamage 0;
                    _x doMove _vPos;
                } forEach _units;
                {
                    [_x,_veh] call ITW_AllyOrderGetIn;
                } forEach _units;
                [_units,true] remoteExec ["orderGetIn",_leader];
                _grp setVariable ["ITW_ExitVehicle",false];
                
                // SPAWN ----------------------------------------------------------------------------------------
                [_grp,_veh,_reportProgress] spawn { 
                    params ["_grp","_veh","_reportProgress"];                              
                    private _players = allPlayers select {vehicle _x isEqualto _veh};
                    private _units = units _grp select {ALIVE(_x)};
                    private _leader = leader _grp;
                    private _timeout = time + 40;
                    [_grp,_timeout-time] remoteExec ["ITW_AllySpeedUp",0];
                    waitUntil { sleep 1;
                        private _vPos = getPosATL _veh;
                        private _ready = 
                            ITW_ELEVATION(_vPos) > 5 || 
                            {{ALIVE(_x) && vehicle _x == _x} count _units == 0 ||
                            {_veh getVariable ["ITW_BlockAllyEntry",false] ||
                            {_veh emptyPositions "Cargo" == 0 ||
                            {isNull currentPilot _veh ||
                            {(!canMove _veh) ||
                            {(fuel _veh == 0) ||
                            {_grp getVariable ["ITW_ExitVehicle",false]}}}}}}};
                        if (!_ready) then {
                            // player may have taken someone's seat
                            {
                                private _unit = _x;
                                if (isNull assignedVehicle _unit) then {
                                    [_unit,_veh] call ITW_AllyOrderGetIn;
                                };
                            } forEach _units;
                            if (time > _timeout) then {
                                playSound3D ["a3\sounds_f\vehicles\soft\mrap_01\getin.wss", _veh,true,_vPos,0.5];
                                private _fullCrew = fullCrew [_veh,"",true];
                                {
                                    private _unit = _x;
                                    if (vehicle _unit ==_unit) then {
                                        private _seatInfo = _fullCrew select {_x#5 == _unit};
                                        private _seat = if (_seatInfo isEqualTo []) then {""} else {if (_seatInfo#0#2 < 0) then {_seatInfo#0#3} else {_seatInfo#0#2}};
                                        switch (typeName _seat) do {
                                            case "SCALAR": {_unit moveInCargo  [_veh,_seat,true]; sleep 0.2};
                                            case "ARRAY":  {_unit moveInTurret [_veh,_seat,true]; sleep 0.2};
                                        };
                                    };
                                } forEach _units;
                                sleep 0.2;
                                {
                                    if (vehicle _x ==_x) then {
                                        [_x,_veh,true] call ITW_AllyOrderGetIn;
                                    };
                                } forEach _units;
                            };
                        };           
                        _ready
                    };                   
                    
                    private _success = true;
                    private _pilot = currentPilot _veh;
                    if (! isNull _pilot && 
                       {vehicle _leader == _veh && 
                       {!(_veh getVariable ["ITW_BlockAllyEntry",false]) &&
                       {!(_grp getVariable ["ITW_ExitVehicle",false])}}}) then {
                       if (isPlayer _pilot) then {
                            [format ["Deliver units to within %1m of an objective",TRANSPORT_DROP_MAX_DIST]] remoteExec ["hint",_pilot];
                        };
                        _veh setVariable ["ITW_pickupSuccess",true];
                        private _groups = _veh getVariable ["ITW_transportGroups",[]];
                        _groups = _groups + [_grp];
                        _veh setVariable ["ITW_transportGroups",_groups];
                    } else {
                        _success = false;
                        _grp leaveVehicle _veh;
                        _grp setVariable ["ITW_getInState",-1];
                        _leader doMove getPosATL _leader;
                        private _unitsNotFollowing = [];
                        {
                            if (_x != _leader) then {_unitsNotFollowing pushBack _x};
                        } forEach _units;
                        if !(_unitsNotFollowing isEqualTo []) then {[_unitsNotFollowing,_leader] remoteExec ["doFollow",_leader]};
                    };                                     
                    private _groups = _veh getVariable ["ITW_reservedGroups",[]];
                    _groups = _groups - [_grp];
                    if (_groups isEqualTo []) then {
                        if (_reportProgress && {_veh getVariable ["ITW_pickupSuccess",false]}) then {
                            private _nearbyPlayers = allPlayers select {_veh distance _x < 20};
                            ["bEnd",_veh] remoteExec ["ITW_AllyRadioMsg",_nearbyPlayers];
                            if (!isNull driver _veh) then {[leader _grp,"We're all in."] remoteExec ["sideChat",driver _veh]};
                        };
                        _veh setVariable ["ITW_pickupSuccess",nil];
                        _veh setVariable ["ITW_reservedGroups",nil];
                        _veh setVariable ["reported",nil];
                    } else {
                        _veh setVariable ["ITW_reservedGroups",_groups];
                    };
                    if (_success) then {
                        waitUntil {sleep 1; speed _veh > 3};
                        // tell any units that couldn't get in to continue to the objective  
                        {
                            if (vehicle _x == _x) then {
                                [_x,_veh,true] call ITW_AllyOrderGetIn;
                            };
                        } forEach _units;
                    } else {
                        {
                            [_x] remoteExec ["unassignVehicle",_x];
                        } forEach _units;
                        _veh setVariable ["ITW_groupCntActive",(_veh getVariable ["ITW_groupCntActive",0]) - 1];
                        _grp setVariable ["ITW_getInState",2];
                        _veh setVariable ["reported",nil];
                    };
                };
                // END -----------------------------------------------------------------------------------------
                _grp setVariable ["ITW_getInState",1];
                _groupsInState1 = true;
            };
        
            // Get out of transport
            if (_grp getVariable ["ITW_getInState",-1] == 1) then {
                private _vehPos = getPosATL _veh;
                if (!_wrongWarningShown && {_wrongBaseWarning && {ITW_ELEVATION(_vehPos) < 2 && {speed _veh < 5}}}) then {
                    _wrongWarningShown = true;
                    ["Nearest objective is already captured"] remoteExec ["hint",currentPilot _veh];
                };
                if (_doGetOut) then {
                    if (ITW_ELEVATION(_vehPos) < 2 && {speed _veh < 5}) then {
                        _grp setVariable ["ITW_ExitVehicle",true];
                        {
                            [_x] remoteExec ["unassignVehicle",_x];
                        } forEach units _grp;
                        private _units = units _grp;
                        private _leader = leader _grp;
                        [_units,false] remoteExec ["orderGetIn",_leader];
                        [_units,_leader] remoteExec ["doFollow",_leader];
                        // SPAWN -----------------------------------------------------------------------------------------
                        [_grp,_veh,_reportProgress] spawn {
                            params ["_grp","_veh","_reportProgress"];
                            if (_reportProgress) then {
                                if !(_veh getVariable ["reported",false]) then {
                                    _veh setVariable ["reported",true];
                                    private _nearbyPlayers = allPlayers select {_veh distance _x < 20};
                                    ["dStart",_veh] remoteExec ["ITW_AllyRadioMsg",_nearbyPlayers];
                                };
                            };
                            private _timeout = time + 15; 
                            waitUntil {sleep 3; {ALIVE(_x) && vehicle _x != _x} count units _grp == 0 || {time > _timeOut || {_vehPos = getPosATL _veh;ITW_ELEVATION(_vehPos) > 2}}};
                            {
                                moveOut _x;
                            } forEach units _grp;
                            private _groups = _veh getVariable ["ITW_transportGroups",[]];
                            _groups = _groups - [_grp];
                            _veh setVariable ["ITW_transportGroups",_groups];
                            if (_groups isEqualTo []) then {
                                {
                                    private _assignedUnit = _x#5;
                                    if (! isNull _assignedUnit && {vehicle _assignedUnit != _veh}) then {
                                        [_assignedUnit] remoteExec ["unassignVehicle",_assignedUnit];
                                    };
                                } forEach fullCrew [_veh,"",true];
                                if (_reportProgress && {canMove _veh && fuel _veh > 0}) then {
                                    private _nearbyPlayers = allPlayers select {_veh distance _x < 20};
                                    ["dEnd",_veh] remoteExec ["ITW_AllyRadioMsg",_nearbyPlayers];
                                    [leader _grp,"Everyone is out, you're good to go."] remoteExec ["sideChat",driver _veh];
                                };
                                // clear the vehicle transport variables just in case there's a hole in the logic somewhere
                                _veh setVariable ["ITW_pickupSuccess",nil];
                                _veh setVariable ["ITW_reservedGroups",nil];
                                _veh setVariable ["ITW_transportGroups",nil];
                                _veh setVariable ["reported",nil];
                            };
                            // tell them to get out again, sometimes a couple get back in
                            units _grp apply { _x leaveVehicle (assignedVehicle _x) };
                            // move the units away from the vehicle
                            private _toPos = _veh getPos [200,_veh getDir (([getPosATL _veh] call ITW_ObjGetNearest)#ITW_OBJ_POS)];
                            {_x doMove _toPos} forEach units _grp;
                        };
                        // END -----------------------------------------------------------------------------------------
                        _grp setVariable ["ITW_getInState",2];
                        _veh setVariable ["ITW_groupCntActive",(_veh getVariable ["ITW_groupCntActive",0]) - 1];
                        
                        if (_grp getVariable ["itwDelivery",false]) then {
                            private _curPos = getPosATL leader _grp;
                            private _pos = _grp getVariable ["itwDeliveryPos",_curPos];
                            if (_pos distance _curPos < 500) then {
                                [_grp] call ITW_AllyDelivery;
                            } else {
                                _grp setVariable ["itwDelivery",nil];
                                _grp setVariable ["itwDeliveryPos",nil];
                                ITW_DELETE_WAYPOINTS(_grp);                                
                            };
                        };
                    };
                };
            };
        } count _groupsToLoad;
        sleep 8;
    };
    
    private _closestObj = [getPosATL _veh, ITW_OWNER_CONTESTED, ITW_OWNER_ENEMY] call ITW_ObjGetNearest;
    {
        _x setVariable ["ITW_getInState",-1];
        VAR_SET_OBJ_IDX(_x,_closestObj#ITW_OBJ_INDEX);
    } count _groupsToLoad;
};

ITW_AllySpeedUp = {
    // run on all clients
    params ["_group","_timeout"];
    private _units = units _group;
    {
        _x setAnimSpeedCoef 1.5;
        if (local _x) then {
            _x setSpeedMode "FULL"; 
            _x setBehaviour "COMBAT"; 
        };
    } forEach _units;
    sleep _timeout;
    {
        _x setAnimSpeedCoef 1;
    } forEach _units;
};
    
ITW_AllyOrderGetIn = {
    params ["_unit","_veh",["_force",false]];  
    private _seats = fullCrew [_veh,"",true] select {_x#5 == _unit};
    if (_force && {!(_seats isEqualTo [])}) exitWith {
        private _seat = _seats#0;
        if (_seat#2 >= 0) then {
            _unit moveInCargo [_veh,_seat#2];
        } else {
            _unit moveInTurret [_veh,_seat#3];
        };
    };
    private _emptySeats = {isNull (_x#5) && {_x#2 >= 0}} count fullCrew [_veh,"",true];
    if (_emptySeats > 0) then {
        _unit assignAsCargo _veh; 
        if (_force) then {_unit moveInCargo _veh} else {[[_unit],true] remoteExec ["orderGetIn",_unit]};
    } else {
        if !(_veh getVariable ["ITW_BlockAllyCrew",true]) then {
            private _emptyTurrretSeats =  fullCrew [_veh,"",true] select {isNull (_x#5) && {!(_x#3 isEqualTo [])}};
            if !(_emptyTurrretSeats isEqualTo []) then {
                private _turret = (_emptyTurrretSeats select -1)#3;
                _unit assignAsTurret [_veh,_turret]; 
                if (_force) then {_unit moveInTurret [_veh,_turret]} else {[[_unit],true] remoteExec ["orderGetIn",_unit]};
            };           
        };
    };
};

ITW_AllyRadioMsg = {
    // call on clients
    params ["_msgType","_veh"]; // "bStart","bEnd","dEnd"
    if (!hasInterface) exitWith {};
    
    private _path = "\a3\dubbing_f_heli\";
    private "_msg";
    switch (_msgType) do {
        case "bStart": {
            _msg = selectRandom ["mp_groundsupport\05_BoardingStarted\mp_groundsupport_05_boardingstarted_IHQ_2.ogg",
                                 "mp_groundsupport\05_BoardingStarted\mp_groundsupport_05_boardingstarted_BHQ_0.ogg",
                                 "mp_groundsupport\05_BoardingStarted\mp_groundsupport_05_boardingstarted_BHQ_1.ogg",
                                 "mp_groundsupport\05_BoardingStarted\mp_groundsupport_05_boardingstarted_BHQ_2.ogg",
                                 "mp_groundsupport\05_BoardingStarted\mp_groundsupport_05_boardingstarted_IHQ_0.ogg",
                                 "mp_groundsupport\05_BoardingStarted\mp_groundsupport_05_boardingstarted_IHQ_1.ogg"];
        };
        case "bEnd": {
            _msg = selectRandom ["mp_groundsupport\10_BoardingEnded\mp_groundsupport_10_boardingended_IHQ_2.ogg",
                                 "mp_groundsupport\10_BoardingEnded\mp_groundsupport_10_boardingended_BHQ_0.ogg",
                                 "mp_groundsupport\10_BoardingEnded\mp_groundsupport_10_boardingended_BHQ_1.ogg",
                                 "mp_groundsupport\10_BoardingEnded\mp_groundsupport_10_boardingended_BHQ_2.ogg",
                                 "mp_groundsupport\10_BoardingEnded\mp_groundsupport_10_boardingended_IHQ_0.ogg",
                                 "mp_groundsupport\10_BoardingEnded\mp_groundsupport_10_boardingended_IHQ_1.ogg"];
        };
        case "dStart": {
            _msg = selectRandom ["showcase_slingloading\37_Landed\showcase_slingloading_37_landed_PIL_0.ogg"];
        };
        case "dEnd": {
            _msg = selectRandom ["mp_groundsupport\15_Disembarked\mp_groundsupport_15_disembarked_IHQ_2.ogg",
                                 "mp_groundsupport\15_Disembarked\mp_groundsupport_15_disembarked_BHQ_0.ogg",
                                 "mp_groundsupport\15_Disembarked\mp_groundsupport_15_disembarked_BHQ_1.ogg",
                                 "mp_groundsupport\15_Disembarked\mp_groundsupport_15_disembarked_BHQ_2.ogg",
                                 "mp_groundsupport\15_Disembarked\mp_groundsupport_15_disembarked_IHQ_0.ogg",
                                 "mp_groundsupport\15_Disembarked\mp_groundsupport_15_disembarked_IHQ_1.ogg"];
        };
    };
    if (! isNil "_msg") then {
        private _volume = 1;
        if (vehicle player != _veh) then {_volume = 0.5 - ((player distance _veh)/20)}; 
        playSoundUI [_path + _msg,_volume,1];
    };
};

ITW_AllyShowAssignmentsDisplay = {
    // spawn on client
    if (!hasInterface) exitWith {};
    scriptname "ITW_AllyShowAssignmentsDisplay";
    
    waitUntil {sleep 1;ITW_ZoneIndex > 0};
    
    createDialog 'RscItwAssignments';
    
    private _timeout = time + 5;
    private "_display";
    waitUntil {_display = findDisplay ITW_DISPLAY_ASSIGNMENTS_ID; !isNull _display || {time > _timeout}};
    if (isNull _display) exitWith {};
    
    _table = _display displayCtrl ITW_ASSIGNMENTS_TABLE_IDC;
    _header = ctAddHeader _table;
    _header#1 params ["_hdrBack","_hdrCol0","_hdrCol1","_hdrCol2","_hdrCol3","_hdrCol4","_hdrCol5","_hdrCloseBtn"];
    _hdrCol0 ctrlSetText "Objective Name";
    _hdrCol1 ctrlSetText "--";
    _hdrCol2 ctrlSetText " -";
    _hdrCol3 ctrlSetText "0";
    _hdrCol4 ctrlSetText " +";
    _hdrCol5 ctrlSetText "++";
    _hdrBack ctrlSetBackgroundColor [0,0,0,1];
    
    _hdrCloseBtn ctrlSetText "X";
    _hdrCloseBtn ctrlSetBackgroundColor [0,0,0,0.7];
    _hdrCloseBtn ctrlAddEventHandler ["ButtonClick",{closeDialog 1}];
    
    private _visibleMap = visibleMap;
    if (!_visibleMap) then {openMap true};
    
    private _objectives = ITW_Zones#ITW_ZoneIndex;
    private _azPriCnt = count _objectives;
    if (count ITW_AllyPriority != _azPriCnt) then {
        ITW_AllyPriority = [];
        ITW_AllyPriority resize [_azPriCnt,3];
    };
    ITW_AllyTempPriorities = +ITW_AllyPriority;
    ITW_AllyRowCBoxes = [];
    ITW_AllyCBoxesUpdating = true;
    
    {
        private _objIdx = _x;
        private _obj    = ITW_Objectives#_objIdx;
        private _objName     = _obj#ITW_OBJ_NAME;
        private _objCaptured = _objIdx call ITW_ObjContestedOwnerIsFriendly; 
        private _priority    = ITW_AllyTempPriorities param [_forEachIndex,3];
        
        _newRow = ctAddRow _table;
        _newRow#1 params ["_rowBack","_rowCol0","_rowCol1","_rowCol2","_rowCol3","_rowCol4","_rowCol5"];
        private _cboxes = [_rowCol1,_rowCol2,_rowCol3,_rowCol4,_rowCol5];
        ITW_AllyRowCBoxes pushBack _cboxes;
        _rowCol0 ctrlSetText _objName;
        {
            private _cbox = _x;
            _cbox cbSetChecked ((_priority-1) == _forEachIndex);
            _cbox ctrlAddEventHandler ["CheckedChanged", {
                    params ["_cb","_checked"];
                    if !(ITW_AllyCBoxesUpdating) then {;
                        ITW_AllyCBoxesUpdating = true;
                        if (_checked == 1) then {
                            {
                                private _cboxes = _x;
                                private _priority = _cboxes find _cb;
                                if (_priority >= 0) exitWith {
                                    private _row = _forEachIndex;
                                    _cboxes apply {_x cbSetChecked false}; // disable all cboxes in row
                                    ITW_AllyTempPriorities set [_row,_priority + 1];
                                };    
                            } forEach ITW_AllyRowCBoxes;
                        };
                        _cb cbSetChecked true;
                        ITW_AllyCBoxesUpdating = false;
                    };
            }];
        } forEach _cboxes;
        _rowBack ctrlSetBackgroundColor (if (_objCaptured) then {[0,0,0.5,1]} else {[0.5,0,0,1]});
    } forEach _objectives;
    ITW_AllyCBoxesUpdating = false;
      
    waitUntil {isNull _display};
    
    if (!_visibleMap) then {openMap false};
    
    if !(ITW_AllyTempPriorities isEqualTo ITW_AllyPriority) then {
        [ITW_AllyTempPriorities] remoteExec ["ITW_AllyReassign",2];
    };
};

ITW_AllyPlaceLandRouteMarker = {
    params ["_marker","_objIdx","_attakToObjIdx"];
    private _dir = random 360;
    if (_objIdx < 0) then {_objIdx = _attakToObjIdx;_dir = 0};
    private _objPos = ITW_Objectives#_objIdx#ITW_OBJ_POS;
    private _pos = _objPos getPos [200,_dir];
    _marker setMarkerPosLocal _pos;
};

ITW_AllyChooseLandRoutes = {
    ITW_LAND_ROUTE_RESET = false;
    ITW_LAND_MKR = "";
    ITW_LAND_MARKERS = []; // array of [marker,attackFromObjIdx,attackToObjIdx]
    if (ITW_ZoneIndex >= count ITW_Zones) exitWith {};
    private _objIds = ITW_Zones#ITW_ZoneIndex;
    private _objs = [];
    private _resetIndexes = [];
    private _zoneIndex = ITW_ZoneIndex;
    private _tooSoon = false;
    {
        private _objIdx = _x;
        private _obj = ITW_Objectives#_objIdx;
        private _letter = _obj#ITW_OBJ_NAME;
        private _attacks = _obj#ITW_OBJ_ATTACKS;
        if (_attacks isEqualTo []) exitWith {_tooSoon = true};
        private _attackFromIdx = if (_obj#ITW_OBJ_LAND_ATK#0) then {_obj#ITW_OBJ_ATTACKS#ITW_ATTACK_LAND_F} else {-1};
        _objs pushBack _obj;
        _resetIndexes pushBack _attackFromIdx;
        private _marker = createMarkerLocal ["landRoute"+str(_forEachIndex), [0,0]]; 
        _marker setMarkerTypeLocal "loc_BusStop";
        _marker setMarkerColorLocal "ColorBlue";
        _marker setMarkerTextLocal _letter;
        _marker setMarkerAlphaLocal 0.8;
        ITW_LAND_MARKERS pushBack [_marker,_attackFromIdx,_objIdx];
        [_marker,_attackFromIdx,_objIdx] call ITW_AllyPlaceLandRouteMarker;
    } forEach _objIds;
    if (_tooSoon) exitWith {hint "Feature unavailable.\nTry again later"}; // attack vectors are still being calculated
    ITW_LAND_MARKERS_RESET = +ITW_LAND_MARKERS;
    
    private _keyHandler = findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["KeyDown", 
        {
            params ["_displayorcontrol", "_key", "_shift", "_ctrl", "_alt"];
            private ["_return"];
            _return = false;
            // key 0x13 is R
            if (_key == 0x13 and !_alt and !_shift) then {
                ITW_LAND_ROUTE_RESET = true;
                ITW_LAND_MKR = "";
                {_x call ITW_AllyPlaceLandRouteMarker} forEach ITW_LAND_MARKERS_RESET;
                _return = true;
            };
            _return
        }];
    
    private _handlerDown = findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["MouseButtonDown", 
        {
            params ["_control", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];
            // 0 is left button
            if (!_alt and !_shift and !_ctrl and _button == 0) then {
                // Get marker near click location
                private _pos = (_control ctrlMapScreenToWorld [_xPos,_yPos]);
                private _minDist = 1e6; // 1000 squared
                private _closest = "";
                {
                    private _dist = (getMarkerPos (_x#0)) distanceSqr _pos;
                    if (_dist < _minDist) then {
                        _minDist = _dist;
                        _closest = _x#0;
                    };
                } forEach ITW_LAND_MARKERS;
                ITW_LAND_MKR = _closest; 
            };
            false
        }];
    private _handlerUp = findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["MouseButtonUp", 
        {
            params ["_control", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];
            // 0 is left button
            if (_button == 0 && {ITW_LAND_MKR != ""}) then {
                // Drop the marker
                private _mIdx = ITW_LAND_MARKERS findIf {_x#0 == ITW_LAND_MKR};
                if (_mIdx < 0) exitWith {};
                private _pos = (_control ctrlMapScreenToWorld [_xPos,_yPos]);
                private _nearestObj = [_pos,ITW_OWNER_FRIENDLY] call ITW_ObjGetNearest;
                private _nearestObjPos = _nearestObj#ITW_OBJ_POS;
                if (_pos distanceSqr _nearestObjPos < 1e6) then {
                    private _objIdx = _nearestObj#ITW_OBJ_INDEX;
                    ITW_LAND_MARKERS#_mIdx set [1,_objIdx];
                } else {
                    ITW_LAND_MARKERS#_mIdx set [1,-1];
                };
                (ITW_LAND_MARKERS#_mIdx) call ITW_AllyPlaceLandRouteMarker;
                ITW_LAND_MKR = ""; 
            };
            false
        }];    
    private _handlerMoving = findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["MouseMoving",
        {
            params ["_control", "_xPos", "_yPos", "_mouseOver"];
            if (ITW_LAND_MKR != "") then {
                ITW_LAND_MKR setMarkerPosLocal (_control ctrlMapScreenToWorld [_xPos,_yPos]);
            };
            false
        }];
        
    ITW_ShowFriendlyPaused = true;
    showMap true; 
    openMap true;
    waitUntil {visibleMap};
    mapAnimAdd [0, 1, [worldSize/2,worldSize/2]];
    mapAnimCommit;
    private _timeout = 0;
    while {visibleMap && {_zoneIndex == ITW_ZoneIndex}} do {
        if (time > _timeout) then {
            hintSilent "Drag car icons:\n-to base they should spawn from\n-away from base for 'no land route'\nPress R to reset\nESC when done";
            _timeout = time + 29;
        };
        sleep 1;
    };
    ITW_ShowFriendlyPaused = false;
    findDisplay 12 displayCtrl 51 ctrlRemoveEventHandler ["MouseButtonUp",_handlerUp];
    findDisplay 12 displayCtrl 51 ctrlRemoveEventHandler ["MouseButtonDown",_handlerDown];
    findDisplay 12 displayCtrl 51 ctrlRemoveEventHandler ["MouseMoving",_handlerMoving]; 
    findDisplay 12 displayCtrl 51 ctrlRemoveEventHandler ["KeyDown",_keyHandler]; 
    if (_zoneIndex == ITW_ZoneIndex) then {
        private _msg = "";
        private _updatedObjs = [];
        {      
            _x params ["_marker","_fromObjIdx","_toObjIdx"];
            private _origFromIdx = ITW_LAND_MARKERS_RESET#_forEachIndex#1;
            if (_fromObjIdx != _origFromIdx) then {
                // friendly land attack vector changed
                _updatedObjs pushBack [_toObjIdx,_fromObjIdx];
                _msg = _msg + (markerText _marker) + " updated\n";
            };
            deleteMarker _marker;
        } forEach ITW_LAND_MARKERS;
        if !(_updatedObjs isEqualTo []) then { 
            _updatedObjs remoteExec ["ITW_ObjLandAtkAdjust",2];
            hint _msg;
        } else {hint "No routes updated"};
    } else {
        hint "Operation Canceled\nZones was captured";
    };
};

ITW_AllyDelivery = {
    params ["_grp"];
    ITW_DELETE_WAYPOINTS(_grp);
    private _pos = ([getPosATL leader _grp] call ITW_BaseNearest)#ITW_BASE_POS;
    _grp setVariable ["itwDelivery",true];
    _grp setVariable ["itwDeliveryPos",_pos];
    private _wp1 = _grp addWaypoint [[_pos,100,0,60] call ITW_AtkWpPoint,10];
    _wp1 setWaypointBehaviour "SAFE";
    _wp1 setWaypointSpeed "LIMITED";
    _wp1 setWaypointCombatMode "YELLOW";
    _wp1 setWaypointType "MOVE";
    _wp1 setWaypointFormation selectRandom ["COLUMN","STAG COLUMN","DIAMOND"];
    _wp1 setWaypointStatements ["true",format ["
        if (isNil ""thisList"") exitWith {};
        private _grp = group this;
        [_grp,currentWaypoint _grp] setWaypointPosition [[%1,100,0,60] call ITW_AtkWpPoint,10]",_pos]];
    private _wp2 = _grp addWaypoint [_pos,0];
    _wp2 setWaypointType "CYCLE";
    _wp2 setWaypointCompletionRadius 150;
};

["ITW_AllyInit"] call SKL_fnc_CompileFinal;
["ITW_AllyGroupCallback"] call SKL_fnc_CompileFinal;
["ITW_AllyAttackVectors"] call SKL_fnc_CompileFinal;
["ITW_AllyReassign"] call SKL_fnc_CompileFinal;
["ITW_AllyGetAssignedGroups"] call SKL_fnc_CompileFinal;
["ITW_AllyCalculateWeights"] call SKL_fnc_CompileFinal;
["ITW_AllyNext"] call SKL_fnc_CompileFinal;
["ITW_AllyDismiss"] call SKL_fnc_CompileFinal;
["ITW_AllyRecruit"] call SKL_fnc_CompileFinal;
["ITW_AllyRecall"] call SKL_fnc_CompileFinal;
["ITW_AllyHighCmdr"] call SKL_fnc_CompileFinal;
["ITW_AllyHcRespawn"] call SKL_fnc_CompileFinal;
["ITW_AllyLoadIntoVehManager"] call SKL_fnc_CompileFinal;
["ITW_AllyLoadGrpIntoVeh"] call SKL_fnc_CompileFinal;
["ITW_AllySpeedUp"] call SKL_fnc_CompileFinal;
["ITW_AllyOrderGetIn"] call SKL_fnc_CompileFinal;
["ITW_AllyRadioMsg"] call SKL_fnc_CompileFinal;
["ITW_AllyShowAssignmentsDisplay"] call SKL_fnc_CompileFinal;
["ITW_AllyPlaceLandRouteMarker"] call SKL_fnc_CompileFinal;
["ITW_AllyChooseLandRoutes"] call SKL_fnc_CompileFinal;
["ITW_AllyDelivery"] call SKL_fnc_CompileFinal;
