
//#define OBJ_DEBUG_ZONES true
#include "defines.hpp"
#include "defines_gui.hpp"

ITW_Objectives = []; // array of ["_aoPos","_aoSize","_marker","_name","_flag","_taskId","_zoneIdx","_captured","_attackVectors","_baseIndex"]...];
ITW_Zones = []; // array of objective indexes [_zone0IndexArray,_zone1IndexArray,...],  #0 is players starting base
ITW_ZoneIndex = 0;   // the contested zone
ITW_SeaPoints = [];
ITW_FlagsActive = [objNull,objNull];
ITW_GameOver = false; 
ITW_KeepOutSize = 1000; // size of keep out zone around enemy bases
ITW_ObjZonesUpdating = false; // allow threads to pause while we update for the next zone
ITW_ObjContestedState = []; // array of arrays of [objIdx,owner,is fully captured by players]
ITW_ObjShowArty = false; // if true, artillery hits will show on host's map

#define END_ZONE_LETTER    " "

// zone state will be zone number if inactive red, zones count from zero (player's base zone)
#define OBJ_STATE_INACTIVE_BLUE -3
#define OBJ_STATE_ACTIVE_BLUE   -2
#define OBJ_STATE_ACTIVE_RED    -1
#define OBJ_STATE_INACTIVE_RED  0  // or higher

#if __has_include("\z\ace\addons\main\script_component.hpp")
#define CONSCIOUS(unit) (!(unit getVariable ["ACE_isUnconscious", false]))
#else
#define CONSCIOUS(unit) (lifeState unit in ["HEALTHY","INJURED"])
#endif

#define WAIT_FOR_BASE_MAP(BM_MSG,BM_OBJ) \
    private _doBaseMsg = false;          \
   if (BM_OBJ select ITW_OBJ_ATTACKS isEqualTo []) then {_doBaseMsg = true; diag_log format ["%1 waiting for base map %2",BM_MSG,BM_OBJ select ITW_OBJ_INDEX]}; \
   while {BM_OBJ select ITW_OBJ_ATTACKS isEqualTo []} do {sleep 1};    \
   if (_doBaseMsg) then {diag_log format ["%1 done waiting for base map",BM_MSG]};

ITW_ShowSeaPoints = {
    if (isNil "ITW_SPMRK") then {ITW_SPMRK = []};
    {deleteMarker _x} forEach ITW_SPMRK;
    {
      _spIdx = _forEachIndex;
      {
       _m = createMarker ["ms"+str _spIdx + "-" +str _forEachIndex,_x];
       ITW_SPMRK pushBack _m;
       _m setMarkerType "hd_dot";
      } foreach _x;
    } foreach ITW_SeaPoints;
};

