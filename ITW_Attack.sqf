
#include "defines.hpp"
ITW_AtkVehicleManagerBusy = false;
ITW_AtkInfantryManagerBusy = false;
ITW_ManagedVehs     = [];
ITW_AtkVectors   = [{},{}];
ITW_AtkManagersStarted = false;
ITW_VehArrays = [];
ITW_VehArraysUpdating = false;
ITW_AllyIndex = -1; // used when triggering a new zone to wake up the ITW_AtkManagers
ITW_AirVehsDef = [[[],[],[]],[[],[],[]]]; // vehDefs for air vehicles allowed in this zone as array of [[friendly attack,dual,transport],[enemy attack,dual,transport]]
ITW_AtkStaticNeedsCrew = [[],[]];
#define WEAPONLESS_FACTIONS ["OPTRE_FC_COVENANT","HL_ZOMBIES","RYANZOMBIESFACTION","RYANZOMBIESFACTIONOPFOR","RYANZOMBIESFACTIONMODULE"] // units that are 'kindOf' these are not checked for weapons (UPPER CASE)
#define ATK_DEBUG(msg1,msg2,msg3)  //diag_log format ["ITW: %1 %2 %3",msg1,msg2,msg3]

ITW_AtkMgrDebug = {
    {
        _x params ["_type","_role","_zones","_ticketsReq","_tickets","_maxCnt","_count","_vehs","_isFriendly"];
        diag_log [
            if (_isFriendly) then {"Friend"}else{"Enemy "},
            ["Plane","Heli ","Tank ","APC  ","Car  ","Ship "] # (_type -10),
            ["Attack","Transp","Dual  ","DONE  "]     # (_role -20),
            "   Tickets",floor _tickets,_ticketsReq,
            "   Counts",_count,_maxCnt,
            "   VehTypes",count _vehs
        ];
    } forEach ITW_VehArrays;
};

