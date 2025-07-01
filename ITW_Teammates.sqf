
#define MedicActions ["AinvPknlMstpSnonWnonDnon_medic_1","AinvPknlMstpSnonWnonDnon_medic0","AinvPknlMstpSnonWnonDnon_medic1","AinvPknlMstpSnonWnonDnon_medic2"]
#define HitCries ["A3\Sounds_F\characters\human-sfx\Person0\P0_hit_01.wss", "A3\Sounds_F\characters\human-sfx\Person3\P3_hit_13.wss", "A3\Sounds_F\characters\human-sfx\Person3\P3_hit_12.wss", "A3\Sounds_F\characters\human-sfx\Person3\P3_hit_11.wss", "A3\Sounds_F\characters\human-sfx\Person3\P3_hit_10.wss", "A3\Sounds_F\characters\human-sfx\Person3\P3_hit_09.wss", "A3\Sounds_F\characters\human-sfx\Person3\P3_hit_08.wss", "A3\Sounds_F\characters\human-sfx\Person3\P3_hit_07.wss", "A3\Sounds_F\characters\human-sfx\Person3\P3_hit_06.wss", "A3\Sounds_F\characters\human-sfx\Person3\P3_hit_05.wss", "A3\Sounds_F\characters\human-sfx\Person3\P3_hit_04.wss", "A3\Sounds_F\characters\human-sfx\Person3\P3_hit_03.wss", "A3\Sounds_F\characters\human-sfx\Person3\P3_hit_02.wss", "A3\Sounds_F\characters\human-sfx\Person3\P3_hit_01.wss", "A3\Sounds_F\characters\human-sfx\Person2\P2_hit_09.wss", "A3\Sounds_F\characters\human-sfx\Person2\P2_hit_08.wss", "A3\Sounds_F\characters\human-sfx\Person2\P2_hit_07.wss", "A3\Sounds_F\characters\human-sfx\Person2\P2_hit_06.wss", "A3\Sounds_F\characters\human-sfx\Person2\P2_hit_05.wss", "A3\Sounds_F\characters\human-sfx\Person2\P2_hit_04.wss", "A3\Sounds_F\characters\human-sfx\Person2\P2_hit_03.wss", "A3\Sounds_F\characters\human-sfx\Person2\P2_hit_02.wss", "A3\Sounds_F\characters\human-sfx\Person2\P2_hit_01.wss", "A3\Sounds_F\characters\human-sfx\Person1\P1_hit_11.wss", "A3\Sounds_F\characters\human-sfx\Person1\P1_hit_10.wss", "A3\Sounds_F\characters\human-sfx\Person1\P1_hit_09.wss", "A3\Sounds_F\characters\human-sfx\Person1\P1_hit_08.wss", "A3\Sounds_F\characters\human-sfx\Person1\P1_hit_07.wss", "A3\Sounds_F\characters\human-sfx\Person1\P1_hit_06.wss", "A3\Sounds_F\characters\human-sfx\Person1\P1_hit_05.wss", "A3\Sounds_F\characters\human-sfx\Person1\P1_hit_04.wss", "A3\Sounds_F\characters\human-sfx\Person1\P1_hit_03.wss", "A3\Sounds_F\characters\human-sfx\Person1\P1_hit_02.wss", "A3\Sounds_F\characters\human-sfx\Person1\P1_hit_01.wss", "A3\Sounds_F\characters\human-sfx\Person0\P0_hit_13.wss", "A3\Sounds_F\characters\human-sfx\Person0\P0_hit_12.wss", "A3\Sounds_F\characters\human-sfx\Person0\P0_hit_11.wss", "A3\Sounds_F\characters\human-sfx\Person0\P0_hit_10.wss", "A3\Sounds_F\characters\human-sfx\Person0\P0_hit_09.wss", "A3\Sounds_F\characters\human-sfx\Person0\P0_hit_08.wss", "A3\Sounds_F\characters\human-sfx\Person0\P0_hit_07.wss", "A3\Sounds_F\characters\human-sfx\Person0\P0_hit_06.wss", "A3\Sounds_F\characters\human-sfx\Person0\P0_hit_05.wss", "A3\Sounds_F\characters\human-sfx\Person0\P0_hit_04.wss", "A3\Sounds_F\characters\human-sfx\Person0\P0_hit_03.wss", "A3\Sounds_F\characters\human-sfx\Person0\P0_hit_02.wss"] 

if (isNil "LV_PAUSE") then {LV_PAUSE = false};

ITW_TeammatesInit = {
    // call on all clients
    if (isServer) then { 
        ITW_AI_UNITS = [];
        [] spawn ITW_TeammateRevive;
    };
};