ITW_ObjectivesSetup = {
    params ["_fromSave"];
    
    if (!_fromSave) then {
        0 call ITW_ObjGetObjectives;
        [0,["Setting up objectives","BLACK OUT",0.001]] remoteExec ["cutText",0,false];  
        true call ITW_ObjGetZones;
    } else {
        [0,["Setting up objectives","BLACK OUT",0.001]] remoteExec ["cutText",0,false];  
    };
    
    // setup vehicle spawn points on roads
    {
        private _obj = _x;
        [_obj] call ITW_ObjSetVehicleSpawn;
        false
    } count ITW_Objectives;   
    
    // ensure contested objectives are marked as such
    {
        ITW_Objectives#_x#ITW_OBJ_OWNER == ITW_OWNER_CONTESTED;
    } count (ITW_Zones#ITW_ZoneIndex);
    
    _fromSave call ITW_CreateBases;   
    
    if (!_fromSave) then {
        // handle the final enemy spawn point that is out to sea
        private _pos = call ITW_ObjGetOutToSeaPos;
        _obj = EMPTY_OBJECTIVE;
        _obj set [ITW_OBJ_POS,_pos];
        _obj set [ITW_OBJ_V_SPAWN,_pos];
        _obj set [ITW_OBJ_INDEX,count ITW_Bases];
        _obj set [ITW_OBJ_NAME,"Enemy Attack Corridor"];
        _obj set [ITW_OBJ_ZONEID,count ITW_Zones - 1];
        
        ITW_Objectives pushBack _obj;

        private _base = EMPTY_BASE;
        _base set [ITW_BASE_POS,_pos];
        _base set [ITW_BASE_A_SPAWN,_pos];
        ITW_Bases pushBack _base;
    } else {
        ITW_OutToSeaPos = ITW_Objectives#-1#ITW_OBJ_POS;
    }; 
    
    waitUntil {! isNil "VEHICLE_ARRAYS_COMPLETE"};
    _fromSave call ITW_ObjNext;
    
    // add flag options
    private _flags = [];
    {
        private _flag = _x#ITW_OBJ_FLAG;
        private _pos = ITW_Bases#_forEachIndex#ITW_BASE_GARAGE_POS;
        _flags pushBack [_flag,_pos];
        _x call ITW_ObjSetMarker;
    } forEach ITW_Objectives;
    [_flags] remoteExec ["ITW_ObjFlagMP",0,true];
     
    // calculate sea points
    {
        private _objPt = _x#ITW_OBJ_POS;
        private _seaPts = [];
        private _minDistToSea = 100;
        private _maxDistToSea = 500 + ITW_ParamObjectiveSize;
        private _minDepth = -0.5;
        for "_d" from 0 to 359 step 15 do {
            private _cnt = 0;
            for "_r" from _minDistToSea to _maxDistToSea step 10 do {
                private _pos = _objPt getPos [_r,_d];
                if (surfaceIsWater _pos && {getTerrainHeightASL _pos < _minDepth}) then {
                    private _fromPosASL = +_pos;
                    _fromPosASL set [2,0];
                    private _toPosASL = +_fromPosASL;
                    _toPosASL set [2,20];
                    private _surfaces = lineIntersectsSurfaces [_fromPosASL, _toPosASL, objNull, objNull, true, 1, "GEOM", "NONE", true];
                    if (_surfaces isEqualTo []) then {_cnt = _cnt + 1} else {_cnt = 0};
                } else {
                    _cnt = 0;
                };
                if (_cnt >= 10) exitWith {_seaPts pushBack _pos};
            };
        };
        if (count _seaPts < 5) then {_seaPts = []}; // at least 5 points required
        ITW_SeaPoints pushBack _seaPts;
    } forEach ITW_Objectives;
    
    private _seaIsViable = {count _x > 0} count ITW_SeaPoints > 1;
    if (!_seaIsViable) then {
        va_pShipClassesTransport = [];
        va_eShipClassesTransport = [];
        va_cShipClassesTransport = [];
        va_pShipClassesAttack = [];
        va_eShipClassesAttack = [];
        va_cShipClassesAttack = [];
        va_pShipClassesDual = [];
        va_eShipClassesDual = [];
        va_cShipClassesDual = [];
    };
            
    0 call ITW_ObjCreateNearestBasesMap;
    0 spawn ITW_ObjFlagTask; 
    0 spawn ITW_ObjArtillery; 
    
    //{diag_log ["Zone",_forEachIndex,_x]} forEach ITW_Zones; 
    //{diag_log ["OBJ",_forEachIndex,_x]} forEach ITW_Objectives;
    //{diag_log ["Base",_forEachIndex,_x]} forEach ITW_Bases;  
                 
};
    
ITW_ObjGetObjectives = {
    // get all locations
    private _allLocationTypes = ["NameLocal", "NameVillage", "NameCity", "NameCityCapital","Airport"];
    private _locs = "true" configClasses (configFile >> "CfgLocationTypes");
    {_allLocationTypes pushBack (configName _x);false} count _locs;    
    // SOG Prairie Fire has a couple of location types that throw a ton of warnings, so remove them
    _allLocationTypes = _allLocationTypes - ["HandDrawnPoint","NameCityCapitalFormer"];
        
    // constants
    private _objInCities = true;
    private _minNumberOfBuildings = 5;
    private _numBldgsSize = 100;
    private _blacklist = ["water"];
    private _worldSize = worldSize/2; 
    private _worldSizeMargin = _worldSize - 400;
    private _whiteList = [[[_worldSize,_worldSize],[_worldSizeMargin,_worldSizeMargin,0,true]]]; // defaults to whole map
    private _alternateNames = ["Apple","Brother","Continental","Dover","Eastern","Father","George","Harry","Ivy","Joker",
                               "King","London","Mother","Nobel","October","Peter","Quigley","Robert","Sugar","Thomas",
                               "Uncle","Victoria","Wednesday","Xmas","Yellow","Zebra","Amsterdam","Baltimore","Casablanca","Denmark",
                               "Edison","Florida","Golf","Havana","India","Jerusalem","Kilogramme","Liverpool","Madagascar","New York",
                               "Oslo","Paris","Queen","Roma","Santiago","Tripoli","Uppsala","Valencia","Washington","Xanthippe","Yokohama","Zurich"
                              ];
    private _altNameCount = count _alternateNames;
    
    switch (toLowerANSI worldname) do {
        case "cam_lao_nam": {
            // cam lao nam tunnels don't really work
            _blacklist = ["water",
                [[350,     16979.3,0],1000],
                [[253.172, 18696.2,0],1000],
                [[556.726 ,20229.9,0],1000],
                [[2730.52, 20066.4,0],1000],
                [[4252.47, 20084.8,0],1000],
                [[5769.42, 20088.9,0],1000]
            ];
        };
        case "zargabad": {
            _whiteList = [[[4250,4000],[750,700,0,true]]];
        };
    };
    
    // clear objectives if we're re-making them
    {
        _x params ["_center","_size","_marker"];
        deleteMarker _marker;
    } count ITW_Objectives;
    ITW_Objectives = [];
    
    if (ITW_ParamObjectiveCount == 0) then {
        // player chooses locations
        private _objs = call ITW_ObjPlayerSelection;
        if (count _objs < 3) then {
            ITW_ParamObjectiveCount = 10; // fall back if player didn't choose locations
            [0,["AO selection canceled. Setting up objectives randomly","BLACK OUT",0.001]] remoteExec ["cutText",0,false];
            sleep 2;
        } else {
            // move the 2nd obj (enemy base) to the last one
            private _objLast = _objs#1;
            _objs deleteAt 1;
            _objs pushBack _objLast;
            
            {
                private _aoPos = _x;
                _aoText = _alternateNames#((_forEachIndex-1) mod _altNameCount);
                ITW_Objectives pushBack [_aoPos,nil,_aoText,objNull,"",0,[],-1,ITW_OWNER_ENEMY,nil,[],false];
            } forEach _objs;
        };
    };
    if (ITW_ParamObjectiveCount > 0) then {
        // algorithm chooses objective locations
        // Determine appropriate number of objectives based on world size
        private _objectiveSpacing = 1500/ITW_ParamObjectiveCount + ITW_ParamObjectiveSize;
        private _landSqKm = 0;
        private _seaSqKm = 0;
        for "_i" from 500 to worldSize step 1000 do {
            for "_j" from 500 to worldSize step 1000 do {
                private _pos = [_i,_j,0];
                if (surfaceIsWater _pos && {getTerrainHeightASL _pos < -5}) then {
                    _seaSqKm = _seaSqKm + 1;
                } else {
                    _landSqKm = _landSqKm + 1;
                };
            };
        };
        private _objSuggestedCnt = (_landSqKm / 5) min 50; // don't add more than 50 objectives
        private _objCnt = floor (_objSuggestedCnt * (ITW_ParamObjectiveCount/10)) max (ITW_ParamObjectivesPerZone + 2);    
        diag_log format ["ITW: Obj Count: suggested %1  (Land %2 sqkm) adjusted to %3 based on parameter setting",floor _objSuggestedCnt,_landSqKm, _objCnt];
        
        // Find all the objectives
        for "_i" from 1 to _objCnt do {
            [0,[format ["Setting up objective %1 of %2",_i,_objCnt],"BLACK OUT",0.001]] remoteExec ["cutText",0,false];  
            private _aoPos = [];
            private _aoSize = 100;
            private _nearby = [];
            
            // POSITION
            private _okay = false;
            private _loopCnt = 500;
            while {!_okay && {_loopCnt > 0}} do {
                _loopCnt = _loopCnt - 1;
                _aoPos = [_whitelist, _blacklist] call BIS_fnc_randomPos;
                if (count _aoPos == 2) exitWith {diag_log "ITW_ObjGetObjectives: quit looking because BIS_fnc_randomPos has given up"};
                if (_objInCities) then {
                    if (_loopCnt == 0) then {
                        // give up on cities
                        _objInCities = false;
                        _loopCnt = 200;
                    }; 
                    _bldg = nearestBuilding _aoPos;
                    if ((_bldg distance2D _aoPos) < 800) then {
                        _nearby = [_bldg, _numBldgsSize] call ITW_ObjNearestBuildings;
                        if (count _nearby >= _minNumberOfBuildings) then {
                            _okay = true;
                            _aoPos = [_nearby] call ITW_ObjCenter;
                        };
                    };
                } else {
                    _okay = true;
                };
                if (_okay) then {
                    // make sure we're not too close to another AO
                    {
                        private _otherAoCenter = _x#ITW_OBJ_POS;
                        if (_aoPos distance2D _otherAoCenter < _objectiveSpacing) exitWith {_okay = false};
                    } count ITW_Objectives;
                    
                    if (_okay) then {
                        // recenter
                        _aoSize = ITW_ParamObjectiveSize;
                        _nearby = [_aoPos, _aoSize/2] call ITW_ObjNearestBuildings;
                        if (count _nearby > 0) then {
                            private _centeredPos = [_nearby] call ITW_ObjCenter;
                            // make sure we're still not too close to another AO
                            {
                                private _otherAoCenter = _x#ITW_OBJ_POS;
                                if (_centeredPos distance2D _otherAoCenter < _objectiveSpacing) exitWith {_centeredPos = _aoPos};
                            } count ITW_Objectives;
                            _aoPos = _centeredPos;
                        };
                    };
                };
            }; 
            if (!_okay) exitWith {diag_log "ITW_ObjGetObjectives: quit looking because we've tried too many times"};// quit adding locations as there are none left
            
            

            // TEXT   
            _aoText = _alternateNames#((_i-1) mod _altNameCount);
            
            _blacklist pushBack [_aoPos,1500];
            
            ITW_Objectives pushBack [_aoPos,nil,_aoText,objNull,"",0,[],-1,ITW_OWNER_ENEMY,nil,[],false];
        };
    };
};

ITW_ObjPlayerSelection = {
    missionNamespace setVariable ["ITW_OBJ_SELECTION_DONE",nil];
    // choose who will pick locations
    if (isDedicated) then {        
        // if using a dedicated server, use a the first player to choose 
        waitUntil {count (call BIS_fnc_listPlayers) > 0};
        private _playerClient = owner ((call BIS_fnc_listPlayers)#0);
        [false] remoteExec ["ITW_ObjPlayerSelectionMP",-(_playerClient),true];
        [true] remoteExec ["ITW_ObjPlayerSelectionMP",_playerClient];
    } else {
        // hosted server, so just let the host choose 
        [false] remoteExec ["ITW_ObjPlayerSelectionMP",-2,true];
        [true] call ITW_ObjPlayerSelectionMP;
    };
    waitUntil {sleep 0.5; missionNamespace getVariable ["ITW_OBJ_SELECTION_DONE",false]};
    [0,["Setting up objectives","BLACK OUT",0.001]] remoteExec ["cutText",0,false];
    private _objs = missionNamespace getVariable ["OBJ_SELECTION",[]];
    _objs
};

ITW_ObjPlayerSelectionMP = {
    params ["_isChooser"];
    if (!hasInterface) exitWith {};
    private _debug = true;
    private _hadMap = true;
    if (player getSlotItemName 608 isEqualTo "") then {
        _hadMap = false;
        player linkItem "ItemMap";
    };
    if (_isChooser) then {
        ITW_MAP_BS = false;
        ITW_MAP_CLICK_POS = [];
        ITW_MAP_CIRCLE_POS = [0,0];
        private _keyHandler = findDisplay 12 displayAddEventHandler ["KeyDown", 
            {
                params ["_displayorcontrol", "_key", "_shift", "_ctrl", "_alt"];
                private ["_return"];
                _return = false;
                // key 0xD3 is delete
                //if (_key == 0xD3 and !_alt and !_shift) then {
                //    ITW_MAP_DEL = true;
                //    openMap false;  
                //    _return = true;
                //};
                // key 0x0E is backspace
                if (_key == 0x0E and !_alt and !_shift) then {
                    ITW_MAP_BS = true;
                    _return = true;
                };
                // 0x1C 0x9C and are carriage return
                if (_key == 0x1C || _key == 0x9C) then {
                    _return = true;
                };
                _return
            }];
        
        // jump through some hoops to block ctrl clicks
        ITW_MAPCLICK_TIME = 0;
        private _mapHandlerDown = findDisplay 12 displayAddEventHandler ["MouseButtonDown", 
            {
                params ["_control", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];
                // 0 is left button
                if (!_alt and !_shift and !_ctrl and _button == 0) then {
                    ITW_MAPCLICK_TIME = time;
                };
                false
            }];
        private _ehId = addMissionEventHandler ["MapSingleClick", {
            params ["_units", "_pos", "_alt", "_shift"];
            if (!_alt && !_shift) then {
                _delta = time-ITW_MAPCLICK_TIME;
                if (_delta < 0.8) then {
                    ITW_MAP_CLICK_POS = _pos;
                };
            }}];
    
        ITW_MAP_CIRCLE = createMarkerLocal ["baseSelector",[0,0]];
        ITW_MAP_CIRCLE setMarkerSizeLocal [ITW_ParamObjectiveSize,ITW_ParamObjectiveSize];
        ITW_MAP_CIRCLE setMarkerShapeLocal "ELLIPSE";
        ITW_MAP_CIRCLE setMarkerBrushLocal "Border";
        ITW_MAP_CIRCLE setMarkerColorLocal "ColorBlue";
        ITW_MAP_CIRCLE setMarkerAlphaLocal 0;
        
        private _circleMovingEH = findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["MouseMoving",
            {
                params ["_control", "_xPos", "_yPos", "_mouseOver"];
                ITW_MAP_CIRCLE setMarkerPosLocal (_control ctrlMapScreenToWorld [_xPos,_yPos]);
            }];
            
        showMap true; 
        openMap [true,false];
        waitUntil {visibleMap};
        mapAnimAdd [0, 1, [worldSize/2,worldSize/2]];
        mapAnimCommit;
        0 cutText ["","PLAIN"];
        #define STATE_INIT          0
        #define STATE_FRIENDLY_BASE 1
        #define STATE_ENEMY_BASE    2
        #define STATE_OBJECTIVES    3
        private _state = 0;
        private _objs = [];
        if (_debug) then {diag_log format ["ITW Objective Selection: START visibleMap %1",visibleMap]}; 
        while {visibleMap} do {    
            switch (_state) do {
                case STATE_INIT: {
                    ITW_MAP_CLICK_POS = []; ITW_MAP_BS = false;  
                    ITW_MAP_CIRCLE setMarkerAlphaLocal 0; 
                    private _marker = createMarkerLocal ["baseSelectBlur", [worldSize/2,worldSize/2]];    
                    _marker setMarkerShapeLocal "RECTANGLE";   
                    _marker setMarkerBrushLocal "SolidFull";   
                    _marker setMarkerColorLocal "ColorBlack";   
                    _marker setMarkerSizeLocal [worldSize/2,worldSize/2];     
                    _marker setMarkerAlphaLocal 0.7;
                    "chooser" cutText ["<t size='2'><br/>You will choose the friendly base,<br/>Then the enemy final base,<br/>Then the objectives in between in any order.<br/>Use BACKSPACE to back up<br/>Use ESC when done.<br/>Click on the map to begin</t>","PLAIN",4,true,true]; 
                    waitUntil {!visibleMap || ITW_MAP_BS || !(ITW_MAP_CLICK_POS isEqualTo [])};
                    if (_debug) then {diag_log format ["ITW Objective Selection: STATE_INIT          visibleMap %1, backspace %2, mapClick %3",visibleMap,ITW_MAP_BS,!(ITW_MAP_CLICK_POS isEqualTo [])]}; 
                    deleteMarkerLocal _marker;
                    if (!ITW_MAP_BS) then {
                        _state = STATE_FRIENDLY_BASE;
                        ITW_MAP_CIRCLE setMarkerAlphaLocal 1;
                        "chooser" cutText ["","PLAIN"];    
                    };
                };
                case STATE_FRIENDLY_BASE: {
                    ITW_MAP_CLICK_POS = []; ITW_MAP_BS = false;       
                    hint "Choose friendly start location"; 
                    ITW_MAP_CIRCLE setMarkerColorLocal "ColorBlue";
                    waitUntil {!visibleMap || ITW_MAP_BS || !(ITW_MAP_CLICK_POS isEqualTo [])};
                    if (_debug) then {diag_log format ["ITW Objective Selection: STATE_FRIENDLY_BASE visibleMap %1, backspace %2, mapClick %3",visibleMap,ITW_MAP_BS,!(ITW_MAP_CLICK_POS isEqualTo [])]}; 
                    if (visibleMap && !ITW_MAP_BS) then {
                        _objs pushBack ITW_MAP_CLICK_POS;
                        _state = STATE_ENEMY_BASE;
                        private _marker = createMarkerLocal ["baseSelect0", ITW_MAP_CLICK_POS]; 
                        _marker setMarkerTypeLocal "loc_Frame";
                        _marker setMarkerColorLocal "ColorBlue";
                        _marker setMarkerSize [0.5,0.5];
                    } else {
                        _state = STATE_INIT;
                        if (ITW_MAP_BS) then {
                            _objs deleteAt (count _objs - 1);
                            deleteMarker ("baseSelect" + str(count _objs));
                        };
                    };
                };
                case STATE_ENEMY_BASE: {
                    ITW_MAP_CLICK_POS = []; ITW_MAP_BS = false; 
                    ITW_MAP_CIRCLE setMarkerColorLocal "ColorRed";      
                    hint "Choose enemy final location"; 
                    waitUntil {!visibleMap || ITW_MAP_BS || !(ITW_MAP_CLICK_POS isEqualTo [])};
                    if (_debug) then {diag_log format ["ITW Objective Selection: STATE_ENEMY_BASE    visibleMap %1, backspace %2, mapClick %3",visibleMap,ITW_MAP_BS,!(ITW_MAP_CLICK_POS isEqualTo [])]}; 
                    if (visibleMap && !ITW_MAP_BS) then {
                        _objs pushBack ITW_MAP_CLICK_POS;
                        _state = STATE_OBJECTIVES;
                        private _marker = createMarkerLocal ["baseSelect1", ITW_MAP_CLICK_POS]; 
                        _marker setMarkerTypeLocal "loc_Frame";
                        _marker setMarkerColorLocal "ColorRed";
                        _marker setMarkerSize [0.5,0.5];
                    } else {
                        _state = STATE_FRIENDLY_BASE;
                        if (ITW_MAP_BS) then {
                            _objs deleteAt (count _objs - 1);
                            deleteMarker ("baseSelect" + str(count _objs));
                        };
                    };
                };
                default {
                    ITW_MAP_CLICK_POS = []; ITW_MAP_BS = false; 
                    ITW_MAP_CIRCLE setMarkerColorLocal "ColorCivilian";      
                    hint format ["Choose objective (%1). Backspace to back up. ESC to finish.",count _objs - 1]; 
                    waitUntil {!visibleMap || ITW_MAP_BS || !(ITW_MAP_CLICK_POS isEqualTo [])};
                    if (_debug) then {diag_log format ["ITW Objective Selection: STATE_OBJECTIVES    visibleMap %1, backspace %2, mapClick %3",visibleMap,ITW_MAP_BS,!(ITW_MAP_CLICK_POS isEqualTo [])]}; 
                    if (visibleMap && !ITW_MAP_BS) then {
                        _objs pushBack ITW_MAP_CLICK_POS;
                        private _marker = createMarkerLocal ["baseSelect"+str(count _objs - 1), ITW_MAP_CLICK_POS]; 
                        _marker setMarkerTypeLocal "loc_Frame";
                        _marker setMarkerColorLocal "ColorCivilian";
                        _marker setMarkerSize [0.5,0.5];
                    } else {
                        if (ITW_MAP_BS) then {
                            _objs deleteAt (count _objs - 1);
                            deleteMarker ("baseSelect" + str(count _objs));
                        };
                        if (count _objs < 2) then {_state = STATE_ENEMY_BASE};
                    };
                };
            };
        };
        if (_debug) then {diag_log format ["ITW Objective Selection: DONE visibleMap %1, backspace %2, num objectives %3",visibleMap,ITW_MAP_BS,count _objs]};
        hint "";
        0 cutText ["","BLACK OUT",0.001];
        removeMissionEventHandler ["MapSingleClick", _ehId];
        findDisplay 12 displayRemoveEventHandler ["MouseButtonDown",_mapHandlerDown];
        findDisplay 12 displayRemoveEventHandler ["KeyDown",_keyHandler]; 
        findDisplay 12  displayCtrl 51 ctrlRemoveEventHandler ["MouseMoving",_circleMovingEH]; 
        missionNamespace setVariable ["OBJ_SELECTION",_objs,true];
        missionNamespace setVariable ["ITW_OBJ_SELECTION_DONE",true,true];
        for "_i" from 1 to count _objs do {deleteMarker ("baseSelect"+str(_i-1))};
        deleteMarkerLocal ITW_MAP_CIRCLE;
    } else {
        showMap true; 
        openMap [true,true];
        waitUntil {visibleMap};
        0 cutText ["","PLAIN"];
        hint "Another player is choosing base locations";
        waitUntil {sleep 0.5; missionNamespace getVariable ["ITW_OBJ_SELECTION_DONE",false]};
        0 cutText ["","BLACK OUT",0.001];
        openMap [false,false];
    };
    if (!_hadMap) then {player unlinkItem "ItemMap"};
};

ITW_ObjGetZones = {
    params ["_createNewZones"];
    if (_createNewZones) then {        
        // sanity check
        if (count ITW_Objectives < 3) exitWith {
            ITW_Zones = [];
            ["Too few bases found to generate game"] remoteExec ["ITW_ObjFailure",0];
        };
        
        private _zoneDir = random 360;
        private _w2 = worldSize/2;
        private _finalZone = [];
        if (ITW_ParamObjectiveCount == 0) then {
            // players chose locations
            _zoneDir = [_w2,_w2] getDir (ITW_Objectives#0#ITW_OBJ_POS);
            // player choosen already has the player base 1st and enemy final base last
        } else {
            // find first (player base) point nearest the _zoneDir direction by sorting distance from line
            private _ptToLineDist = {
                params ["_pt","_line"];
                _line params ["_a","_b","_c"];
                // find distance between _pt and line: d = |Ax0 + By0 + C| / sqrt(a² + b²)
                abs(_a*(_pt#0) + _b*(_pt#1) + _c)/sqrt((_a*_a) + (_b*_b))
            };
            
            // we want to sort the objectives from player's side of the map to the enemies side of the map
            private ["_A","_B","_C"];
            // y = mx+b
            // m = slope
            // b = y - mx
            // mx - y + b = 0
            // Ax+By+C=0
            // so A = m, B = -1, C = b
            // m = tan(angle)
            private _pt = [_w2,_w2] getPos [worldSize,_zoneDir];
           
            private _m = tan(-_zoneDir);
            private _A = _m;
            private _B = -1;
            private _C = (_pt#1) - (_m * (_pt#0));
            private _line = [_A,_B,_C];
       
            private _objSorter = []; // array of [dist,index]    
            {
                private _center = _x#ITW_OBJ_POS;
                private _dist = [_center,_line] call _ptToLineDist;
                _objSorter pushBack [_dist,_forEachIndex];
            } forEach ITW_Objectives;
            
            _objSorter sort true;
        
            // now rearrange the objective array to be in the desired order
            private _objs = [];
            {
                private _idx = _x#1;
                _objs pushBack (ITW_Objectives#_idx);
                false
            } count _objSorter;
            ITW_Objectives = _objs;
            private _objCnt = count _objs;
        };
        
        // now we can resort by how close they are to this zero point
        
        // Define zones
        private _objSorter = []; // array of [dist,index] 
        private _pt0 = ITW_Objectives#0#ITW_OBJ_POS;
        {
            private _center = _x#ITW_OBJ_POS;
            private _dist = _center distance2D _pt0;
            _objSorter pushBack [_dist,_forEachIndex];
        } forEach ITW_Objectives;
        
        if (ITW_ParamObjectiveCount == 0) then {
            // players chose locations          
            _objSorter#0 set [0,0];
            _objSorter#-1 set [0,1e10];
        };
        _objSorter sort true;
        
        // now rearrange the objective array to be in the desired order
        private _objs = [];
        {
            private _idx = _x#1;
            private _obj = ITW_Objectives#_idx;
            _obj set [ITW_OBJ_MARKER,"obj" + str _forEachIndex];
            _objs pushBack _obj;
        } forEach _objSorter;
        ITW_Objectives = _objs;
        private _objCnt = count _objs;
        
        // Define zones
        private _numBases = _objCnt - 2;
        
        private _zoneId = 0;
        private _objsAvailable = ITW_Objectives apply {_x}; // array that is a copy of all the objectives
        _objsAvailable deleteAt 0; // player's base is not available
        if (ITW_ParamObjectiveCount == 0) then {_objsAvailable deleteAt (count _objsAvailable - 1)}; // final base is fixed as enemy camp
        while {count _objsAvailable > 0} do {
            _zoneId = _zoneId + 1;
            private _obj0 = _objsAvailable#0;
            private _pos0 = _obj0#ITW_OBJ_POS;
            _obj0 set [ITW_OBJ_ZONEID,_zoneId]; // save the zone (will update in ITW_Objectives
            _objsAvailable deleteAt 0;          // remove this objective from the local array _objAvailable
            for "_i" from 2 to ITW_ParamObjectivesPerZone do { 
                if (count _objsAvailable == 0) exitWith {};
                private _idx = [_pos0,_objsAvailable,ITW_OBJ_POS] call ITW_FncClosestIndex;
                _objsAvailable#_idx set [ITW_OBJ_ZONEID,_zoneId]; // save the zone (will update in ITW_Objectives
                _objsAvailable deleteAt _idx;                     // remove this objective from the local array _objAvailable
            };
        };
        if (ITW_ParamObjectiveCount == 0) then {ITW_Objectives#-1 set [ITW_OBJ_ZONEID,_zoneId]};
    }; 
    // create ITW_Zones array
    private _zoneCnt = 0;
    {
        if (_x#ITW_OBJ_HIDDEN) then {continue}; 
        private _cnt = _x#ITW_OBJ_ZONEID;
        if (_cnt > _zoneCnt) then {_zoneCnt = _cnt};
    } count ITW_Objectives;
    ITW_Zones = [];
    ITW_Zones resize [_zoneCnt+1,[]];
    {
        if (_x#ITW_OBJ_HIDDEN) then {continue};
        private _objZone = _x#ITW_OBJ_ZONEID;
        ITW_Zones#_objZone pushBack _forEachIndex;
    } forEach ITW_Objectives;
    
    // make the final zone have only 1 or 2 objectives
    if (count (ITW_Zones#-1) > 2 || {count ITW_Zones < 3}) then {
        private _lastZone = ITW_Zones#-1;
        private _lastIndex = count _lastZone - 1;
        private _lastObjIdx = _lastZone#_lastIndex;
        _lastZone deleteAt _lastIndex;
        ITW_Zones pushBack [_lastObjIdx];
        ITW_Objectives#_lastObjIdx set [ITW_OBJ_ZONEID,count ITW_Zones - 1];
    };
    publicVariable "ITW_Zones";
    
    {    
        // Objective Markers
        if (_x#ITW_OBJ_HIDDEN) then {continue};
        private _objective = _x;
        private _aoPos = _objective#ITW_OBJ_POS;
        private _owner = _objective#ITW_OBJ_OWNER;
        private _captured = switch (_owner) do {
            case ITW_OWNER_CONTESTED: {_forEachIndex call ITW_ObjContestedOwnerIsFriendly};
            case ITW_OWNER_FRIENDLY:  {true};
            default                   {false};
        };
        if (_forEachIndex == 0) then {_captured = true};
        private _flag = [_aoPos,_captured] call ITW_ObjFlag;
        _objective set [ITW_OBJ_FLAG,_flag];
        private _taskId = format ["tCap%1",_forEachIndex];
        _objective set [ITW_OBJ_TASKID,_taskId];
    } forEach ITW_Objectives;
};

ITW_ObjContestedOwnerIsFriendly = {
    // flag is owned by friendlies (blue), but may be going up/down either red or blue
    // this call is safe on server or client
    params ["_objIdx"];
    private _idx = ITW_ObjContestedState findIf {_x#ITW_CONT_OBJ_IDX == _objIdx};
    if (_idx < 0) exitWith {false};
    ITW_ObjContestedState#_idx#ITW_CONT_PLAYER_OWNED
};

ITW_ObjFailure = {
    // call on all clients
    cuttext ["<t size='2'>" + _msg + "</t>","PLAIN",-1,true,true];
};

ITW_ObjGenStructures = {
    params ["_aoCenter","_aoSize","_minBuildings","_keepClearZones"];
    
    // collections that only need to happen once
    if (isNil "ITW_BUILDING_TYPES") then {
        // this collects thousands of buildings, so convert it to a weighted array to keep from keeping an 11k array around
        // on altis it found 11,354 buildings, but only took 20msec to convert it to a weighted array of 93 building types
        private _mapSize2 = worldSize/2;
        ITW_ADDED_BUILDING_BLACKLIST = ["water"];
        ITW_BUILDING_TYPES = [];
        private _allBuildings = ([[_mapSize2,_mapSize2,0], worldSize] call ITW_ObjNearestBuildings) apply {typeOf _x} select {sizeOf _x < 40};
        private _bldTypes = _allBuildings arrayIntersect _allBuildings;
        private _hashmap = createHashMap;
        {_hashmap set [_x,0]} count _bldTypes;
        {
            private _bldg = _x;
            private _cnt = _hashmap get _bldg;
            _hashmap set [_bldg,_cnt + 1];
        } count _allBuildings;
        {
            ITW_BUILDING_TYPES pushBack _x;
            ITW_BUILDING_TYPES pushBack _y;
            false
        } forEach _hashmap;
        
        // don't put buildings near airports
        ITW_AIRPORT_BLACKLIST = ["water"]; 
        if (count (allAirports#0) > 0) then {
            private _taxiOff = (getArray (configfile >> "CfgWorlds" >> worldname >> "ilsTaxiOff")) call ITW_AirfieldFixIlsTaxi;
            private _ils = getArray (configfile >> "CfgWorlds" >> worldname >> "ilsPosition");
            if (count _taxiOff > 3 && count _ils > 1) then {
                private _taxi = [_taxiOff#2,_taxiOff#3,0];
                private _center = [(_taxi#0 + _ils#0)/2,(_taxi#1 + _ils#1)/2,0];
                private _dist = 200 + (_taxi distance2D _ils)/2; 
                private _ilsDir = getArray (configfile >> "CfgWorlds" >> worldname >> "ilsDirection");
                private _angle = (_ilsDir#0) atan2 (_ilsDir#2);
                if (_dist < 2000) then {ITW_AIRPORT_BLACKLIST pushBack [_center,200,_dist,_angle,true]};
            };
            private _sec = (configfile >> "CfgWorlds" >> worldname >> "SecondaryAirports");
            for "_i" from 0 to (count _sec - 1) do {
                private _cfg = _sec select _i;
                _taxiIn = (getArray (_cfg >> "ilsTaxiIn")) call ITW_AirfieldFixIlsTaxi;
                _ils = getArray (_cfg >> "ilsPosition");
                if (count _taxiIn > 1 && count _ils > 1) then { 
                    private _taxi = [_taxiIn#0,_taxiIn#1,0];
                    private _center = [(_taxi#0 + _ils#0)/2,(_taxi#1 + _ils#1)/2,0];
                    private _dist = 150 + (_taxi distance2D _ils)/2; 
                    private _ilsDir = getArray (_cfg >> "ilsDirection");
                    private _angle = (_ilsDir#0) atan2 (_ilsDir#2);
                    if (_dist < 2000) then {ITW_AIRPORT_BLACKLIST pushBack [_center,200,_dist,_angle,true]};
                };
            };
        };    
    };
    private _nearest = [_aoCenter, _aoSize] call ITW_ObjNearestBuildings;
    private _numBuildings = count _nearest;    
    if (_numBuildings < _minBuildings) then {  
        private _origNumBldgs = _numBuildings;
        private _placeDir = if (_numBuildings > 0) then {getDir (selectRandom _nearest)} else {random 360};
        private _loopCnt = 50;
        private _blacklist = ITW_AIRPORT_BLACKLIST + _keepClearZones;
        
        while {_numBuildings < _minBuildings && {_loopCnt > 0}} do {
            _loopCnt = _loopCnt - 1;
            private _type = selectRandomWeighted ITW_BUILDING_TYPES;
            if (isNil "_type") exitWith {diag_log "ITW: ITW_ObjGenStructures: no structures to mimic found"};
            private _bSize = sizeOf _type;
            private _posLoopCnt = 10;            
            private _pos = [];
            while {count _pos < 2 && {_posLoopCnt > 0}} do {
                _posLoopCnt = _posLoopCnt - 1;
                _pos = [_aoCenter, 0, _aoSize, _bSize, 0, 0.2, 0, _blacklist] call BIS_fnc_findSafePos;
                if (count _pos == 2 && {isOnRoad _pos}) exitWith {_blacklist pushBack [_pos,10]; _pos = []};
            };
            if (count _pos == 2) then {
                _numBuildings = _numBuildings + 1;
                _pos pushBack 0;
                private _bldg = _type createVehicle _pos;
                _bldg setDir _placeDir + (floor random 4 * 90);
                _bldg setPosATL _pos;  
                _blacklist pushBack [_pos, sizeOf _type + 10];
                ITW_ADDED_BUILDING_BLACKLIST pushBack [_pos, sizeOf _type + 10];
            };            
        };      
        diag_log format ["ITW: Added %1/%2 buildings to the zone",_numBuildings - _origNumBldgs,_origNumBldgs];
    };
};

ITW_ObjGetNearest = {
    params ["_pos",["_owner",ITW_OWNER_CONTESTED],["_capturedBy",ITW_OWNER_CONTESTED],["_allowEmpty",false]]; 
    // _owner: ITW_OWNER_UNDEFINDED:all objectives or ITW_OWNER_ENEMY or ITW_OWNER_FRIENDLY or ITW_OWNER_CONTESTED
    // _capturedBy: if _owner is contested, who has captured it ITW_OWNER_FRIENDLY, ITW_OWNER_ENEMY, or ITW_OWNER_CONTESTED for any owner
    // if _allowEmpty is true, then if the desired objective does not exist then [] is returned, otherwise a suitable replacement is returned
    if (ITW_Objectives isEqualTo []) exitWith {EMPTY_OBJECTIVE};
    if (ITW_ZoneIndex < 0) exitWith {ITW_Objectives#0};
    if (ITW_ZoneIndex >= count ITW_Zones) exitWith {ITW_Objectives#-1};
    private _objectives = switch (_owner) do {
        case ITW_OWNER_ENEMY;
        case ITW_OWNER_FRIENDLY: {ITW_Objectives select {_x#ITW_OBJ_OWNER == _owner}};
        case ITW_OWNER_CONTESTED: {
            switch (_capturedBy) do {
                case ITW_OWNER_CONTESTED: {ITW_Objectives select {_x#ITW_OBJ_OWNER == ITW_OWNER_CONTESTED}};
                default {ITW_Objectives select {_x#ITW_OBJ_OWNER == ITW_OWNER_CONTESTED && {_x#ITW_OBJ_INDEX call ITW_ObjContestedOwnerIsFriendly == (_capturedBy == ITW_OWNER_FRIENDLY)}}};
            };
        };
        default {ITW_Objectives};
    };
    if (_objectives isEqualTo []) exitWith {
        if (_allowEmpty) then {
            []
        } else {
            diag_log format ["ITW_ObjGetNearest, no objective (_this = %1, ITW_ZoneIndex = %2)",_this,ITW_ZoneIndex];
            if (_owner isEqualTo ITW_OWNER_FRIENDLY) then {ITW_Objectives#0} else {ITW_Objectives#-1};
        };
    };
    private _nearestObj = [_pos,_objectives,ITW_OBJ_POS] call ITW_FncClosest;
    //private _garagePos = [ITW_Garages, _nearestObj#ITW_OBJ_POS] call BIS_fnc_nearestPosition;
    _nearestObj
};

ITW_ObjIsNearestFriendly = {
    private _pos = _this;
    if (typeName _pos == "OBJECT" || {typeName _pos == "GROUP"}) then {_pos = getPosATL _pos};
    private _nearestObj = [_pos,ITW_OWNER_CONTESTED,ITW_OWNER_CONTESTED] call ITW_ObjGetNearest;
    _nearestObj#ITW_OBJ_INDEX call ITW_ObjContestedOwnerIsFriendly
};

ITW_ObjGetBase = {
    params ["_posNearObj",["_isFriendly",true]];
    private _nearestObj = [_posNearObj,if (_isFriendly) then {ITW_OWNER_FRIENDLY} else {ITW_OWNER_ENEMY}] call ITW_ObjGetNearest;
    ITW_Bases#(_nearestObj#ITW_OBJ_INDEX)
};

ITW_ObjGetPlayerSpawnPtDir = {
    params [["_posNearObj",[]],["_isByLand",true]];
    // if _posNearObj == [] then it will choose a random attack objective
    if (_posNearObj isEqualTo []) then {
        private _objs = [true,true] call ITW_ObjGetContestedObjs;
        _posNearObj = if (_objs isEqualTo []) then {ITW_Objectives#0#ITW_OBJ_POS} else {(selectRandom _objs)#ITW_OBJ_POS};
    }; 
    private _base = [_posNearObj,true] call ITW_ObjGetBase;
    private _spawnDir = (_base#ITW_BASE_DIR)-90;
    private _spawnPt = _base#ITW_BASE_P_SPAWN;
    [_base] call ITW_BaseEnsure;
    [_spawnPt,_spawnDir]
};

ITW_ObjGetContestedObjs = {
    // gets contested points, falls back to returning defend points if no attack points available and vise versa
    // if no arguments supplied then all contested points are returned
    params [["_isFriendly",nil],["_isAttack",true]];
    private _objectives = ITW_Objectives select {_x#ITW_OBJ_OWNER == ITW_OWNER_CONTESTED};
    if (isNil "_isFriendly") exitWith {_objectives};
    
    private _friendlyAttackPts = _objectives select {!(_x#ITW_OBJ_INDEX call ITW_ObjContestedOwnerIsFriendly)};
    private _friendlyDefendPts = _objectives - _friendlyAttackPts;
    if (_friendlyAttackPts isEqualTo []) then {_friendlyAttackPts = _friendlyDefendPts}
    else {if (_friendlyDefendPts isEqualTo []) then {_friendlyDefendPts = _friendlyAttackPts}};
    private _objs = if (_isFriendly) then {if (_isAttack) then {_friendlyAttackPts} else {_friendlyDefendPts}}
                                     else {if (_isAttack) then {_friendlyDefendPts} else {_friendlyAttackPts}};
    _objs
};

ITW_ObjSetMarker = {
    private _objective = _this;
    private _hidden = _objective#ITW_OBJ_HIDDEN;
    if (_hidden) exitWith {};
    
    private _aoPos = _objective#ITW_OBJ_POS;
    private _aoSize = ITW_ParamObjectiveSize;
    private _marker = _objective#ITW_OBJ_MARKER;
    private _name = _objective#ITW_OBJ_NAME;
    private _zoneId = _objective#ITW_OBJ_ZONEID;
    private _objId = _objective#ITW_OBJ_INDEX;
    private _captured = _objId call ITW_ObjContestedOwnerIsFriendly;
    private _garagePadMrk = GARAGE_MARKER_NAME(_objective#ITW_OBJ_FLAG); // garage pad marker only shows in player owned contested objectives
    
    #define COLOR_ACTIVE_BLUE   "ColorBlue"
    #define COLOR_ACTIVE_RED    "ColorEast"
    #define COLOR_INACTIVE_BLUE "ColorWest"
    #define COLOR_INACTIVE_RED  "ColorRed"

//#def SHOW_COLORED_ZONES 1
#ifdef SHOW_COLORED_ZONES
    #define COLOR_ARRAY ["ColorRed"] // ["ColorRed","ColorCIV","ColorYellow","Color3_FD_F","ColorBlack"]
    private _clrArrayCnt = count COLOR_ARRAY;
#endif
    
    private "_color";
    private _brush = "Solid";
    private _alpha = 0.5;
    switch (true) do {
        case (_zoneId < ITW_ZoneIndex || _zoneId == 0): {
                                            _color = COLOR_INACTIVE_BLUE;
                                            _brush = "DiagGrid";
                                            _aoSize = ZONE_KEEP_OUT_SIZE;
                                            _aoPos = ITW_Bases#(_objective#ITW_OBJ_INDEX)#ITW_BASE_POS;
                                            _garagePadMrk setMarkerAlpha 0;
                                        };
        case (_zoneId > ITW_ZoneIndex): {
                                            _color = COLOR_INACTIVE_RED;
                                            _brush = "DiagGrid";
                                            _aoSize = ZONE_KEEP_OUT_SIZE;
                                            _name = "";
                                            _alpha = 1;
                                            _aoPos = ITW_Bases#(_objective#ITW_OBJ_INDEX)#ITW_BASE_POS;
                                            _garagePadMrk setMarkerAlpha 0;
                                            #ifdef SHOW_COLORED_ZONES
                                                private _idx = _zoneId - 2;
                                                if (_idx < 0) then {_idx = 0};
                                                if (_idx >= _clrArrayCnt) then {_idx = _idx mod _clrArrayCnt};
                                                _color = COLOR_ARRAY#_idx; 
                                            #endif
                                        };
        case (_captured):               {_color = COLOR_ACTIVE_BLUE;_garagePadMrk setMarkerAlpha 1};
        default                         {_color = COLOR_ACTIVE_RED ;_garagePadMrk setMarkerAlpha 1};
    };
    
    private ["_mrkr","_mrkrT"];
    if (getMarkerColor _marker isEqualTo "") then {
        _mrkr = createMarkerLocal [_marker,_aoPos];
        _mrkrT = createMarkerLocal [_marker+"t",_aoPos];
    } else {
        _mrkr = _marker;
        _mrkrT = _marker+"t";
        _mrkr setMarkerPosLocal _aoPos;
        _mrkrT setMarkerPosLocal _aoPos;
    };
    _mrkr setMarkerBrushLocal _brush;
    _mrkr setMarkerColorLocal _color;
    _mrkr setMarkerShapeLocal "ELLIPSE";
    _mrkr setMarkerSizeLocal [_aoSize,_aoSize];
    _mrkr setMarkerAlpha _alpha;
    
    _mrkrT setMarkerTextLocal _name;
    _mrkrT setMarkerTypeLocal "EmptyIcon";
    _mrkrT setMarkerColorLocal _color;
    _mrkrT setMarkerAlpha 1;
};
        
ITW_ObjNearestBuildings = {
    // Get nearest buildings (not power lines and garbage heaps)
    params ["_pos","_radius"];
    
    private _nonBuildingTypes = [
        "Land_SCF_01_heap_bagasse_F","Land_vn_dyke_10","Land_vn_bridge_monkey_01","Land_vn_bridge_monkey_02",
        "Land_vn_bridge_monkey_03","Land_vn_bridge_monkey_04","Land_vn_bridge_monkey_05","Land_vn_fence_bamboo_01_03",
        "Land_vn_fence_bamboo_01_05","Land_vn_fence_bamboo_01_10","Land_vn_fence_bamboo_01_gate","Land_vn_fence_bamboo_02",
        "Land_vn_fence_bamboo_02_gate","Land_vn_crater_04_pond_black","Land_vn_crater_04_pond_blue",
        "Land_vn_crater_04_pond_brown","Land_vn_crater_04_pond_green","Land_vn_crater_04_pond_orange", 
        "Land_vn_crater_04_pond_yellow","Land_vn_crater_decal_01","Land_vn_crater_decal_02","Land_vn_crater_01_01",
        "Land_vn_crater_01_02","Land_vn_crater_02_01","Land_vn_crater_02_02","Land_vn_crater_03_01","Land_vn_crater_03_02",
        "Land_vn_crater_04_01","Land_vn_crater_04_02","Land_House_2W03_F","Land_vn_b_tower_01","Land_vn_guardtower_01_f",
        "Land_vn_hut_tower_01","Land_vn_o_prop_cong_cage_01","Land_vn_o_prop_cong_cage_03","Land_vn_o_bunker_02",
        "Land_vn_o_shelter_01","Land_vn_o_shelter_02","Land_vn_o_shelter_03","Land_vn_o_shelter_04","Land_vn_o_shelter_05",
        "Land_vn_o_shelter_06","Land_vn_o_platform_01","Land_vn_o_platform_02","Land_vn_o_platform_03","Land_vn_o_platform_04",
        "Land_vn_o_platform_05","Land_vn_o_platform_06","Land_vn_o_wallfoliage_01","Land_vn_trench_01_grass_f",
        "Land_vn_trenchframe_01_f","Land_vn_trench_01_forest_f","Land_vn_o_trench_firing_01","Land_vn_pierwooden_02_16m_f",
        "Land_vn_pierwooden_01_10m_norails_f", "Land_vn_pierwooden_01_16m_f", "Land_vn_pierwooden_01_dock_f", 
        "Land_vn_pierwooden_01_hut_f", "Land_vn_pierwooden_01_ladder_f", "Land_vn_pierwooden_01_platform_f", 
        "Land_vn_pierwooden_02_16m_f", "Land_vn_pierwooden_02_30deg_f", "Land_vn_pierwooden_02_barrel_f", 
        "Land_vn_pierwooden_02_hut_f", "Land_vn_pierwooden_02_ladder_f", "Land_vn_pierwooden_03_f", "land_gm_euro_railramp_01",
        "land_gm_euro_railramp_02","land_gm_euro_railramp_03","land_gm_standard_gauge_1_18m","land_gm_standard_gauge_2_18m",
        "land_gm_standard_gauge_5_18m","land_gm_standard_gauge_10_18m","land_gm_standard_gauge_25m","land_gm_standard_gauge_3m",
        "land_gm_standard_gauge_36m_bridge","Land_nav_pier_m_F","Land_Pier_addon","Land_Pier_Box_F","Land_Pier_F","Land_Pier_small_F",
        "Land_Pier_wall_F","Land_PierLadder_F","Land_Pillar_Pier_F","Land_Sea_Wall_F","Land_Canal_Dutch_01_15m_F","Land_Canal_Dutch_01_bridge_F",
        "Land_Canal_Dutch_01_corner_F","Land_Canal_Dutch_01_plate_F","Land_Canal_Dutch_01_stairs_F","Land_Breakwater_01_F",
        "Land_Breakwater_02_F","Land_QuayConcrete_01_5m_ladder_F","Land_QuayConcrete_01_20m_F","Land_QuayConcrete_01_20m_wall_F",
        "Land_QuayConcrete_01_innerCorner_F","Land_QuayConcrete_01_outterCorner_F","Land_QuayConcrete_01_pier_F",
        "Land_PierConcrete_01_4m_ladders_F","Land_PierConcrete_01_16m_F","Land_PierConcrete_01_30deg_F","Land_PierConcrete_01_end_F",
        "Land_PierConcrete_01_steps_F","Land_PierWooden_01_10m_noRails_F","Land_PierWooden_01_16m_F","Land_PierWooden_01_dock_F",
        "Land_PierWooden_01_hut_F","Land_PierWooden_01_ladder_F","Land_PierWooden_01_platform_F","Land_PierWooden_02_16m_F",
        "Land_PierWooden_02_30deg_F","Land_PierWooden_02_barrel_F","Land_PierWooden_02_hut_F","Land_PierWooden_02_ladder_F",
        "Land_PierWooden_03_F","Land_vn_nav_pier_m_2","Land_vn_breakwater_01_f","Land_vn_breakwater_02_f","Land_vn_quayconcrete_01_5m_ladder_f",
        "Land_vn_quayconcrete_01_20m_f","Land_vn_quayconcrete_01_20m_wall_f","Land_vn_quayconcrete_01_innercorner_f",
        "Land_vn_quayconcrete_01_outtercorner_f","Land_vn_quayconcrete_01_pier_f","Land_vn_pierconcrete_01_4m_ladders_f",
        "Land_vn_pierconcrete_01_16m_f","Land_vn_pierconcrete_01_30deg_f","Land_vn_pierconcrete_01_end_f","Land_vn_pierconcrete_01_steps_f",
        // SPE_NORWAY
        "Land_Calvary_03_F", "Land_ChickenCoop_01_F", "Land_cmp_Tower_F", "Land_ConcreteWell_02_F", "Land_Cross_01_small_F",
        "Land_FeedRack_01_F", "Land_FeedShack_01_F", "Land_FeedStorage_01_F", "Land_Grave_08_F", "Land_Grave_09_F", 
        "Land_Grave_10_F", "Land_Grave_11_F", "Land_Grave_dirt_F", "Land_Grave_forest_F", "Land_Grave_rocks_F", 
        "Land_GraveFence_01_F", "Land_GraveFence_02_F", "Land_GraveFence_03_F", "Land_GraveFence_04_F", "Land_Hutch_01_F", 
        "Land_LampIndustrial_02_F", "Land_SPE_bocage_long_mound", "Land_SPE_bocage_long_mound_lc", 
        "Land_SPE_bocage_short_mound_lc", "Land_SPE_bocage_tree_01_mound_lc", "Land_SPE_bocage_tree_02_mound_lc", 
        "Land_SPE_bocage_tree_03_mound_lc", "Land_SPE_French_Gate_01_Blue", "Land_SPE_French_Gate_01_Green", 
        "Land_SPE_French_Gate_01_White", "Land_SPE_French_Wall_01_Gate", "Land_SPE_French_Wall_01_Short_d", 
        "Land_SPE_French_Wall_01_Tall_d", "Land_SPE_French_Wall_02_Gate", "Land_SPE_French_Wall_02_Short_d", 
        "Land_SPE_French_Wall_02_Tall_d", "Land_SPE_French_Wall_03_Gate", "Land_SPE_French_Wall_03_Short_d", 
        "Land_SPE_French_Wall_03_Tall_d", "Land_SPE_French_Wall_Dark_01_Gate", "Land_SPE_French_Wall_Dark_01_Small_d", 
        "Land_SPE_French_Wall_Dark_01_Tall_d", "Land_SPE_French_Wall_Dark_02_Gate", "Land_SPE_French_Wall_Dark_02_Small_d",
        "Land_SPE_French_Wall_Dark_02_Tall_d", "Land_SPE_French_Wall_Dark_03_Gate", "Land_SPE_French_Wall_Dark_03_Small_d",
        "Land_SPE_French_Wall_Dark_03_Tall_d", "Land_SPE_French_Wall_Light_01_Gate", 
        "Land_SPE_French_Wall_Light_01_Small_d", "Land_SPE_French_Wall_Light_01_Tall_d", 
        "Land_SPE_French_Wall_Light_02_Gate", "Land_SPE_French_Wall_Light_02_Small_d", 
        "Land_SPE_French_Wall_Light_02_Tall_d", "Land_SPE_French_Wall_Light_03_Gate", 
        "Land_SPE_French_Wall_Light_03_Small_d", "Land_SPE_French_Wall_Light_03_Tall_d", "Land_SPE_Ger_Lamp", 
        "Land_SPE_Haystack", "Land_SPE_Haystack_low", "Land_SPE_Mound_End_01", "Land_SPE_Mound_End_01_LC", 
        "Land_SPE_Mound_End_02", "Land_SPE_Mound_End_02_LC", "Land_SPE_Mound_Long", "Land_SPE_Mound_Long_LC", 
        "Land_SPE_Mound_Low_01", "Land_SPE_Mound_Low_01_LC", "Land_SPE_Mound_Low_02", "Land_SPE_Mound_Low_02_LC", 
        "Land_SPE_Mound_Short_LC", "Land_SPE_Onion_Lamp", "Land_spe_pond1", "land_spe_pond2", 
        "land_spe_river_large_10m_left_10d_01", "land_spe_river_large_10m_left_20d_01", 
        "land_spe_river_large_10m_left_30d_01", "land_spe_river_large_10m_left_5d_01", 
        "land_spe_river_large_10m_right_10d_01", "land_spe_river_large_10m_right_20d_01", 
        "land_spe_river_large_10m_right_30d_01", "land_spe_river_large_10m_right_5d_01", 
        "land_spe_river_large_10m_straight_01", "land_spe_river_large_20m_left_10d_01", 
        "land_spe_river_large_20m_left_5d_01", "land_spe_river_large_20m_right_10d_01", 
        "land_spe_river_large_20m_right_10d_Junction_2m_01", "land_spe_river_large_20m_right_10d_Junction_2m_02", 
        "land_spe_river_large_20m_right_5d_01", "land_spe_river_large_20m_straight_01", 
        "land_spe_river_large_20m_straight_01_crossing_01", "land_spe_river_large_40m_straight_01", 
        "land_spe_river_medium_10m_left_10d_01", "land_spe_river_medium_10m_left_30d_01", 
        "land_spe_river_medium_10m_left_5d_01", "land_spe_river_medium_10m_right_10d_01", 
        "land_spe_river_medium_10m_right_30d_01", "land_spe_river_medium_10m_right_5d_01", 
        "land_spe_river_medium_10m_straight_01", "land_spe_river_medium_20m_left_10d_01", 
        "land_spe_river_medium_20m_left_5d_01", "land_spe_river_medium_20m_right_10d_01", 
        "land_spe_river_medium_20m_right_5d_01", "land_spe_river_medium_20m_straight_01", 
        "land_spe_river_medium_40m_straight_01", "land_spe_river_medium_junction_01", "land_spe_river_medium_junction_02", 
        "land_spe_river_medium_junction_03", "land_spe_river_medium_junction_04", "land_spe_river_medium_junction_05", 
        "land_spe_river_medium_junction_06", "land_spe_river_medium_junction_07", "land_spe_river_medium_junction_08", 
        "land_spe_river_small_10m_left_10d_01", "land_spe_river_small_10m_left_30d_01", 
        "land_spe_river_small_10m_left_5d_01", "land_spe_river_small_10m_right_10d_01", 
        "land_spe_river_small_10m_right_30d_01", "land_spe_river_small_10m_right_5d_01", 
        "land_spe_river_small_10m_straight_01", "land_spe_river_small_20m_left_10d_01", 
        "land_spe_river_small_20m_left_5d_01", "land_spe_river_small_20m_right_10d_01", 
        "land_spe_river_small_20m_right_5d_01", "land_spe_river_small_20m_straight_01", 
        "land_spe_river_small_40m_straight_01", "land_spe_river_small_junction_01", "land_spe_river_small_junction_02", 
        "land_spe_river_water_large_10m_left_10d_01", "land_spe_river_water_large_10m_left_20d_01", 
        "land_spe_river_water_large_10m_left_30d_01", "land_spe_river_water_large_10m_left_5d_01", 
        "land_spe_river_water_large_10m_right_10d_01", "land_spe_river_water_large_10m_right_20d_01", 
        "land_spe_river_water_large_10m_right_30d_01", "land_spe_river_water_large_10m_right_5d_01", 
        "land_spe_river_water_large_10m_straight_01", "land_spe_river_water_large_20m_left_10d_01", 
        "land_spe_river_water_large_20m_left_5d_01", "land_spe_river_water_large_20m_right_10d_01", 
        "land_spe_river_water_large_20m_right_10d_Junction_2m_01", 
        "land_spe_river_water_large_20m_right_10d_Junction_2m_02", "land_spe_river_water_large_20m_right_5d_01", 
        "land_spe_river_water_large_20m_straight_01", "land_spe_river_water_large_20m_straight_01_crossing_01", 
        "land_spe_river_water_large_40m_straight_01", "land_spe_river_water_medium_10m_left_10d_01", 
        "land_spe_river_water_medium_10m_left_30d_01", "land_spe_river_water_medium_10m_left_5d_01", 
        "land_spe_river_water_medium_10m_right_10d_01", "land_spe_river_water_medium_10m_right_30d_01", 
        "land_spe_river_water_medium_10m_right_5d_01", "land_spe_river_water_medium_10m_straight_01", 
        "land_spe_river_water_medium_20m_left_10d_01", "land_spe_river_water_medium_20m_left_5d_01", 
        "land_spe_river_water_medium_20m_right_10d_01", "land_spe_river_water_medium_20m_right_5d_01", 
        "land_spe_river_water_medium_20m_straight_01", "land_spe_river_water_medium_40m_straight_01", 
        "land_spe_river_water_medium_junction_01", "land_spe_river_water_medium_junction_02", 
        "land_spe_river_water_medium_junction_03", "land_spe_river_water_medium_junction_04", 
        "land_spe_river_water_medium_junction_05", "land_spe_river_water_medium_junction_06", 
        "land_spe_river_water_medium_junction_07", "land_spe_river_water_medium_junction_08", 
        "land_spe_river_water_small_10m_left_10d_01", "land_spe_river_water_small_10m_left_30d_01", 
        "land_spe_river_water_small_10m_left_5d_01", "land_spe_river_water_small_10m_right_10d_01", 
        "land_spe_river_water_small_10m_right_30d_01", "land_spe_river_water_small_10m_right_5d_01", 
        "land_spe_river_water_small_10m_straight_01", "land_spe_river_water_small_20m_left_10d_01", 
        "land_spe_river_water_small_20m_left_5d_01", "land_spe_river_water_small_20m_right_10d_01", 
        "land_spe_river_water_small_20m_right_5d_01", "land_spe_river_water_small_20m_straight_01", 
        "land_spe_river_water_small_40m_straight_01", "land_spe_river_water_small_junction_01", 
        "land_spe_river_water_small_junction_02", "Land_SPE_StreetLamp", "Land_SPE_StreetLamp_Off", 
        "Land_SPE_StreetLamp_pole", "Land_SPE_StreetLamp_pole_off", "Land_SPE_StreetLamp_wall", "Land_SPE_US_Lamp", 
        "Land_SPE_Wood_Fence_02_Gate", "Land_SPE_Wood_Gate_4m_01", "Land_SPE_Wood_Gate_4m_02", "Land_SPE_Wood_Gate_5m_01", 
        "Land_SPE_Wood_Gate_5m_02", "Land_SPE_Wood_TrenchLogWall_01_4m_v1", "Land_StoneWell_01_F", 
        "Land_TelephoneLine_01_wire_50m_main_F",
        "Land_vn_tunnel_01_building_01_01","Land_vn_tunnel_01_building_01_02","Land_vn_tunnel_01_building_01_03","Land_vn_tunnel_01_building_01_04",
        "Land_vn_tunnel_01_building_02_01","Land_vn_tunnel_01_building_02_02","Land_vn_tunnel_01_building_02_03","Land_vn_tunnel_01_building_02_04",
        "Land_vn_tunnel_01_building_03_01","Land_vn_tunnel_01_building_03_02","Land_vn_tunnel_01_building_03_03","Land_vn_tunnel_01_building_03_04",
        "Land_vn_tunnel_01_building_04_01","Land_vn_tunnel_01_building_04_02","Land_vn_tunnel_01_building_04_03","Land_vn_tunnel_01_building_04_04",
        "Land_vn_tunnel_01_building_01_05","Land_vn_tunnel_01_building_02_05","Land_vn_tunnel_01_building_03_05","Land_vn_tunnel_01_building_04_05",
        "Land_Crane_F","Land_MobileCrane_01_F","Land_MobileCrane_01_hook_F","Land_CraneRail_01_F","Land_GantryCrane_01_F","Land_A_Crane_02a",
        "Land_A_Crane_02b","Land_A_CraneCon"
    ];                                                                             
                                                                                   
    private _objectsArray = nearestObjects [_pos, ["house"], _radius];  
    
    {
        // no-buildings have building positions equal to [0,0,0] or are in my list
        if ((_x buildingPos 0) isEqualTo [0,0,0] || {typeOf _x in _nonBuildingTypes}) then {
            _objectsArray deleteAt _forEachIndex;
        };
    } forEachReversed _objectsArray;                     
            
    _objectsArray
};

ITW_ObjCenter = {
    params ["_buildings"];
    private ["_xmin","_xmax","_ymin","_ymax","_p","_px","_py"];
    
    // Find center of the nearby buildings
    _xmin = worldSize;
    _xmax = 0;
    _ymin = worldSize;
    _ymax = 0;
    {
        _p = getPosATL _x;
        _px = _p select 0;
        _py = _p select 1;
        if (_px > _xmax) then { _xmax = _px; };
        if (_px < _xmin) then { _xmin = _px; };
        if (_py > _ymax) then { _ymax = _py; };
        if (_py < _ymin) then { _ymin = _py; };
    } count _buildings;
    _center = [(_xmax + _xmin)/2, (_ymax + _ymin)/2, 0];
    
    // now find the center of the current town
    _dist = 50;
    _radius = 150;
    _done = false;
    while {not _done} do {
        _centerN  = _center getPos [_dist, 0];
        _centerNE = _center getPos [_dist, 45];
        _centerE  = _center getPos [_dist, 90];
        _centerSE = _center getPos [_dist, 135];
        _centerS  = _center getPos [_dist, 180];
        _centerSW = _center getPos [_dist, 125];
        _centerW  = _center getPos [_dist, 270];
        _centerNW = _center getPos [_dist, 315];
    
        _count   = count ([_center,   _radius] call ITW_ObjNearestBuildings);
        _countN  = count ([_centerN , _radius] call ITW_ObjNearestBuildings);
        _countNE = count ([_centerNE, _radius] call ITW_ObjNearestBuildings);
        _countE  = count ([_centerE , _radius] call ITW_ObjNearestBuildings);
        _countSE = count ([_centerSE, _radius] call ITW_ObjNearestBuildings);
        _countS  = count ([_centerS , _radius] call ITW_ObjNearestBuildings);
        _countSW = count ([_centerSW, _radius] call ITW_ObjNearestBuildings);
        _countW  = count ([_centerW , _radius] call ITW_ObjNearestBuildings);
        _countNW = count ([_centerNW, _radius] call ITW_ObjNearestBuildings);
        
        //diag_log format ["GP: center ao %1 : N%2 E%3 S%4 W%5",_count,_countN,_countE,_countS,_countW];
        _done = true;
        if (_count < _countN ) then { _count = _countN ; _center = _centerN ; _done = false; };
        if (_count < _countNE) then { _count = _countNE; _center = _centerNE; _done = false; };
        if (_count < _countE ) then { _count = _countE ; _center = _centerE ; _done = false; };
        if (_count < _countSE) then { _count = _countSE; _center = _centerSE; _done = false; };
        if (_count < _countS ) then { _count = _countS ; _center = _centerS ; _done = false; };
        if (_count < _countSW) then { _count = _countSW; _center = _centerSW; _done = false; };
        if (_count < _countW ) then { _count = _countW ; _center = _centerW ; _done = false; };
        if (_count < _countNW) then { _count = _countNW; _center = _centerNW; _done = false; };
        
        if (!_done and (_count > 40) and ((random 10) > 6)) then { _done = true; }; // random chance to just leave it offcenter
    };
    _center
};

ITW_ObjNext = {
    params [["_isSaveLoad",false]]; // _isSaveLoad is true when starting up a saved game
    
    private _prevZoneIndex = ITW_ZoneIndex;
    if (!_isSaveLoad) then {ITW_ZoneIndex = ITW_ZoneIndex + 1};       
    publicVariable "ITW_ZoneIndex";
    private _contestedObjectives = if (ITW_ZoneIndex < count ITW_Zones) then {ITW_Zones#ITW_ZoneIndex} else {[]};
    
    diag_log format ["ITW: ZoneNext %1 >> %2",_prevZoneIndex,ITW_ZoneIndex];
    
    if (!_isSaveLoad && ITW_ZoneIndex > 1) then {
        // complete previous tasks
        private _oldObjIds = ITW_Zones#_prevZoneIndex;
        if (isNil "_oldObjIds") exitWith {};
        {
            private _idx = _x;
            private _obj = ITW_Objectives#_idx;
            private _taskId = _obj#ITW_OBJ_TASKID;
            private _name = _obj#ITW_OBJ_NAME;         
            [_taskId, "SUCCEEDED", _forEachIndex == 0] call BIS_fnc_taskSetState;
            _obj call ITW_ObjSetMarker;
            private _board = nearestObject [ITW_Bases#(_obj#ITW_OBJ_INDEX)#ITW_BASE_GARAGE_POS,ITW_BASE_PLACARD];
            private _gInfo = _board getVariable ["itwrepair",[]];
            if !(_gInfo isEqualTo []) then {
                _gInfo call ITW_vehRepairPointRemove;
                ITW_VehFTPoints pushBack (_gInfo#0);
            };
            deleteVehicle _board; // 'fast travel from garage pad to flag' board needs deleting on captured zones
            false
        } forEach _oldObjIds;
        if (ITW_ParamMines > 0) then {[_oldObjIds,true] spawn ITW_ObjMinefields};
    };
    
    // handle win state
    if (ITW_ZoneIndex >= count ITW_Zones) exitWith {
        ITW_GameOver = true;
        sleep 7;
        call ITW_EraseGame;
        ["END1", true,  true, true, true] remoteExec ["BIS_fnc_endMission",0, true];
    };
        
    if (!_isSaveLoad) then {
        // mark contested objectives
        {
            private _obj = ITW_Objectives#_x;
            _obj set [ITW_OBJ_OWNER,ITW_OWNER_CONTESTED];
            false
        } count _contestedObjectives;
        
        // setup captured bases
        {
            private _obj = ITW_Objectives#_x;
            _obj set [ITW_OBJ_OWNER,ITW_OWNER_FRIENDLY];
            private _baseIndex = _obj#ITW_OBJ_INDEX;
            _baseIndex spawn ITW_BaseNext;
            false
        } count (ITW_Zones#_prevZoneIndex);
        
        0 call ITW_AtkNext;
    } else {
        // on loading a game, setup all owned bases
        {
            if (_forEachIndex >= ITW_ZoneIndex) exitWith {};
            private _objIds = _x;
            {
                private _obj = ITW_Objectives#_x;
                private _baseIndex = _obj#ITW_OBJ_INDEX;
                _baseIndex call ITW_BaseNext;
                _obj set [ITW_OBJ_OWNER,ITW_OWNER_FRIENDLY];
            } forEach _objIds;
            false
        } forEach ITW_Zones;
    };
    publicVariable "ITW_Bases";
    publicVariable "ITW_Objectives";
    
    0 call ITW_EnemyCivManager;
    
    private _flags = [];
    {
        // add extra buildings if needed
        private _obj = ITW_Objectives#_x;
        private _aoPos = +(_obj#ITW_OBJ_POS);
        private _basePos = ITW_Bases#(_obj#ITW_OBJ_INDEX)#ITW_BASE_POS;
        private _vehSpawn = _obj#ITW_OBJ_V_SPAWN;
        private _keepClearZones = [[_basePos,120]];
        if (!isNil "_vehSpawn" && {!(_vehSpawn isEqualTo [])}) then {_keepClearZones pushBack [_vehSpawn,50]};
        if (ITW_ParamExtraBuildings > 0) then {
            private _minNumberOfBuildings = round (ITW_ParamObjectiveSize/12);
            [_aoPos,ITW_ParamObjectiveSize,_minNumberOfBuildings,_keepClearZones] call ITW_ObjGenStructures;
        };
                
        // create new tasks
        private _idx = _x;
        private _taskId = _obj#ITW_OBJ_TASKID;
        private _name   = _obj#ITW_OBJ_NAME;
        private _flag   = _obj#ITW_OBJ_FLAG;
        private _assign = "CREATED";
        private _showHint = if (_isSaveLoad || _forEachIndex > 0) then {false} else {true};
        _aoPos set [2,1];       
        [true, _taskId, ["","Attack "+_name,""], _aoPos, _assign, 10, _showHint, "attack", ITW_ParamObjectivesVisible3D == 1] call BIS_fnc_taskCreate;
        _flags pushBack _flag;
        _obj call ITW_ObjSetMarker;
    } forEach _contestedObjectives;
    [_contestedObjectives] call ITW_ObjGenStatics;
    
    // add minefields if needed
    if (ITW_ParamMines > 0) then {[_contestedObjectives] spawn ITW_ObjMinefields};
        
    // handle flags and markers
    ITW_FlagsActive = _flags;
    publicVariable "ITW_FlagsActive";
    
    [] call ITW_SaveGame;
    ITW_OwnedAirports = nil;
    [true] call ITW_ObjOwnedAirports; // update the markers
};

ITW_ObjFlag = {
    params ["_aoPos","_captured"];
    private _flag = objNull;
    private _flagPos = _aoPos;
    private _flagTexture = if (_captured) then {FLAG_PLAYER} else {FLAG_ENEMY};
    
    private _pos = _aoPos findEmptyPosition [0,ITW_ParamObjectiveSize,"Flag_Blue_F"];
    if (_pos isEqualTo []) then {_pos = _aoPos};
    _flag = createVehicle [FLAG_TYPE, _pos, [], 0, "Can_collide"];
    _flag setVariable ["ITW_FlagPos",_aoPos];
    _flag setFlagTexture _flagTexture;
    _flag allowDamage false;
    _flagPos = getPosATL _flag;
        
    _flag
};

ITW_ObjFlagMP = {
    // call on all clients
    waitUntil {!isNil "ITW_ParamVirtualGarage"};
    params ["_flags"];
    {
        _x params ["_flag","_pos"];
        _lightPos = getPosATL _flag;
        _lightPos set [2,2];
        private _light = "#lightpoint" createVehicleLocal _lightPos;
        _light setLightIntensity 500;
        _light setLightAmbient [0,0,0]; 
        _light setLightColor [0.3,0.3,0.3];
        if (ITW_ParamVirtualGarage > 0) then {
            _flag addAction ["Fast travel to garage pad",{
                    params ["_flag", "_player", "_actionId", "_arguments"];
                    private _pos = [ITW_Garages, _flag] call BIS_fnc_nearestPosition;
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
                    _player setDir -90;
                    _pos = _pos getPos [10,90];
                    _player setPosASL _pos;
                    _bringUnits apply {_x setPosASL _pos};
                },nil,10,true,true,"","vehicle _this == _this && {flagTexture _target isEqualTo 'a3\data_f\flags\flag_blue_co.paa' && {flagAnimationPhase _target > 0.9}}",6];
        };
        _flag addAction ["Fast travel to base",{
                params ["_flag", "_player", "_actionId", "_arguments"];
                [] spawn ITW_RadioFastTravel;
            },nil,10,false,true,"","vehicle _this == _this && {flagTexture _target isEqualTo 'a3\data_f\flags\flag_blue_co.paa' && {flagAnimationPhase _target > 0.9}}",8];
        //_flag addAction ["Arsenal",{
        //        params ["_flag", "_player", "_actionId", "_arguments"];
        //        ["Open",true,missionNamespace] call BIS_fnc_arsenal;
        //    },nil,10,false,true,"","flagTexture _target isEqualTo 'a3\data_f\flags\flag_blue_co.paa' && {flagAnimationPhase _target > 0.9}",6];
        
    } forEach _flags;
    [_flags apply {_x#0},true,6] call CustomArsenal_AddVAs;
};

ITW_ObjFlagTask = {
    // runs on server
    scriptname "ITW_FlagTask";
    #define FLAG_SLEEP           0.5
    #define FLAG_MAX_UNIT_EFFECT 15 // maximum number of units one team has over the other that still increase capture speed
    #define FLAG_MOVE_PER_SEC    0.0004 
    
    private _captureSpeed = FLAG_MOVE_PER_SEC * ITW_ParamObjectiveCaptureSpeed/3;
    private _objSize = ITW_ParamObjectiveSize;
    private _prevZoneIndex = 0;
    private "_currObjIdxs";
    
    waitUntil {sleep 1;ITW_ZoneIndex > 0};
    
    while {ITW_ZoneIndex < count ITW_Zones} do {
        if (ITW_ZoneIndex != _prevZoneIndex) then {
            _currObjIdxs = ITW_Zones#ITW_ZoneIndex;
            if (ITW_ObjContestedState isEqualTo [] || {ITW_ObjContestedState#0#0 != _currObjIdxs#0}) then {
                ITW_ObjContestedState = _currObjIdxs apply {[_x,false]};
            };
            publicVariable "ITW_ObjContestedState";
        };
        
        private _contestedStateChanged = false;
        private _allCaptured = true;
        {
            private _objIdx = _x;
            private _obj = ITW_Objectives#_objIdx;
            
            private _flag = _obj#ITW_OBJ_FLAG;         
            if (ITW_ZoneIndex != _prevZoneIndex) then {
                _flag setVariable ["ITW_FlagIsPlayer",_objIdx call ITW_ObjContestedOwnerIsFriendly,true];
                _flag setVariable ["ITW_FlagPhase",1,true]; 
            };
            
            private _pos = _flag getVariable "ITW_FlagPos";
            
            private _unitsInZone = allUnits select {private _side = side _x; _x distance _pos < _objSize && {_side != civilian && {!(_x isKindOf "LOGIC")}}};
            private _unitCount = count _unitsInZone;

            private _ratio = 1;
            private _prevPhase = _flag getVariable ["ITW_FlagPhase",1];
            private _flagIsPlayer = _flag getVariable "ITW_FlagIsPlayer"; 
            private _isAttack = _flag getVariable ["ITW_FlagIsAttack",!(_objIdx call ITW_ObjContestedOwnerIsFriendly)];            
            
            if (_prevPhase < 1 || {!_flagIsPlayer}) then {_allCaptured = false};
            
            if (_unitCount == 0) then {
                // allow flag to drop/recover when no one around
                if ( _isAttack && {!_flagIsPlayer && {_prevPhase >= 1}})  then {continue}; 
                if (!_isAttack && { _flagIsPlayer && {_prevPhase >= 1}})  then {continue};
                if (_isAttack) then {_ratio = -1} else {_ratio = 1};
            } else {
                private _friendlyCnt = {side _x == west && {CONSCIOUS(_x)}} count _unitsInZone;
                private _enemyCnt = _unitCount - _friendlyCnt;  
                if (_friendlyCnt == _enemyCnt) then {continue};         
                // check for flag not going to change cases
                if ( _isAttack && {!_flagIsPlayer && {_prevPhase >= 1 && {_friendlyCnt < _enemyCnt}}}) then {continue};
                if (!_isAttack && { _flagIsPlayer && {_prevPhase >= 1 && {_friendlyCnt > _enemyCnt}}}) then {continue}; 
                
                _ratio = FLAG_MAX_UNIT_EFFECT min (_friendlyCnt - _enemyCnt); // how many more units in zone (negative is more enemy)
                if (_ratio > FLAG_MAX_UNIT_EFFECT ) then {_ratio = FLAG_MAX_UNIT_EFFECT };
                if (_ratio < -FLAG_MAX_UNIT_EFFECT) then {_ratio = -FLAG_MAX_UNIT_EFFECT};
                _ratio = if (_ratio < 0) then {(_ratio/2)-0.5} else {(_ratio/2)+0.5}; // scale as 1, 1.5, 2
                if (_enemyCnt == 0 || {_friendlyCnt == 0}) then {_ratio = _ratio + 0.5}; // capture even faster if no opposition
            };
            
            private _phaseAdj = _ratio * _captureSpeed;
            if (!_flagIsPlayer) then {_phaseAdj = -_phaseAdj};
            
            _phase = _prevPhase + _phaseAdj;            
            if (_phase < 0) then {
                _phase = 0;
                _flagIsPlayer = !_flagIsPlayer;              
                _flag setVariable ["ITW_FlagIsPlayer",_flagIsPlayer,true];
                _flag setFlagTexture (if (_flagIsPlayer) then {FLAG_PLAYER} else {FLAG_ENEMY});
            } else {
                if (_phase > 1) then {
                    _phase = 1;
                    if (_prevPhase != 1) then {
                        private _updateMarker = false;
                        if ( _isAttack && { _flagIsPlayer}) then {_flag setVariable ["ITW_FlagIsAttack",false];_updateMarker=true} else {
                        if (!_isAttack && {!_flagIsPlayer}) then {_flag setVariable ["ITW_FlagIsAttack",true] ;_updateMarker=true}};
                        ITW_ObjContestedState#_forEachIndex set [ITW_CONT_PLAYER_OWNED,_flagIsPlayer];
                        _contestedStateChanged = true;
                        if (_updateMarker) then {_obj call ITW_ObjSetMarker;};
                    };
                };
            };
            if (_phase != _prevPhase) then {
                _flag setVariable ["ITW_FlagPhase",_phase,true];
            };          
        } forEach _currObjIdxs;
        _prevZoneIndex = ITW_ZoneIndex;
        
        if (_contestedStateChanged) then {publicVariable "ITW_ObjContestedState"};
        if (_allCaptured) then {
            ITW_ObjZonesUpdating = true;
            false call ITW_ObjNext;
            ITW_ObjZonesUpdating = false;
        };
        
        sleep FLAG_SLEEP;
        while {LV_PAUSE} do {sleep 5};
        
    };
};

ITW_ObjRedOut = {
    // spawn on clients
    scriptName "ITW_ObjRedOut";
    if (!hasInterface) exitWith {};
    private _handle = -1;
    private _delay = ITW_ParamRedOut;
    private _timeout = -1;
    private _hinting = false;
    while {!ITW_GameOver} do {
        sleep 1;
        // Exit Area Warning & Damage
        private _pos = getPosATL player;
        private _nearestContestedObj = [_pos,ITW_OWNER_CONTESTED,ITW_OWNER_CONTESTED] call ITW_ObjGetNearest;
        if (_nearestContestedObj#ITW_OBJ_POS distanceSqr _pos > ZONE_KEEP_OUT_SQR) then {
            private _closestEnemyObj = [_pos,ITW_OWNER_ENEMY] call ITW_ObjGetNearest;
            private _nearestBase = ITW_Bases#(_closestEnemyObj#ITW_OBJ_INDEX);
            if (_pos distanceSqr (_nearestBase#ITW_BASE_POS) < ZONE_KEEP_OUT_SQR) then {
                _hinting = true;
                if (_timeout < 0) then {
                    _timeout = time + _delay;
                    hint "You are too near an enemy stronghold";
                } else {
                    hintSilent "You are too near an enemy stronghold";
                };
                if (time >= _timeout && {_handle < 0}) then {
                    _handle = ppEffectCreate ["colorCorrections", 1501];
                    _handle ppEffectEnable true;
                    _handle ppEffectAdjust [
                        1,   // brightness,
                        1,   // contrast,
                        0,   // offset,
                        [1,0,0,0.30], // [blendR, blendG, blendB, blendA],
                        [1,1,1,0.63], // [colorizeR, colorizeG, colorizeB, colorizeA],
                        [0.2,0.2,1,0] // [weightR, weightG, weightB, 0],
                    ];
                    _handle ppEffectCommit 1;
                };
            } else {
                _timeout = -1;
                if (_handle >= 0) then {
                    ppEffectDestroy _handle;
                    _handle = -1;
                };
                if (_hinting) then {hintSilent ""};
            };
        } else {
            _timeout = -1;
            if (_handle >= 0) then {
                ppEffectDestroy _handle;
                _handle = -1;
            };
            if (_hinting) then {hintSilent ""};
        };
        if (LV_PAUSE) then {waitUntil {sleep 1;!LV_PAUSE}};
    };
    if (_handle >= 0) then {
        ppEffectDestroy _handle;
    };
};

ITW_ObjFlagHud = {
    // spawn on all clients
    if (!hasInterface) exitWith {};
    scriptname "ITW_ObjFlagHud";
    
    waitUntil {sleep 1;ITW_ZoneIndex > 0};
    
    private _layerId = "RscItwFlagStatus" call BIS_fnc_rscLayer;
    _layerId cutRsc ["RscItwFlagStatus", "PLAIN", -1, false];
    
    private "_display";
    waitUntil {_display = uiNamespace getVariable ['RscItwFlagStatus',displayNull]; !isNull _display};
    
    private _blueCtrls = [ITW_0_BLUE_CTRL,ITW_1_BLUE_CTRL,ITW_2_BLUE_CTRL,ITW_3_BLUE_CTRL,ITW_4_BLUE_CTRL,ITW_5_BLUE_CTRL,ITW_6_BLUE_CTRL,ITW_7_BLUE_CTRL] apply {_display displayCtrl _x};
    private _redCtrls  = [ITW_0_RED_CTRL,ITW_1_RED_CTRL,ITW_2_RED_CTRL,ITW_3_RED_CTRL,ITW_4_RED_CTRL,ITW_5_RED_CTRL,ITW_6_RED_CTRL,ITW_7_RED_CTRL]         apply {_display displayCtrl _x};
    private _textCtrls = [ITW_0_TEXT_CTRL,ITW_1_TEXT_CTRL,ITW_2_TEXT_CTRL,ITW_3_TEXT_CTRL,ITW_4_TEXT_CTRL,ITW_5_TEXT_CTRL,ITW_6_TEXT_CTRL,ITW_7_TEXT_CTRL] apply {_display displayCtrl _x};
    
    if (ITW_ParamObjectivesFlagGui == 2) then {
        // gui on left
        private _GUI_GRID_WAbs = ((safezoneW / safezoneH) min 1.2);
        private _GUI_GRID_HAbs = (_GUI_GRID_WAbs / 1.2);
        private _GUI_GRID_W =    (_GUI_GRID_WAbs / 40);
        private _GUI_GRID_H =    (_GUI_GRID_HAbs / 25);
        private _FLAG_WIDTH =    (_GUI_GRID_W * 0.25);
        private _FLAG_HEIGHT =   (_GUI_GRID_H * 3);
        private _FLAG_SPACE =    (_GUI_GRID_W * 0.15);
        private _FLAG_VSPACE =   (_GUI_GRID_H * 0.45);
        
        private _FLAG_X0 =       (safezoneX + _FLAG_SPACE);
        private _FLAG_X1 =       (_FLAG_X0 + _FLAG_WIDTH + _FLAG_SPACE);
        private _FLAG_X2 =       (_FLAG_X0 + 2*(_FLAG_WIDTH + _FLAG_SPACE));
        private _FLAG_X3 =       (_FLAG_X0 + 3*(_FLAG_WIDTH + _FLAG_SPACE));
        private _FLAG_Y0 =       (safezoneY + (safezoneH*0.25));
        private _FLAG_Y1 =       (_FLAG_Y0 - _FLAG_HEIGHT - _FLAG_VSPACE);
        private _TEXT_W  =       (_GUI_GRID_W);
        private _TEXT_H  =       (_GUI_GRID_H);
        private _TEXT_X0 =       (_FLAG_X0 - _FLAG_WIDTH);
        private _TEXT_X1 =       (_FLAG_X1 - _FLAG_WIDTH);
        private _TEXT_X2 =       (_FLAG_X2 - _FLAG_WIDTH); 
        private _TEXT_X3 =       (_FLAG_X3 - _FLAG_WIDTH);
        private _TEXT_Y0 =       (_FLAG_Y0 + _FLAG_HEIGHT - _TEXT_H/3);
        private _TEXT_Y1 =       (_FLAG_Y1 + _FLAG_HEIGHT - _TEXT_H/3);

        private _ctrl = _blueCtrls#0;
        _ctrl ctrlSetPosition [_FLAG_X0 ,_FLAG_Y0,_FLAG_WIDTH,_FLAG_HEIGHT];
        _ctrl ctrlCommit 0;
        _ctrl = _blueCtrls#1;        
        _ctrl ctrlSetPosition [_FLAG_X1 ,_FLAG_Y0,_FLAG_WIDTH,_FLAG_HEIGHT];
        _ctrl ctrlCommit 0;
        _ctrl = _blueCtrls#2;        
        _ctrl ctrlSetPosition [_FLAG_X2 ,_FLAG_Y0,_FLAG_WIDTH,_FLAG_HEIGHT];
        _ctrl ctrlCommit 0;
        _ctrl = _blueCtrls#3;        
        _ctrl ctrlSetPosition [_FLAG_X3 ,_FLAG_Y0,_FLAG_WIDTH,_FLAG_HEIGHT];
        _ctrl ctrlCommit 0;
        _ctrl = _blueCtrls#4;
        _ctrl ctrlSetPosition [_FLAG_X0 ,_FLAG_Y1,_FLAG_WIDTH,_FLAG_HEIGHT];
        _ctrl ctrlCommit 0;
        _ctrl = _blueCtrls#5;        
        _ctrl ctrlSetPosition [_FLAG_X1 ,_FLAG_Y1,_FLAG_WIDTH,_FLAG_HEIGHT];
        _ctrl ctrlCommit 0;
        _ctrl = _blueCtrls#6;        
        _ctrl ctrlSetPosition [_FLAG_X2 ,_FLAG_Y1,_FLAG_WIDTH,_FLAG_HEIGHT];
        _ctrl ctrlCommit 0;
        _ctrl = _blueCtrls#7;        
        _ctrl ctrlSetPosition [_FLAG_X3 ,_FLAG_Y1,_FLAG_WIDTH,_FLAG_HEIGHT];
        _ctrl ctrlCommit 0;
        
        _ctrl = _redCtrls#0;
        _ctrl ctrlSetPosition [_FLAG_X0 ,_FLAG_Y0,_FLAG_WIDTH,_FLAG_HEIGHT];
        _ctrl ctrlCommit 0;
        _ctrl = _redCtrls#1;        
        _ctrl ctrlSetPosition [_FLAG_X1 ,_FLAG_Y0,_FLAG_WIDTH,_FLAG_HEIGHT];
        _ctrl ctrlCommit 0;
        _ctrl = _redCtrls#2;        
        _ctrl ctrlSetPosition [_FLAG_X2 ,_FLAG_Y0,_FLAG_WIDTH,_FLAG_HEIGHT];
        _ctrl ctrlCommit 0;
        _ctrl = _redCtrls#3;        
        _ctrl ctrlSetPosition [_FLAG_X3 ,_FLAG_Y0,_FLAG_WIDTH,_FLAG_HEIGHT];
        _ctrl ctrlCommit 0;
        _ctrl = _redCtrls#4;
        _ctrl ctrlSetPosition [_FLAG_X0 ,_FLAG_Y1,_FLAG_WIDTH,_FLAG_HEIGHT];
        _ctrl ctrlCommit 0;
        _ctrl = _redCtrls#5;        
        _ctrl ctrlSetPosition [_FLAG_X1 ,_FLAG_Y1,_FLAG_WIDTH,_FLAG_HEIGHT];
        _ctrl ctrlCommit 0;
        _ctrl = _redCtrls#6;        
        _ctrl ctrlSetPosition [_FLAG_X2 ,_FLAG_Y1,_FLAG_WIDTH,_FLAG_HEIGHT];
        _ctrl ctrlCommit 0;
        _ctrl = _redCtrls#7;        
        _ctrl ctrlSetPosition [_FLAG_X3 ,_FLAG_Y1,_FLAG_WIDTH,_FLAG_HEIGHT];
        _ctrl ctrlCommit 0;
        
        _ctrl = _textCtrls#0;
        _ctrl ctrlSetPosition [_TEXT_X0 ,_TEXT_Y0,_TEXT_W,_TEXT_H];
        _ctrl ctrlCommit 0;
        _ctrl = _textCtrls#1;        
        _ctrl ctrlSetPosition [_TEXT_X1 ,_TEXT_Y0,_TEXT_W,_TEXT_H];
        _ctrl ctrlCommit 0;
        _ctrl = _textCtrls#2;        
        _ctrl ctrlSetPosition [_TEXT_X2 ,_TEXT_Y0,_TEXT_W,_TEXT_H];
        _ctrl ctrlCommit 0;
        _ctrl = _textCtrls#3;        
        _ctrl ctrlSetPosition [_TEXT_X3 ,_TEXT_Y0,_TEXT_W,_TEXT_H];
        _ctrl ctrlCommit 0;
        _ctrl = _textCtrls#4;
        _ctrl ctrlSetPosition [_TEXT_X0 ,_TEXT_Y1,_TEXT_W,_TEXT_H];
        _ctrl ctrlCommit 0;
        _ctrl = _textCtrls#5;        
        _ctrl ctrlSetPosition [_TEXT_X1 ,_TEXT_Y1,_TEXT_W,_TEXT_H];
        _ctrl ctrlCommit 0;
        _ctrl = _textCtrls#6;        
        _ctrl ctrlSetPosition [_TEXT_X2 ,_TEXT_Y1,_TEXT_W,_TEXT_H];
        _ctrl ctrlCommit 0;
        _ctrl = _textCtrls#7;        
        _ctrl ctrlSetPosition [_TEXT_X3 ,_TEXT_Y1,_TEXT_W,_TEXT_H];
        _ctrl ctrlCommit 0;
        
    };
    
    private _show = ITW_ParamObjectivesFlagGui > 0;
    
    private _flags = [];
    private _garagePads = []; // in same order as flags
    private _prevIndex = -1;
    while {!ITW_GameOver} do {
        sleep FLAG_SLEEP;
        if (ITW_ZoneIndex != _prevIndex) then {
            _flags = (ITW_Zones#ITW_ZoneIndex) apply {ITW_Objectives#_x#ITW_OBJ_FLAG};
            if (isNil "_flags") then {continue};
            private _names = (ITW_Zones#ITW_ZoneIndex) apply {ITW_Objectives#_x#ITW_OBJ_NAME};
            if (isNil "_flags" || {isNil "_names" || {_names isEqualTo []}}) exitWith {};
            // hide the controls then show the used ones
            {_x ctrlShow false} count _blueCtrls;
            {_x ctrlShow false} count _redCtrls;
            {_x ctrlShow false} count _textCtrls;
            {
                private _name = _x;
                private _blueCtrl = _blueCtrls#_forEachIndex;
                private _textCtrl = _textCtrls#_forEachIndex;
                _textCtrl ctrlSetText (_name select [0,1]);
                _textCtrl ctrlShow _show;              
            } forEach _names;
            _garagePads = _flags apply {GARAGE_MARKER_NAME(_x)};
            _prevIndex = ITW_ZoneIndex;
        };
        {
            private _flag = _x;
            private _blueCtrl = _blueCtrls#_forEachIndex;
            private _redCtrl = _redCtrls#_forEachIndex;
            private _textCtrl = _textCtrls#_forEachIndex;
            private _flagIsPlayer = _flag getVariable "ITW_FlagIsPlayer";
            if (! isNil "_flagIsPlayer") then {
                private _phase = _flag getVariable ["ITW_FlagPhase",1];
                _flag setFlagAnimationPhase _phase;
                if (_flagIsPlayer) then {
                    _blueCtrl progressSetPosition _phase;
                    _blueCtrl ctrlShow _show;
                    _redCtrl ctrlShow false;
                    _textCtrl ctrlSetTextColor [0,0,1,1];
                } else {
                    _redCtrl progressSetPosition _phase;
                    _redCtrl ctrlShow _show;
                    _blueCtrl ctrlShow false;
                    _textCtrl ctrlSetTextColor [1,0,0,1];
                };
                _garagePads#_forEachIndex setMarkerColorLocal (if (_flagIsPlayer && {_phase == 1}) then {"ColorBlue"} else {"ColorGrey"});
            };
        } forEach _flags;
    };
};
  
ITW_ObjNearestBasesMap = nil; // map between current zone objective point and the nearest base to attack it from
                             // [objPos,[nearestLandPlayer,nearestAirPlayer,nearestLandEnemy,nearestAirEnemy]] or nil if not yet setup                         
ITW_ObjGetNearestBase = {
    params ["_objPos","_getFriendlyBase","_getLand"];
    private "_base";
    // wait for the current zone to be completed
    private _cntr = 0;
    {
        if (_forEachIndex == 0) then {continue};
        if (_forEachIndex > ITW_ZoneIndex) exitWith {};
        _cntr = _cntr + (count _x);
    } forEach ITW_Zones;
    while {isNil "ITW_ObjNearestBasesMap" || {count ITW_ObjNearestBasesMap < _cntr}} do {sleep 1};

    private _nearestBases = ITW_ObjNearestBasesMap get _objPos;
    if (isNil "_nearestBases") then {
        _base = if (_getFriendlyBase) then {ITW_Bases#0} else {[ITW_Bases select -1]};
    } else {
        _base = if (_getFriendlyBase) then {
                    if (_getLand) then {
                        _nearestBases#0
                    } else {
                        _nearestBases#1
                    };
                } else {
                    if (_getLand) then {
                        _nearestBases#2
                    } else {
                        _nearestBases#3
                    };
                };
    };
    _base
};

ITW_ObjCreateNearestBasesMap = {
    // call on server 
    waitUntil {sleep 1;(count ITW_Bases == count ITW_Objectives)};
    private _ready = [false];
    _ready spawn {
        scriptName "ITW_ObjCreateNearestBasesMap";
        private _ready = _this;
        private _agent = objNull;
        private _car = objNull;
        private _agent2 = objNull;
        private _boat = objNull;
        private _hashMap = createHashMap; // hashKey is [objId,objId] with the 1st one being the lower number
        private _slowSleep = 0.75;
        private _DEBUG = false;
        if (_DEBUG) then {diag_log ["ITW_ObjCreateNearestBasesMap","STARTED"]};
            
        private _fnCreateAgent = {
            // create agent for calculating path on land
            // _agent, _agent2, _car, _boat are local to the caller
            private _basePt = ITW_Bases#0#ITW_BASE_A_SPAWN;
            private _spawnPt = _basePt findEmptyPosition [0,200,"C_Quadbike_01_F"];
            if (_spawnPt isEqualTo []) then {_spawnPt = _basePt};
            _car = "B_MRAP_01_F" createVehicle _spawnPt;
            _car allowDamage false;
            _agent = createAgent ["C_man_1", _spawnPt, [], 0, "NONE"];
            _agent allowDamage false;
            hideObjectGlobal _car;
            hideObjectGlobal _agent;
            while {vehicle _agent == _agent} do {
                _agent moveInDriver _car;
                sleep 0.5;
            };
            _agent setBehaviour "CARELESS";            
            _agent addEventHandler ["PathCalculated", {
                params ["_agent", "_path"];
                if (!isNil "ITW_PathDist") exitWith {};
                private _prevPos = [0,0,0];
                private _dist = 0;
                {
                    if (_forEachIndex > 0) then {
                        _dist = _dist + (_x distance2D _prevPos);
                    };
                    _prevPos = _x;
                } forEach _path;
                if (_dist == 0) then {_dist = 1e10};
                ITW_PathDist = _dist;
            }];
            
            waitUntil {! isNil "VEHICLE_ARRAYS_COMPLETE"};
            private _seaIsViable = !(va_pShipClassesTransport isEqualTo [] && va_eShipClassesTransport isEqualTo [] && va_cShipClassesTransport isEqualTo []);
            if (_seaIsViable) then {
                _boat = "B_Boat_Transport_01_F" createVehicle [0,0,0];
                _boat allowDamage false;
                _agent2 = createAgent ["C_man_1", _spawnPt, [], 0, "NONE"];
                _agent2 allowDamage false;
                hideObjectGlobal _boat;
                hideObjectGlobal _agent2;
                while {vehicle _agent2 == _agent2} do {
                    _agent2 moveInDriver _boat;
                    sleep 0.5;
                };
                _agent2 setBehaviour "CARELESS";
                _agent2 addEventHandler ["PathCalculated", {
                    params ["_agent", "_path"];
                    if (!isNil "ITW_PathDist") exitWith {};
                    private _prevPos = [0,0,0];
                    private _dist = 0;
                    {
                        if (_forEachIndex > 0) then {
                            _dist = _dist + (_x distance2D _prevPos);
                        };
                        _prevPos = _x;
                    } forEach _path;
                    if (_dist == 0) then {_dist = 1e10};
                    ITW_PathDist = _dist;
                }];
            };
        };
        
        private _fnAddNearestObjBases = {       
            params ["_zoneId","_objIds","_agent","_car","_agent2","_boat","_hashMap","_fast"];
            if (_DEBUG) then {diag_log ["NearestBasesMap: Adding Bases","zone",_zoneId,"objectives",_objIds,"fast",_fast]}; 
            
            private _fnLandSeaDist = {
                params ["_objId1","_objId2","_agent","_car","_agent2","_boat","_hashMap"];
                
                
                if (_objId1 > _objId2) then {
                    private _temp = _objId1;
                    _objId1 = _objId2;
                    _objId2 = _temp;
                };
                private _hashKey = [_objId1,_objId2];
                private _landSeaDist = _hashMap get _hashKey;
                if (isNil "_landSeaDist") then {
                    private _pt1 = ITW_Objectives#_objId1#ITW_OBJ_POS;
                    private _pt2 = ITW_Objectives#_objId2#ITW_OBJ_POS;                    
                    private _objId = if (_agent distance2D _pt1 > (_agent distance2D _pt2)) then {_objId1} else {_objId2};
                    private _obj = ITW_Objectives#_objId;
                    
                    // Land distance
                    private _pt = _obj#ITW_OBJ_V_SPAWN;
                    if (_pt isEqualTo []) then {
                        private _base = ITW_Bases#(_obj#ITW_OBJ_INDEX);
                        _pt = _base#ITW_BASE_A_SPAWN;
                    };
                    private _landDist = 1e10;
                    ITW_PathDist = nil; // distance, point path-ed to
                    _agent setDestination [_pt, "LEADER PLANNED", true];
                    private _timeout = time + 6;
                    waitUntil {time > _timeout || {!isNil "ITW_PathDist"}}; 
                    doStop _agent;
                    _car engineOn false;
                    if !(isNil "ITW_PathDist") then {
                        _landDist = ITW_PathDist;
                    };    
                    
                    private _seaDist = 1e10;
                    if (!isNull _boat) then {
                        // Sea distance
                        private _seaPts1 = ITW_SeaPoints#_objId1;
                        private _seaPts2 = ITW_SeaPoints#_objId2;
                        if !(_seaPts1 isEqualTo [] || {_seaPts2 isEqualTo []}) then {
                            _pt = if (_agent2 distance2D (_seaPts1#0) > (_agent2 distance2D (_seaPts2#0))) then {_seaPts1#0} else {_seaPts2#0};
                            ITW_PathDist = nil; // distance, point path-ed to
                            _agent2 setDestination [_pt, "LEADER PLANNED", true];
                            private _timeout = time + 6;
                            waitUntil {time > _timeout || {!isNil "ITW_PathDist"}}; 
                            doStop _agent2;
                            _boat engineOn false;
                            if !(isNil "ITW_PathDist") then {
                                _seaDist = ITW_PathDist;
                            }; 
                        };
                    };
                    _landSeaDist = [_landDist,_seaDist];
                    _hashMap set [_hashKey,_landSeaDist];
                };
                _landSeaDist
            };
            
            private _baseFirst = 0;
            private _baseLast = (count ITW_Bases)-1;
            private _friendlyObjIds = [];
            private _enemyObjIds = [];
            private _nearestData = [];
            {
                switch (true) do {
                    case (_x#ITW_OBJ_ZONEID > _zoneId): {_enemyObjIds    pushBack _forEachIndex};
                    case (_x#ITW_OBJ_ZONEID < _zoneId): {_friendlyObjIds pushBack _forEachIndex};
                };
            } forEach ITW_Objectives;
            
            private _closestCount = 5; // how many closest bases will be do land routing for
            private _maxLoopCnt = if (_fast) then {(1 + _closestCount) * count _objIds} else {1};
            private _loopCnt = 1;
            
            {
                private _objectiveId = _x;
                private _objective = ITW_Objectives#_objectiveId;
                private _objectivePt = _objective#ITW_OBJ_POS;
                private _distAir = 1e10;
                private _distLandF = 1e10;
                private _distLandE = 1e10;
                private _distSeaF = 1e10;
                private _distSeaE = 1e10;
                private _nearestAirF  = _baseFirst;
                private _nearestLandF = [];
                private _nearestSeaF = [];
                private _nearestAirE  = _baseLast;
                private _nearestLandE = [];
                private _nearestSeaE = [];
                private _spawnPt = _objective#ITW_OBJ_V_SPAWN;
                if (_spawnPt isEqualTo []) then {
                    private _base = ITW_Bases#(_objective#ITW_OBJ_INDEX);
                    _spawnPt = _base#ITW_BASE_A_SPAWN;
                };
                _spawnPt set [2,0.5];
                _car setPosATL _spawnPt;
                _car setVectorUp surfaceNormal getPosASL _car;
                while {vehicle _agent == _agent} do {
                    _agent moveInDriver _car;
                    sleep 0.2;
                };
                
                if (!isNull _boat) then {
                    private _seaPts = ITW_SeaPoints#_objectiveId;
                    if !(_seaPts isEqualTo []) then {
                        _boat setPosATL _seaPts#0;
                        while {vehicle _agent2 == _agent2} do {
                            _agent2 moveInDriver _boat;
                            sleep 0.2;
                        };
                    };
                };
                sleep 0.1;
                
                // _distList is array of [distance,objId] so it can be sorted by distance
                private _distList = _friendlyObjIds apply {
                    private _objId = _x;
                    private _pt1 = ITW_Objectives#_objectiveId#ITW_OBJ_POS;
                    private _pt2 = ITW_Objectives#_objId#ITW_OBJ_POS;
                    private _airDist = _pt1 distance2D _pt2;
                    [_airDist,_objId]
                };
                _distList sort true;
                _distAir = _distList#0#0;
                _nearestAirF = _distList#0#1;
                private _closestFriendlyObjIds = _distList select [0,_closestCount];
                
                {
                    if (_fast && {isNil "ITW_GameReady"}) then {[0,[format ["Calculating attack vectors (%1/%2)",_loopCnt,_maxLoopCnt],"BLACK OUT",0.001]] remoteExec ["cutText",0,false];_loopCnt = _loopCnt + 1};
                    private _objId = _x#1;
                    [_objectiveId,_objId,_agent,_car,_agent2,_boat,_hashMap] call _fnLandSeaDist params ["_dLand","_dSea"];
                    if (_dLand < _distLandF) then {
                        _distLandF = _dLand;
                        _nearestLandF = _objId;
                    };
                    if (_dSea < _distSeaF) then {
                        _distSeaF = _dSea;
                        _nearestSeaF = _objId;
                    };
                    if (!_fast) then {sleep _slowSleep};
                } count _closestFriendlyObjIds;
                if (_DEBUG) then {diag_log ["NearestBasesMap: FLandX",_distLandF,"FAir",_distAir,_nearestLandF,_nearestAirF,_objectivePt]};  
              
                _distList = _enemyObjIds apply {
                    private _objId = _x;
                    private _pt1 = ITW_Objectives#_objectiveId#ITW_OBJ_POS;
                    private _pt2 = ITW_Objectives#_objId#ITW_OBJ_POS;
                    private _airDist = _pt1 distance2D _pt2;
                    [_airDist,_objId]
                };
                _distList sort true;
                _distAir = _distList#0#0;
                _nearestAirE = _distList#0#1;
                if (isNil "_nearestAirE") then {_nearestAirE = _baseLast}; // last zone has enemy coming from OutToSea (the last base)
                
                private _closestEnemyObjIds = _distList select [0,_closestCount];
                
                {
                    if (_fast && {isNil "ITW_GameReady"}) then {[0,[format ["Calculating attack vectors (%1/%2)",_loopCnt,_maxLoopCnt],"BLACK OUT",0.001]] remoteExec ["cutText",0,false];_loopCnt = _loopCnt + 1};
                    private _objId = _x#1;
                    [_objectiveId,_objId,_agent,_car,_agent2,_boat,_hashMap] call _fnLandSeaDist params ["_dLand","_dSea"];
                    if (_DEBUG) then {diag_log ["NearestBasesMap: EX",_dLand,_dSea,_obj#ITW_OBJ_INDEX,_objId]};
                    if (_dLand < _distLandE) then {
                        _distLandE = _dLand;
                        _nearestLandE = _objId;
                    };
                    if (_dSea < _distSeaE) then {
                        _distSeaE = _dSea;
                        _nearestSeaE = _objId;
                    };
                    if (!_fast) then {sleep _slowSleep};
                } count _closestEnemyObjIds;
                if (_DEBUG) then {diag_log ["NearestBasesMap: ELandX",_distLandE,"EAir",_distAir,"ESea",_distSeaE,_nearestLandE,_nearestAirE,_objectivePt]};  
                
                // if no land paths found, just leave from closest base
                private _landAttackPossible = [true,true,true,true];
                if (_nearestLandF isEqualTo []) then {_nearestLandF = _nearestAirF; _landAttackPossible set [ATTACK_FRIENDLY,false]}; 
                if (_nearestLandE isEqualTo []) then {_nearestLandE = _nearestAirE; _landAttackPossible set [ATTACK_ENEMY,false]};
                if (_distLandF > 7000) then {_landAttackPossible set [ATTACK_FRIENDLY,false]};
                if (_distLandE > 7000) then {_landAttackPossible set [ATTACK_ENEMY,false]};
                if (_nearestSeaF isEqualTo []) then {_nearestSeaF = _nearestAirF; _landAttackPossible set [ATTACK_SEA_FRIENDLY,false]}; 
                if (_nearestSeaE isEqualTo []) then {_nearestSeaE = _nearestAirE; _landAttackPossible set [ATTACK_SEA_ENEMY,false]};
                
                _nearestData pushBack [_objective,[ITW_Objectives#_nearestLandF#ITW_OBJ_INDEX,
                                                   ITW_Objectives#_nearestAirF #ITW_OBJ_INDEX,
                                                   ITW_Objectives#_nearestLandE#ITW_OBJ_INDEX,
                                                   ITW_Objectives#_nearestAirE #ITW_OBJ_INDEX,
                                                   _nearestSeaF,
                                                   _nearestSeaE
                                                  ],_landAttackPossible];
                if (_DEBUG) then {diag_log ["NearestBasesMap: ObjUpdate",_objectiveId,_nearestData#-1#1]};              
                if (!_fast) then {sleep _slowSleep};
            } count _objIds;
            
            // on the final objective, place 
            // update the objectives all at once in case the player saves during the calculation and only some of the data is done
            {
                _x params ["_obj","_data","_landAttackPossible"];
                _obj set [ITW_OBJ_ATTACKS,_data];
                _obj set [ITW_OBJ_LAND_ATK,_landAttackPossible];
            } count _nearestData;
        };
        
        {
            private _zoneNum = _forEachIndex;
            private _fast = _zoneNum <= ITW_ZoneIndex; // run as fast as possible to calculate the current zone, others can be slower
            if (_DEBUG) then {diag_log ["NearestBasesMap","_zoneNum",_zoneNum,"begun",ITW_ZoneIndex,"fast",_fast]};        
            if (_zoneNum < ITW_ZoneIndex) then {continue};
            private _objIds = _x;
            private _obj = ITW_Objectives#(_objIds#0); // just check the first objective to see if it's already been done
            if (_obj#ITW_OBJ_ATTACKS isEqualTo []) then {
                if (isNull _agent) then { call _fnCreateAgent};
                if (!_fast) then {sleep _slowSleep};
                [_forEachIndex,_objIds,_agent,_car,_agent2,_boat,_hashMap,_fast] call _fnAddNearestObjBases;
                publicVariable "ITW_Objectives";
                diag_log format ["ITW: NearestBasesMap: zone %1 completed (obj: %2)",_forEachIndex,_objIds];
                if (_zoneNum != 0) then {0 call ITW_SaveGame}; 
            }; 
            _ready set [0,true]; // trigger that we are ready to work with the current zone
        } forEach ITW_Zones;
        
        if (_DEBUG) then {diag_log ["NearestBasesMap","COMPLETED"]};
        _car deleteVehicleCrew _agent;
        deleteVehicle _car;
        deleteVehicle _agent; // in case agent got out of car
        if (!isNull _boat) then {
            _boat deleteVehicleCrew _agent2;
            deleteVehicle _boat;
            deleteVehicle _agent2; // in case agent got out of boat
        };
    };
    
    waitUntil {sleep 1;_ready#0};
};

ITW_ObjGetOutToSeaPos = {
    if (isNil "ITW_OutToSeaPos") then {
        private _lastObjIdx = ITW_Zones#-1#-1;
        private _firstObjPos = ITW_Objectives#0#ITW_OBJ_POS;
        private _lastObjPos = ITW_Objectives#_lastObjIdx#ITW_OBJ_POS;
        ITW_OutToSeaPos = _lastObjPos getPos [3000,_firstObjPos getDir _lastObjPos];
    };
    ITW_OutToSeaPos;
};

ITW_ObjGetAttackVectorFromPos = {
    // given an objective, get which base it should be attacked from
    params ["_obj","_isFriendly","_isLand"];
    private _which = if (_isFriendly) then {if (_isLand) then {ITW_ATTACK_LAND_F} else {ITW_ATTACK_AIR_F}}
                                      else {if (_isLand) then {ITW_ATTACK_LAND_E} else {ITW_ATTACK_AIR_E}};
    WAIT_FOR_BASE_MAP("ITW_ObjGetAttackVectorBase",_obj);
    private _fromObjIdx = _obj#ITW_OBJ_ATTACKS#_which;
    private "_pos";
    if (_fromObjIdx >= 0) then {
        _pos = ITW_Bases#_fromObjIdx#ITW_BASE_POS
    } else {
        _pos = call ITW_ObjGetOutToSeaPos;
    };
    _pos
};

ITW_ObjLandAtkAdjust = {
    // params is array of [toObjIdx,fromObjIdx]  fromObjIdx == -1 if no land route
    {
        _x params ["_toObjIdx","_fromObjIdx"];
        private _obj = ITW_Objectives#_toObjIdx;
        _obj#ITW_OBJ_ATTACKS  set [ITW_ATTACK_LAND_F,if (_fromObjIdx >= 0) then {_fromObjIdx} else {_obj#ITW_OBJ_ATTACKS#ITW_ATTACK_AIR_F}];
        _obj#ITW_OBJ_LAND_ATK set [0,_fromObjIdx >= 0];
    } forEach _this;
    publicVariable "ITW_Objectives";
};
            
ITW_ObjShowAttackVectors = {
    if (!canSuspend) exitWith {0 spawn ITW_ObjShowAttackVectors};
    // spawn from the debug console
    BM_PT1 = [0,0,0];
    BM_PT2 = [0,0,0];
    BM_PT3 = [0,0,0];
    BM_PT4 = [0,0,0];
    BM_OBJPT = [0,0,0];
    BM_SHOW = FALSE;
    private _mBase = createMarkerLocal ["ITW_MkrBaseShow",[0,0,0]];
    private _mVeh  = createMarkerLocal ["ITW_MkrVehShow",[0,0,0]];
    _mBase setMarkerShapeLocal "ICON";
    _mBase setMarkerTypeLocal "loc_frame";
    _mVeh setMarkerShapeLocal "ICON";
    _mVeh setMarkerTypeLocal "loc_car";
    (finddisplay 49) closeDisplay 1;
    openMap true;
    private _mapCtrl = (findDisplay 12 displayCtrl 51);
    private _ehID = _mapCtrl ctrlAddEventHandler ["Draw", {
        if (BM_SHOW) then {
            private _map = _this#0;
            _map drawLine [BM_PT1,BM_OBJPT,[0,0,1,1]];
            _map drawLine [BM_PT2,BM_OBJPT,[0,1,1,1]];
            _map drawLine [BM_PT3,BM_OBJPT,[1,0,0,1]];
            _map drawLine [BM_PT4,BM_OBJPT,[1,1,0,1]];
        };
    }];
    
    private _objIndexes = [];
    {_objIndexes = _objIndexes + _x} count ITW_Zones;
    private _index = 1;
    private _maxIndex = count ITW_Objectives - 1;
    while {true} do {
        if (_index < 1) then {_index = 1};
        if (_index > _maxIndex) then {_index = _maxIndex};
        private _objIndex = _objIndexes#_index;
        private _obj = ITW_Objectives#_objIndex;
        BM_OBJPT = _obj#0;
        diag_log ["SHOWING OBJECTIVE",_objIndex,_obj#8];
        BM_SHOW = false;
        BM_PT1 = ([_obj,true,true]   call ITW_ObjGetAttackVectorBasePos);
        BM_PT2 = ([_obj,true,false]  call ITW_ObjGetAttackVectorBasePos);
        BM_PT3 = ([_obj,false,true]  call ITW_ObjGetAttackVectorBasePos);
        BM_PT4 = ([_obj,false,false] call ITW_ObjGetAttackVectorBasePos);         
        BM_SHOW = true;
        hint "Press move forward key for next objective, move backward for previous. Close map to quit. Red & Blue are land";
        // now show base and vehicle spawn locations
        _mBase setMarkerPosLocal (ITW_Bases#(_obj#ITW_OBJ_INDEX)#ITW_BASE_POS);
        private _vehPt = _obj#ITW_OBJ_V_SPAWN;
        if (isNil "_vehPt" || {_vehPt isEqualTo []}) then {
            _mVeh setMarkerAlphaLocal 0;
        } else {
            _mVeh setMarkerAlphaLocal 1;
            _mVeh setMarkerPosLocal _vehPt;
        };
        waitUntil {inputAction "MoveForward" > 0 || inputAction "MoveBack" > 0 || !visibleMap};
        if (inputAction "MoveForward" > 0) then {_index = _index + 1}
        else {if (inputAction "MoveBack" > 0) then {_index = _index - 1}};
        if (!visibleMap) exitWith{};
        waitUntil {inputAction "MoveForward" == 0 && inputAction "MoveBack" == 0};       
    };
    _mapCtrl ctrlRemoveEventHandler ["Draw",_ehID];
    deleteMarkerLocal _mVeh;
    deleteMarkerLocal _mBase;
    hint "";
};

ITW_ObjSetVehicleSpawn = {
    // vehicle spawn point (on a road), or [] if no reads nearby, or nil if not setup yet
    params ["_obj"];  
    private _center = _obj#ITW_OBJ_POS;
    private _aiVehSpawnPt = _obj#ITW_OBJ_V_SPAWN;
    if (isNil "_aiVehSpawnPt") then {
        private _roads = [];
        private _dist = 400;
        while {_roads isEqualTo [] && {_dist <= 800}} do {
            _roads = (_center nearRoads _dist) select {private _info = getRoadInfo _x; !(_info#2 || _info#8)}; // not pedestrian or bridge
            _dist = _dist + 200;
        };
        if (!(_roads isEqualTo [])) then {
            _aiVehSpawnPt = getPosATL (selectRandom _roads);
            _aiVehSpawnPt set [2,_aiVehSpawnPt#2 + 0.5];
        } else {
            _aiVehSpawnPt = [];
        };
        _obj set [ITW_OBJ_V_SPAWN,_aiVehSpawnPt];
    };
    if !(_aiVehSpawnPt isEqualTo []) then {[_aiVehSpawnPt,30,[FLAG_TYPE]] remoteExec ["ITW_RemoveTerrainObjects",0,true]};
};

ITW_ObjOwnedAirports = {
    // returns array of positions or [] if no airports owned
    params ["_isFriendly"];
    
    if (isNil "ITW_ZoneAirportMap") then {
        ITW_ZoneAirportMap = createHashMap;
        private _airportPts = [];
        private _cfg = (configFile >> "CfgWorlds" >> worldName);
        private _ilsPos = getArray (_cfg >> "ilsTaxiOff");
        if !(_ilsPos isEqualTo []) then {_airportPts pushBack [_ilsPos#0,_ilsPos#1]};
        {
            _ilsPos = getArray (_x >> "ilsTaxiOff");
            if !(_ilsPos isEqualTo []) then {_airportPts pushBack [_ilsPos#0,_ilsPos#1]};
        } forEach ("true" configClasses (_cfg >> "SecondaryAirports"));
        
        {
            private _airport = _x;
            private _dist = 1e10;
            private _closestZoneId = 0;
            {
                private _obj = _x;
                private _d = _airport distance2D (_obj#ITW_OBJ_POS);
                if (_d < _dist) then {
                    _dist = _d;
                    _closestZoneId = _obj#ITW_OBJ_ZONEID;
                };
            } count ITW_Objectives;
            ITW_ZoneAirportMap set [_closestZoneId,_airport];
        } forEach _airportPts;
    };
    
    waitUntil {isNil "ITW_OwnedAirportsProcessing"};
    if (isNil "ITW_OwnedAirports") then {
        ITW_OwnedAirportsProcessing = true;
        private _airportsF = [];
        private _airportsE = [];
        private _startF = 0;
        private _startE = ITW_ZoneIndex+1;
        private _endF = ITW_ZoneIndex-1;
        private _endE = count ITW_Zones-1;
        {
            private _zone = _x,
            private _airport = _y;
            private _mrkr = "itwAPmrkr"+str _airport;
            if (getMarkerColor _mrkr isEqualTo "") then {createMarkerLocal [_mrkr, _airport]};
            _mrkr setMarkerSizeLocal [0.01,0.01];
            _mrkr setMarkerTypeLocal "EmptyIcon";
            if (_zone >= _startF && {_zone <= _endF}) then {
                _airportsF pushBack _airport;
                _mrkr setMarkerColorLocal COLOR_INACTIVE_BLUE;
                _mrkr setMarkerTextLocal "Allied Airfield";
                _mrkr setMarkerAlpha 1;
            } else {
                if (_zone >= _startE && {_zone <= _endE}) then {
                    _airportsE pushBack _airport;
                    _mrkr setMarkerColorLocal COLOR_ACTIVE_RED;
                    _mrkr setMarkerTextLocal "Enemy Airfield";
                    _mrkr setMarkerAlpha 1;
                } else {
                    _mrkr setMarkerAlpha 0;
                };
            };
        } forEach ITW_ZoneAirportMap;
        ITW_OwnedAirports = [_airportsF,_airportsE];
        ITW_OwnedAirportsProcessing = nil;
        
        if (ITW_ParamAirplaneWithoutAirport == 1) then {
            ITW_OwnedAirports#0 pushBack (ITW_Objectives#0#ITW_OBJ_POS);
            ITW_OwnedAirports#1 pushBack (ITW_Objectives#(count ITW_Objectives - 1)#ITW_OBJ_POS);
        };
    };
    
    ITW_OwnedAirports#(if(_isFriendly)then{0}else{1})
};

ITW_ObjClosestOwnedAirport = {
    // returns position of nearest airport or [] if no airports owned
    params ["_isFriendly","_pos"];
    private _airportPos = [];
    private _airportPositions = _isFriendly call ITW_ObjOwnedAirports;
    [_pos,_airportPositions] call ITW_FncClosest
};

ITW_ObjOwnsAirport = {
    // returns true if this side (friendly or not) owns at least one airport
    params ["_isFriendly"];
    !((_isFriendly call ITW_ObjOwnedAirports) isEqualTo [])
};

ITW_ObjMinefields = {
    params ["_objs",["_clear",false]];
    {
        private _obj = ITW_Objectives#_x;
        private _objPos = _obj#ITW_OBJ_POS;
        if (_clear) then {
            private _mines = nearestMines [_objPos, [], ITW_ParamObjectiveSize+720, false, true];
            {deleteVehicle _x} count _mines;
        } else {
            if (random 1 < (0.4 * ITW_ParamMines)) then {
                private _mineTypes = ["ATMine","APERSMine","APERSBoundingMine","SLAMDirectionalMine"];
                private _fromBasePos = [_obj,true,true] call ITW_ObjGetAttackVectorFromPos;
                private _count = ceil random 3;
                for "_i" from 1 to _count do {
                    private _dir = (_objPos getDir _fromBasePos) - 80 + random 160;
                    private _size = 150 + random 100;
                    private _range = ITW_ParamObjectiveSize + (_size/2) + random (400);
                    private _pos = _objPos getPos [_range,_dir];
                    private _numMines = _size*_size*0.001; // scale to around 20 per 200m circle
                    for "_m" from 1 to _numMines do {   
                        _mine = createMine [selectRandom _mineTypes, _pos, [], _size];
                        _mine setDir (_dir - 45 + random 90);
                    };
                };
            };
        };
    } forEach _objs;
};

ITW_ObjShowMines = {
    private _mineMarkers = [];
    {
        private _m = createMarkerLocal ["itwmine"+str _forEachIndex,getPosATL _x];
        _m setMarkerType "hd_dot";
        _mineMarkers pushBack _m;
    } forEach allMines;
    sleep 10;
    { deleteMarker _x} count _mineMarkers;
};

ITW_ObjArtillery = {
    // spawn on server
    scriptName "ITW_ObjArtillery";
    if (ITW_ParamArtillery == 0) exitWith {};
    
    private _artilleryParamSec = ITW_ParamArtillery * 60;
    private _showArtyInfo = [];
    
    private _etaTime           = 30; // how long mortar shell is in the air
    
    private _dropMaxCount      = 4;
    private _dropSpacingMin    = 2;
    private _dropSpacingAdd    = 1;
    
    private _volleyMaxCount    = ITW_ParamObjectivesPerZone + 1;
    private _volleySpacingMin  = 0; // time between each round in a volley: _etaTime + MIN + random ADD
    private _volleySpacingAdd  = 30;

    private _rechargeSpacingMin = _artilleryParamSec/2 - _etaTime; // time between artillery volleys: MIN + random ADD
    private _rechargeSpacingAdd = _volleySpacingMin + _artilleryParamSec; 
    
    private _accuracy = 180; // how close to the target a round will land
    private _friendlyDist = _accuracy + 80; // distance from target friendlies must not be
    #define A_VAR_DROP_TIME   0  // _artillery array indexes
    #define A_VAR_DROP_CNTR   1 
    #define A_VAR_DROP_MAX    2 
    #define A_VAR_VOLLEY_CNTR 3
    #define A_VAR_VOLLEY_MAX  4
    #define A_VAR_TARGET_POS  5
    private _artillery = [[time + _volleySpacingMin + random _volleySpacingAdd,0,ceil random _dropMaxCount,0,ceil random _volleyMaxCount,[]],
                          [time + _volleySpacingMin + random _volleySpacingAdd,0,ceil random _dropMaxCount,0,ceil random _volleyMaxCount,[]]]; 
    
    while {true} do {
        while {LV_PAUSE} do {sleep 5};
        private _sleep = 1e10;
        {
            if (ITW_ZoneIndex >= count ITW_Zones) exitWith {};
            private _arty = _x;
            private _dropTime  = _arty#A_VAR_DROP_TIME;
            if (time >= _dropTime) then {
                private _dropCnt = _arty#A_VAR_DROP_CNTR;
                private _dropMax = _arty#A_VAR_DROP_MAX;
                private _volleyCnt = _arty#A_VAR_VOLLEY_CNTR;
                private _volleyMax = _arty#A_VAR_VOLLEY_MAX;
                private _targetPos = _arty#A_VAR_TARGET_POS;
                
                if (_targetPos isEqualTo []) then {
                    // time to pick a target
                    // choose the target for the next shell to hit
                    private _isFriendly = _forEachIndex == 0;
                    private _targetObjIdx = selectRandom (ITW_Zones#ITW_ZoneIndex);
                    if (isNil "_targetObjIdx") exitWith {}; // skip this drop as we must be setting up or shutting down
                    private _objPos = ITW_Objectives#_targetObjIdx#ITW_OBJ_POS;
                    private _hitUnits = []; 
                    private _avoidUnits = [];
                    private _hitSide = if (_isFriendly) then {ITW_EnemySide} else {west}; 
                    private _avoidSide = if (_isFriendly) then {west} else {ITW_EnemySide};
                    {
                        switch (side _x) do {
                            case _hitSide: {if (_avoidSide knowsAbout _x > 0.105) then {_hitUnits pushBack _x}};
                            case _avoidSide: {_avoidUnits pushBack _x};
                        };
                    } forEach (_objPos nearEntities ["Land",ITW_ParamObjectiveSize+750]);
                    
                    private _target = objNull;
                    {
                        private _unit = _x;
                        private _okay = true;
                        {if (_unit distance _x < _friendlyDist) exitWith {_okay = false}} count _avoidUnits;
                        if (_okay) exitWith {_target = _unit};
                    } count (_hitUnits call BIS_fnc_arrayShuffle);
                    
                    _dropTime = time + _etaTime;
                    _arty set [A_VAR_DROP_TIME  ,_dropTime];
                    _arty set [A_VAR_TARGET_POS,if (isNull _target) then {[]} else {getPosATL _target}];
                } else {
                    // time to drop an artillery shell
                    private _posToFireAt = _targetPos getPos [random _accuracy, random 360];
                    _posToFireAt set [2,600];
                    private _shell = "Sh_82mm_AMOS" createVehicle _posToFireAt;
                    _shell setPosATL _posToFireAt;
                    _shell setVelocity [0,0,-50];  

                    // setup for next volley
                    _dropCnt = _dropCnt + 1;
                    if (_dropCnt < _dropMax) then {
                        _dropTime = time + _dropSpacingMin + random _dropSpacingAdd;
                        _arty set [A_VAR_DROP_TIME,_dropTime];
                        _arty set [A_VAR_DROP_CNTR,_dropCnt]; 
                    } else {
                        // drops complete
                        _volleyCnt = _volleyCnt + 1;
                        if (_volleyCnt < _volleyMax) then {
                            // volleys NOT complete
                            _dropTime = time + _volleySpacingMin + random _volleySpacingAdd;
                            _arty set [A_VAR_DROP_TIME  ,_dropTime];
                            _arty set [A_VAR_DROP_CNTR  ,0];
                            _arty set [A_VAR_VOLLEY_CNTR,_volleyCnt];
                            _arty set [A_VAR_TARGET_POS ,[]];                     
                        } else {
                            // volleys COMPLETE
                            _dropTime = time + _rechargeSpacingMin + random _rechargeSpacingAdd;
                            _arty set [A_VAR_DROP_TIME  ,_dropTime];
                            _arty set [A_VAR_DROP_CNTR  ,0]; 
                            _arty set [A_VAR_DROP_MAX   ,ceil random _dropMaxCount];
                            _arty set [A_VAR_VOLLEY_CNTR,0]; 
                            _arty set [A_VAR_VOLLEY_MAX ,ceil random _volleyMaxCount];
                            _arty set [A_VAR_TARGET_POS ,[]];                    
                        };
                    };
                    
                    if (ITW_ObjShowArty) then {
                        if (_showArtyInfo isEqualTo []) then {
                            _showArtyInfo = [[0,[]],[0,[]]];
                            for "_i" from 0 to 9 do {
                                private _mrkr = createMarkerLocal ["itwsarty"+str _i,[0,0,0]];
                                _mrkr setMarkerTypeLocal "hd_dot";
                                _mrkr setMarkerColorLocal "ColorBlue";
                                (_showArtyInfo#0#1) pushBack _mrkr;
                                _mrkr = createMarkerLocal ["itwsarty2"+str _i,[0,0,0]];
                                _mrkr setMarkerTypeLocal "hd_dot";
                                _mrkr setMarkerColorLocal "ColorRed";
                                (_showArtyInfo#1#1) pushBack _mrkr;
                            };
                        };
                        private _showInfo = _showArtyInfo#_forEachIndex;
                        private _index = _showInfo#0;
                        private _mrkr = _showInfo#1#_index;
                        _mrkr setMarkerPosLocal _posToFireAt;
                        _mrkr setMarkerTextLocal ([time,"MM:SS"] call BIS_fnc_secondsToString);
                        _index = _index + 1;
                        if (_index > 9) then {_index = 0};
                        _showInfo set [0,_index];
                        diag_log ["Arty Hit","side",_forEachIndex,_arty];
                    };
                };
            };
            private _nextDropIn = _dropTime - time;
            if (_nextDropIn < _sleep) then {_sleep = _nextDropIn};
        } forEach _artillery;
        sleep _sleep;      
    };
};
    
ITW_Statics = [];
ITW_ObjGenStatics = {
    params ["_objIds"];
    if (ITW_ParamStatics == 0) exitWith {ITW_Statics = []};
    if !(ITW_Statics isEqualTo []) then {
        private _statics = +ITW_Statics; // copy so we can change the original
        _statics spawn {
            private _statics = _this;
            while {!(_statics isEqualTo [])} do {
                {
                    private _static = _x;
                    private _deletable = true;
                    if (_deletable) then {
                        {
                            if (_x distance _static < 1000) exitWith {_deletable = false};
                        } forEach playableUnits;
                    };
                    if (_deletable) then {
                        {deleteVehicle _x} count crew _static;
                        deleteVehicle _static;
                    };
                } forEach _statics;
                sleep 10;
                _statics = _statics - [objNull];
            };           
        };
    };
    
    if (isNil "ITW_AoStaticTypes") then {
        ITW_AoStaticTypes = va_eStaticClasses;
        if (ITW_ParamStatics > 0) then {ITW_AoStaticTypes = ITW_AoStaticTypes + va_eMortarClasses};
        if (ITW_AoStaticTypes isEqualTo []) then {diag_log "ITW: ITW_AoGenStatics: no statics available to this faction"};
    };
    if (ITW_AoStaticTypes isEqualTo []) exitWith {};
    
    if (isNil "SKL_SmartStaticDefense") then {
        SKL_SmartStaticDefense = compileFinal preprocessFileLineNumbers "scripts\SKULL\SKL_SmartStaticDefence.sqf";
    };
    if (isNil "ITW_ADDED_BUILDING_BLACKLIST") then {ITW_ADDED_BUILDING_BLACKLIST = ["water"]};
    
    #define MAX_STATICS 9 // max statics in a 300m zone, levels will be 1/3, 2/3, or this amount depending on ITW_ParamStatics
    private _aoSize = ITW_ParamObjectiveSize;
    private _maxStatics = floor (MAX_STATICS * (abs ITW_ParamStatics)/3 * _aoSize / 300);
    private _statics = [];
    {
        private _aoCenter = ITW_Objectives#_x#ITW_OBJ_POS;
        private _isFriendly = _x call ITW_ObjContestedOwnerIsFriendly;
        private _placeSize = _aoSize - 50;
        private _loopCnt = 10;
        private _numStatics = 0;
        private _maxThisObj = floor (_maxStatics - 1 + random 2);      
        while {_numStatics < _maxThisObj && {_loopCnt > 0}} do {
            _loopCnt = _loopCnt - 1;
            private _vehTypeTxtr = selectRandom ITW_AoStaticTypes;
            private _type = if (typeName _vehTypeTxtr == "ARRAY") then {_vehTypeTxtr#0} else {_vehTypeTxtr};
            private _pos = [];
            private _isMortar = _vehTypeTxtr in va_eMortarClasses;
            private _maxLoops = 30;
            while {count _pos != 2 && {_maxLoops > 0}} do {
                _maxLoops = _maxLoops - 1;
                _pos = [_aoCenter, 0, _placeSize, _type call ITW_FncSizeOf, 0, 0.2, 0, ITW_ADDED_BUILDING_BLACKLIST] call BIS_fnc_findSafePos;
                private _road = roadAt _pos;
                if (!isNull _road) then {
                    // move the static off the road
                    getRoadInfo _road  params ["_mapType", "_width", "_isPedestrian", "_texture", "_textureEnd", "_material", "_begPos", "_endPos", "_isBridge"];
                    if (_isBridge) exitWith {_pos = []};
                    private _crossDir = (_begPos getDir _endPos) + (if (random 1 < 0.5) then {90} else {-90});
                    _pos = _pos getPos [_width,_crossDir];
                    if (_pos isFlatEmpty [3, -1, 0.8, 2, 0, false, objNull] isEqualTo []) then {_pos = []};
                };
                if (_isMortar && {count _pos == 2 && {!(_pos call ITW_ObjClearSkyCode)}}) then  {_pos = []};
            };
            if (count _pos == 2) then {
                _numStatics = _numStatics + 1;
                _pos pushBack 0.2;
                private _static = [_vehTypeTxtr,_pos] call ITW_VehCreateVehicle;
                _static allowDamage false;
                _static setDir (_aoCenter getDir _pos);
                _static setPosATL _pos; 
                _static setVectorUp surfaceNormal getPosASL _static;
                [_static,_isFriendly] call ITW_AtkAddCrewToStatic;
                [_static] call SKL_SmartStaticDefense;
                _statics pushBack _static;
                ITW_Statics pushBack _static;
                sleep 0.2;              
            };             
        };
        diag_log format ["ITW: Added %1 statics to %2",_numStatics,ITW_Objectives#_x#ITW_OBJ_NAME];
    } forEach _objIds;
    if !(_statics isEqualTo []) then { { _x addCuratorEditableObjects [_statics, true]; } forEach allCurators };
    sleep 2;
    {_x allowDamage true} forEach ITW_Statics;
};

ITW_ObjClearSkyCode = {
    private _pos = +_this;
    _pos set [2,1];
    private _beg = ATLToASL _pos;
    _pos set [2,20];
    private _end = ATLToASL _pos;
    // _ix will be an array of [intersectPosASL, surfaceNormal, intersectObj, parentObject] or empty array
    private _ix = lineIntersectsSurfaces [_beg,_end,objNull,objNull,true,1,"VIEW","NONE"];
    _ix isEqualTo []
};

ITW_ObjLoad = {
    params ["_objectives","_zoneIndex","_captured"];
    ITW_ObjContestedState = _captured;
    ITW_Objectives = _objectives;
    ITW_ZoneIndex = _zoneIndex;
    false call ITW_ObjGetZones;
    publicVariable "ITW_Objectives";
    publicVariable "ITW_ZoneIndex"; 
    true call ITW_ObjectivesSetup;
};


["ITW_ObjCenter"] call SKL_fnc_CompileFinal;
["ITW_ObjClosestOwnedAirport"] call SKL_fnc_CompileFinal;
["ITW_ObjCreateNearestBasesMap"] call SKL_fnc_CompileFinal;
["ITW_ObjectivesSetup"] call SKL_fnc_CompileFinal;
["ITW_ObjFailure"] call SKL_fnc_CompileFinal;
["ITW_ObjFlag"] call SKL_fnc_CompileFinal;
["ITW_ObjFlagHud"] call SKL_fnc_CompileFinal;
["ITW_ObjFlagTask"] call SKL_fnc_CompileFinal;
["ITW_ObjGenStructures"] call SKL_fnc_CompileFinal;
["ITW_ObjGetBase"] call SKL_fnc_CompileFinal;
["ITW_ObjGetContestedObjs"] call SKL_fnc_CompileFinal;
["ITW_ObjGetNearest"] call SKL_fnc_CompileFinal;
["ITW_ObjGetNearestBase"] call SKL_fnc_CompileFinal;
["ITW_ObjGetObjectives"] call SKL_fnc_CompileFinal;
["ITW_ObjGetPlayerSpawnPtDir"] call SKL_fnc_CompileFinal;
["ITW_ObjGetZones"] call SKL_fnc_CompileFinal;
["ITW_ObjLoad"] call SKL_fnc_CompileFinal;
["ITW_ObjNearestBuildings"] call SKL_fnc_CompileFinal;
["ITW_ObjNext"] call SKL_fnc_CompileFinal;
["ITW_ObjOwnedAirports"] call SKL_fnc_CompileFinal;
["ITW_ObjOwnsAirport"] call SKL_fnc_CompileFinal;
["ITW_ObjSetMarker"] call SKL_fnc_CompileFinal;
["ITW_ObjSetVehicleSpawn"] call SKL_fnc_CompileFinal;
["ITW_ObjShowAttackVectors"] call SKL_fnc_CompileFinal;
["ITW_ObjIsNearestFriendly"] call SKL_fnc_CompileFinal;
["ITW_ObjFlagMP"] call SKL_fnc_CompileFinal;
["ITW_ObjContestedOwnerIsFriendly"] call SKL_fnc_CompileFinal;
["ITW_ObjRedOut"] call SKL_fnc_CompileFinal;
["ITW_ObjGetOutToSeaPos"] call SKL_fnc_CompileFinal;
["ITW_ObjGetAttackVectorFromPos"] call SKL_fnc_CompileFinal;
["ITW_ObjMinefields"] call SKL_fnc_CompileFinal;
["ITW_ObjShowMines"] call SKL_fnc_CompileFinal;
["ITW_ObjArtillery"] call SKL_fnc_CompileFinal;
["ITW_ObjPlayerSelection"] call SKL_fnc_CompileFinal;
["ITW_ObjPlayerSelectionMP"] call SKL_fnc_CompileFinal;
["ITW_ObjLandAtkAdjust"] call SKL_fnc_CompileFinal;
["ITW_ObjGenStatics"] call SKL_fnc_CompileFinal;
["ITW_ObjClearSkyCode"] call SKL_fnc_CompileFinal;
["ITW_ShowSeaPoints"] call SKL_fnc_CompileFinal;