ITW_AtkManager = {
    // spawn on server for friendly and enemy ai separately
    params ["_isFriendly","_factions","_vehArray","_variablesArray","_fnAttackVectors",["_fnGroupsCallback",{}]];
    scriptName "ITW_AtkManager" + (if (_isFriendly) then {"_player"} else {"_enemy"});
    
    private _whichSide = if (_isFriendly) then {ATTACK_FRIENDLY} else {ATTACK_ENEMY};
    
    // _variablesArray params ["_reloadRocketsGrenadesTime","_onFootTeleportChance"];
    ITW_VehArrays = ITW_VehArrays + _vehArray;
     
    // spawn the managers only once
    if (!ITW_AtkManagersStarted) then {
        ITW_AtkManagersStarted = true;
        0 spawn ITW_AtkInfantryManager;
        0 spawn ITW_AtkVehicleManager;
        0 spawn ITW_AtkStuckHandler;
    };
    ITW_AtkVectors set [_whichSide,_fnAttackVectors];
    
    private "_side";
    if (_isFriendly) then {
        _side = west;
    } else {
        _side = ITW_EnemySide;
    };
    private _fallback = if (_isFriendly) then {FACTION_UNIT_FALLBACK_SUBF_BLU} else {FACTION_UNIT_FALLBACK_SUBF_OPF};
    private _unitTypes =   [_factions,["SpecialOperative","Crewman"],true,call _fallback] call FactionUnits;
    private _crewTypes =   [_factions,["Crewman"],false,call FACTION_UNIT_FALLBACK_ROLE_REQ] call FactionUnits;
    private _missleTypes = [_factions,["MissileSpecialist"],false,call FACTION_UNIT_FALLBACK_ROLE_REQ] call FactionUnits;
    
    if (_crewTypes isEqualTo []) then {_crewTypes = _unitTypes};
    
    private _zoneCount = count ITW_Zones - 1; // -1 since no-one owns the contested zone
    private _deliveryUnits = if (_isFriendly) then {ITW_ParamFriendlySquadDelivery * AI_SQUAD_SIZE} else {0};
    
    private _groups = [];
    private _spawnGroup = grpNull;
    private _homeObj = ITW_Objectives#(if (_isFriendly) then {ITW_Zones#0#0} else {ITW_Zones#-1#0});
    private _homeBase = ITW_Bases#(_homeObj#ITW_OBJ_INDEX);
    private _homeSpawnPt = _homeBase#ITW_BASE_A_SPAWN;
    private _homeVehSpawnPt = _homeObj#ITW_OBJ_V_SPAWN;
    private _spawnRateSlow = ITW_ParamEnemyAiCnt * AI_SPAWN_RATE;
    private _spawnRateFast = _spawnRateSlow * 2;
    
    private _fnEnsureSpawn = {
        params ["_spawnPt","_obj"];
        if (_spawnPt isEqualTo []) then {
            private _begin = _obj#ITW_OBJ_POS;
            private _center = [worldSize/2,worldSize/2,0];
            private _dir = _begin getDir _center;
            private _dist = 100;
            private _pt = +_center;
            while {true} do {
                _dist = _dist + 20;
                _pt = _begin getPos [_dist,_dir];
                if (_pt distance2D _center < 200) exitWith {_pt = _center};
                if (_pt isFlatEmpty [5,-1,1.0,1,0,false,objNull] isEqualTo []) exitWith {};
            };
            // copy elements so that array is updated
            _spawnPt set [0,_pt#0];
            _spawnPt set [1,_pt#1];
            _spawnPt set [2,0];
            [_pt,20,[FLAG_TYPE]] remoteExec ["ITW_RemoveTerrainObjects",0,true];
        };
    };
    
    [_homeSpawnPt,_homeObj] call _fnEnsureSpawn;
    [_homeVehSpawnPt,_homeObj] call _fnEnsureSpawn;
    
    private _spawnTrigger = AI_SPAWN_TRIGGER - 2;
    private _prevVehSideAdj = -1;
    private ["_ticketsBase","_ticketsBasePlaneAttack","_ticketsBaseHeliAttack","_ticketsBaseTankAttack","_ticketsBaseApcAttack","_ticketsBaseCarAttack","_ticketsBaseShipAttack"];

    {
        private _role = _x#ITW_VEH_ROLE;
        private _type = _x#ITW_VEH_TYPE;
        private _oldMax = _x#ITW_VEH_MAX;
        private _typeAdj = switch (_type) do {
                case ITW_TYPE_VEH_AIRPLANE: {ITW_ParamAttackPlaneSpawnAdjustment};
                case ITW_TYPE_VEH_HELI:     {ITW_ParamAttackHeliSpawnAdjustment };
                case ITW_TYPE_VEH_TANK:     {ITW_ParamAttackTankSpawnAdjustment };
                case ITW_TYPE_VEH_APC:      {ITW_ParamAttackApcSpawnAdjustment  };
                case ITW_TYPE_VEH_CAR:      {ITW_ParamAttackCarSpawnAdjustment  };
                case ITW_TYPE_VEH_SHIP:     {ITW_ParamAttackShipSpawnAdjustment };
                default {1};
            };
        private _adjustment = ITW_ParamVehicleSpawnAdjustment * _typeAdj;
        private _newMax =  1 max round (_oldMax * ITW_ParamVehicleSpawnAdjustment);
        if (_isFriendly) then {
            _adjustment = _adjustment * ITW_ParamVehicleSideAdjustment;
            _newMax =  1 max round (_oldMax * ITW_ParamVehicleSideAdjustment);
        };
        if (_role in [ITW_VEH_ROLE_ATTACK,ITW_VEH_ROLE_DUAL]) then { 
            if (_adjustment <= 0) then { _newMax = 0} else {_newMax = 1 max round (_newMax * _adjustment)};
        } else { 
            if (_adjustment < 0) then {_newMax = 0};
        };
        _x set [ITW_VEH_MAX,_newMax];
    } count _vehArray;
    
    if (ITW_AllyIndex < 0) then {ITW_AllyIndex = ITW_ZoneIndex};
    
    while {!ITW_GameOver} do {
        while {ITW_ObjZonesUpdating} do {sleep 0.5};
        while {LV_PAUSE} do {sleep 5};
        private _zoneIndex = ITW_ZoneIndex;
        if (_zoneIndex >= count ITW_Zones) exitWith {};
        
        private _zonesOwned = if (_isFriendly || {ITW_ParamVehicleEscalation == 1}) then {_zoneIndex - 1} else {_zoneCount - _zoneIndex};        

        private _zoneLimtedCount = 0;
        private _transport = [];
        private _attackVeh = [];
        private _transportAir = [];
        private _attackVehAir = [];
        private _dualVehAir = [];
        private _ownsAirport = _isFriendly call ITW_ObjOwnsAirport;
        private _objsAttackableBySea = false;
        private _objectiveIds = ITW_Zones#_zoneIndex;
        
        // determine if any obj are able to be attacked by sea
        {
            if !(ITW_SeaPoints#(ITW_Objectives#_x#ITW_OBJ_INDEX) isEqualTo []) exitWith {_objsAttackableBySea = true};
        } forEach _objectiveIds;
        
        {
            private _vehDef = _x;
            if (_vehDef#ITW_VEH_ZONES_OWNED <= _zonesOwned) then {
                if (_vehDef#ITW_VEH_TYPE==ITW_TYPE_VEH_AIRPLANE && {!_ownsAirport}) then {
                    continue; // cannot use plane without airport
                };
                if (ITW_VEH_IS_SEA(_vehDef#ITW_VEH_TYPE) && {!_objsAttackableBySea}) then {
                    continue; // cannot use ship if ships can't reach objectives
                };
                if (_vehDef#ITW_VEH_ROLE==ITW_VEH_ROLE_TRANSPORT) then {
                    _transport pushback _vehDef;
                    if (ITW_VEH_IS_AIR(_vehDef#ITW_VEH_TYPE)) then {_transportAir pushback _vehDef};
                } else {
                    _attackVeh pushBack _vehDef;
                    if (ITW_VEH_IS_AIR(_vehDef#ITW_VEH_TYPE)) then {
                        if (_vehDef#ITW_VEH_ROLE==ITW_VEH_ROLE_ATTACK) then {_attackVehAir pushback _vehDef} else {_dualVehAir pushback _vehDef};
                    };
                };
            } else {
                if (ITW_ParamVehicleEscalation == 2) then {_zoneLimtedCount = _zoneLimtedCount + 1};
            };
            false
        } count _vehArray;
      
        ITW_AirVehsDef set [_whichSide,[_attackVehAir,_dualVehAir,_transportAir]];
        
        private _ownedObjCnt = {_isFriendly == _x call ITW_ObjContestedOwnerIsFriendly} count (ITW_Zones#_zoneIndex);
        private _populateObjectives = _ownedObjCnt > 0; // we have captured objectives to populate
        private _populateSquadCnt = 3; // populate zones owned at the start with this many squads if available
        
        if (!_isFriendly && {_zoneIndex == (count ITW_Zones - 1)}) then {
            // for last zone, enemy spawn out to sea
            _homeObj = ITW_Objectives#-1;
            _homeBase = ITW_Bases#-1;
            _homeSpawnPt = _homeBase#ITW_BASE_A_SPAWN;
            _homeVehSpawnPt = _homeObj#ITW_OBJ_V_SPAWN;
            [_homeSpawnPt,_homeObj] call _fnEnsureSpawn;
            [_homeVehSpawnPt,_homeObj] call _fnEnsureSpawn;
        };
        
        while {_zoneIndex == ITW_ZoneIndex} do {
            if !((ITW_AtkStaticNeedsCrew#_whichSide) isEqualTo []) then {
                private _statics = ITW_AtkStaticNeedsCrew#_whichSide;
                ITW_AtkStaticNeedsCrew set [_whichSide,[]];
                private _units = [];
                {
                    private _veh = _x;
                    private _group = createGroup [_side,false];         
                    for "_i" from 1 to (_veh emptyPositions "") do {               
                        private _unit = [_group,_unitTypes,_homeSpawnPt,false] call ITW_AtkUnitToGroup; 
                        _unit moveInAny _veh;
                        _units pushBack _unit;
                    };
                    _group deleteGroupWhenEmpty true;
                    [_group,[],false] call ITW_AtkAddInfantryGroup;
                } forEach _statics;
                if !(_units isEqualTo []) then { { _x addCuratorEditableObjects [_units, true]; } forEach allCurators };
            };
            
            private _maxAiCount = _isFriendly call ITW_AtkAiCount;
            if (_zoneLimtedCount > 0) then {
                _maxAiCount = _maxAiCount * (1.05 + (0.05*(floor (_zoneLimtedCount/3)))); // 20% extra units when weakest, 15% in middle, and 10% extra when just 1 level is limited
            };
            private _activeAiCnt = {alive _x} count (units _side);
            private _spawnRate = if (time < 300) then {_spawnRateFast} else {_spawnRateSlow};
            private _maxAiRightNow = _maxAiCount min (_activeAiCnt + _spawnRate);
            // ensure we can populate the owned objectives with one squad each right at the start
            if (_populateObjectives) then {_maxAiRightNow = _maxAiCount max (_activeAiCnt + (_populateSquadCnt * _ownedObjCnt*AI_SQUAD_SIZE))};
            private _newUnits = [];
            if (_activeAiCnt + _spawnTrigger < _maxAiRightNow || {random 10 < 1}) then {
                // spawn in some ai
                while {_activeAiCnt < _maxAiRightNow} do {
                   _spawnPos = [_homeSpawnPt,0,25,1,0,0,0] call BIS_fnc_findSafePos;
                    if (count _spawnPos < 3) then {_spawnPos pushBack 0} else {_spawnPos = _homeSpawnPt};
    
                    // extra missile specialists?
                    private _types = _unitTypes;
                    if (ITW_ParamExtraLaunchers > 0 && !(_missleTypes isEqualTo [])) then {
                        private _chance = if (ITW_ParamExtraLaunchers == 2) then {25/*lots percentage*/} else {15/*few percentage*/};
                        if (random 100 < _chance) then {
                            _types = _missleTypes;
                        };
                    };
   
                    if (isNull _spawnGroup) then {
                        _spawnGroup = createGroup [_side,false];
                        _spawnGroup setVariable ["noHeadless",true];
                        _spawnGroup setVariable ["itwInit",true];
                    };
                    private _unit = [_spawnGroup,_types,_spawnPos,false] call ITW_AtkUnitToGroup;                
                    if !(isNull _unit) then {
                        _newUnits pushBack _unit; 
                        _activeAiCnt = _activeAiCnt + 1;
                    };
                    sleep 0.01;
                };
                if !(_newUnits isEqualTo []) then { { _x addCuratorEditableObjects [_newUnits, true]; } forEach allCurators };

                // if we have zones to populate, put one group each in them before we setup the transports
                if (_populateObjectives) then {
                    for "_i" from 1 to _populateSquadCnt do {
                        {
                            private _objIdx = _x;
                            private _obj = ITW_Objectives#_objIdx;
                            if (_objIdx call ITW_ObjContestedOwnerIsFriendly == _isFriendly) then {
                                // assign to groups
                                private _units = [];
                                while {count _units < AI_SQUAD_SIZE && {!(_newUnits isEqualTo [])}} do {
                                    _units pushBack (_newUnits#0);
                                    _newUnits deleteAt 0;
                                };
                                {_x allowDamage true} count _units; // do this before they leave the spawngroup since it's protected from headlessCLient control
                                private _group = createGroup [_side,false];    
                                _units joinSilent _group;
                                _group deleteGroupWhenEmpty true;
                                // send units on their way
                                [_group,_obj] call ITW_AtkAddInfantryGroup;
                                [_group] call _fnGroupsCallback;
                                VAR_SET_OBJ_IDX(_group,_objIdx);
                            };
                        } forEach _objectiveIds;
                    };
                    _populateObjectives = false;
                };
                
                // hold back some squads for delivery to the AOs by players
                if (_deliveryUnits > 0) then {        
                    private _currentDeliveryUnits = 0;
                    {_currentDeliveryUnits = _currentDeliveryUnits + count units _x} forEach (groups _side select {_x getVariable ["itwDelivery",false]});
                    if (_currentDeliveryUnits < _deliveryUnits && {!(_newUnits isEqualTo [])}) then {
                        private _units = [];
                        while {count _units < AI_SQUAD_SIZE && {!(_newUnits isEqualTo [])}} do {
                            _units pushBack (_newUnits#0);
                            _newUnits deleteAt 0;
                        };                      
                        _currentDeliveryUnits = _currentDeliveryUnits + count _units;
                        {_x allowDamage true} count _units; // do this before they leave the spawngroup since it's protected from headlessCLient control
                        private _grp = createGroup [_side,false];    
                        _grp setVariable ["itwInit",true];
                        _units joinSilent _grp;
                        _grp deleteGroupWhenEmpty true;
                        [_grp] call ITW_AtkAddInfantryGroup;
                        [_grp] call _fnGroupsCallback;
                        [_grp] call ITW_AllyDelivery;
                        _grp setVariable ["itwInit",false];                       
                    };
                };
                
                private _vehInfos = [_attackVeh,_transport,_homeVehSpawnPt,_newUnits,_crewTypes,_unitTypes,_side] call ITW_AtkVehicleSpawner;
                if !(_vehInfos isEqualTo []) then {
                    _vehInfos apply {[_x#VEHINFO_CREW_GRP] call _fnGroupsCallback};
                }; 
                
                // assign the AI
                private _unitsOnFoot = [];
                private _groupsInTransport = [];
                private _groupsOnFoot = [];
                {
                    private _unit = _x;
                    if (vehicle _x == _x) then {_unitsOnFoot pushBack _unit;_groupsOnFoot pushBackUnique (group _unit)}
                    else {_groupsInTransport pushBackUnique (group _unit)};
                    false
                } count _newUnits;
                
                if !(_unitsOnFoot isEqualTo []) then {
                    while {!(_unitsOnFoot isEqualTo [])} do {
                        // assign to groups
                        private _units = [];
                        while {count _units < AI_SQUAD_SIZE && {!(_unitsOnFoot isEqualTo [])}} do {
                            _units pushBack (_unitsOnFoot#0);
                            _unitsOnFoot deleteAt 0;
                        };
                        private _group = createGroup [_side,false];    
                        _units joinSilent _group;
                        _group deleteGroupWhenEmpty true;
                        // send units on their way
                        [_group] call ITW_AtkAddInfantryGroup;
                        [_group] call _fnGroupsCallback;
                    };
                };
                
                {
                    [_x] call _fnGroupsCallback;
                    _x setVariable ["itwInit",true];
                } count _groupsInTransport;
                
                {
                    _x setVariable ["itwInit",true];
                } count _groupsOnFoot;
                
                {_x allowDamage true} count _newUnits;
            };
            
            private _delaySec = ((TICKET_CYCLE/2) + random TICKET_CYCLE); // total sleep time desired
            
            private _sleepStep = 10; // seconds between checks
            private _startTime = time;
            for "_i" from 1 to _delaySec step _sleepStep do {
                sleep _sleepStep;
                if (_zoneIndex != ITW_AllyIndex) exitWith {}; // wake up and process new guys if zone changed
            };
            _delaySec = time - _startTime; // actual delay we slept
            while {LV_PAUSE} do {sleep 5};
            
            // enemy tickets per cycle can be reduced when they own fewer objectives
            private _enemyScale = 1;
            private "_numOwnedEnemy";
            while {ITW_ObjZonesUpdating} do {sleep 0.5};
            private _numOwnedEnemy    = {ITW_Objectives#_x#ITW_OBJ_OWNER == ITW_OWNER_ENEMY   } count _objectiveIds;
            private _numOwnedFriendly = {ITW_Objectives#_x#ITW_OBJ_OWNER == ITW_OWNER_FRIENDLY} count _objectiveIds;
            if (_numOwnedFriendly>_numOwnedEnemy && {_numOwnedEnemy > 0}) then {
                _enemyScale = 1 - (0.20/_numOwnedEnemy);
            };
            
            // ticket base
            if (ITW_ParamVehicleSpawnAdjustment != _prevVehSideAdj) then {
                _prevVehSideAdj = ITW_ParamVehicleSpawnAdjustment;
                // tickets & max number are adjusted based on the vehicle spawn rate adjust param as well, tickest also based on the number of ai param
                _ticketsBase = (ITW_ParamVehicleSpawnAdjustment) * ((ITW_ParamEnemyAiCnt+70)/100) * (TICKETS_PER_MIN/60);
                if (_isFriendly) then {_ticketsBase = _ticketsBase * ITW_ParamVehicleSideAdjustment};
                diag_log ("ITW: Ticket base per min : " + str (round (_ticketsBase*600)/10) + " " + (if (_isFriendly) then {"friendly"} else {"enemy"}));
                _ticketsBasePlaneAttack = (ITW_ParamAttackPlaneSpawnAdjustment) * _ticketsBase;
                _ticketsBaseHeliAttack  = (ITW_ParamAttackHeliSpawnAdjustment) * _ticketsBase;
                _ticketsBaseTankAttack  = (ITW_ParamAttackTankSpawnAdjustment) * _ticketsBase;
                _ticketsBaseApcAttack   = (ITW_ParamAttackApcSpawnAdjustment) * _ticketsBase;
                _ticketsBaseCarAttack   = (ITW_ParamAttackCarSpawnAdjustment) * _ticketsBase;
                _ticketsBaseShipAttack  = (ITW_ParamAttackShipSpawnAdjustment) * _ticketsBase;
            };
            
            // add tickets for this loop
            ITW_TICKET_SEM_CHECK; 
            {
                private _vehDef = _x;
                // only increment if under the max vehicles are currently in action
                if (_vehDef#ITW_VEH_ZONES_OWNED <= _zonesOwned && {_vehDef#ITW_VEH_COUNT < (_vehDef#ITW_VEH_MAX)}) then {
                    private _scale = if (_vehDef#ITW_VEH_IS_FRIENDLY) then {1} else {_enemyScale};
                    private _role = _x#ITW_VEH_ROLE;
                    private _type = _x#ITW_VEH_TYPE;
                    private _tickets = _ticketsBase;
                    if (_type == ITW_TYPE_VEH_AIRPLANE && !_ownsAirport) then {continue};
                    if (_role in [ITW_VEH_ROLE_ATTACK,ITW_VEH_ROLE_DUAL]) then {
                        _tickets = switch (_type) do {
                            case ITW_TYPE_VEH_AIRPLANE: {_ticketsBasePlaneAttack};
                            case ITW_TYPE_VEH_HELI:     {_ticketsBaseHeliAttack};
                            case ITW_TYPE_VEH_TANK:     {_ticketsBaseTankAttack};
                            case ITW_TYPE_VEH_APC:      {_ticketsBaseApcAttack};
                            case ITW_TYPE_VEH_CAR:      {_ticketsBaseCarAttack};
                            case ITW_TYPE_VEH_SHIP:     {_ticketsBaseShipAttack};
                            default {_ticketsBase};
                        };
                    };
                    private _increment = _scale * _tickets * _delaySec;
                    _vehDef set [ITW_VEH_CURR_TICKETS,(_vehDef#ITW_VEH_CURR_TICKETS) + _increment]};
            } count _vehArray;
        };
    };
};

ITW_AtkAiCount = {    
    private _isFriendly = _this;
    if (!_isFriendly) exitWith {ITW_ParamEnemyAiCnt};
    
    private _fnUupdateCnts = { 
        private _numPlayers = count call BIS_fnc_listPlayers;
        ITW_MaxFriendlyUnits = round ((ITW_ParamEnemyAiCnt * (1+ITW_ParamFriendlyAiCntAdjustment/10)) - (_numPlayers * 2));
        ITW_PrevFriendlyAiCntAdjustment = ITW_ParamFriendlyAiCntAdjustment;
    };
    if (isNil "ITW_PrevPlayerCnt") then {ITW_PrevPlayerCnt = -1};
    if (ITW_PrevPlayerCnt != count call BIS_fnc_listPlayers) then {call _fnUupdateCnts};
    if (ITW_PrevFriendlyAiCntAdjustment != ITW_ParamFriendlyAiCntAdjustment) then {call _fnUupdateCnts};
    ITW_MaxFriendlyUnits
};

ITW_AtkUnitCreateSem = false;
ITW_AtkUnitToGroup = {
    params ["_grp","_unitTypes","_aiSpawnPt",["_allowDamage",true]];
    if (!isServer) exitWith {diag_log "Error Pos: ITW_AtkUnitToGroup called on client not server";objNull};
    if (isNull _grp) exitWith {diag_log "Error Pos: ITW_AtkUnitToGroup called with a null group at start";objNull};
    private _fnStartTime = time;
    private _skill = if (side _grp == west) then {ITW_ParamFriendlySquadSkill} else {ITW_ParamDifficulty};
    private _hasWeapon = false;
    private _unit = objNull;
    private _cnt = 5;
    while {!_hasWeapon} do {    
        private _unitType = selectRandom _unitTypes;
        private _atkUnit = nil; 
        private _timeout = time + 15;       
        SEM_LOCK(ITW_AtkUnitCreateSem);
        if (isNull _grp) exitWith {diag_log ("Error Pos: ITW_AtkUnitToGroup called with a null group at "+str(time - _fnStartTime)+" sec");_unit = objNull;SEM_UNLOCK(ITW_AtkUnitCreateSem)};
        private _startTime = time;
        ItwAtkUnitCreated = nil;      
        _unitType createUnit [_aiSpawnPt, _grp, "ItwAtkUnitCreated = this"];
        waitUntil {sleep 0.05;!isNil "ItwAtkUnitCreated" || time > _timeout};
        _unit = if (!isNil "ItwAtkUnitCreated") then {ItwAtkUnitCreated} else {objNull};
        SEM_UNLOCK(ITW_AtkUnitCreateSem);
        if (isNull _unit) then {
            diag_log format ["Error Pos: ITW_AtkUnitToGroup: unit not created (%1 grpSize:%2 grp:%3 totalGroups:%4,%5)",_unitType,count units _grp,_grp,count groups west,count groups east + (count groups independent)] ;
            continue;
        } else {
            if (time - _startTime > 2) then {diag_log format ["Warning/Error Pos: Unit created too slowly: %1 sec",time - _startTime]};
        };
        _cnt = _cnt - 1;
        if (toUpperANSI (faction _unit) in WEAPONLESS_FACTIONS) exitWith {_hasWeapon = true};
        // don't allow weaponized backpacks
        if (backpack _unit isKindOf "Weapon_Bag_Base") then {
            removeBackpack _unit;
        };
        // if unit has no weapon, then change his loadout
        if (primaryWeapon _unit isEqualTo "") then {
            if (_cnt > 0 && {!(_unit isKindOf "WBK_C_ExportClass")}) then {
                deleteVehicle _unit;
                _unit = nil;  
            } else {
                if (handgunWeapon _unit isEqualTo "") then {
                    _unit addMagazines ["10Rnd_9x21_Mag",10];
                    _unit addWeapon "hgun_Pistol_01_F";
                };
                _hasWeapon = true;
            };
        } else {
            _hasWeapon = true;
        };
    };
    if (isNull _unit) exitWith {_unit};
    
    // ensure unit has first aid and some ammo
    private _FAK = "FirstAidKit";
    {
        private _type = getNumber (configFile >> "cfgWeapons" >> _x >> "iteminfo" >> "type");
        if (_type == 401) exitWith {_FAK = _x};
    } forEach items _unit;
    private _count = 6;
    while {_count > 0 && _unit canAdd _FAK} do {
        _count = _count - 1;
        _unit addItem _FAK;
    };
    private _ammo = primaryWeaponMagazine _unit;
    if !(_ammo isEqualTo []) then {
        _ammo = _ammo#0;
        _count = 6;
        while {_count > 0 && _unit canAdd _ammo} do {
            _count = _count - 1;
            _unit addItem _ammo;
        };
    };
    // ACE: add medical items
    #if __has_include("\z\ace\addons\main\script_component.hpp")
        (uniformContainer _unit) addItemCargoGlobal ["ACE_fieldDressing",1];
        (uniformContainer _unit) addItemCargoGlobal ["ACE_plasmaIV",1];
    #endif  
    
    _unit allowDamage _allowDamage;
    _unit setSkill _skill;
    _unit setSkill ["courage",1]; 
    _unit setVariable ["ITW_loadout",getUnitLoadout _unit];
    [_unit,true,true] call ITW_FncInfiniteAmmo;
    _unit
};

ITW_AtkVehicleSpawner = {
    params ["_vehsAttack","_vehsTransport","_spawnPt","_availableUnits","_crewTypes","_unitTypes","_side"];
    // _vehInfos array is returned: array of vehicles added [[_type,_veh,_crewGroup,_cargoGroups]],...] or [] if no vehs added
    // _vehsAttack are attack and dual purpose, _vehsTransport are transport only
    private _vehInfos = []; 
    private _newObjects = [];   
   
    private _unitCount = count _availableUnits; // available units counter
    private _cargoCount = 0;                    // units assigned counter
    
    private _ticketCheckFn = {
        params ["_vehArray","_shipsAllowed"];
        private _resultArray = (_vehArray) select {(_x select ITW_VEH_REQD_TICKETS) <= (_x select ITW_VEH_CURR_TICKETS) && {_x select ITW_VEH_ROLE == ITW_VEH_ROLE_TRANSPORT || {_x select ITW_VEH_COUNT < (_x select ITW_VEH_MAX)}}};
        if (!_shipsAllowed) then {_resultArray select {(_x select ITW_VEH_TYPE) != ITW_TYPE_VEH_SHIP}};
        _resultArray
    };
    
    private _shipsAllowed = {count (ITW_SeaPoints#_x) >= 0} count (ITW_Zones#ITW_ZoneIndex) > 0;

    // attack vehicles
    if !(_vehsAttack isEqualTo []) then {        
        ITW_TICKET_SEM_CHECK; 
        private _vehAttackTrimmed = [_vehsAttack,_shipsAllowed] call _ticketCheckFn;
        private _loopCnt = 50;
        while {!(_vehAttackTrimmed isEqualTo []) && {_loopCnt > 0}} do {
            _loopCnt = _loopCnt - 1;
            private _vehDef = selectRandom _vehAttackTrimmed;
            private _types = if (ITW_VEH_IS_AIR(_vehDef#ITW_VEH_TYPE)) then {_crewTypes} else {_unitTypes};
            _veh = [_vehDef,_types,_side,_spawnPt] call ITW_AtkSpawnVeh;
            if (!isNull _veh) then {  
                private _crew = crew _veh;
                private _crewGroup = if (_crew isEqualTo []) then {createGroup [_side,false]} else {group (crew _veh # 0)};
                private _cargoGroups = [];
                // if is dual role, add cargo
                if (_vehDef#ITW_VEH_ROLE == ITW_VEH_ROLE_DUAL && {_cargoCount < _unitCount}) then {
                    private _units = [];
                    private _vehSpace = _veh emptyPositions "";
                    for "_i" from 1 to _vehSpace do {
                        private _unit = _availableUnits#_cargoCount;
                        _units pushBack _unit;
                        _unit moveInAny _veh;
                        _cargoCount = _cargoCount + 1;
                        if (_cargoCount >= _unitCount) exitWith {};
                        if (_i % AI_SQUAD_SIZE == (AI_SQUAD_SIZE-1)) then {
                            private _cargoGroup = createGroup [_side,false];
                            _units joinSilent _cargoGroup;
                            _cargoGroups pushback _cargoGroup;
                            _units = [];
                        };
                    };
                    if !(_units isEqualTo []) then {
                        private _cargoGroup = createGroup [_side,false];
                        _units joinSilent _cargoGroup;
                        _cargoGroups pushback _cargoGroup;
                        _veh addEventHandler ["GetOut", { // have units get clear of vehicle when unloading
                            params ["_veh", "_role", "_unit", "_turret", "_isEject"];
                            private _objIdx = VAR_GET_OBJ_IDX(group _unit);
                            _objPos = if (_objIdx >= 0) then {ITW_Objectives#_objIdx#ITW_OBJ_POS} else {_veh getPos [50,getDir _veh]};
                            _unit doMove (getPosATL _unit getPos [60,(_veh getDir _objPos) - 45 + (random 90)]);
                        }];
                    };
                };
                
                private _vehInfo = [_vehDef#ITW_VEH_TYPE,_vehDef#ITW_VEH_ROLE,_veh,_crewGroup,_cargoGroups,getPosATL _veh];
                _vehInfo call ITW_AtkAddVehicle; // place vehicle and send on it's way
                _vehInfo set [VEHINFO_FROM_POS,getPosATL _veh]; // update from pos now that AtkAddVehicle has been called
                _vehInfos pushBack _vehInfo;
                _newObjects pushBack _veh;
                _newObjects = _newObjects + units _crewGroup;
                ITW_LastVehSpawnTime = time;
                
                // keep track of how many of this type is in the battle
                ITW_TICKET_SEM_CHECK;
                ITW_VEH_COUNT_INCR(_vehDef); 
                _veh setVariable ["ITW_VehDef",_vehDef];
                
                // pay ticket price and update the vehicles available
                ITW_TICKET_SEM_CHECK;
                ITW_TICKET_REDUCE(_vehDef);
                _vehAttackTrimmed = [_vehAttackTrimmed,_shipsAllowed] call _ticketCheckFn;
                
                sleep 5; // give vehicles chance to get placed 
                while {LV_PAUSE} do {sleep 5};
                
                _crewGroup deleteGroupWhenEmpty true;
                {_x deleteGroupWhenEmpty true} forEach _cargoGroups;
            };
        };
    };
        
    // transports 
    if !(_vehsTransport isEqualTo []) then {
        ITW_TICKET_SEM_CHECK;
        private _vehTranspTrimmed = [_vehsTransport,_shipsAllowed] call _ticketCheckFn;
        private _loopCnt = 50;
        while {!(_vehTranspTrimmed isEqualTo []) && {_cargoCount < _unitCount && {_loopCnt > 0}}} do {
            _loopCnt = _loopCnt - 1;
            private _vehDef = selectRandom _vehTranspTrimmed;         
            _veh = [_vehDef,_crewTypes,_side,_spawnPt] call ITW_AtkSpawnVeh;
            if (!isNulL _veh) then { 
                // put units into cargo
                private _units = [];
                private _cargoGroups = [];
                private _vehSpace = _veh emptyPositions "";
                for "_i" from 1 to _vehSpace do {
                    private _unit = _availableUnits#_cargoCount;
                    _units pushBack _unit;
                    _unit moveInAny _veh;
                    _cargoCount = _cargoCount + 1;
                    if (_cargoCount >= _unitCount) exitWith {};
                    if (_i % AI_SQUAD_SIZE == (AI_SQUAD_SIZE-1)) then {
                        private _cargoGroup = createGroup [_side,false];
                        _units joinSilent _cargoGroup;
                        _cargoGroups pushback _cargoGroup;
                        _units = [];
                    };
                };
                if !(_units isEqualTo []) then {
                    private _cargoGroup = createGroup [_side,false];
                    _units joinSilent _cargoGroup;
                    _cargoGroups pushback _cargoGroup;
                    //_veh addEventHandler ["GetOut", { // have units get clear of vehicle when unloading
                    //    params ["_veh", "_role", "_unit", "_turret", "_isEject"];
                    //    private _objIdx = VAR_GET_OBJ_IDX(group _unit);
                    //    _objPos = if (_objIdx >= 0) then {ITW_Objectives#_objIdx#ITW_OBJ_POS} else {_veh getPos [50,getDir _veh]};
                    //    _unit doMove (getPosATL _unit getPos [60,(_veh getDir _objPos) - 45 + (random 90)]);
                    //}];
                };
                private _crewGroup = group driver _veh;
                
                private _vehInfo = [_vehDef#ITW_VEH_TYPE,_vehDef#ITW_VEH_ROLE,_veh,_crewGroup,_cargoGroups,getPosATL _veh];
                _vehInfo call ITW_AtkAddVehicle; // place vehicle and send on it's way
                _vehInfo set [VEHINFO_FROM_POS,getPosATL _veh]; // update from pos now that AtkAddVehicle has been called
                _vehInfos pushBack _vehInfo;
                _newObjects pushBack _veh;
                _newObjects = _newObjects + units _crewGroup;
                
                // keep track of how many of this type is in the battle
                ITW_TICKET_SEM_CHECK;
                ITW_VEH_COUNT_INCR(_vehDef); 
                _veh setVariable ["ITW_VehDef",_vehDef];
                    
                // pay ticket price and update the vehicles available
                ITW_TICKET_SEM_CHECK;
                ITW_TICKET_REDUCE(_vehDef);
                _vehTranspTrimmed = [_vehTranspTrimmed,_shipsAllowed] call _ticketCheckFn;
                
                sleep 1; // give vehicles chance to get placed 
                while {LV_PAUSE} do {sleep 5};
                
                _crewGroup deleteGroupWhenEmpty true;
                {_x deleteGroupWhenEmpty true} forEach _cargoGroups;
            };
        };
    };
    
    {
        private _veh =  _x#VEHINFO_VEH;
        _veh addAction ["<t color='#00ff00'>Unlock vehicle</t>",{
                params ["_veh", "_caller", "_actionId", "_arguments"];
                [_veh,true] remoteExec ["enableSimulationGlobal",2];
                [_veh,true] remoteExec ["allowDamage",_veh];
            },nil,10,true,true,"","! simulationEnabled _target && {_this == vehicle _this}",10,false];
        false
    } count _vehInfos;
    
    if !(_newObjects isEqualTo []) then { { _x addCuratorEditableObjects [_newObjects, true]; } forEach allCurators };
    
    _vehInfos
};

ITW_AtkSwitchToAirVeh = {
    params ["_vehInfo","_deleteIfFail","_baseFromIdx"];
    private _success = false;
    private _type = _vehInfo#ITW_VEH_TYPE;
    private _role = _vehInfo#VEHINFO_ROLE;
    private _sideIndex = ATTACK_SIDE(_vehInfo#VEHINFO_CREW_GRP);
    private _airVehs = [];
    private _attack = 0;
    private _dual = 1;
    private _transport = 2; 
    private _typeWasCar = false;
      
    // adjust role based on how dangerous the vehicle was
    if (_type == ITW_TYPE_VEH_CAR) then {
        _role = ITW_VEH_ROLE_TRANSPORT;
        _typeWasCar = true;
    };
    
    if (_role == ITW_VEH_ROLE_ATTACK) then {    
        _airVehs = ITW_AirVehsDef#_sideIndex#_attack;
        if (_airVehs isEqualTo []) then {_airVehs = ITW_AirVehsDef#_sideIndex#_dual};
        if (_airVehs isEqualTo []) then {_airVehs = ITW_AirVehsDef#_sideIndex#_transport};
    };
    if (_role == ITW_VEH_ROLE_DUAL) then {
        _airVehs = ITW_AirVehsDef#_sideIndex#_dual;
        if (_airVehs isEqualTo []) then {_airVehs = ITW_AirVehsDef#_sideIndex#_transport};
    };
    if (_role == ITW_VEH_ROLE_TRANSPORT) then {
        _airVehs = ITW_AirVehsDef#_sideIndex#_transport;
        if (_airVehs isEqualTo []) then {_airVehs = ITW_AirVehsDef#_sideIndex#_dual};
    };
  
    if !(_airVehs isEqualTo []) then {
        private _oldVeh = _vehInfo#VEHINFO_VEH;
        private _crewGrp = _vehInfo#VEHINFO_CREW_GRP;
        private _cargoGrps = _vehInfo#VEHINFO_CARGO_GRPS;
        
        if (_cargoGrps isEqualTo [] && {_role == ITW_VEH_ROLE_TRANSPORT}) exitWith {
            // if we are switching to a transport, but there are not groups to transport, then don't spawn new aircraft
            if (_deleteIfFail) then {           
                private _groups = crew _oldVeh apply {group _x};
                _groups = _groups arrayIntersect _groups;
                deleteVehicleCrew _oldVeh;
                deleteVehicle _oldVeh;
                _vehInfo set [VEHINFO_VEH,objNull];
                _groups apply {if !(units _x isEqualTo []) then {[[_x],"deleteGroup",_x] call ITW_FncRemoteLocalGroup}};
            };
            false
        };
        
        {{unassignVehicle _x;moveOut _x} forEach (units _x)} forEach ([_crewGrp] + _cargoGrps);
        sleep 0.2;
        
        private _vehDef = selectRandom _airVehs;
        private _vehTypeTxtr = selectRandom (_vehDef#ITW_VEH_CLASSES);
        if (isNil "_vehTypeTxtr") exitWith {false};
        private _vehType = if (typeName _vehTypeTxtr == "ARRAY") then {_vehTypeTxtr#0} else {_vehTypeTxtr};
        
        private _basePos = ITW_Bases#_baseFromIdx#ITW_BASE_POS;
        private _airSpawn = _oldVeh getPos [800,_oldVeh getDir _basePos]; // with "FLY" option, it will spawn in at 50m elevation
        
        private _vehCfg = configFile >> "CfgVehicles" >> _vehType;
        if (isNil "_vehCfg") exitWith {false};
        private _crewCount = {
            round getNumber (_x >> "dontCreateAI") < 1 &&
            ((_x == _vehCfg && { round getNumber (_x >> "hasDriver") > 0 }) ||
            (_x != _vehCfg && { round getNumber (_x >> "hasGunner") > 0 }))
        } count ([_vehType, configNull] call BIS_fnc_getTurrets);
        private _newCrewCnt = 0;
        private _pilot = if (_crewCount == 0) then {objNull} else {leader _crewGrp};
        
        _veh = [_vehTypeTxtr,_airSpawn,"FLY",_pilot] call ITW_VehCreateVehicle;
        
        private _newCargoCnt = 0;
        private _overflowUnits = [];
        
        // transfer crew
        {
            private _unit = _x;
            if (vehicle _unit == _veh) then {_newCrewCnt = _newCrewCnt + 1;continue};
            if (_newCrewCnt < _crewCount) then {
                _newCrewCnt = _newCrewCnt + 1;
                //moveOut _unit;
                _unit moveInAny _veh;
            } else {
                _overflowUnits pushBack _unit;
            };
            false
        } count units _crewGrp;
        
        if (_newCrewCnt < _crewCount) then {
            private _leader = leader _crewGrp;
            private _type = typeOf _leader;
            private _pos = getPosATL _oldVeh;
            while {_newCrewCnt < _crewCount} do {
                _newCrewCnt = _newCrewCnt + 1; 
                private _unit = [_crewGrp,[_type],_pos,true] call ITW_AtkUnitToGroup;
                //moveOut _unit;
                _unit moveInAny _veh;
            };
        };
        
        // transfer cargo
        private _cargoCount = (_veh emptyPositions "") - _crewCount;
        {
            private _grp = _x;
            {
                private _unit = _x;
                if (_newCargoCnt < _cargoCount) then {
                    _newCargoCnt = _newCargoCnt + 1;
                    //moveOut _unit;
                    _unit moveInAny _veh;
                } else {
                    _overflowUnits pushBack _unit;
                };
            } forEach units _grp;
            false
        } count _cargoGrps;
           
        {deleteVehicle _x} count _overflowUnits;
        {if (count units _x == 0) then {[[_x],"deleteGroup",_x] call ITW_FncRemoteLocalGroup}} forEach _cargoGrps;
        
        {_x setRank "SERGEANT";_x setSkill ["courage",1]} count units _crewGrp;
        private _driver = driver _veh;
        _driver setRank "LIEUTENANT";
        [_driver,"CARELESS"] call ITW_FncSetUnitBehavior;
        { _x addCuratorEditableObjects [[_veh], false]; } forEach allCurators;
               
        // update the vehicle info
        _vehInfo set [VEHINFO_TYPE,_vehDef#ITW_VEH_TYPE];
        _vehInfo set [VEHINFO_VEH,_veh];
        if (_typeWasCar) then {_vehInfo set [VEHINFO_ROLE,ITW_VEH_ROLE_TRANSPORT]};
        deleteVehicle _oldVeh;
        _success = true;
    };
    _success
};

ITW_AtkAirDropVeh = {
    params ["_vehInfo","_objPos","_objSize"];
    private _success = false;
    private _type = _vehInfo#ITW_VEH_TYPE;
    private _role = _vehInfo#VEHINFO_ROLE;
    private _veh = _vehInfo#VEHINFO_VEH;
    private _fromPos =  _vehInfo#VEHINFO_FROM_POS;
    
    private _isAllLandFn = {
        // check if there is water in a line from _pos along _dir
        params ["_pos","_dir","_objSize","_dist"];
        private _okay = true;
        for "_r" from _objSize to _dist step 5 do {
            if (getTerrainHeight (_pos getPos [_r,_dir]) < -0.4) exitWith {_okay = false}; 
        };
        _okay
    };
    
    private _pos = [];
    if (_type == ITW_TYPE_VEH_SHIP) then {
        // find a point to air drop sea vehicle
        private _cnt = 100;
        while {_pos isEqualTo [] && {_cnt > 0}} do {
            _cnt = _cnt - 1;
            private _dir = random 360;
            private _dist = ZONE_KEEP_OUT_SIZE + random 1000;
            _pos = _objPos getPos [_dist,_dir];
            if (getTerrainHeightASL _pos < -1) then {
                private _closestEnemyObj = [_pos,ITW_OWNER_ENEMY] call ITW_ObjGetNearest;
                private _nearestBase = ITW_Bases#(_closestEnemyObj#ITW_OBJ_INDEX);
                if (_pos distanceSqr (_nearestBase#ITW_BASE_POS) < ZONE_KEEP_OUT_SQR) then {_pos = []};
            } else {
                _pos = [];
            };
            sleep 0.01; // don't monopolize the cpu
        };
    } else {
        // find a point to air drop land vehicle
        private _cnt = 60;
        while {_pos isEqualTo [] && {_cnt > 0}} do {
            _cnt = _cnt - 1;
            private _dir = (_objPos getDir _fromPos) + (if (_cnt < 20) then {90 + random 180} else {-90 + random 180});
            private _dist = ZONE_KEEP_OUT_SIZE + random 500;
            if ([_objPos,_dir,_objSize,_dist] call _isAllLandFn) then {
                _pos = _objPos getPos [_dist,_dir];
                private _closestEnemyObj = [_pos,ITW_OWNER_ENEMY] call ITW_ObjGetNearest;
                private _nearestBase = ITW_Bases#(_closestEnemyObj#ITW_OBJ_INDEX);
                if (_pos distanceSqr (_nearestBase#ITW_BASE_POS) < ZONE_KEEP_OUT_SQR) then {_pos = []};
            } else {
                _pos = [];
            };
            sleep 0.01; // don't monopolize the cpu
        };
    };
    
    if !(_pos isEqualTo []) then {
        _success = true;
        _vehInfo set [VEHINFO_FROM_POS,_pos];
        _pos set [2,150];
        [_veh,_pos] remoteExec ["ITW_FncVehicleHalo",_veh];
    };
    _success
};

ITW_AtkSpawnVeh = {
    // returns vehicle object or objNull if spawning failed, damage is not allowed on vehicle
    params ["_vehArrayItem","_crewTypes","_side","_spawnPt"];
    if (isNil "_vehArrayItem") exitWith {objNull};
    private _veh = objNull;
    private _vehTypeTxtr = selectRandom (_vehArrayItem#ITW_VEH_CLASSES);
    if (!isNil "_vehTypeTxtr") then {
        private _vehType = if (typeName _vehTypeTxtr == "ARRAY") then {_vehTypeTxtr#0} else {_vehTypeTxtr};
        private _vehCfg = configFile >> "CfgVehicles" >> _vehType;
        if (isNil "_vehCfg") exitWith {};
        private _crewCount = {
            round getNumber (_x >> "dontCreateAI") < 1 &&
            ((_x == _vehCfg && { round getNumber (_x >> "hasDriver") > 0 }) ||
            (_x != _vehCfg && { round getNumber (_x >> "hasGunner") > 0 }))
        } count ([_vehType, configNull] call BIS_fnc_getTurrets);
        private _units = [];
        private _crewGrp = createGroup [_side,false];   
        if (_vehType isKindOf "Air") then {  
            private _pilot = if (_crewCount > 0) then {[_crewGrp,_crewTypes,_spawnPt,false] call ITW_AtkUnitToGroup} else {objNull};
            _crewCount = _crewCount - 1;
            // with "FLY" option, it will spawn in at 50m elevation
            _veh = [_vehTypeTxtr,_spawnPt,"FLY",_pilot] call ITW_VehCreateVehicle;
        } else {
            private _landSpawn = +_spawnPt;
            _landSpawn set [2,_landSpawn#2 + 4];     
            _veh = [_vehTypeTxtr,_landSpawn] call ITW_VehCreateVehicle;
        };
        _veh allowDamage false;
        
        for "_i" from 1 to _crewCount do {
            private _unit = [_crewGrp,_crewTypes,_spawnPt,false] call ITW_AtkUnitToGroup;
            _units pushBack _unit;
            _unit moveInAny _veh;
        };
        {_x setRank "SERGEANT";_x setSkill ["courage",1]} count _units;
        private _driver = driver _veh;
        _driver setRank "LIEUTENANT";
        [_driver,"CARELESS"] call ITW_FncSetUnitBehavior;
        _crewGrp allowFleeing 0;
        _crewGrp deleteGroupWhenEmpty true;
        ITW_AtkNewVehSpawned = true;
    };
    _veh
};

ITW_AtkAddVehicle = {
    private _vehInfo = _this;
    private _crewGroup = _vehInfo#VEHINFO_CREW_GRP;
    private _cargoGroups = _vehInfo#VEHINFO_CARGO_GRPS;
    [_vehInfo,true] call ITW_AtkEngageVehicle;
    
    SEM_LOCK(ITW_AtkVehicleManagerBusy);
    isNil {ITW_ManagedVehs pushBack _vehInfo};
    SEM_UNLOCK(ITW_AtkVehicleManagerBusy);
};

ITW_AtkSafeGroupAllowDamage = {
    params ["_groups","_allowed"];
    if (typeName _groups == "GROUP") then {_groups = [_groups]};
    _groups = _groups arrayIntersect _groups;
    {
        private _grp = _x;
        if (!local _grp) then {
            [[_grp,_allowed],"ITW_AtkSafeGroupAllowDamage",_grp] call ITW_FncRemoteLocalGroup;
        } else {
            {_x allowDamage _allowed} count units _grp;
        };
    } forEach _groups
};

ITW_AtkSafeMove = {
    params ["_group","_pos"];
    private _units = units _group;
    {
        _x allowDamage false;
        _x setPosATL _pos;
    } count _units;    
    sleep 2;
    {
        _x allowDamage true;
    } count _units;    
};

ITW_AtkSafeSetVectorUp = {
    // set vector up accounting for locality
    params ["_veh","_pos"];
    if (!local _veh) then {
        _this remoteExec ["",_veh];
        sleep 1;
    } else {
        _veh allowDamage false;
        if (!surfaceIsWater _pos) then {
            _veh setVectorUp surfaceNormal _pos;
        } else {
            _veh setVectorUp [0,0,1];
        };
        _pos set [2,_pos#2 + 0.25];
        _veh setPosATL _pos;
        sleep 2;
        _veh allowDamage true;
    };
};

ITW_AtkAddCrewToStatic = {
    params ["_veh","_isFriendly"];  
    ITW_AtkStaticNeedsCrew#(if (_isFriendly) then {ATTACK_FRIENDLY} else {ATTACK_ENEMY}) pushBack _veh;
};

ITW_AtkAddInfantryGroup = {
    params ["_group",["_objToPopulate",[]],["_teleportToAttackPos",true]];
    [_group,_teleportToAttackPos,_objToPopulate] call ITW_AtkEngageInfantry;
};

ITW_AtkEngageInfantry = {
    params ["_group","_teleportToAttackPos",["_objToPopulate",[]]];
    // choose objective to attack/defend and assign waypoints
    // 
    private _populateObj = !(_objToPopulate isEqualTo []);
    private _isFriendly = GRP_IS_FRIENDLY(_group);
    private _idx = ATTACK_SIDE(_group);
    private _fnAttackVectors = ITW_AtkVectors#_idx;
    private _vector = [AV_INFANTRY,_group] call _fnAttackVectors;
    _vector params ["_objTo","_baseFromIdx"]; 
    private _toPos = _objTo#ITW_OBJ_POS;
    if (_populateObj) then {
        if (((_objToPopulate#ITW_OBJ_INDEX) call ITW_ObjContestedOwnerIsFriendly) != _isFriendly) then {
            _populateObj = false; // can only populate objectives that are captured by your side
        } else {
            _toPos = _objToPopulate#ITW_OBJ_POS;
        };
    };
    
    if (_teleportToAttackPos || _populateObj) then {
        private _pos = if (_populateObj) then {_toPos} else {
            if (_baseFromIdx >= 0) then {ITW_Bases#_baseFromIdx#ITW_BASE_A_SPAWN} else {call ITW_ObjGetOutToSeaPos};
        };
        if (surfaceIsWater _pos) then {
            private _toDir = _pos getDir _toPos;
            while {surfaceIsWater _pos} do {
                _pos = _pos getPos [300,_toDir];
                if (_pos distance2D _toPos < 800) exitWith {};
            };
        };  
        [[_group,_pos],"ITW_AtkSafeMove",_group] call ITW_FncRemoteLocalGroup;
        sleep 0.5;
    };

    if (!_populateObj && {!(vehicle leader _group in ITW_Statics)}) then {
        private _objSize = ITW_ParamObjectiveSize;
        private _toPos = _toPos getPos [_objSize,_toPos getDir (getPosATL leader _group)];
        ITW_DELETE_WAYPOINTS(_group);
        _group addWaypoint [_toPos,100];
    };
};

ITW_AtkEngageVehicle = {
    params ["_vehInfo",["_teleportToAttackPos",false]];
    private _crewGroup = _vehInfo#VEHINFO_CREW_GRP;
    private _cargoGroups = _vehInfo#VEHINFO_CARGO_GRPS;
    private _type = _vehInfo#VEHINFO_TYPE;
    private _veh = _vehInfo#VEHINFO_VEH;
    // choose objectives to attack/defend and assign waypoints
    private _atkSide = ATTACK_SIDE(_crewGroup);
    private _fnAttackVectors = ITW_AtkVectors#_atkSide;
    private _vector = [AV_VEHICLE,_crewGroup,_cargoGroups] call _fnAttackVectors;
    _vector params ["_objTo","_baseFromIdx"];
    private _objPos = _objTo#ITW_OBJ_POS;
    private _objSize = ITW_ParamObjectiveSize;
    private _objIndex = _objTo#ITW_OBJ_INDEX;
    private _seaPts = if (ITW_VEH_IS_SEA(_type)) then {ITW_SeaPoints#_objIndex} else {[]};
    private _atkPossible = _objTo#ITW_OBJ_LAND_ATK#(if (ITW_VEH_IS_SEA(_type)) then {ATTACK_SIDE_SEA(_crewGroup)} else {_atkSide});
  
    // this is run only on first assignment, skipped when waypoint updated on vehicle in the field
    if (_teleportToAttackPos) then {
        if (!_atkPossible && {!ITW_VEH_IS_AIR(_type) && {!(_veh isKindOf "Air")}}) then {
            // if no land/sea route, air drop or switch to air vehicle
            switch (true) do {
                case (ITW_VEH_IS_SEA(_type)): {
                    if (_seaPts isEqualTo []) then {
                        // to obj is not accessible from sea           
                        [_vehInfo,false,_baseFromIdx] call ITW_AtkSwitchToAirVeh;
                    } else {
                        private _success = if (ITW_ParamAirDropVehicles == 1) then {[_vehInfo,_objPos,_objSize] call ITW_AtkAirDropVeh} else {false};
                        if (!_success) then {
                            [_vehInfo,true,_baseFromIdx] call ITW_AtkSwitchToAirVeh;
                        };
                    };
                };
                case ITW_VEH_IS_LAND(_type): {
                    // randomly choose 'air drop' or 'switchToAir', then try the other if not successful
                    if (random 1 < 0.5) then {           
                        private _success = [_vehInfo,false,_baseFromIdx] call ITW_AtkSwitchToAirVeh;
                        if (!_success) then {           
                            if (ITW_ParamAirDropVehicles == 1) then {[_vehInfo,_objPos,_objSize] call ITW_AtkAirDropVeh} else {false};
                        };
                    } else {    
                        private _success = if (ITW_ParamAirDropVehicles == 1) then {[_vehInfo,_objPos,_objSize] call ITW_AtkAirDropVeh} else {false};
                        if (!_success) then {
                            [_vehInfo,true,_baseFromIdx] call ITW_AtkSwitchToAirVeh;
                        };
                    };
                };
            };
            if (!alive (_vehInfo#VEHINFO_VEH)) exitWith {}; // vehicle was removed
            _type = _vehInfo#VEHINFO_TYPE;
        };
                   
        private _veh = _vehInfo#VEHINFO_VEH;            
        private _pos = if (_baseFromIdx >= 0) then {ITW_Bases#_baseFromIdx#ITW_BASE_POS} else {call ITW_ObjGetOutToSeaPos};
        private _dir = _pos getDir _objPos;
        [_veh,false] remoteExec ["allowDamage",_veh];
        if (_type == ITW_TYPE_VEH_AIRPLANE) then {
            // airplanes spawn by airfield
            private _veh = _vehInfo#VEHINFO_VEH;
            private _isFriendly = GRP_IS_FRIENDLY(_crewGroup);
            _pos = [_isFriendly,_objPos] call ITW_ObjClosestOwnedAirport;
            if (_pos isEqualTo []) then {
                // this shouldn't happen
                _pos = ITW_Objectives#(if (_isFriendly) then {0} else {-1})#ITW_OBJ_POS;
            };
            _pos = _pos getPos [- 200,_dir];
        } else {
            if (_type == ITW_TYPE_VEH_HELI) then {
                // helis spawn on far side of base from objective
                _pos = _pos getPos [1000,_objPos getDir _pos];
            } else {
                if (_type == ITW_TYPE_VEH_SHIP) then {
                    // leave _pos as is, it isn't used anyway
                } else {
                    // Land Veh: ideal spawn point for spawning on the ground is on the side of the base towards the objective
                    _pos = _pos getPos [500,_pos getDir _objPos];
                };
            };
        };
        [_type,_pos,_dir,_baseFromIdx,_objTo#ITW_OBJ_INDEX,typeOf _veh] call ITW_AtkSpawnOffsetter params ["_offsetPos","_offsetDir"];
        if !(_offsetPos isEqualTo []) then {
            if (local _veh) then {_veh setDir _offsetDir} else {[_veh,_offsetDir] remoteExec ["setDir",_veh]};
            ITW_SETPOS_AGL(_veh,_offsetPos);
            if (ITW_VEH_IS_LAND(_type)) then {
                [_veh,getPosATL _veh] call ITW_AtkSafeSetVectorUp;
            } else {
                if (ITW_VEH_IS_AIR(_type)) then {
                    private _vel = 60;
                    if (local _veh) then {_veh setVelocityModelSpace [0,_vel,0]} else {[_veh,[0,_vel,0]] remoteExec ["setVelocityModelSpace",_veh]};
                };
            };
        };
        _veh setVariable ["ITW_VehStartSafe",[getPosATL _veh, time+60]];
    };
    
    ITW_DELETE_WAYPOINTS(_crewGroup);
    private _wp = _crewGroup addWaypoint [_objPos,100]; // move to center of obj, manager will take over once it gets close
    if !(_seaPts isEqualTo []) then {
        _wp setWaypointPosition [selectRandom _seaPts,5];
    };
    _wp setWaypointCompletionRadius 300;
    _wp setWaypointType (if (_cargoGroups isEqualTo []) then {"SAD"} else {"MOVE"});
};

ITW_AtkSpawnOffsetter = {
    params ["_type","_pos","_dir","_fromBaseIdx","_toObjIdx",["_landVehClass","B_Quadbike_01_F"]];
    // returns [pos,dir]
    // pos: a position offset from pos to keep spawned vehicles from colliding
    // dir: direction facing towards the _toPos (land vehicles will be facing road direction)
    private _offset = 0;
    private _newPos = [];
    private _newDir = _dir;
    
    if (ITW_VEH_IS_AIR(_type)) then {
        // airplanes need to remain in the air
        // start with a radial offset at two different distances (works find for aircraft)
        
        if (isNil "ITW_SpawnPlaneOffset") then {ITW_SpawnPlaneOffset=0};
        private _offset = ITW_SpawnPlaneOffset;
        ITW_SpawnPlaneOffset = (_offset+1) mod 16;
        
        private _dist = if (_offset < 8) then {300} else {200};
        private _angle = switch (_offset) do {
                             case  0;
                             case  8: {0};
                             case  4;
                             case 13: {45};
                             case  1;
                             case  9: {90};
                             case  5;
                             case 14: {135};
                             case  2;
                             case 10: {180};
                             case  6;
                             case 15: {225};
                             case  3;
                             case 11: {270};
                             case  7;
                             case 12: {315};
                         };
        _newPos = _pos getPos [_dist,_angle];
        _newPos set [2,if (_type == ITW_TYPE_VEH_AIRPLANE) then {100} else {40}];
        
    } else {
        if (ITW_VEH_IS_SEA(_type)) then {
            // sea vehicles
            if (isNil "ITW_SpawnShipOffset") then {ITW_SpawnShipOffset=0};
            private _offset = ITW_SpawnShipOffset;
            ITW_SpawnShipOffset = (_offset+1);
            
            private _seaPts = ITW_SeaPoints#_fromBaseIdx;
            if !(_seaPts isEqualTo []) then {
                _offset = _offset mod (count _seaPts);
                _newPos = _seaPts#_offset;
                _newPos set [2,0];
            };
            
        } else {
            // land vehicles might end up in buildings and such
            // 1st try to place on roads
            
            // we cache the roads around a base biased towards the first objective we see from this base
            if (isNil "ITW_AtkRoadMap"  ) then {ITW_AtkRoadMap = createHashMap};
            private _roads = ITW_AtkRoadMap getOrDefault [[_fromBaseIdx,_toObjIdx],nil];
            if (isNil "_roads" && {_fromBaseIdx>= 0}) then {
                private _basePos = ITW_Bases#_baseFromIdx#ITW_BASE_POS;
                _roads = _pos nearRoads 700 select {_x distance _basePos > 100};
                private _i = 1;
                while {_i < count _roads} do {
                    private _r = _roads#(_i-1);
                    for "_j" from (count _roads -1) to _i step -1  do {
                        private _r2 = _roads#_j;
                        if (_r distance _r2 < 25) then {_roads deleteAt _j};
                    };
                    _i = _i + 1;
                };      
                _roads = [_roads,[_pos],{_x distance2D _input0},"ASCEND"] call BIS_fnc_sortBy;
                if (count _roads < 10) then {_roads = []} else {
                    if (count _roads > 20) then {_roads resize 20};
                };
                //// Show dots on spawning roads
                //if (true) then {
                //    {
                //        private _m = createMarkerLocal [format ["mroad_%1_%2",count ITW_AtkRoadMap,_forEachIndex],getPosATL _x];
                //        _m setMarkerTypeLocal "hd_dot";
                //        _m setMarkerColorLocal ["ColorBlack","ColorRed","ColorOrange","ColorYellow","ColorGreen","ColorBlue","ColorPink","ColorWhite","ColorCIV"] # (_fromBaseIdx mod 9);
                //    } forEach _roads;
                //};
                ITW_AtkRoadMap set [[_fromBaseIdx,_toObjIdx],_roads]; 
            };
            
            if (isNil "_roads" || {_roads isEqualTo []}) then {
                // no roads available
                private _emptyPos = _pos findEmptyPosition [0,100,_landVehClass];
                if (_emptyPos isEqualTo []) then {
                    _newPos = [];
                } else {
                    _newPos = _emptyPos;
                };
            } else {
                // roads available 
                // keep different offsets for each base (it's cleared at NextZone)
                if (isNil "ITW_SpawnOffsets") then {ITW_SpawnOffsets = createHashMap};
                private _offset = ITW_SpawnOffsets getOrDefault [_fromBaseIdx,0];
                ITW_SpawnOffsets set [_fromBaseIdx,(_offset+1) mod count _roads];
                private _road = _roads#_offset;
                _newPos = getPosATL _road;
                _newDir = getDir _road;
                private _diff = abs (_newDir - _dir);
                if (_diff > 180) then {_diff = _diff - 180};
                if (_diff > 90) then {_newDir = _newDir + 180};
            };
            // land vehicles need to spawn slightly above the ground and drop down 
            if !(_newPos isEqualTo []) then {
                _newPos set [2,0.5];
            };
        };
    };
    
    [_newPos,_newDir]
};

ITW_AtkStuckHandler = {
    scriptName "ITW_AtkStuckHandler";
    // Stuck Handler
    // If it's 1st time it's checked then delay = JustSpawnedTimeout otherwise noMoveTimeout
    // after timeout, check if it's moved, if not move it a little and check again
    #define AFTER_MOVE_TIME    100 // after unit moved, check again in this many seconds
    #define INIT_PREV_POS      [-10,-10]
    #define NEWLY_SPAWNED_TIME 90  // is considered newly spawned for first 90sec after spawning 
    private _started = false;
    while {!ITW_GameOver} do {
        private _vehiclesProcessed = [];
        private _allUnits = +allUnits;
        private _sleepTime = AFTER_MOVE_TIME;
        ITW_AtkNewVehSpawned = false;
        {
            private _unit = _x;
            if (_unit isKindOf "LOGIC") then {continue};
            private _unitGrp = group _unit;
            private _unitCurWpIdx = currentWaypoint _unitGrp;      
            if ( isPlayer _unit || {side _unit == civilian || {!ALIVE(_unit) || {_unitCurWpIdx == 0 || {_unitCurWpIdx >= count waypoints _unitGrp}}}}) then {continue};
            
            private _veh = vehicle _unit; 
            if (_veh in _vehiclesProcessed || _veh in ITW_Statics || {fuel _veh == 0}) then {continue};
            
            // unit stuck in water check (not veh)
            if !(_veh isKindOf "Ship") then {
                if (_veh == _unit && {surfaceIsWater getPosATL _unit}) then {
                    private _waterTimeout = _unit getVariable ["itw_inWater",0];
                    if (_waterTimeout == 0) then {
                        _waterTimeout = time + 480; // 8 minutes
                        _unit setVariable ["itw_inWater",_waterTimeout];
                    };
                    if (time > _waterTimeout) then {
                        deleteVehicle _unit;
                        if (count units _unitGrp == 0) then {[[_unitGrp],"deleteGroup",_unitGrp] call ITW_FncRemoteLocalGroup};
                        continue;
                    };
                } else {
                    _unit setVariable ["itw_inWater",nil];
                };
            };
            
            // check if group in correct zone, it's allowed to idle in the zone it's capturing/defending           
            private _objIdx = VAR_GET_OBJ_IDX(group _unit);
            if (_objIdx >= 0) then {
                private _obj = ITW_Objectives#_objIdx;
                private _objPt = _obj#ITW_OBJ_POS;
                if (_unit distance2D _objPt <= ITW_ParamObjectiveSize) then {continue};
            };
            
            // group stuck in position check
            _vehiclesProcessed pushBack _veh;
            private _pos = getPosATL _veh;
            private _group = group driver _veh;
            private _wpIdx = currentWaypoint _group;
            if (_wpIdx == 0 || {_wpIdx >= count waypoints _group}) then {continue};
            private _wpPos = waypointPosition [_group,_wpIdx];
            if (_wpPos isEqualTo [0,0,0] || {_wpPos distance _pos < 50}) then {continue};            
            
            (_veh getVariable ["StuckPos",[0,0,INIT_PREV_POS,0,time]]) params ["_timeout","_maxTime","_prevPos","_stuckCnt","_spawnedTime"];
            if (time >= (_timeout - 1)) then {
                private ["_stuckLimit","_delay"];
                if (_veh == _unit) then {
                    // units : 1.5 minutes (after 4x as much [7min] it will be deleted)
                    _stuckLimit = 4;
                    _delay = 90;
                } else {if (_spawnedTime + NEWLY_SPAWNED_TIME > time) then {
                    // new vehicles : 20 sec (after 4x as much [80sec] it will be deleted)
                    _stuckLimit = 4;
                    _delay = 20;
                } else {
                    // old vehicles : 1.1 minutes (after 4x as much [5min] it will be deleted)
                    _stuckLimit = 4;
                    _delay = 75;
                }};
                _timeout = time + _delay;
                _maxTime = _timeout;
                if (_pos distance _prevPos < 5) then {
                    private _nearestPlayer = [_pos,playableUnits] call ITW_FncClosest;
                    if (_nearestPlayer distance2D _pos > 800 && {_stuckCnt > _stuckLimit}) then {
                        // no one around and over stuck limit
                        if (_veh isEqualTo _unit) then {    
                            deleteVehicle _unit;
                            if (count units _unitGrp == 0) then {[[_unitGrp],"deleteGroup",_unitGrp] call ITW_FncRemoteLocalGroup};
                        } else {
                            deleteVehicleCrew _veh;
                            deleteVehicle _veh;  
                        };
                    } else {
                        if (_nearestPlayer distance2D _pos > 100) then {
                            private _newWpGrp = grpNull;
                            if (_veh isEqualTo _unit && {leader _unit == _unit}) then {_newWpGrp = group _unit};
                            if !(_veh isEqualTo _unit) then {_newWpGrp = group driver _veh};
                            if (!isNull _newWpGrp) then {{deleteWaypoint _x} forEachReversed waypoints _newWpGrp};
                            // under stuck limit (or players too nearby)
                            if (isTouchingGround _veh) then {
                                // land vehicles
                                if (_veh == _unit && {_stuckCnt < (_stuckLimit/2)}) exitWith {}; // units standing still get longer to get moving
                                private _dist = if (_veh isEqualTo _unit) then {2} else {10};
                                private _handled = false;
                                if !(_veh isEqualTo _unit) then {
                                    private _advPos = _pos getPos [50,getDir _veh] ;
                                    private _roads = _advPos nearRoads 200;
                                    private _road = [_advPos,_roads] call ITW_FncClosest;
                                    if (!isNull _road) then {
                                        private _roadInfo = getRoadInfo _road;
                                        private _roadPosASL = _roadInfo#6;
                                        _roadPosASL set [2,_roadPosASL#2 + 0.2];
                                        private _dirR = _roadPosASL getDir (_roadInfo#7);
                                        private _dirV = getDir _veh;
                                        private _abs = abs (_dirR - _dirV);
                                        private _angle = _abs min (360 - _abs);
                                        if (_angle > 90) then {
                                            _dirR = _dirR + 180;
                                        };
                                        _veh setDir _dirR;
                                        _veh setPosASL _roadPosASL;
                                        _handled = true;
                                   };
                                };
                                if (!_handled) then {
                                    private _newPos = _pos findEmptyPosition [_dist,200,typeOf _veh];
                                    if !(_newPos isEqualTo []) then {
                                        _newPos set [2,4];
                                        [_veh,_newPos] call ITW_AtkSafeSetVectorUp;
                                        _pos = getPosATL _veh;
                                    };
                                };
                            } else {  
                                if (_veh isKindOf "Ship") then {
                                    // ships
                                    private _newPos = _pos findEmptyPosition [10,200,typeOf _veh];
                                    if !(_newPos isEqualTo []) then {
                                        _newPos set [2,0.5];
                                        [_veh,ASLToATL _newPos] call ITW_AtkSafeSetVectorUp;
                                        _pos = getPosASL _veh;
                                    };
                                } else {
                                    // aircraft
                                    private _newPos = _pos getPos [10,random 360];
                                    _newPos set [2,_pos#2];
                                    _veh setPosATL _newPos;
                                    _pos = getPosATL _veh;
                                };
                            };
                        };
                        _veh setVariable ["StuckPos",[_timeout,_maxTime,_pos,_stuckCnt + 1,_spawnedTime]];                 
                    };
                } else {
                    if (_prevPos isEqualTo INIT_PREV_POS) then {
                        // if initial check, then we really haven't moved yet so leave _delay as is
                        _timeout = time + _delay;
                        _maxTime = _timeout;
                    } else {
                        _started = true; // some vehicles have moved so we can wait a while 
                        _timeout = time + AFTER_MOVE_TIME;
                        _maxTime = time + (AFTER_MOVE_TIME*2); // allow a variation in the time to trigger this routine less often
                    };
                    _veh setVariable ["StuckPos",[_timeout,_maxTime,_pos,0,_spawnedTime]];
                };             
            };
            private _timeLeft = _maxTime - time;
            if (_timeLeft < _sleepTime) then {_sleepTime = _timeLeft};
            
            
        } count _allUnits; 
                
        private _sleepUntil = time + (if (_started) then {20 max _sleepTime min AFTER_MOVE_TIME} else {20}); 
        while {time < _sleepUntil && {!ITW_AtkNewVehSpawned}} do {sleep 10};
        while {LV_PAUSE} do {sleep 5};
    };
};

ITW_AtkGetInfantryGroups = {
    private _managedGroups = allGroups select {
        private _grp = _x;
        private _leader = leader _grp;
        side _x in [east,west,independent] && {
        count units _grp > 0               && {
        _leader isEqualTo vehicle _leader  && {
        !(_grp call ITW_IsGarrisoned)      && {
        !(_leader getVariable ["LV_PAUSE",false]) && {
        !(_grp getVariable ["itwDelivery",false]) && {
        !(!isNil "IGIT_HCC_HC_Groups_Array" && {_grp in IGIT_HCC_HC_Groups_Array}) && { // // hack for HCC (High Command Converter)
        {isPlayer _x} count units _grp == 0 }}}}}}}
    };    
    _managedGroups
};

ITW_AtkInfantryManager = {
    scriptName "ITW_AtkInfantryManager";
    waitUntil {sleep 1;!isNil "ITW_MaxFriendlyUnits"};
    waitUntil {sleep 1; count call ITW_AtkGetInfantryGroups > 2};
    private _playerSide = ITW_PlayerSide;
    private _enemySide = ITW_EnemySide;
    private _objSize = ITW_ParamObjectiveSize;
    private _garrisonSafeSize = _objSize + 300;
    private _garrisonMaxCntE = 0;
    private _garrisonMaxCntF = 0;
    private _minSquadSize = AI_SQUAD_SIZE * 0.75;
    private _objCount = 
    switch (ITW_ParamGarrison) do {
        case 1: {
            _garrisonMaxCntE = 6 max (ITW_ParamEnemyAiCnt /ITW_ParamObjectivesPerZone/3) min 18; // 6 to 18 units
            _garrisonMaxCntF = 6 max (ITW_MaxFriendlyUnits/ITW_ParamObjectivesPerZone/3) min 18; 
        };
        case 2: {
            _garrisonMaxCntE = 12 max (ITW_ParamEnemyAiCnt /ITW_ParamObjectivesPerZone*2/3) min 50; // 12 to 50 units
            _garrisonMaxCntF = 12 max (ITW_MaxFriendlyUnits/ITW_ParamObjectivesPerZone*2/3) min 50; 
        };
        default {};
    };
    while {!ITW_GameOver} do {
        while {ITW_ObjZonesUpdating} do {sleep 0.5};
        SEM_LOCK(ITW_AtkInfantryManagerBusy);
        
        // check if any objectives need a garrison
        private _friendlyGarrisonObjs = createHashMap; // array of [objId,#unitsToGarrison]
        private _enemyGarrisonObjs = createHashMap;  
        if (ITW_ParamGarrison > 0) then {
            {
                private _obj = _x;
                private _objPos = _obj#ITW_OBJ_POS;
                private _objIdx = _obj#ITW_OBJ_INDEX;
                private _objIsFriendly = [_objIdx] call ITW_ObjContestedOwnerIsFriendly;
                private _badSide = if (_objIsFriendly) then {_enemySide} else {_playerSide};
                private _safeToGarrison = true;
                {
                    private _grp = _x;
                    if (side _grp == _badSide && {{ALIVE(_x) && {_x distance _objPos < _garrisonSafeSize}} count units _grp > 0}) exitWith {_safeToGarrison = false};
                } count call ITW_AtkGetInfantryGroups;
                if (_safeToGarrison) then {;
                    private _garrisonMaxCnt = if (_objIsFriendly) then {_garrisonMaxCntF} else {_garrisonMaxCntE};
                    private _garrisonCurrSize = [_objPos,if (_objIsFriendly) then {_playerSide} else {_enemySide}] call ITW_GarrisonSize;
                    if (_garrisonCurrSize < _garrisonMaxCnt) then {
                        if (_objIsFriendly) then {
                            _friendlyGarrisonObjs set [_objIdx,_garrisonMaxCnt - _garrisonCurrSize];
                        } else {
                            _enemyGarrisonObjs set [_objIdx,_garrisonMaxCnt - _garrisonCurrSize];
                        };
                    };
                };
            } forEach ([]call ITW_ObjGetContestedObjs);
        };
        
        private _smallGroups = [];
        private _managedGroups = call ITW_AtkGetInfantryGroups;
        {
            private _grp = _x;
            private _grpSize = {alive _x} count units _grp; 
            
            // ignore groups that are entering vehicles via the Ally or Enemy manager
            if (_grp getVariable ["ITW_getInState",-1] != -1) then {continue};
            
            private _leader = leader _grp;
            if (!ALIVE(_leader)) then {
                _alive = units _grp select {ALIVE(_x)};
                if !(_alive isEqualTo []) then {_leader = _alive#0};
            };
            
            // ignore groups in vehicles (they are being managed by the vehicle manager)
            if (vehicle _leader != _leader) then {continue};
            
            // groups that bailed out of their vehicle need to un-assign it and move on
            if !(isNull assignedVehicle _leader) then {{ [_x] remoteExec ["unassignVehicle",_x] } forEach units _grp};
            
            // keep track of small groups so we can join them up
            if (_grpSize < 2 && {vehicle _leader == _leader}) then {
                if !(_grp getVariable ["smallGrp",false]) then {
                    _grp setVariable ["smallGrp",true];
                } else {
                    _smallGroups pushBack _grp;
                };
            } else {
                _grp setVariable ["smallGrp",nil];
            };
            
            private _objIdx = VAR_GET_OBJ_IDX(_grp);
            if (_objIdx < 0) then {
                [_grp,false] spawn ITW_AtkEngageInfantry;
                continue;
            };
            
            private _obj = ITW_Objectives#_objIdx;
            private _objPt = _obj#ITW_OBJ_POS;
            private _dist = _leader distance2D _objPt;
            
            // setup garrisons as needed
            if (ITW_ParamGarrison > 0 && {_dist < _objSize}) then {
                private _isFriendly = side _grp == _playerSide;
                private _garrisonHashMap = if (_isFriendly) then {_friendlyGarrisonObjs} else {_enemyGarrisonObjs};
                private _cnt = _garrisonHashMap getOrDefault [_objIdx,0];
                if (_cnt > 1) then { // not > 0 just to keep from adding a lot when only a few more are allowed
                    _garrisonHashMap set [_objIdx,_cnt - count units _grp];
                    [_objPt,_objSize,[_grp]] spawn ITW_Garrison;
                    continue;
                };
            };
            
            // UPDATE WAYPOINTS 
            private _wpIdx = currentWaypoint _grp;
            if (vehicle _leader == _leader &&                                 // not in transit
                  {!VAR_GET_WAIT_TRANSP(_grp) &&                              // not awaiting transport
                  {_wpIdx == 0 || _wpIdx >= count waypoints _grp}}) then {    // not executing any waypoints
                ATK_DEBUG("INF WAYPOINTS-udpateWP",_grp,"");
                ITW_DELETE_WAYPOINTS(_grp);
                private _wpPos = if (_leader distance _objPt <= 600) then {
                    [_objPt,_objSize] call ITW_AtkWpPoint;
                } else {
                    _leader getPos [0 max (_dist - 400),_leader getDir _objPt];
                };
                if (surfaceIsWater _wpPos) then {
                    _wpPos = [_objPt,_objSize] call ITW_AtkWpPoint;
                };              
                private _wp = _grp addWaypoint [_wpPos,0];
                _wp setWaypointBehaviour "AWARE";
                _wp setWaypointSpeed "FULL";
                _wp setWaypointCombatMode "YELLOW";
                _wp setWaypointType "MOVE";
                _wp setWaypointCompletionRadius 50;
                _wp setWaypointStatements ["true",format ['
                    if (isNil "thisList") exitWith {};
                    private _grp = group this;
                    if (isNull _grp) exitWith {};
                    {deleteWaypoint _x} forEachReversed waypoints _grp;
                    private _wp1 = _grp addWaypoint [[%1,%2] call ITW_AtkWpPoint, 0];
                    _wp1 setWaypointBehaviour "AWARE";
                    _wp1 setWaypointSpeed "NORMAL";
                    _wp1 setWaypointCombatMode "RED";
                    _wp1 setWaypointType "SAD";
                    _wp1 setWaypointFormation selectRandom ["WEDGE","VEE","STAG COLUMN","DIAMOND"];
                    _wp1 setWaypointStatements ["true","
                        if (isNil ""thisList"") exitWith {};
                        private _grp = group this;
                        [_grp,currentWaypoint _grp] setWaypointPosition [[%1,%2] call ITW_AtkWpPoint,0]"];
                    
                    private _wp2 = _grp addWaypoint [%1,0];
                    _wp2 setWaypointType "CYCLE";
                    _wp2 setWaypointCompletionRadius %2;
                ',_objPt,_objSize]];                
                ATK_DEBUG(_grp,"waypoints updated",""); 
            };
            
            // Limit fleeing
            private _fleeTime = _grp getVariable ["ITW_fleeTimeout",0];
            if (fleeing _leader) then {               
                if (_fleeTime == 0) then {
                    _grp setVariable ["ITW_fleeTimeout",time + FLEE_TIMEOUT];   
                } else {
                    if (time > _fleeTime) then {
                        if (_fleeTime >= 0) then {_grp setVariable ["ITW_fleeTimeout",-(time + FLEE_TIMEOUT)]};
                        ATK_DEBUG("VEHBOARD-FleeMove",_grp,"");                      
                        _grp allowFleeing 0;
                        {_x moveTo getPosATL _x} forEach units _grp;                   
                    };
                };
            } else {
                if (_fleeTime != 0 && {time > -(_fleeTime)}) then {
                    _grp setVariable ["ITW_fleeTimeout",0];
                    _grp allowFleeing (1-UNIT_COURAGE);
                };
            };  
        } count _managedGroups;
        
        // Merge small groups into other groups
        if (count _smallGroups >= _minSquadSize) then {
            private _grpsF = _smallGroups select {side _x == west};
            private _grpsE = _smallGroups select {side _x != west};
            while {count _grpsF >= _minSquadSize} do {
                private _newSqaud = _grpsF select [0,_minSquadSize];
                _grpsF = _grpsF - _newSqaud;
                _newSqaud joinSilent (_newSqaud#0);
            };
            while {count _grpsE >= _minSquadSize} do {
                private _newSqaud = _grpsE select [0,_minSquadSize];
                _grpsE = _grpsE - _newSqaud;
                _newSqaud joinSilent (_newSqaud#0);
            };
            _smallGroups = _grpsF + _grpsE
        };
        {
            private _grp = _x;
            private _side = side _grp;
            private _unitCnt = {ALIVE(_x)} count units _grp;
            private _otherSquads = (_managedGroups select {side _x == _side}) - [_grp];
            private _nearestSquad = [_otherSquads, getPosATL leader _grp] call BIS_fnc_nearestPosition;
            if (typeName _nearestSquad == "GROUP" && {getPosATL leader _nearestSquad distance leader _grp < 800}) then {
                units _grp joinSilent _nearestSquad;
                [[_grp],"deleteGroup",_grp] call ITW_FncRemoteLocalGroup;
            };
        } forEach _smallGroups;
        
        SEM_UNLOCK(ITW_AtkInfantryManagerBusy);
        
        // slowly damage any unit in the other teams zones so they eventually die if stuck there
        {
            private _unit = _x;
            if (isPlayer _unit || {side _unit == civilian || {_unit isKindOf "LOGIC"}}) then {continue}; // players don't take damage
            if (!isDamageAllowed _unit) then {[_unit,true] remoteExec ["allowDamage",_unit]}; // Hack for: every once in a while I'm seeing units not allowing damage only on server
            private _pos = getPosATL _unit;
            private _isFriendly = side _x == west;
            private _nearestContestedObj = [_pos,ITW_OWNER_CONTESTED,ITW_OWNER_CONTESTED] call ITW_ObjGetNearest;
            if (_nearestContestedObj#ITW_OBJ_POS distanceSqr _pos > ZONE_KEEP_OUT_SQR) then {
                private _nearestObj = [_pos,if (_isFriendly) then {ITW_OWNER_ENEMY} else {ITW_OWNER_FRIENDLY}] call ITW_ObjGetNearest;
                private _nearestBase = ITW_Bases#(_nearestObj#ITW_OBJ_INDEX);
                if (_nearestBase#ITW_BASE_POS distanceSqr _pos < ZONE_KEEP_OUT_SQR) then {_unit setDamage (damage _unit + 0.1)}; // die in 5 minutes
            }; 
        } count allUnits;
        sleep 30;
        while {LV_PAUSE} do {sleep 5};
    };
};
    
ITW_AtkWpPoint = {
    params ["_center","_size",["_vehType",0],["_innerClearSize",0]];
    //_vehType 0 for infantry
    private "_blacklist";
    switch (true) do {
        case ITW_VEH_IS_SEA(_vehType): {_blacklist = ["ground"]};
        case ITW_VEH_IS_AIR(_vehType): {_blacklist = []};
        default                        {_blacklist = ["water"]}; // land veh or infantry
    };
    if (_innerClearSize > 0) then {_blacklist pushBack [_center,_innerClearSize]};
    private _wpPos = [[[_center,_size]],_blacklist] call BIS_fnc_randomPos;
    if (_wpPos isEqualTo [0,0]) then {
        _wpPos = _center;
        if (ITW_VEH_IS_SEA(_vehType)) then {
            private _obj = [_center,ITW_OWNER_CONTESTED,ITW_OWNER_CONTESTED,true] call ITW_ObjGetNearest;
            if !(_obj isEqualTo []) then {
                private _index = _obj#ITW_OBJ_INDEX;
                private _seaPts = if (count ITW_SeaPoints > _index) then {ITW_SeaPoints#_index} else {[]};
                if !(_seaPts isEqualTo []) then {
                    _wpPos = selectRandom _seaPts;
                };
            };
        };
    };
    _wpPos;
};

ITW_AtkVehicleManager = {
    scriptName "ITW_AtkVehicleManager";
    private _zoneIndex = ITW_ZoneIndex; 
    private _sleepCnt = 0;
    private _unloadDistance = ITW_ParamObjectiveSize + UNLOAD_DISTANCE;
    private _unloadDistanceAir = _unloadDistance + 600;
    private _unloadDistanceSea = ITW_ParamObjectiveSize + 400;
    private _heliSlowDist0 = _unloadDistanceAir + 300;
    private _heliSlowDist1 = _unloadDistanceAir + 500;
    private _heliSlowDist2 = _unloadDistanceAir + 1000;
    private _heliSlowDist3 = _unloadDistanceAir + 1500;
    private _heliSlowDist4 = _unloadDistanceAir + 2000;
    private _heliSlowDist5 = _unloadDistanceAir + 2500;
    private _heliSlowDist6 = _unloadDistanceAir + 3000;
    private _cleanupDist = 1500 - (1300 * ITW_ParamAggressiveCleanup);
    private _travelHdlrDist = ITW_ParamObjectiveSize + 300;
    private _objSize = ITW_ParamObjectiveSize;
    while {!ITW_GameOver} do {
        while {LV_PAUSE} do {sleep 5};
        while {ITW_ObjZonesUpdating} do {sleep 0.5};
        SEM_LOCK(ITW_AtkVehicleManagerBusy);
        private _removeVehs = [];
        private _aircraft = [];
        private _managedVehs = ITW_ManagedVehs;
        {
            private _vehInfo = _x;
            _vehInfo params ["_type","_role","_veh","_grp","_cargoGroups","_fromPos"];
            
            private _vehStartSafe = _veh getVariable ["ITW_VehStartSafe",[]];
            if !(_vehStartSafe isEqualTo []) then {
                _vehStartSafe params ["_startPos","_startTime"];
                if (_veh distance _startPos > 50 || time > _startTime) then {
                    _veh setVariable ["ITW_VehStartSafe",nil];
                    [_veh,true] remoteExec ["allowDamage",_veh];
                    private _crewGrps = crew _veh apply {group _x};
                    _crewGrps = (_crewGrps arrayIntersect _crewGrps) - [grpNull];
                    if !(_crewGrps isEqualTo []) then {
                        [_crewGrps,true] call ITW_AtkSafeGroupAllowDamage;
                    };
                };
            };
            
            private _aliveCrew = units _grp select {ALIVE(_x)};
            
            // remove empty & broken vehicles from the manager
            if (_aliveCrew isEqualTo [] || {!canMove _veh || {fuel _veh == 0}}) then {
                if (isTouchingGround _veh || {(getPos _veh)#2 < 5}) then { // getPos to handle on water or land
                    _removeVehs pushBack _vehInfo; 
                    {_x leaveVehicle _veh; [_x] remoteExec ["unassignVehicle",_x]} forEach crew _veh;
                    _veh setVariable ["ITW_CleanupVeh",true];
                    _veh setVariable ["ITW_VehDef",nil];
                };
                continue;
            };
            
            private _objIdx = VAR_GET_OBJ_IDX(_grp);
            if (_objIdx < 0) then {
                [_vehInfo,false] call ITW_AtkEngageVehicle;
                continue;
            };
            
            // reassign leader if needed
            private _leader = leader _grp;
            if (!ALIVE(_leader)) then {
                if !(_aliveCrew isEqualTo []) then {_leader = _aliveCrew#0};
            };
            
            // if driver is dead, move other crew into driver seat
            if (! ALIVE(driver _veh) && {!(_aliveCrew isEqualTo [])}) then {
                private _newDriver = _aliveCrew#-1;
                moveOut _newDriver;
                _newDriver moveInDriver _veh;
            };
            
            private _obj = ITW_Objectives#_objIdx;
            private _objPt = _obj#ITW_OBJ_POS;
            
            // unload cargo
            if !(_cargoGroups isEqualTo []) then {
                if (_veh getVariable ["UnloadingCargo",false]) then {
                    private _cargoStillIn = false;
                    {{if (alive _x && {vehicle _x == _veh}) then {_cargoStillIn = true}} forEach (units _x)} forEach _cargoGroups;
                    if !(_cargoStillIn) then {
                        ATK_DEBUG("VEH UNLOADED",_veh,_type);  
                        _vehInfo set [VEHINFO_CARGO_GRPS,[]];
                        _veh setVariable ["UnloadingCargo",nil];
                        if (_veh isKindOf "Helicopter") then {
                            _veh limitSpeed 500;
                            _veh flyInHeight 30;
                        };
                    };
                    continue
                } else {
                    private _distToAo = _veh distance _objPt;
                    private _unloadDist = switch (true) do {
                        case (_veh isKindOf "Air"): {_unloadDistanceAir};
                        case (_veh isKindOf "Ship"): {_unloadDistanceSea};
                        default {_unloadDistance + 150 - random 50}; // random so long line of vehs stop at different distances
                    };
                    if (_distToAo < _unloadDist) then {
                        ATK_DEBUG("VEH UNLOAD",_veh,_type);                    
                        switch (_type) do {
                            case ITW_TYPE_VEH_AIRPLANE: { [_veh,_grp,_cargoGroups,_objPt] spawn ITW_AtkUnloadAirplane};
                            case ITW_TYPE_VEH_HELI    : { [_veh,_grp,_cargoGroups,_objPt] spawn ITW_AtkUnloadHeli    };
                            case ITW_TYPE_VEH_SHIP    : { [_veh,_grp,_cargoGroups,_objPt] spawn ITW_AtkUnloadShip    };
                            default                     { [_veh,_grp,_cargoGroups,_objPt] spawn ITW_AtkUnloadLand    };
                        };
                        _veh setVariable ["UnloadingCargo",true];
                        continue
                    } else {
                        if (_veh isKindOf "Helicopter") then {
                            // helicopters need to slow down as they get close
                            private ["_speed","_height"];
                            switch (true) do {
                                case (_distToAo < _heliSlowDist0): {_speed =  80;_height = 10};  // < 300
                                case (_distToAo < _heliSlowDist1): {_speed =  90;_height = 11};  // < 500
                                case (_distToAo < _heliSlowDist2): {_speed = 110;_height = 16};  // < 1000
                                case (_distToAo < _heliSlowDist3): {_speed = 150;_height = 23};  // < 1500
                                case (_distToAo < _heliSlowDist4): {_speed = 190;_height = 30};  // < 2000
                                case (_distToAo < _heliSlowDist5): {_speed = 230;_height = 37};  // < 2500
                                case (_distToAo < _heliSlowDist6): {_speed = 270;_height = 44};  // < 3000
                                default                            {_speed = 500;_height = 50};  // >= 3000
                            };                          
                            _veh limitSpeed _speed;
                            _veh flyInHeight _height;
                        };
                    };
                };
            
                // transports need to keep moving even if enemy are around, so forget further out enemy
                private _driver = driver _veh;
                _driver targets [true] select {_veh distance _x > 500} apply {_driver forgetTarget _x};
            };
            
            // transports and attack vehicles w/o ammo need to vacate the area after unloading
            private _driverGrp = group driver _veh;
            private _transportDone = (_role == ITW_VEH_ROLE_TRANSPORT) && {_cargoGroups isEqualTo []};
            private _attackDone = (_role != ITW_VEH_ROLE_TRANSPORT) && 
                                        {_cargoGroups isEqualTo [] && 
                                        {{_veh ammo currentMuzzle _x > 0} count crew _veh == 0}};
            private _dualTransDone = (_role == ITW_VEH_ROLE_DUAL) && {_cargoGroups isEqualTo [] && {waypointType [_driverGrp, currentWaypoint _driverGrp] isEqualTo "TR UNLOAD"}};
            if (_dualTransDone) then {{deleteWaypoint _x} forEachReversed waypoints _driverGrp};
            if (_transportDone || _attackDone) then {
                private _extraGroupsInCargo = [];
                crew _veh select {alive _x && {group _x != _grp}} apply {_extraGroupsInCargo pushBackUnique group _x};
                if !(_extraGroupsInCargo isEqualTo []) then {
                    {ITW_DELETE_WAYPOINTS(_x)} forEach _extraGroupsInCargo;
                    _cargoGroups = _extraGroupsInCargo;
                    _role = ITW_VEH_ROLE_TRANSPORT;
                    _vehInfo set [VEHINFO_CARGO_GRPS,_cargoGroups];
                    _vehInfo set [VEHINFO_ROLE,_role];
                } else {
                    ATK_DEBUG("VEH Atk/Trans Done",_grp,"");
                    _vehInfo set [VEHINFO_ROLE,ITW_VEH_ROLE_COMPLETE];
                    _role = ITW_VEH_ROLE_COMPLETE;
                    ITW_DELETE_WAYPOINTS(_grp);
                    _removeVehs pushBack _vehInfo;
                    private _wp1 = _grp addWaypoint [_fromPos,0];
                    _wp1 setWaypointBehaviour "CARELESS";
                    _wp1 setWaypointSpeed "FULL";
                    _wp1 setWaypointCombatMode "YELLOW";
                    _wp1 setWaypointType "MOVE";
                    _wp1 setWaypointCompletionRadius 200;                 
                    if (_veh isKindOf "Air") then {
                        // aircraft can fly right to a good despawn position
                        _wp1 setWaypointStatements ["true", 
                                'if (isServer) then {                      
                                    private _veh = vehicle this;
                                    private _grp = group (crew _veh #0);
                                    deleteVehicleCrew _veh;
                                    deleteVehicle _veh;
                                    if (!isNil "_grp" && {count units _grp == 0}) then {[[_grp],"deleteGroup",_grp] call ITW_FncRemoteLocalGroup};
                                }']; 
                    } else {
                        if (ITW_ParamDespawnTransports == 1) then {
                            deleteVehicleCrew _veh;
                            deleteVehicle _veh;
                        };
                        // land vehicles need to drive back to their spawn point
                        // and then drive a bit further if possible
                        _wp1 setWaypointStatements ["true", 
                            'if (isServer) then {
                                this spawn {
                                    scriptName "ITW_AtkVehicleManager - transport return";
                                    private _veh = vehicle _this;
                                    sleep 30;
                                    private _grp = group (crew _veh #0);
                                    deleteVehicleCrew _veh;
                                    deleteVehicle _veh;
                                    if (!isNil "_grp" && {count units _grp == 0}) then {[[_grp],"deleteGroup",_grp] call ITW_FncRemoteLocalGroup};
                                };
                            }']; 
                        private _wp2 = _grp addWaypoint [_fromPos getPos [1000,getPosATL _veh getDir _fromPos],0];
                        _wp2 setWaypointType "MOVE";
                        _wp2 setWaypointCompletionRadius 200;
                    };
                    continue;
                };
            };
            
            // UPDATE WAYPOINTS  
            private _wpIdx = currentWaypoint _grp;
            if (_wpIdx == 0 || {_wpIdx >= count waypoints _grp}) then {    // not executing any waypoints
                ATK_DEBUG("VEH WAYPOINTS-udpateWP",_grp,"");
                ITW_DELETE_WAYPOINTS(_grp);
                private _dist = _leader distance2D _objPt;
                private "_wpPos";
                if (ITW_VEH_IS_SEA(_type)) then {
                    _wpPos = selectRandom (ITW_SeaPoints#_objIdx);
                    if (isNil "_wpPos") then {_wpPos = [_objPt,_objSize,_type] call ITW_AtkWpPoint};
                } else {
                    _wpPos = _leader getPos [0 max (_dist - 400),_leader getDir _objPt];
                };
                private _wp = _grp addWaypoint [_wpPos,0];
                _wp setWaypointBehaviour "AWARE";
                _wp setWaypointSpeed "FULL";
                _wp setWaypointCombatMode "YELLOW";
                _wp setWaypointType "MOVE";
                _wp setWaypointCompletionRadius 100;
                _wp setWaypointStatements ["true",format ['
                    if (isNil "thisList") exitWith {};
                    private _grp = group this;
                    if (isNull _grp) exitWith {};
                    {deleteWaypoint _x} forEachReversed waypoints _grp;
                    private _wp1 = _grp addWaypoint [[%1,%2,%3] call ITW_AtkWpPoint, 0];
                    _wp1 setWaypointBehaviour "AWARE";
                    _wp1 setWaypointSpeed "NORMAL";
                    _wp1 setWaypointCombatMode "RED";
                    _wp1 setWaypointType "SAD";
                    _wp1 setWaypointFormation selectRandom ["WEDGE","VEE","STAG COLUMN","DIAMOND"];
                    _wp1 setWaypointStatements ["true","
                        if (isNil ""this"") exitWith {};
                        private _grp = group this;
                        [_grp,currentWaypoint _grp] setWaypointPosition [[%1,%2,%3] call ITW_AtkWpPoint,0]"];
                    
                    private _wp2 = _grp addWaypoint [%1,0];
                    _wp2 setWaypointType "CYCLE";
                    _wp2 setWaypointCompletionRadius %2;
                ',_objPt,_objSize,_type]]; 
                ATK_DEBUG(_grp,"waypoints updated",""); 
                _wpIdx = currentWaypoint _grp;
            };
            
            // Travel handler - slow down/speed up vehicles if vehicles in their way
            if (_veh distance _objPt > _travelHdlrDist) then {
                _wpPos = waypointPosition [_grp,_wpIdx];
                if !(_wpPos isEqualTo [0,0,0] || {_wpPos distance _veh < 300}) then {
                    private _frontPos = _veh getPos [102,getDir _veh];
                    // if veh within 100m in front, then slow down
                    if ({(_x#VEHINFO_VEH) distance _frontPos < 100} count _managedVehs > 0) then {
                        _grp setSpeedMode "LIMITED";
                    } else {
                        _grp setSpeedMode "FULL";
                    };
                };
            };   
            
            if (_veh isKindOf "Air") then {_aircraft pushBack _veh};
        } forEach _managedVehs;
        
        // remove dead groups
        if !(_removeVehs isEqualTo []) then {ITW_ManagedVehs = ITW_ManagedVehs - _removeVehs};
        
        SEM_UNLOCK(ITW_AtkVehicleManagerBusy);
        
        // SLEEP
        private _sleepTime = 8;
        if (_aircraft isEqualTo []) then {sleep _sleepTime} else {
            // while sleeping, check if any aircraft crew need to eject
            for "_i" from 1 to _sleepTime step 1 do {
                sleep 1;
                while {LV_PAUSE} do {sleep 5};
                private _aircraftUnloaded = [];
                {
                    private _veh = _x;
                    if ((isNull (currentPilot _veh) || {!canMove _veh || fuel _veh == 0}) && {getPosATL _veh #2 > 50}) then {
                        // use airplane unload even for helis if they are crashing
                        private _groups = crew _veh select {alive _x} apply {group _x};
                        [_veh,grpNull,_groups arrayIntersect _groups,getPosATL _veh] spawn ITW_AtkUnloadAirplane;
                        _aircraftUnloaded pushBack _veh;
                    };
                    false
                } count _aircraft;
                if !(_aircraftUnloaded isEqualTo []) then {_aircraft = _aircraft - _aircraftUnloaded};
            };
        };
        while {ITW_ObjZonesUpdating} do {sleep 0.5};
        
        // Update count and dead vehicles every 30 seconds
        _sleepCnt = _sleepCnt + _sleepTime;
        if (_sleepCnt >= 30) then {
            _sleepCnt = 0;
            ITW_VehArraysUpdating = true;
            ITW_VehArrays apply {_x set [ITW_VEH_COUNT,0]};
            if (ITW_ParamAggressiveCleanup >= 0) then {
                {
                    private _veh = _x;
                    if (_veh in ITW_Statics) then {continue};
                    if (_veh isKindOf "AllVehicles") then {
                        _cleanUp = _veh getVariable ["ITW_CleanupVeh",false];
                        if (_cleanUp && {{isPlayer _x} count crew _veh > 0}) then {_veh setVariable ["ITW_CleanupVeh",false]};
                        
                        // alive but empty vehicles are 'disableSimulation'ed in ITW_Vehicles
                        if (!alive _veh || {!canMove _veh || {fuel _veh == 0 || {_cleanUp}}}) then {
                            if (_veh getVariable ["ITW_CleanupTime",0] == 0) then {
                                _veh setVariable ["ITW_CleanupTime",time + 200];
                            } else {
                                if (_veh getVariable ["ITW_CleanupTime",1e10] < time) then {
                                    private _remove = true;
                                    {
                                        private _dist = _veh distance _x;
                                        if (_dist < _cleanupDist) exitWith {_remove = false};
                                    } count playableUnits;
                                    if (_remove) then {
                                        deleteVehicle _veh;
                                    };
                                };
                            };
                        } else {
                            _veh setVariable ["ITW_CleanupTime",nil];
                            private _vehDef = _veh getVariable ["ITW_VehDef",[]];
                            if !(_vehDef isEqualTo []) then {
                                ITW_VEH_COUNT_INCR(_vehDef);
                            };
                        };
                    };
                } count vehicles;   
            };
            ITW_VehArraysUpdating = false;
        };
    };
};

ITW_AtkUnloadAirplane = {
    params ["_veh","_crewGroup","_cargoGroups","_objPt"];
    scriptName "ITW_AtkUnloadAirplane";
    // keep flying over target
    if !(_crewGroup isEqualTo grpNull) then {
        ITW_DELETE_WAYPOINTS(_crewGroup);
        private _vPos = getPosATL _veh;
        private _wPos = _vPos getPos [1000,getDir _veh];
        _wPos set [2,_vPos#2];
        private _wp = _crewGroup addWaypoint [_wPos,100];
        _wp setWaypointBehaviour "CARELESS";
    };
    if !(_objPt isEqualTo []) then {
        private _timeout = time + 60;
        waitUntil {sleep 0.5;!surfaceIsWater getPosATL _veh || {time > _timeout}};
        private _unloadDist = ITW_ParamObjectiveSize + UNLOAD_DISTANCE + 100;
        waitUntil {sleep 0.25;_veh distance2D _objPt < _unloadDist || {time > _timeout}};
    };
    private _toggle = true;
    {
        private _grp = _x;
        {
            private _unit = _x;
            if (!alive _unit || {vehicle _unit != _veh}) then {continue};
            private _dirTo = getDir _veh;
            private _vPos = getPosASL _veh;
            private _pos = if (_toggle) then {_veh modeltoWorld [7, -20, -15]} else {_veh modeltoWorld [-7, -20, -15]};
            if (_pos#2 < 0) then {_pos set [2,0]};
            _toggle = !_toggle;
            [_unit,_pos] call ITW_AtkParachute;
        } count units _grp;
        false
    } count _cargoGroups;
};

ITW_AtkParachute = {
    // delays 1/2 sec even if unit is not local
    params ["_unit","_pos"];
    if (!alive(_unit)) exitWith {};
    if (!local _unit) exitWith {
        [_unit,_pos] remoteExec ["ITW_AtkParachute",_unit];
        sleep 0.5;
    };
    private _para = "Steerable_Parachute_F" createVehicle _pos;
    _unit allowDamage false;
    _para setpos _pos;
    _para setdir _dirTo;
    [_unit] remoteExec ["unassignVehicle",_unit];
    moveOut _unit;
    _unit moveindriver _para;
    _para lock false;
    sleep 0.5;
    _unit allowDamage true;
};

ITW_AtkUnloadHeli = {
    params ["_veh","_crewGroup","_cargoGroups","_objPt"];
    if (random 1 < 0.5) exitWith {_this call ITW_AtkUnloadAirplane};
    scriptName "ITW_AtkUnloadHeli";
    ITW_DELETE_WAYPOINTS(_crewGroup);
    private _wp = _crewGroup addWaypoint [_objPt getPos [ITW_ParamObjectiveSize + UNLOAD_DISTANCE + 100,_objPt getDir _veh],100];
    _wp setWaypointType "TR UNLOAD";
    _wp setWaypointCompletionRadius 10;
    _wp setWaypointBehaviour "CARELESS";
    private _prevPos = getPosATL _veh;
    waitUntil {
        sleep 2; 
        private _pos = getPosATL _veh;
        private _height = _pos#2;
        if !(_prevPos isEqualTo []) then {
            if (_height < 2 || {isTouchingGround _veh}) exitWith {_prevPos = []};
            if (_pos distance _prevPos < 0.5) then {
                _veh land "LAND";
            } else {
                _prevPos = _pos;
            };
        };
        !alive _veh || {_height < 10 || {isTouchingGround _veh}}
    };
   {_x leaveVehicle _veh; {[_x] remoteExec ["unassignVehicle",_x]} forEach units _x} forEach _cargoGroups; 
};

ITW_AtkUnloadShip = {
    params ["_veh","_crewGroup","_cargoGroups","_objPt"];
    ITW_DELETE_WAYPOINTS(_crewGroup);
    if (_veh isKindOf "Air") exitWith {_this call ITW_AtkUnloadHeli}; // sometime helis take role of ground vehs 
    scriptName "ITW_AtkUnloadShip";
    private _pos = getPos _veh;
    private _wp = _crewGroup addWaypoint [_pos,0];
    _wp setWaypointType "TR UNLOAD";
    _wp setWaypointCompletionRadius 10;
    _wp setWaypointBehaviour "CARELESS";
    _wp setWaypointStatements ["true","_veh setVariable ['doUnload',true]"];
    
    private _timeout = time + 60;
    waitUntil {sleep 1;time > _timeout || _veh getVariable ["doUnload",false]};
    
    {_x leaveVehicle _veh; {[_x] remoteExec ["unassignVehicle",_x]} forEach units _x} forEach _cargoGroups;
    
    private _units = [];
    _cargoGroups apply {_units append units _x};
    while {!(_units isEqualTo [])} do {
        sleep 10;
        {
            if (!CONSCIOUS(_x) || vehicle _x != _x) then {_units deleteAt _forEachIndex; continue};
            moveOut _x;
            unassignVehicle _x;
        } forEachReversed _units;
    };
    private _toPos = _veh getPos [200,_veh getDir (([getPosATL _veh] call ITW_ObjGetNearest)#ITW_BASE_POS)];
    {leader _x doMove _toPos} forEach _cargoGroups;
    if !(_veh getVariable ["doUnload",false]) then {ITW_DELETE_WAYPOINTS(_crewGroup)};
};

ITW_AtkUnloadLand = {
    params ["_veh","_crewGroup","_cargoGroups","_objPt"];
    ITW_DELETE_WAYPOINTS(_crewGroup);
    if (_veh isKindOf "Air") exitWith {_this call ITW_AtkUnloadHeli}; // sometime helis take role of ground vehs 
    scriptName "ITW_AtkUnloadLand";
    private _wp = _crewGroup addWaypoint [_veh getPos [150,getDir _veh + (if (random 1 < 0.5) then {20} else {-20})],0];
    _wp setWaypointType "TR UNLOAD";
    _wp setWaypointCompletionRadius 10;
    _wp setWaypointBehaviour "CARELESS";
    _wp setWaypointStatements ["true","_veh setVariable ['doUnload',true]"];
    
    private _timeout = time + 30;
    waitUntil {sleep 1;time > _timeout || _veh getVariable ["doUnload",false]};
    
    {_x leaveVehicle _veh; {[_x] remoteExec ["unassignVehicle",_x]} forEach units _x} forEach _cargoGroups;
    
    private _units = [];
    _cargoGroups apply {_units append units _x};
    while {!(_units isEqualTo [])} do {
        sleep 1;
        {
            if (!CONSCIOUS(_x) || vehicle _x != _x) then {_units deleteAt _forEachIndex; continue};
        } forEachReversed _units;
    };
    private _toPos = _veh getPos [200,_veh getDir (([getPosATL _veh] call ITW_ObjGetNearest)#ITW_BASE_POS)];
    {leader _x doMove _toPos} forEach _cargoGroups;
    if !(_veh getVariable ["doUnload",false]) then {ITW_DELETE_WAYPOINTS(_crewGroup)};
};

ITW_AtkNext = {
    // reset stuff for next zone
    0 call ITW_AllyNext;
    
    [] call ITW_GarrisonDone;
    
    SEM_LOCK(ITW_AtkVehicleManagerBusy);
    ITW_AtkRoadMap = nil;
    ITW_SpawnOffsets = nil;
    {
        private _vehInfo = _x;
        private _veh = _vehInfo#VEHINFO_VEH;
        private _okayToDelete = !ITW_VEH_IS_AIR(_vehInfo#VEHINFO_TYPE);
        if (_okayToDelete) then {{if (_x distance _veh < 2000) exitWith {_okayToDelete = false}} count (allPlayers - HeadlessClients)};
        if (_okayToDelete) then {
            // delete vehs that are > 2000m from any player
            deleteVehicleCrew _veh;
            [[_vehInfo#VEHINFO_CREW_GRP],"deleteGroup",_vehInfo#VEHINFO_CREW_GRP] call ITW_FncRemoteLocalGroup;
            {[[_x],"deleteGroup",_x] call ITW_FncRemoteLocalGroup} forEach (_vehInfo#VEHINFO_CARGO_GRPS);
            deleteVehicle _veh;
        } else {
            private _role = _vehInfo#VEHINFO_ROLE;
            if (_role != ITW_VEH_ROLE_COMPLETE) then {
                // reset veh crew waypoints so new ones will be assigned
                private _crewGroup = _x#VEHINFO_CREW_GRP;
                ITW_DELETE_WAYPOINTS(_crewGroup);
                VAR_SET_OBJ_IDX(_crewGroup,-1);
            };
            private _cargoGroups = _x#VEHINFO_CARGO_GRPS;
            _cargoGroups apply {VAR_SET_OBJ_IDX(_x,-1)};
        };
    } forEach ITW_ManagedVehs;
    SEM_UNLOCK(ITW_AtkVehicleManagerBusy);
    
    SEM_LOCK(ITW_AtkInfantryManagerBusy);
    // delete groups that are > 1000m from any player
    {
        private _grp = _x;
        VAR_SET_OBJ_IDX(_grp,-1);
        private _leader = leader _grp;
        if (vehicle _leader == _leader) then {
            private _okayToDelete = true;
            {if (_x distance _leader < 1000) exitWith {_okayToDelete = false}} count (allPlayers - HeadlessClients);
            if (_okayToDelete) then {
                {deleteVehicle _x} count (units _grp);
                [[_grp],"deleteGroup",_grp] call ITW_FncRemoteLocalGroup;
            };
        };
    } forEach (call ITW_AtkGetInfantryGroups);
    SEM_UNLOCK(ITW_AtkInfantryManagerBusy);
    
    ITW_AllyIndex = ITW_ZoneIndex;
};

["ITW_AtkMgrDebug"] call SKL_fnc_CompileFinal;
["ITW_AtkManager"] call SKL_fnc_CompileFinal;
["ITW_AtkAiCount"] call SKL_fnc_CompileFinal;
["ITW_AtkUnitToGroup"] call SKL_fnc_CompileFinal;
["ITW_AtkSpawnVeh"] call SKL_fnc_CompileFinal;
["ITW_AtkAddInfantryGroup"] call SKL_fnc_CompileFinal;
["ITW_AtkAddVehicle"] call SKL_fnc_CompileFinal;
["ITW_AtkEngageInfantry"] call SKL_fnc_CompileFinal;
["ITW_AtkEngageVehicle"] call SKL_fnc_CompileFinal;
["ITW_AtkSpawnOffsetter"] call SKL_fnc_CompileFinal;
["ITW_AtkInfantryManager"] call SKL_fnc_CompileFinal;
["ITW_AtkWpPoint"] call SKL_fnc_CompileFinal;
["ITW_AtkVehicleManager"] call SKL_fnc_CompileFinal;
["ITW_AtkUnloadAirplane"] call SKL_fnc_CompileFinal;
["ITW_AtkUnloadHeli"] call SKL_fnc_CompileFinal;
["ITW_AtkUnloadShip"] call SKL_fnc_CompileFinal;
["ITW_AtkUnloadLand"] call SKL_fnc_CompileFinal;
["ITW_AtkNext"] call SKL_fnc_CompileFinal;
["ITW_AtkVehicleSpawner"] call SKL_fnc_CompileFinal;
["ITW_AtkSwitchToAirVeh"] call SKL_fnc_CompileFinal;
["ITW_AtkStuckHandler"] call SKL_fnc_CompileFinal;
["ITW_AtkAddCrewToStatic"] call SKL_fnc_CompileFinal;
["ITW_AtkGetInfantryGroups"] call SKL_fnc_CompileFinal;
["ITW_AtkAirDropVeh"] call SKL_fnc_CompileFinal;
["ITW_AtkSafeGroupAllowDamage"] call SKL_fnc_CompileFinal;
["ITW_AtkSafeMove"] call SKL_fnc_CompileFinal;
["ITW_AtkSafeSetVectorUp"] call SKL_fnc_CompileFinal;
["ITW_AtkParachute"] call SKL_fnc_CompileFinal;