ITW_TeammateCreated = {
    // called on each teammate after they are created (called on all clients)
    params ["_unit"];
    
    if (isServer) then { 
        ITW_AI_UNITS pushBack _unit;
        // add unit to zeus
        { _x addCuratorEditableObjects [[_unit],true] } forEach allCurators;
        
        if (group _unit getVariable ["tmCommandChangedEH",-1] < 0) then {
            private _eh = group _unit addEventHandler ["CommandChanged", {
                params ["_group", "_newCommand"];
                if (_newCommand == "JOIN") then {
                    {
                        if (!isPlayer _x && {!(isNull (_x getVariable ["tmFollowing",objNull])) && {formLeader _x == _x}}) then {
                            _x setVariable ["tmFollowing",nil,true];
                        };
                    } forEach units _group;
                };
            }];
            group _unit setVariable ["tmCommandChangedEH",_eh];
        };
    };
    
    // ensure unit never runs out of ammo or FAK
    _unit addEventHandler ["Reloaded", {
        params ["_unit", "_weapon", "_muzzle", "_newMagazine", "_oldMagazine"];
        private _mag = _newMagazine#0;
        if !(_mag in (magazines _unit)) then {_unit addMagazines [_mag,1]};
        
        // make sure they have at least 1 FAK
        private _items = items _unit;
        private _found = false;
        #if __has_include("\z\ace\addons\main\script_component.hpp")
            private _aceCnt = 0;
            { 
                private _type = getnumber (configfile >> "cfgweapons" >> _x >> "itemInfo" >> "type");
                if (_type == 401) exitWith {_found = true};
                if (_type == 302) then {_aceCnt = _aceCnt + 1};
                if (_aceCnt > 3) exitWith {_found = true};
            } forEach _items;
            if (!_found) then {
                _unit addItem "ACE_fieldDressing";
                _unit addItem "ACE_plasmaIV";
            };
        #else
            { 
                if (getnumber (configfile >> "cfgweapons" >> _x >> "itemInfo" >> "type") == 401) exitWith {_found = true};
            } forEach _items;
            if (!_found) then {
                _unit addItem "FirstAidKit";
            };
        #endif
    }];
    
    if (local _unit) then {
        _unit doFollow leader _unit;
        _unit allowFleeing 0;
        _unit setSkill (ITW_ParamFriendlySquadSkill);
        _unit setSkill ["courage",1];
    };

    _unit setVariable ["ITW_loadout",getUnitLoadout _unit];    

    #if __has_include("\z\ace\addons\main\script_component.hpp")
        #include "\z\ace\addons\main\script_macros.hpp"
        _unit setUnitTrait ["Medic",true];
        _unit setVariable [QEGVAR(medical,medicClass), 1, true];
        (uniformContainer _unit) addItemCargoGlobal ["ACE_fieldDressing",1];
        (uniformContainer _unit) addItemCargoGlobal ["ACE_plasmaIV",1];
    #else
        if (ITW_ParamFriendlyRevive == 1) then {
            // setup to allow AI to go unconscious
            _unit addEventHandler ["HandleDamage", {
                // damage handler only activates on client where ai is local
                params ["_unit", "_selection", "_damage", "_source", "_projectile", "_hitIndex", "_instigator", "_hitPoint"];
                private _returnDmg = _damage;
                
                if (!alive _unit) exitWith {_unit removeEventHandler [_thisEvent, _thisEventHandler]; damage _unit};
                //if (lifeState _unit == "INCAPACITATED") exitWith {damage _unit}; 
                
                if !(_unit getVariable ["tmAICanDie",false]) then {
                    private _veh = vehicle _unit;
                    if (alive _veh && {_damage > 0.6 && {_damage < 8}}) then {
                        // go unconscious
                        _damage = 0.85;
                        if (lifeState _unit != "INCAPACITATED") then {
                            _unit setUnconscious true;
                            _unit setCaptive true;
                            [_unit] remoteExec ["ITW_TeammateDown",0];
                        };
                    };    
                };
                _damage
            }]; 
        };
    #endif
    
    if (isNil "ITW_TMLoadoutMenu_1") then {
        private _header = [["Select Loadout", false]];
        private _index = 0;
        private _maxItems = 10;
        private _cnt = _maxItems+2;
        private _menu = +_header;
        waitUntil {!isNil "ITW_AllyUnitTypes"};
        {
            private _unitType = _x;
            private _name = getText (configFile >> "CfgVehicles" >> _unitType >> "displayName");
            if (_cnt > _maxItems) then {
                if (_index > 0) then {
                    if (_index > 1) then {_menu pushBack ["BACK",[17], "", -4, [["expression",""]], "1", "1"]};
                    _menu pushBack ["MORE",[31], format ["#USER:ITW_TMLoadoutMenu_%1",_index+1], -5, [["expression",""]], "1", "1"];
                    call compile format ["ITW_TMLoadoutMenu_%1 = _menu;",_index];
                };
                _menu = +_header;
                _cnt = 0;
                _index = _index + 1;
            } else {
                _cnt = _cnt + 1;
            };          
            _menu pushBack [_name,[_cnt+2], "", -5, [["expression",format ["['%1','%2'] spawn ITW_TeammateLoadout;",_x,_name]]], "1", "1"];
        } forEach ITW_AllyUnitTypes;
        _menu pushBack ["BACK",[17], "", -4, [["expression",""]], "1", "1"];
        call compile format ["ITW_TMLoadoutMenu_%1 = _menu;",_index];
    };
    _unit addAction ["Select loadout",{ITW_TeammateLoadoutUnit = _this#0; showCommandingMenu "#USER:ITW_TMLoadoutMenu_1"},nil,1.5,false,false,"","group _this == group _target"]; 

    _unit addAction ["Follow me",{
            params ["_target", "_caller", "_actionId", "_arguments"];
            [_target,_caller] remoteExec ["ITW_TeammateFollow",_target];
        },nil,1.4,false,true,"",
        "group _this == group _target && _target != leader _target && {isNull (_target getVariable ['tmFollowing',objNull])}"];         
    _unit addAction ["Continue following me",{
            params ["_target", "_caller", "_actionId", "_arguments"];
            _target spawn ITW_TeammateUnStop
        },nil,1.4,false,true,"",
        "_this isEqualto (_target getVariable ['tmFollowing',objNull]) && {currentCommand _target == 'STOP'}"];
    _unit addAction ["Stop following me",{
            params ["_target", "_caller", "_actionId", "_arguments"];
            _target setVariable ["tmFollowing",objNull,true];
        },nil,1.4,false,true,"",
        "_this isEqualto (_target getVariable ['tmFollowing',objNull])"];
};

ITW_TeammateUnStop = {
    params ["_unit"];
    if (currentCommand  _unit == "STOP") then {
        private _grp = group _unit;
        private _grp2 = createGroup west; 
        [_unit] joinSilent _grp2;
        waitUntil {currentCommand  _unit != "STOP"};
        [_unit] joinSilent _grp;
        deleteGroup _grp2;
    };
};

ITW_TeammateFollow = {
    // call where ai unit is local
    
    // AI will follow unit, get in/out vehicles and copy stance
    // AI has an action to 'stop following' or group lead can issue 'regroup' to the ai
    // Squad leader can also issue 'stop' command to hold still, issue a move command (or use continue action
    // on the ai) to resume following
    
    params ["_unit", "_player"];
    #define FOLLOW_DIST_CLOSE 15
    #define FOLLOW_DIST_FAR   25
    #define STATE_FOLLOW  1
    #define STATE_GET_IN  2
    #define STATE_IN_VEH  3
    #define STATE_GET_OUT 4
    #define DEBUG_FOLLOW false
    
    _unit setVariable ["tmFollowing",_player,true];
    if (DEBUG_FOLLOW) then {diag_log format ["TeammateFollow: %1 following %2",name _unit, name _player]};  
    
    private _prevState = STATE_FOLLOW;
    private _state = STATE_FOLLOW;
    private _timeout = 0;
    
    _unit call ITW_TeammateUnStop;
    
    while {alive _unit && {alive _player && {! isNull (_unit getVariable ["tmFollowing",objNull])}}} do {
        private _dist = _unit distance _player;        
        private _veh = vehicle _player;
        
        switch (_state) do {
            case STATE_FOLLOW: {
                if (_dist > 100) then {_unit setPosATL ([_player,80,_player getDir _unit] call ITW_FncRelPos)};
                if (_veh != _player) exitWith {
                    unassignVehicle _unit;
                    _unit assignAsCargo _veh;
                    _unit doMove (_veh getPos [4, _veh getDir _unit]);
                    _timeout = time + 20;
                    _state = STATE_GET_IN;
                };
                switch (stance _player) do {
                    case "STAND":  {_unit setUnitPos "UP"};
                    case "CROUCH": {_unit setUnitPos "MIDDLE"};
                    case "PRONE":  {_unit setUnitPos "DOWN"};
                    default        {_unit setUnitPos "AUTO"};
                };
                if (_dist > FOLLOW_DIST_FAR) then {
                    private _pos = (_player getPos [FOLLOW_DIST_CLOSE,_player getDir _unit]);
                    _unit doMove _pos;
                    if (DEBUG_FOLLOW) then {diag_log format ["TeammateFollow: %1 moving to %2",name _unit,_pos]};                  
                };
            };
            case STATE_GET_IN: {
                if (_unit distance _veh < 13 || time > _timeout) then {
                    if (getPosATL _veh #2 < 2) then {
                        _unit moveInAny _veh;
                        sleep 1;
                    };
                    if (vehicle _unit == _unit) then {
                        [_unit,"I can't get in. Go on without me and I'll catch up."] remoteExec ["groupChat",_player];
                    };
                    _state = STATE_IN_VEH;
                };
                
                if (_veh == _player) exitWith {
                    unassignVehicle _unit;
                    doGetOut _unit;
                    _timeout = time + 5;
                    _state = STATE_GET_OUT;
                };
            };
            case STATE_IN_VEH: {
                if (_veh == _player) then {
                    unassignVehicle _unit;
                    doGetOut _unit;
                    _timeout = time + 5;
                    _state = STATE_GET_OUT;
                };
            };
            case STATE_GET_OUT: {
                if (vehicle _unit == _unit || {time > _timeout}) then {
                    if (time > _timeout) then {
                        moveOut _unit;
                    };
                    _unit call ITW_TeammateUnStop;
                    _state = STATE_FOLLOW;
                };
            };
        };  
        if (DEBUG_FOLLOW && {_prevState != _state}) then {diag_log format ["TeammateFollow: %1 state change %2 => %3",name _unit,_prevState,_state];_prevState = _state};
        
        sleep 3;
    };
    
    if (DEBUG_FOLLOW) then {diag_log format ["TeammateFollow: %1 done following (%2,%3,%4)",name _unit,alive _unit,alive _player,_unit getVariable ["tmFollowing",objNull]]};
    
    if (alive _unit) then {
        unassignVehicle _unit;
        doGetOut _unit;
        _unit setUnitPos "AUTO";
        _unit doMove getPosATL _unit;
        _unit doFollow leader _unit;
    };
    if (! isNull (_unit getVariable ["tmFollowing",objNull])) then {
        _unit setVariable ["tmFollowing",nil,true];
    };
};

ITW_TeammateLoadout = {
    params ["_unitType","_name"];
    private _unit = ITW_TeammateLoadoutUnit;
    [_unit,_unitType call ITW_FncGetLoadoutFromClass] call ITW_FncSetUnitLoadout;
    _unit call ITW_TeammateAddFAKs;
    if (primaryWeapon _unit isEqualTo "" && {handgunWeapon _unit isEqualTo ""}) then {
        _unit addMagazines ["10Rnd_9x21_Mag",10];
        _unit addWeapon "hgun_Pistol_01_F";
    };
    _unit setVariable ["ITW_loadout",getUnitLoadout _unit,true];
    hint format ["Loadout changed to %1",_name];
};

ITW_TeammateAddFAKs = {
    private _unit = _this;
    // if unit has no weapon, then change his loadout
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
};

ITW_TeammateArsenal = {
    scriptName "ITW_TeammateArsenalLoadout"; 
    private _teammates = units group player select {!isPlayer _x};
    if (count _teammates == 0) exitWith {hint "No teammates available"};
    private _unit = _teammates#0;
    if (count _teammates > 1) then {
        ITW_TA_Index = 0;
        private _menu = [["Select Teammate", false]];
        {
            _menu pushBack [name _x,[_forEachIndex+3], "", -5, [["expression",format ["ITW_TA_Index = %1;",_forEachIndex]]], "1", "1"];
        } forEach _teammates;
        showCommandingMenu "#USER:_menu";
        waitUntil {commandingMenu == ""};
        _unit = _teammates#ITW_TA_Index;
    };
    
    if (_unit getVariable ["tmLoadAdj",false]) exitWith {
        "teammate" cutText ["Someone else is adjusting this teammates loadout","PLAIN"];
        [] spawn {sleep 5; "teammate" cutText ["","PLAIN"];};
    };
    _unit setVariable ["tmLoadAdj",true,true];
    
    // use arsenal to set unit loadout
    private _loadout = getUnitLoadout _unit;
    private _playerLoadout = getUnitLoadout player;
    
    _unit setUnitLoadout [[],[],[],[uniform _unit,[]],[],[],"","",[],["","","","","",""]];
    player setUnitLoadout _loadout;
    
    ITW_TMArsenalExited = false;
    ["Open",true,missionNamespace] call BIS_fnc_arsenal;
    waitUntil {ITW_TMArsenalExited};
    
    _unit setUnitLoadout getUnitLoadout player;
    player setUnitLoadout _playerLoadout;
    _unit setVariable ["ITW_loadout",getUnitLoadout _unit,true];
    _unit setVariable ["tmLoadAdj",false,true];
};

ITW_TeammateArsenalExit = {
    // called whenever the player exits the arsenal
    ITW_TMArsenalExited = true;
};

ITW_TeammateDown = {
    // Called on all clients
    if (isNil "bis_revive_duration") then {
        #define DEFAULT_REVIVE_TIME 6
        if ((missionNamespace getVariable["bis_reviveParam_duration",-100]) == -100) then {bis_revive_duration = getMissionConfigValue ["ReviveDelay",DEFAULT_REVIVE_TIME]} else {missionNamespace getVariable["bis_reviveParam_duration",-100]};
        if (bis_revive_duration <= 0) then {bis_revive_duration = DEFAULT_REVIVE_TIME};
    };
                
    params ["_unit"];
    if (!hasInterface) exitWith {};

    _unit groupChat "I'm down!";
    playSound3D [selectRandom HitCries,_unit,false,getPosASL _unit,5,1,200,0,true];

    private _id = addMissionEventHandler ["Draw3D", {
        _thisArgs params ["_unit","_bleedTimeout"];
        if (LV_PAUSE) then {_bleedTimeout = time + bis_revive_bleedOutDuration};
        if (time > _bleedTimeout) then { _unit setDamage 1 };
        if (lifeState _unit == "INCAPACITATED") then {
            private _pos = ASLToAGL getPosASLVisual _unit;
            private _dist = 1 max (player distance _unit);
            private _size = 1 min ((200 - _dist)/200); 
            if (_size > 0.05) then {
                private _alpha = ((_size - 1) * 0.75) + 1;
                _pos set [2,(_pos#2)+0.5];                            
                drawIcon3D ["\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_reviveMedic_ca.paa", [1,1,1,_size], _pos, _size, _size, 0];
            };
        } else {  
            removeMissionEventHandler ["Draw3D", _thisEventHandler];
        }},[_unit,time + bis_revive_bleedOutDuration]];
            
    _actionId = [_unit, format ["Revive %1",name _unit], 
        "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_revive_ca.paa",
        "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_revive_ca.paa", 
        "_this distance _target < 3 && {alive _this && {alive _target}}", 
        "_caller distance _target < 5 && {alive _caller && {alive _target}}", {
            // code start
            _caller playMoveNow selectRandom MedicActions;
            _target setVariable ["tmPlayerHealing",true,0];
        }, {
            // code progress
            //params ["_target", "_caller", "_actionId", "_arguments", "_progress", "_maxProgress"];
            if !(animationState _caller in MedicActions) then {
                _caller playMoveNow selectRandom MedicActions;
            };
        }, {
            // code complete
            //params ["_target", "_caller", "_actionId", "_arguments"];
            _caller switchMove "AinvPknlMstpSnonWnonDnon_medicEnd";
            [_target,false] remoteExec ["setUnconscious",_target];
            [_target,false] remoteExec ["setCaptive",_target];
            _target setDamage 0;        
            _target setVariable ["tmPlayerHealing",nil,0];
        }, {
            // code interrupted
            _caller switchMove "AinvPknlMstpSnonWnonDnon_medicEnd";
            _target setVariable ["tmPlayerHealing",nil,0];
        }, [], bis_revive_duration] call BIS_fnc_holdActionAdd;

    sleep 5;
    // after a few seconds, the ai can be killed
    _unit setVariable ["tmAICanDie",true];
    waitUntil { sleep 1; lifeState _unit != "INCAPACITATED" };
    _unit removeAction _actionId;
    _unit setVariable ["tmAICanDie",false];
};

ITW_TeammateRevive = {
    // runs on server only
    scriptName "ITW_TeammateRevive";
    HasACEMedical = isClass (configFile >> "CfgSounds" >> "ACE_heartbeat_fast_3");
    
    while {true} do {
        sleep 10;
        while {LV_PAUSE} do {sleep 5};
        private _allPlayersDown = {alive _x && {(lifeState _x != "INCAPACITATED")}} count (allPlayers + HeadlessClients) == 0;
        
        if (!HasACEMedical && {ITW_ParamFriendlyRevive == 1}) then {
            private _needRevive = [];
            private _canRevive = [];
            
            //// For ITW, we want the Allies to be able to revive if they are nearby, so I added this
            if !(ITW_AllyGroups isEqualTo []) then {
                ITW_AllyGroups = ITW_AllyGroups - [grpNull];
                private _playersDown = allPlayers select {lifeState _x == "INCAPACITATED"};
                if !(_playersDown isEqualTo []) then {
                    private _allyUnits = [];
                    {_allyUnits = _allyUnits + units _x} count ITW_AllyGroups;
                    private _teammatesAvail = _allyUnits select {
                        private _unit = _x;
                        alive _unit && 
                        {_x == vehicle _x &&
                        {isNull (_unit getVariable ["tmHealing",objNull]) &&
                        {{_unit distance _x < 100} count _playersDown > 0 
                    }}}};
                    _canRevive = _teammatesAvail;
                };
            };
            ////
            
            {
                private _unit = _x;
                if (lifeState _unit == "INCAPACITATED") then {
                    // CHECK: ai already assigned to revive
                    if !(_unit getVariable ["#rev_being_revived", false] || _unit getVariable ["tmPlayerHealing",false]) then {
                        private _aiReviving = _unit getVariable ["tmBeingHealed",objNull];
                        if (isNull _aiReviving) then {
                            _needRevive pushBack _unit;
                        };
                    };
                } else {
                    if (! isPlayer _unit && 
                       {isNull (_unit getVariable ["tmHealing",objNull]) && 
                       {alive _unit &&
                       {vehicle _unit == _unit || {getPosATL vehicle _unit #2 < 1 && speed vehicle _unit < 1}}}}) then {
                        _canRevive pushBack _unit;
                    };
                };
            } forEach (allPlayers + ITW_AI_UNITS);
            
            if !(_needRevive isEqualTo []) then {
                private _matrix = [];
                {
                    private _downUnit = _x;
                    {
                        // if the ai are stopped, they will not respond to get units up unless all players are down or the downed unit is real close
                        if (_x distance _downUnit < 500) then {
                            _matrix pushBack [_x distance _downUnit,_downUnit,_x];
                        }
                    } forEach _canRevive;
                } forEach _needRevive;
            
                if !(_matrix isEqualTo []) then {
                    // sort by distance
                    _matrix sort true; 
                    
                    // have closest pairs trigger revives
                    private _downs = [];
                    private _heals = [];
                    {
                        private _downUnit = _x#1;
                        private _healer = _x#2;
                        if !(_downUnit in _downs || _healer in _heals) then {
                            _downUnit setVariable ["tmBeingHealed",_healer];
                            _healer setVariable ["tmHealing",_downUnit,2];
                            [_downUnit,_healer] remoteExec ["ITW_TeammateReviveMP",_healer];
                            private _chatType = if (group _healer isEqualTo group _downUnit) then {"groupChat"} else {"sideChat"};
                            [_healer,"Going to help " + name _downUnit] remoteExec [_chatType,0];   
                            _downs pushBack _downUnit;
                            _heals pushBack _healer;
                        };
                    } foreach _matrix;                
                    // if any down units are players, then send a 2nd healer if available
                    _downs = _downs - allPlayers; // remove players from down list so they get handled again
                    {
                        private _downUnit = _x#1;
                        private _healer = _x#2;
                        if !(_downUnit in _downs || _healer in _heals) then {
                            _downUnit setVariable ["tmBeingHealed",_healer];
                            _healer setVariable ["tmHealing",_downUnit,2];
                            [_downUnit,_healer,false] remoteExec ["ITW_TeammateReviveMP",_healer];
                            private _chatType = if (group _healer isEqualTo group _downUnit) then {"groupChat"} else {"sideChat"}; 
                            [_healer,"Covering " + name _downUnit] remoteExec [_chatType,0];  
                            _downs pushBack _downUnit;
                            _heals pushBack _healer;
                        };
                    } forEach _matrix; 
                
                    // if all players are down, the AI takes leadership, but they can block
                    // the healers, so make one of the healers the leader so he will do healing
                    if (count _heals > 0) then {
                        private _healer = _heals#0;
                        if (!(isPlayer leader _healer) && {leader _healer != _healer}) then {
                            private _groupHealer = group _healer;
                            [[_groupHealer,_healer],"selectLeader",_groupHealer] call ITW_FncRemoteLocalGroup;
                        };
                    };               
                };
            };
        };
    
        // clean up dead ai
        {
            if (! alive _x) then {
                ITW_AI_UNITS = ITW_AI_UNITS - [_x];
                [_x] spawn { 
                    params ["_deadUnit"];
                    waitUntil {
                        sleep 30;
                        private _safeToDelete = true;
                        {                      
                            if (_x distance _deadUnit < 1000) exitWith {_safeToDelete = false};
                        } forEach (allPlayers - HeadlessClients);                     
                        _safeToDelete || isNull _deadUnit
                    };                  
                    if (! isNull _deadUnit) then {
                        if (vehicle _deadUnit == _deadUnit) then {deleteVehicle _deadUnit} else {vehicle _deadUnit deleteVehicleCrew _deadUnit};
                    };
                };    
            };
        } forEach ITW_AI_UNITS;        
    };
};

#define STATE_MOVE     0
#define STATE_APPROACH 1
#define STATE_REVIVE   2
#define STATE_DELAY    3
#define STATE_CANCELED 4
#define STATE_DONE     5

ITW_TeammateReviveMP = {
    // Must be run on client where AI is local

    // Perform a revive on the unit
    scopeName "aiRevive";
    params ["_downUnit","_ai",["_allowSmoke",true]];                            

    // kick it off
    _ai doMove getPosATL _downUnit;

    private _debug = true;
    private _prevState = -1;
    private _state = STATE_MOVE;
    private _timeout = time + 30;
    private _reviveTime = 0;
    if (_allowSmoke) then {
        _allowSmoke = time >= (_ai getVariable ["tmSmoke",time]);
    };
    private _smoke = _allowSmoke && {random 100 < 75};

    _ai setVariable ["tmSmoke",time+60];
    while { _state != STATE_DONE} do {
        if (!(lifeState _ai == "HEALTHY" || lifeState _ai == "INJURED") 
            || {lifeState _downUnit != "INCAPACITATED" || time > _timeout
            || {_downUnit getVariable ["#rev_being_revived", false]
            || {_downUnit getVariable ["tmPlayerHealing",false]
            || {_ai getVariable ["tmSwitching",false]}}}}) then {
                if (_state == STATE_REVIVE) then {_ai switchMove "AinvPknlMstpSnonWnonDnon_medicEnd"};
                _state = STATE_CANCELED;
        } else {
            if (_downUnit getVariable ["tmApproach",_ai] != _ai) then {
                _state = STATE_DELAY;
            };
        }; 
        if (_debug && {(_state != _prevState)}) then {
            _prevState = _state;
            //diag_log format ["Teammates: Ai Revive %1 reviving %2 state %3",_ai,_downUnit,_state];
        };   
        switch (_state) do {
            case STATE_MOVE: {
                _ai moveTo getPosATL _downUnit;
                if (_ai distance _downUnit < 10 && _smoke) then { 
                    _smoke = false;
                    _ai setVariable ["tmSmoke",time+60];
                    _ai lookAt _downUnit; 
                    private _fPos = getPosATL _ai;
                    _fPos set [2,(_fPos#2)+1];
                    private _speed = (_ai distance2D _downUnit) * 5 / 8;
                    private _dir = _ai getDir _downUnit;
                    private _smoke = "SmokeShell" createVehicle _fPos;
                    _smoke setVelocity [
                        (sin _dir * _speed), 
                        (cos _dir * _speed), 
                        _speed];
                };
                if (_ai distance _downUnit < 12 && {vehicle _downUnit != _downUnit}) then {
                    private _timeout = time + 2;
                    private _veh = vehicle _downUnit;
                    private _radius = (boundingBox _veh #2) * 2 / 3;
                    moveOut _downUnit;
                    waitUntil {vehicle _downUnit == _downUnit || time > _timeout};
                    _downUnit setPosATL ([_veh,_radius,_veh getDir _ai] call ITW_FncRelPos);
                    _ai moveTo getPosATL _downUnit;
                };
                if (_ai distance _downUnit < 5) then { _state = STATE_APPROACH };
                if (moveToFailed _ai) then { _state = STATE_CANCELED };
            };
            case STATE_APPROACH: {
                _downUnit setVariable ["tmApproach",_ai];
                if (_ai distance _downUnit > 1) then { 
                    private _p = _ai getPos [1,_ai getDir _downUnit];
                    _p set [2,(getPosATL _ai)#2 + 0.1];
                    _ai setPosATL ([_ai,0.5,_ai getDir _downUnit] call ITW_FncRelPos);
                };
                _state = STATE_REVIVE;
                _ai disableAI "MOVE";
                _ai disableAI "TARGET";
                _ai disableAI "FSM";
                _ai doWatch _downUnit;
                _ai setDir (_ai getDir _downUnit);
                _ai setPosATL ([_downUnit,1,_downUnit getDir _ai] call ITW_FncRelPos);
                _ai playMoveNow selectRandom MedicActions;
                _ai doWatch _downUnit;
                if (isNil "bis_revive_duration") then {
                    #define DEFAULT_REVIVE_TIME 6
                    bis_revive_duration = if ((missionNamespace getVariable["bis_reviveParam_duration",-100]) == -100) then {getMissionConfigValue ["ReviveDelay",DEFAULT_REVIVE_TIME]} else {missionNamespace getVariable["bis_reviveParam_duration",-100]};
                    if (bis_revive_duration <= 0) then {bis_revive_duration = DEFAULT_REVIVE_TIME};
                };
                #define TYPE_MEDIKIT 619
                private _reviveDuration = bis_revive_duration;
                {
                    if (getNumber (configFile >> "cfgWeapons" >> _x >> "ItemInfo" >> "type") == TYPE_MEDIKIT) exitWith {_reviveDuration = bis_revive_duration / 3};
                } forEach backpackItems _ai;                  
                _reviveTime = time + _reviveDuration + 3;
                _timeout = _reviveTime + 5;
            };
            case STATE_REVIVE: {
                if (time > _reviveTime) then {
                    // trigger arma 3 revive
                    if (isPlayer _downUnit) then {
                        [_downUnit] call ITW_TeammateGetPlayerUp;
                    } else {
                        _downUnit remoteExec ["ITW_TeammateRevived",_downUnit];
                    };
                    sleep 3;
                    // free up ai
                    _ai doWatch objNull;
                    _ai switchMove "AinvPknlMstpSnonWnonDnon_medicEnd";
                    // reset revive unit variables
                    _downUnit setVariable ["tmBeingHealed",objNull,2];
                    _ai setVariable ["tmHealing",objNull,2];
                    _state = STATE_DONE;
                } else {
                    if (_ai distance _downUnit > 6) then { 
                        _ai doWatch objNull;
                        _ai switchMove "AinvPknlMstpSnonWnonDnon_medicEnd";
                        _state = STATE_CANCELED 
                    } else {
                        if !(animationState _ai in MedicActions) then {
                            _ai playMoveNow selectRandom MedicActions;
                        };
                    };
                };
            };
            case STATE_DELAY: {};
            case STATE_CANCELED: {
                _ai enableAI "MOVE";
                _ai enableAI "TARGET";
                _ai enableAI "FSM";
                _downUnit setVariable ["tmBeingHealed",objNull,2];
                _ai spawn {sleep 5; _this setVariable ["tmHealing",objNull,2];};
                if (lifeState _ai == "INCAPACITATED") then {
                    _ai switchMove "unconsciousrevivedefault";
                    _ai setUnconscious true;
                };
                _state = STATE_DONE;
            };
        };
        sleep 2;
    };
    //diag_log format ["Teammates: Ai Done Revive %1 reviving %2 state %3",_ai,_downUnit,_state];

     if (_downUnit getVariable ["tmApproach",objNull] == _ai) then {
        _downUnit setVariable ["tmApproach",nil];
     };
    _ai setVariable ["tmHealing",objNull,2];
    _ai enableAI "MOVE";
    _ai enableAI "TARGET";
    _ai enableAI "FSM";
    sleep 3;
    _ai doFollow leader _ai;
    if !(isNull assignedVehicle _ai) then {unassignVehicle _ai};
};

ITW_TeammateGetPlayerUp = {
    params ["_downUnit"];
    if (!local _downUnit) exitWith {[_downUnit] remoteExec ["ITW_TeammateGetPlayerUp",_downUnit]};
    private _isDisabled = _downUnit getVariable ["#rev_state", 0] == 2;
    if (_isDisabled) then {
        ["",1,_downUnit] call BIS_fnc_reviveOnState;
        _downUnit setVariable ["#rev", 1, true];
    }; 
};

ITW_TeammateRevived = {
    // call where unit is local
    private _downUnit = _this;
    if (!local _downUnit) exitWith {
        diag_log "Error pos: ITW_TeammateRevived called where unit is not local";
        _downUnit remoteExec ["ITW_TeammateRevived",_downUnit];
    };
    _downUnit setDamage 0;
    _downUnit setUnconscious false;
    _downUnit setCaptive false;
    sleep 3;
    _downUnit doFollow leader _downUnit;
};
                        
ITW_TeammateSwitch = {
    // Allow swapping an incapacitated player with a non-incapacitated AI
    // _player is the player to be given the option (or chose randomly).  Only 1 player at a time can get the option.
    // _ai is the teammate the player will swap with (or a random healthy ai if not supplied)

    // runs on server

    if (HasACEMedical) exitWith {};

    params [["_player",selectRandom (allPlayers select {lifeState _x == "INCAPACITATED"})],["_ai",selectRandom (ITW_AI_UNITS select {(lifeState _x) == "HEALTHY" || (lifeState _x) == "INJURED"})]];

    if (isNil "_player" || isNil "_ai") exitWith {};

    // check if it's already running 
    if !(missionNamespace getVariable ["TmTsDone",true]) exitWith {};
    missionNamespace setVariable ["TmTsDone",false];

    [_player,_ai] remoteExec ["ITW_TeammateSwitchMP",_player];
};

ITW_TeammateSwitchMP = {
    // Allow swapping an incapacitated player with a non-incapacitated AI

    // runs on client where player is local
    params ["_player","_ai"];

    TEAM_SWAP_DO = false;
    _actionId = -1;
    sleep 3;
    while {!TEAM_SWAP_DO} do {
        if ({(lifeState _x) == "HEALTHY" || (lifeState _x) == "INJURED"} count allPlayers > 0) exitWith {};
        if ((lifeState _ai) != "HEALTHY" && (lifeState _ai) != "INJURED") exitWith {};
        if (! isNull (_player getVariable ["tmApproach",objNull])) exitWith {};
        if (_actionId == -1) then {
            _actionId = [_player, "Switch to teammate",
                "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_revive_ca.paa",
                "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_revive_ca.paa", 
                "true",
                "true", 
                {},                     // code start
                {},                     // code progress
                {TEAM_SWAP_DO = true;}, // code complete
                {},                     // code interrupted
                [], 5, 1001, true, true] call BIS_fnc_holdActionAdd;
        };       
        sleep 0.2;
    };
    if (_actionId != -1) then {[_player,_actionId] call BIS_fnc_holdActionRemove};
    if (!TEAM_SWAP_DO) exitWith {missionNamespace setVariable ["TmTsDone",true,2]};
    _ai setVariable ["tmSwitching",true,0];

    //diag_log format ["Teammates: Teamswitch %1 <> %2",name _player,name _ai];

    _stance2Pos = {
        switch (_this) do {
            case "CROUCH": {"MIDDLE"};
            case "PRONE" : {"DOWN"};
            default {"UP"};            
        }
    };

    [_ai,false] remoteExec ["allowDamage",_ai];
    _player allowDamage false;

    "TSwitch" cutText ["Switching to teammate","BLACK OUT",0.5,true,false];
    sleep 0.1;

    private _aiPos = getPosATL _ai;
    private _aiLO = getUnitLoadout _ai;
    private _aiDmg = damage _ai;
    private _aiStance = stance _ai;
    private _aiDir = getDir _ai;
    private _playerPos = getPosATL _player;
    private _playerLO = getUnitLoadout _player;
    private _playerDmg = damage _player;
    private _playerStance = stance _player;
    private _playerDir = getDir _player;

    _ai switchMove "";
    _ai setDamage _playerDmg;
    sleep 0.1;

    _ai setPosATL ([_aiPos,2,0] call ITW_FncRelPos);
    sleep 0.5;

    // revive the player
    private _isDisabled = _player getVariable ["#rev_state", 0] == 2;
    if (_isDisabled) then {
        ["",1,_player] call bis_fnc_reviveOnState;
        _player setVariable ["#rev", 1, true];
    }; 
    [_player,""] remoteExec ["switchMove",0];

    _player setDir _aiDir;
    _player setPosATL _aiPos;

    sleep 0.5;

    _ai setPosATL _playerPos;

    sleep 0.5;
    //[_ai,"unconsciousrevivedefault"] remoteExec ["switchMove",0];
    [_ai, true] remoteExec ["setUnconscious",_ai];

    [_player, _aiLO] call ITW_FncSetUnitLoadout;
    [_ai, _playerLO] call ITW_FncSetUnitLoadout;
        
    sleep 0.5; 

    _player setDamage _aiDmg;
    _player setUnitPos (_aiStance call _stance2Pos);

    sleep 0.5;

    [_ai, true] remoteExec ["setCaptive",_ai];
    //[_ai, true] remoteExec ["setUnconscious",_ai];
    [_ai] remoteExec ["ITW_TeammateDown",0];

    [_ai, _playerDir] remoteExec ["setDir",_ai];
    _ai setPosATL _playerPos;

    "TSwitch" cutText ["","BLACK IN",0.5,true,false];

    missionNamespace setVariable ["TmTsDone",true,2];
    _ai setVariable ["tmSwitching",false,0];

    sleep 5;
    [_ai,true] remoteExec ["allowDamage",_ai];
    _player allowDamage true;

};

ITW_TeammatesHeal = {
    if (!isServer) then {
        [] remoteExec ["ITW_TeammatesHeal",2];
    } else {
        if !(isNil "ITW_AI_UNITS") then {
            {
                private _lifestate = lifeState _x;
                if (_lifestate == "HEALTHY" || {_lifestate == "INJURED"}) then {_x setDamage 0};
                _x call ITW_FncAceHeal;
            } forEach ITW_AI_UNITS;
        };
    };
};
ITW_TeammateSaveLocal = {
    private _saveInfo = units group player select {!isPlayer _x} apply {getUnitLoadout _x};
    profileNamespace setVariable [format["ITW_TeammatesLocal%1",worldName],_saveInfo];
    hint format ["%1 teammates saved",count _saveInfo];
};

ITW_TeammateLoadLocal = {
    private _saveInfo = profileNamespace getVariable [format["ITW_TeammatesLocal%1",worldName],[]];
    if (_saveInfo isEqualTo []) exitWith {hint "No saved teammates"};
    private _okayToLoad = true;
    private _playerTeam = units group player;
    if ({!isPlayer _x} count _playerTeam > 0) then {
        ITW_YesNoMenu1Answer = false;
        ITW_YesNoMenu1 = [
            ["Replace current AI?", true],
            ["Yes", [], "", -5, [["expression","ITW_YesNoMenu1Answer = true"]], "1", "1"],
            ["No",  [], "", -5, [["expression", "ITW_YesNoMenu1Answer = false"]], "1", "1"]
        ];
        showCommandingMenu "#USER:ITW_YesNoMenu1";
        waitUntil {!(commandingMenu isEqualTo "")};
        waitUntil {commandingMenu isEqualTo ""};   
        if (ITW_YesNoMenu1Answer) then {
            {deleteVehicle _x} forEach _playerTeam;
        } else {
            _okayToLoad = false;
        };
    };
    if (_okayToLoad) then {
        private _aiCnt = 0;
        {
            if (_aiCnt >= ITW_ParamFriendlySquadSize) exitWith {hint "Max squad size reached"};
            [player,_x] remoteExec ["ITW_AllyRecruit",2];
        } forEach _saveInfo;
    };
};

ITW_TeammatesSave = {
    if (isNil "ITW_AI_UNITS" || {ITW_AI_UNITS isEqualTo []}) exitWith {[]};
    ITW_AI_UNITS apply {getUnitLoadout _x};
};

ITW_TeammatesLoad = {
    // parameter is array of loadouts to save off info, or a player to add teammates to player's squad
    params ["_teammatesOrPlayer"];  
    if (typeName _teammatesOrPlayer == "ARRAY") exitWith { ITW_TEAMMATES_RELOAD = _teammatesOrPlayer };
    if (isNil "ITW_TEAMMATES_RELOAD") exitWith {};
    private _player = _teammatesOrPlayer;
    private _aiCnt = 0;
    {
        if (_aiCnt >= ITW_ParamFriendlySquadSize) exitWith {};
        [_player,_x] call ITW_AllyRecruit;
    } forEach ITW_TEAMMATES_RELOAD;
    [] call ITW_SaveGame; // save the teammates that just got loaded so if we quit before the next save they persist
};


ITW_TeammateReplace = {
    // allows player to swap into a teammate
    params ["_player"];
    private _teammates = units group player select {!isPlayer _x};
    if (count _teammates == 0) exitWith {hint "No teammates available"};
    private _unit = objNull;
    if (count _teammates > 0) then {
        ITW_TA_Index = -1;
        private _menu = [["Become Teammate", false]];
        {
            _menu pushBack [name _x,[_forEachIndex+3], "", -5, [["expression",format ["ITW_TA_Index = %1;",_forEachIndex]]], "1", "1"];
        } forEach _teammates;
        _menu pushBack ["CANCEL",[16], "", -4, [["expression",""]], "1", "1"];
        showCommandingMenu "#USER:_menu";
        waitUntil {commandingMenu == ""};
        if (ITW_TA_Index >= 0) then { 
            _unit = _teammates#ITW_TA_Index;
        };
    };
    if (!isNull _unit) then {
        private _pos = getPosATL _unit;
        private _name = name _unit;
        moveOut _unit;
        deleteVehicle _unit;
        _player setPosATL _pos;
        [format ["%1 replaced %2",name _player,_name]] remoteExec ["hint",0];
    };
};

["ITW_TeammateCreated"] call SKL_fnc_CompileFinal;
["ITW_TeammateLoadout"] call SKL_fnc_CompileFinal;
["ITW_TeammateDown"] call SKL_fnc_CompileFinal;
["ITW_TeammateRevive"] call SKL_fnc_CompileFinal;
["ITW_TeammateReviveMP"] call SKL_fnc_CompileFinal;
["ITW_TeammateRevived"] call SKL_fnc_CompileFinal;
["ITW_TeammateSwitch"] call SKL_fnc_CompileFinal;
["ITW_TeammateSwitchMP"] call SKL_fnc_CompileFinal;
["ITW_TeammatesInit"] call SKL_fnc_CompileFinal;
["ITW_TeammateUnStop"] call SKL_fnc_CompileFinal;
["ITW_TeammateFollow"] call SKL_fnc_CompileFinal;
["ITW_TeammateGetPlayerUp"] call SKL_fnc_CompileFinal;
["ITW_TeammatesHeal"] call SKL_fnc_CompileFinal;
["ITW_TeammateAddFAKs"] call SKL_fnc_CompileFinal;
["ITW_TeammateSaveLocal"] call SKL_fnc_CompileFinal;
["ITW_TeammateLoadLocal"] call SKL_fnc_CompileFinal;
["ITW_TeammatesSave"] call SKL_fnc_CompileFinal;
["ITW_TeammatesLoad"] call SKL_fnc_CompileFinal;
["ITW_TeammateArsenal"] call SKL_fnc_CompileFinal;
["ITW_TeammateArsenalExit"] call SKL_fnc_CompileFinal;
["ITW_TeammateReplace"] call SKL_fnc_CompileFinal;
