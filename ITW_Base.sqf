
#include "defines.hpp"

#define BASE_PLACARD "Land_Noticeboard_F"

ITW_Bases = []; // each Base will have [_center, _direction, _playerRespawnPt, _AiSpawnPt, _AiVehSpawnPt, _spawned] 
ITW_Garages = [];
ITW_BasesNotGenerated = [];
ITW_VehFTPoints = [];

ITW_CreateBases = {
    params ["_isSaveLoad"];
    if (_isSaveLoad) then {
        // if we only build the needed bases, it will improve performance
        private _basesToBuild = [0];
        private _zoneIndexStart = (ITW_ZoneIndex - 2) max 1;
        for "_z" from _zoneIndexStart to (count ITW_Zones - 1) do {
            private _zones = ITW_Zones#_z;
            {
                private _objIdx = _x;
                {    
                    _basesToBuild pushBackUnique _x;
                } forEach (ITW_Objectives#_objIdx#ITW_OBJ_ATTACKS);
            } forEach _zones;
        };
        
        {
            private _obj = _x;
            private _owner = _obj#ITW_OBJ_OWNER;
            private _baseIdx = _obj#ITW_OBJ_INDEX;
            if (_owner == ITW_OWNER_FRIENDLY) then {
                if (_baseIdx in _basesToBuild) then {
                    private _baseInfo = [_baseIdx,true] call ITW_BasePlace;
                    ITW_Bases set [_baseIdx,_baseInfo];
                } else {
                    ITW_BasesNotGenerated pushBack _baseIdx;
                };
            } else {
                private _baseInfo = ITW_Bases#_baseIdx;
                [_baseInfo#ITW_BASE_POS,_baseInfo#ITW_BASE_DIR,true] call ITW_BasePlaceGarage
            };
            false
        } count ITW_Objectives;
    } else {
        private _bases = [];
        private _objCnt = count ITW_Objectives;
        {
            [0,[format ["Setting up AO   %1 of %2",_forEachIndex+1,_objCnt],"BLACK OUT",0.001]] remoteExec ["cutText",0,false]; 
            private _obj = _x;
            private _objZone = _obj#ITW_OBJ_ZONEID;
            private _objPos  = _obj#ITW_OBJ_POS;
            private _objSize = ITW_ParamObjectiveSize;
            private _whitelist = [[_objPos,_objSize]];
            private _blacklist = ["water"];
            private _pos = [_whitelist,_blacklist,true] call ITW_BaseFindNewPos;
            _pos set [2,0];
            private _baseAngle = random 360;
            private _baseInfo = [_pos, _baseAngle,_pos,_pos,[_pos, _baseAngle,_forEachIndex > 0] call ITW_BasePlaceGarage,_pos,false];
            private _owner = _obj#ITW_OBJ_OWNER;
            if (_owner == ITW_OWNER_FRIENDLY) then {
                _baseInfo = [count ITW_Bases,false] call ITW_BasePlace;
            };
            _obj set [ITW_OBJ_INDEX,_forEachIndex];
            ITW_Bases pushBack _baseInfo;
            false
        } forEach ITW_Objectives;
        publicVariable "ITW_Bases";
    };
};

ITW_BaseEnsure = {
    // since some bases are not spawned in, calling this will make sure the give base is placed
    params ["_baseIdx"]; // can be supplied baseIndex or base itself
    if (!isServer) exitWith {_this remoteExec ["ITW_BaseEnsure",2]};
    private _generate = false;
    if (typeName _baseIdx == "ARRAY") then {_baseIdx = ITW_Bases find _baseIdx};
    if (_baseIdx < 0) then {_baseIdx = 0};
    isNil {
        if (_baseIdx in ITW_BasesNotGenerated) then {
            ITW_BasesNotGenerated = ITW_BasesNotGenerated - [_baseIdx];
            _generate = true;
        };
    };
    if (_generate) then {
        private _baseInfo = [_baseIdx,true] call ITW_BasePlace;
        ITW_Bases set [_baseIdx,_baseInfo];
    };
};

ITW_BaseNext = {
    params ["_baseIndex"];
    if (_baseIndex >= count ITW_Bases) exitWith {};
    private _baseInfo = ITW_Bases#_baseIndex;
    if (!(_baseInfo#ITW_BASE_SPAWNED)) then {
        // update the base, don't overwrite array so anyone holding the array gets the update
        private _updatedBaseInfo = [_baseIndex,false] call ITW_BasePlace;
        for "_i" from 0 to ITW_BASE_SPAWNED do {_baseInfo set [_i,_updatedBaseInfo#_i]};
        publicVariable "ITW_Bases";       
    };
};

ITW_BaseNearest = {
    params ["_pos",["_owner",ITW_OWNER_FRIENDLY],["_includeAirfield",false]];
    if (typeName _pos == "OBJECT" || {typeName _pos == "GROUP"}) then {_pos = getPosATL _pos};
    private _airbase = [];
    if (_includeAirfield && {ITW_AirfieldBase getVariable ["Deployed",false]}) then {
        private _airDir = (ITW_AirfieldPos getDir ITW_AirfieldBase) + 45;
        private _airPt = getPosATL ITW_AirfieldBase getPos [5,_airDir];
        _airbase = [[_airPt,_airDir-90,_airPt,_airPt]];
    
    };
    private _bases = (ITW_Objectives select {_x#ITW_OBJ_OWNER == _owner} apply {ITW_Bases#(_x#ITW_OBJ_INDEX)}) + _airbase;
    [_pos,_bases,ITW_BASE_POS] call ITW_FncClosest;
};

ITW_BaseGetCenterPt = {
    if (typeName _this == "ARRAY") exitWith {_this#ITW_BASE_POS};
    if (_this >= count ITW_Bases) exitWith {diag_log format
            ["Error pos: ITW_BaseGetCenterPt: invalid index %1 >= %2",
            _this,count ITW_Bases];[0,0,0]};
    ITW_Bases#_this#ITW_BASE_POS
};

ITW_BaseGetDir = {
    if (typeName _this == "ARRAY") exitWIth {_this#ITW_BASE_DIR};
    if (_this >= count ITW_Bases) exitWith {diag_log format 
            ["Error pos: ITW_BaseGetDir: invalid index %1 >= %2",
            _this,count ITW_Bases];0};
    ITW_Bases#_this#ITW_BASE_DIR
};
 
ITW_BaseGetPlayerSpawnPt = {
    if (typeName _this == "ARRAY") exitWIth {_this#ITW_BASE_P_SPAWN};
    if (_this >= count ITW_Bases) exitWith {diag_log format 
            ["Error pos: ITW_BaseGetPlayerSpawnPt: invalid index %1 >= %2",
            _this,count ITW_Bases];[0,0,0]};
    ITW_Bases#_this#ITW_BASE_P_SPAWN
};

ITW_BaseGetRepairPt = {
    if (typeName _this == "OBJECT" || {typeName _this == "ARRAY" && {typeName (_this#ITW_BASE_POS) == "SCALAR"}}) exitWith {
        private _pt = if (typeName _this == "OBJECT") then {getPosATL _this} else {_this};
        private _dist = worldSize;
        private _closestRepairPt = [0,0,0];
        {
            private _spwnPt = _x#ITW_BASE_REPAIR_PT;
            private _d = _pt distance2D _spwnPt;
            if (_d < _dist) then {
                _dist = _d;
                _closestRepairPt = _spwnPt;
            };
        } count ITW_Bases;
        _closestRepairPt
    };
    if (typeName _this == "ARRAY" && {typeName (_this#ITW_BASE_POS) == "ARRAY"}) exitWith {_this#ITW_BASE_REPAIR_PT};
    if (typeName _this == "SCALAR" && {_this < count ITW_Bases && {_this >= 0}}) exitWith {ITW_Bases#(floor _this)#ITW_BASE_REPAIR_PT};
    
    // error case
    diag_log format ["Error pos: ITW_BaseGetRepairPt: invalid index %1 >= %2",_this,count ITW_Bases];
    [0,0,0]
};
 
ITW_BaseVehFallbacks = {
    params ["_type",["_allowRetexture",true]];
    private _vehArray = 
        switch (toLowerAnsi worldName) do {
            case "gm_weferlingen_summer";
            case "gm_weferlingen_winter": {
                [["gm_gc_civ_mi2sr","gm_gc_civ_mi2r","gm_gc_civ_mi2p","gm_ge_adak_bo105m_vbh","gm_ge_pol_bo105m_vbh"],
                 ["gm_gc_civ_mi2sr","gm_gc_civ_mi2r","gm_gc_civ_mi2p","gm_ge_adak_bo105m_vbh","gm_ge_pol_bo105m_vbh"],
                 ["gm_ge_civ_typ247","gm_ge_civ_typ251"],
                 ["gm_ge_civ_typ247","gm_dk_army_typ253_cargo","gm_dk_army_u1300l_container"],
                 ["gm_ge_civ_typ247","gm_dk_army_typ253_cargo","gm_dk_army_u1300l_container"],
                 ["gm_ge_army_kat1_451_reammo_ols"],
                 ["gm_ge_army_u1300l_repair_ols"],
                 ["gm_ge_army_kat1_451_refuel_ols"],
                 ["gm_gc_army_uaz469_dshkm_ols"]];
            };
            case "stozec": { 
                [["AFMC_UH60"],
                 ["CSLA_Mi17"],
                 ["CSLA_AZU"],
                 ["AFMC_M923c","AFMC_M923o"],
                 ["FIA_BTR40_DSKM"],
                 ["AFMC_M923a"],
                 ["AFMC_M923r"],
                 ["AFMC_M923f"],
                 ["FIA_AZU_DSKM"]];
            };
            case "vn_the_bra";
            case "vn_khe_sanh";
            case "cam_lao_nam": {
                [["vn_i_air_uh1d_02_01"],
                 ["vn_i_air_ch47_03_01"],
                 ["vn_c_wheeled_m151_01","vn_c_wheeled_m151_02"],
                 ["vn_i_wheeled_m54_01","vn_i_wheeled_m54_02"],
                 ["vn_i_wheeled_m54_01","vn_i_wheeled_m54_02"],
                 ["vn_i_wheeled_m54_ammo"],
                 ["vn_i_wheeled_m54_repair"],
                 ["vn_i_wheeled_m54_fuel"],
                 ["vn_o_wheeled_btr40_mg_04_vcmf","vn_o_wheeled_btr40_mg_04_vcmf","vn_o_wheeled_btr40_mg_01_vcmf"]];
            };
            case "sefrouramal": {
                [["B_ION_Heli_Light_02_unarmed_lxWS"],
                 ["B_UN_Heli_Transport_02_lxWS"],
                 [["I_Tura_Offroad_armor_lxWS",["Beige",1]]],
                 ["B_ION_Truck_02_covered_lxWS"],
                 ["I_Tura_Offroad_armor_armed_lxWS"],
                 ["O_SFIA_Truck_02_Ammo_lxWS"],
                 ["O_SFIA_Truck_02_box_lxWS"],
                 ["O_SFIA_Truck_02_fuel_lxWS"],
                 ["I_Tura_Offroad_armor_armed_lxWS"]];
            };
            
        case "spex_utah_beach";
        case "spex_carentan";
        case "spe_mortain";
        case "spe_normandy": {
                [["SPE_OpelBlitz"],
                 ["SPE_OpelBlitz"],
                 ["SPE_OpelBlitz","SPE_FFI_OpelBlitz"],
                 ["SPE_OpelBlitz"],
                 ["SPE_FR_M3_Halftrack"],
                 ["SPE_FFI_OpelBlitz_Ammo"],
                 ["SPE_FFI_OpelBlitz_Repair"],
                 ["SPE_FFI_OpelBlitz_Fuel"],
                 ["SPE_FFI_SdKfz250_1"]];
            };
            default{
                [["B_Heli_Light_01_F"],
                 [["C_IDAP_Heli_Transport_02_F",["Dahoman",1]],["C_IDAP_Heli_Transport_02_F",["ION",1]]],
                 [["B_LSV_01_unarmed_F",["Black",1]]],
                 [["I_Truck_02_transport_F",["Orange",1]],["I_Truck_02_transport_F",["Blue",1]]],
                 [["I_Truck_02_transport_F",["Orange",1]],["I_Truck_02_transport_F",["Blue",1]]],
                 ["CUP_B_M939_AMMO_USA"],
                 ["CUP_C_Ural_Civ_01"],
                 ["C_Truck_02_fuel_F"],
                 [["O_G_Offroad_01_armed_F",["Green",1]]]];
            };
        };       
    private _result = 
        switch (_type) do {
            case "heliS":  {_vehArray#0};
            case "heliL":  {_vehArray#1};
            case "car":    {_vehArray#2};
            case "truck":  {_vehArray#3};
            case "rearm":  {_vehArray#4};
            case "repair": {_vehArray#5};
            case "refuel": {_vehArray#6};
            case "enemy":  {_vehArray#7};
            default {
                diag_log format ["Error pos: ITW_BaseVehFallbacks - invalid type %1",_type];
                _vehArray#3
            };
        };
    if (!_allowRetexture && {count _result > 0 && {typeName (_result#0) == "ARRAY"}}) then {
        _result = _result apply {_x#0};
    };
    _result
};

ITW_BaseVehicleSelector = {
    
    if (isNil "ITW_BASE_VEHS") then {
        
        // Transport Trucks large enough to carry a squad
        private _getTransportSeats = {
            private _vehClasses = _this;
            private _vehs = [];
            private _minSeats = ITW_ParamFriendlySquadSize + 1;// squad plus a driver 
            {
                private _vehClass = _x;
                if (typeName _vehClass == "Array") then {_vehClass = _vehClass#0};
                private _seats = [_vehClass,true] call BIS_fnc_crewCount;
                if (_seats > _minSeats) then {_vehs pushBack _x};
                false
            } count _vehClasses;
            _vehs
        };
        // Transport trucks with the most seats
        private _getTransportSeats = {
            private _vehClasses = _this;
            private _maxSeats = 0;
            {
                private _vehClass = _x;
                if (typeName _vehClass == "Array") then {_vehClass = _vehClass#0};
                private _seats = [_vehClass,true] call BIS_fnc_crewCount;
                if (_seats > _maxSeats) then {_maxSeats = _seats};
            } count _vehClasses;
            private _vehs = [];
            private _minSeats = (_maxSeats + 4)/2;// larger trucks
            {
                private _vehClass = _x;
                if (typeName _vehClass == "Array") then {_vehClass = _vehClass#0};
                private _seats = [_vehClass,true] call BIS_fnc_crewCount;
                if (_seats > _minSeats) then {_vehs pushBack _x};
                false
            } count _vehClasses;
            _vehs
        };
        // 4 or less wheeled cars
        private _getCar = {
            private _vehClasses = _this;
            private _vehs = [];
            {
                private _vehClass = _x;
                if (typeName _vehClass == "Array") then {_vehClass = _vehClass#0};
                private _wheels = count (configFile >> "cfgVehicles" >> _vehClass >> "Wheels");
                if (_wheels <= 4) then {_vehs pushBack _x};
                false
            } count _vehClasses;
            _vehs
        };
        
        private _cars = va_pCarClasses call _getCar;
        if (_cars isEqualTo []) then {_cars = va_pCarClasses};
        if (_cars isEqualTo []) then {_cars = va_pApcClasses};
        if (_cars isEqualTo []) then {_cars = va_pTankClasses};
        if (_cars isEqualTo []) then {_cars = va_cCarClasses};
        if (_cars isEqualTo []) then {_cars = va_eCarClasses call _getCar};
        if (_cars isEqualTo []) then {_cars = ["car"] call ITW_BaseVehFallbacks};
        
        private _trucks = va_pCarClassesDual call _getTransportSeats;
        if (_trucks isEqualTo []) then {_trucks = va_pCarClassesTransport call _getTransportSeats};
        if (_trucks isEqualTo []) then {_trucks = va_pCarClassesAttack call _getTransportSeats};
        if (_trucks isEqualTo []) then {_trucks = va_pCarClasses};
        if (_trucks isEqualTo []) then {_trucks = va_cCarClasses call _getTransportSeats};
        if (_trucks isEqualTo []) then {_trucks = va_cCarClasses};
        if (_trucks isEqualTo []) then {_trucks = va_eCarClassesTransport call _getTransportSeats};
        if (_trucks isEqualTo []) then {_trucks = va_eCarClasses};
        if (_trucks isEqualTo []) then {_trucks = ["truck"] call ITW_BaseVehFallbacks};
        
        private _tanks = va_pTankClasses;
        if (_tanks isEqualTo []) then {_tanks = va_pApcClasses};
        if (_tanks isEqualTo []) then {_tanks = va_pCarClassesAttack};
        if (_tanks isEqualTo []) then {_tanks = va_pCarClassesDual};
        if (_tanks isEqualTo []) then {_tanks = va_pCarClasses};
        if (_tanks isEqualTo []) then {_tanks = va_cCarClasses};
        if (_tanks isEqualTo []) then {_tanks = va_eTankClasses};
        if (_tanks isEqualTo []) then {_tanks = va_eApcClasses};
        if (_tanks isEqualTo []) then {_tanks = va_eCarClassesAttack};
        if (_tanks isEqualTo []) then {_tanks = va_eCarClassesDual};
        if (_tanks isEqualTo []) then {_tanks = va_eCarClasses};
        if (_tanks isEqualTo []) then {_tanks = _trucks};
        
        private _apcs = va_pApcClasses;
        if (_apcs isEqualTo []) then {_apcs = va_pTankClasses};
        if (_apcs isEqualTo []) then {_apcs = va_pCarClassesAttack};
        if (_apcs isEqualTo []) then {_apcs = va_pCarClassesDual};
        if (_apcs isEqualTo []) then {_apcs = va_cCarClasses};
        if (_apcs isEqualTo []) then {_apcs = va_eApcClasses};
        if (_apcs isEqualTo []) then {_apcs = va_eTankClasses};
        if (_apcs isEqualTo []) then {_apcs = va_eCarClassesAttack};
        if (_apcs isEqualTo []) then {_apcs = va_eCarClassesDual};
        if (_apcs isEqualTo []) then {_apcs = _trucks};
        
        private _repair = va_pRepairClasses;
        if (_repair isEqualTo []) then {_repair = va_cRepairClasses};
        if (_repair isEqualTo []) then {_repair = _trucks};
        
        private _fuel = va_pFuelClasses;
        if (_fuel isEqualTo []) then {_fuel = va_cFuelClasses};
        if (_fuel isEqualTo []) then {_fuel = _trucks};
        
        private _ammo = va_pAmmoClasses;
        if (_ammo isEqualTo []) then {_ammo = va_cAmmoClasses};
        if (_ammo isEqualTo []) then {_ammo = _trucks};
        
        // Helicopters
        private _getHeliTransportSeats = {
            private _vehClasses = _this;
            private _vehs = [];
            {
                private _vehClass = _x;
                if (typeName _vehClass == "Array") then {_vehClass = _vehClass#0};
                private _seats = [_vehClass,true] call BIS_fnc_crewCount;
                if (_seats >= 2) then {
                    // skip too big helis
                    private _model = getText (configFile >> "cfgVehicles" >> _vehClass >> "model");
                    if ({_x in _model} count ["cup_airvehicles_mi6","cup_airvehicles_mi8","cup_airvehicles_ch53"] == 0) then {
                        _vehs pushBack [_seats,_x];
                    };
                };
                false
            } count _vehClasses;
            _vehs sort true;
            _midPt = ceil (count _vehs / 2);
            [_vehs select [0,_midPt] apply {_x#1},_vehs select [_midPt,_midPt] apply {_x#1}]
        };
        
        (va_pHeliClasses call _getHeliTransportSeats) params ["_heliS","_heliL"];
        if (_heliS isEqualTo []) then {_heliS = va_pHeliClasses};
        if (_heliS isEqualTo []) then {_heliS = _cars + _trucks + _tanks + _apcs};
        if (_heliL isEqualTo []) then {_heliL = _heliS};
        ITW_LHeli = _heliL;
        ITW_SHeli = _heliS;
        
        // add some defaults for the garage
        if (va_pCarClasses isEqualTo [])  then {va_pAllVehicles = va_pAllVehicles + va_cCarClasses};
        if (va_pHeliClasses isEqualTo []) then {va_pAllVehicles = va_pAllVehicles + va_cHeliClasses};
        
        ITW_BASE_VEHS = [_heliL,_heliS,_cars,_trucks,_tanks,_apcs,_repair,_ammo,_fuel];
    };
    ITW_BASE_VEHS
};

ITW_BasePlace = {
    params ["_baseId","_placeGarage"];
    if (!isServer) exitWith { };
    
    private _baseInfo = ITW_Bases#_baseId;
    _baseInfo params ["_center","_angle","_playerSpawnPt","_aiSpawnPt","_garagePos","_repairPt","_spawned"];    
    _center set [2,0];
    
    private ['_pos','_veh','_grp','_unit','_idx','_mrkr','_elevation'];
    private _cobj = [];
    private _groups = [];
    private _nullGroup = grpNull;
    private _baseName = "base"+str _baseId;
    private _baseInfo = [_center,_angle]; // ITW_BASE_POS , ITW_BASE_DIR
    private _angle = -_angle;
    private _spawnPt = [0,0,1000];
    
    private _rotatePos = { 
        params ['_offset','_center','_angle'];
        private _vect = [_offset, _angle] call BIS_fnc_rotateVector2D;
        private _newPos = _center vectorAdd _vect;
        _newPos
    };
    
    private _size = 78.5;
    
    [_center,_size,["Land_PortableLight_double_F"]] remoteExec ["ITW_RemoveTerrainObjects",0,true];
    sleep 0.5; // let the objects get hidden so clients don't hide the base objects
    
    private _nearbyVehs = nearestObjects [_center,["Air","LandVehicle","Ship"],_size];
    {
        if (isTouchingGround _x && {count crew _x == 0}) then {
            deleteVehicle _x;
        };
    } count _nearbyVehs;
            
    // choose vehicles to spawn
    private _velSelection = [] call ITW_BaseVehicleSelector;
    _velSelection params ["_largeHelis","_smallHelis","_cars","_transportTrucks","_tanks","_apcs","_repairTrucks","_ammoTrucks","_fuelTrucks"];
    
    // _vehData: [_type, _relPos, _dir, _groupId]
    private _vaData = [
        ['Land_OfficeCabinet_02_F', [33.667,-26.9141,0.000696182], 91.1549, _nullGroup],
        ['Land_OfficeCabinet_02_F', [33.6509,-27.9619,0.000686646], 91.1527, _nullGroup],
        ['Land_OfficeCabinet_02_F', [33.6416,-29.0137,0.000652313], 91.152, _nullGroup],
        ['Land_OfficeCabinet_02_F', [33.6279,-30.0439,0.000656128], 91.1516, _nullGroup]
    ];
    private _lampData = [
        ['Land_LampStreet_02_F', [78.2095,10.8408,0.938072], 0, _nullGroup],
        ['Land_LampStreet_02_F', [69.3481,-28.6162,0.75729], 27.6192, _nullGroup],
        ['Land_PortableLight_double_F', [37.4404,28.2725,0.0532875], 357.666, _nullGroup],
        ['Land_PortableLight_double_F', [-1.92432,-42.6895,0.0211487], 192.33, _nullGroup],
        ['Land_PortableLight_double_F', [-22.5327,-38.5947,0.0424843], 193.451, _nullGroup],
        ['Land_PortableLight_double_F', [-7.60205,22.4756,0.0014534], 358.878, _nullGroup],
        ['Land_PortableLight_double_F', [-31.0508,21.1504,-0.00754166], 346.387, _nullGroup],
        ['Land_PortableLight_double_F', [17.6968,-31.874,-0.00309372], 236.34, _nullGroup],
        ['Land_PortableLight_double_F', [14.7441,15.6094,0.0259018], 267.635, _nullGroup],
        ['Land_PortableLight_double_F', [36,-36.5,0.0259018], 0, _nullGroup]
    ];
    private _repairPtData = [
        ['Land_HelipadSquare_F', [31.5835,14.373,0], 0, _nullGroup]
    ];
    private _objectData = [
        ['Land_BagBunker_Large_F', [34.6953,58.2725,0.0659084], 169.1, _nullGroup],
        ['Land_BagBunker_Large_F', [16.1558,-58.2725,0.0255108], 2.26789, _nullGroup],
        ['Land_Cargo20_military_green_F', [30.1558,-35.2002,0.0183926], 135.503, _nullGroup],
        ['Land_ToiletBox_F', [17.3994,-39.6748,0.00193024], 274.568, _nullGroup],
        ['Land_WaterTank_F', [44.9429,13.6348,0.00140381], 358.788, _nullGroup],
        ['Land_ToiletBox_F', [17.8755,-37.0117,0.0108318], 265.845, _nullGroup],
        ['Land_WaterTank_F', [44.9023,10.3799,0.00297356], 358.809, _nullGroup],
        ['Land_WaterBarrel_F', [12.9253,-32.7031,0.00352478], 189.706, _nullGroup],
        ['Land_Cargo20_military_green_F', [34.2891,-12.3018,0.0178719], 160.048, _nullGroup],
        ['Land_vn_b_tower_01', [-53.3271,12.1455,-0.0773239], 95.9647, _nullGroup],
        ['Land_PaperBox_closed_F', [15.7705,7.68555,0.0231838], 274.086, _nullGroup],
        ['Land_MetalBarrel_F', [13.0806,-33.7793,0.00384712], 297.289, _nullGroup],
        ['Land_BarrelEmpty_grey_F', [11.9243,-34.1855,0.00160217], 0.903153, _nullGroup],
        ['Land_BarrelTrash_grey_F', [12.6641,-34.2471,0.00161552], 8.61006, _nullGroup],
        ['Land_PaperBox_closed_F', [16.8662,10.458,0.0427647], 127.968, _nullGroup],
        ['Land_Pallets_stack_F', [15.6299,12.3457,0.0171623], 0.757417, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [23.5051,-40.8052,0.00143433], 358.407, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [32.3408,-37.4453,-0.000160217], 316.117, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [35.3315,-30.1914,0.00112915], 270.378, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [68.2915,-1.31738,0.0590534], 190.713, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [55.5972,-35.6318,0.0249348], 202.443, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [13.7588,-2.70215,0.0123138], 82.7248, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [12.6016,5.8457,0.0811157], 261.007, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [71.1069,-20.1855,0.0980263], 296.673, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [65.6372,-12.3857,0.010674], 200.82, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [68.0239,-27.9795,0.074099], 296.314, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [64.8271,-35.3789,0.038775], 299.095, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [76.1191,0.6875,0.022776], 285.583, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [76.9175,10.6426,0.083892], 274.565, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [77.8198,20.7871,0.063766], 271.567, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [70.8638,24.4844,0.0144196], 183.049, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [70.6489,11.3047,0.018511], 178.027, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [23.5093,-13.78,0.0105915], 36.9294, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [18.1138,-10.0225,0.0512791], 215.781, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [32.9189,-15.877,0.0088768], 158.666, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [40.9453,-12.4561,0.00282097], 337.515, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [25.0991,32.4922,0.0102253], 47.2322, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [8.32813,22.6689,0.00418091], 45.5862, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [32.6924,29.2803,0.0533352], 175.222, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [41.2827,30.1006,0.0186062], 354.457, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [47.7637,4.02344,0.00147438], 282.203, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [46.0796,-4.46875,0.00472832], 101.119, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [48.7671,12.9287,0.00192833], 93.8294, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [11.9453,14.8037,0.010554], 274.899, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [-5.13428,-43.6357,-0.00325584], 191.332, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [3.44873,-45.2373,0.010582], 10.3689, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [-17.6338,-41.5566,0.0172482], 10.1313, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [-26.269,-40.0479,0.0171375], 188.862, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [-37.9429,-33.1348,0.0136833], 95.4457, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [-37.1582,-24.5771,0.0266056], 274.281, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [15.1689,-37.3477,-0.00320625], 95.3228, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [15.9717,-28.6885,0.0311813], 274.115, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [-47.9077,-2.60156,0.00837898], 97.003, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [-46.9521,6.02637,0.0171146], 275.258, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [-42.9312,-13.7578,0.0493546], 38.433, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [-46.3389,14.9121,0.00836945], 273.895, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [-27.147,22.957,0.00238991], 0.883713, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [-35.7871,22.96,0.00592995], 179.768, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [-5.44824,24.5059,-0.00146675], 356.808, _nullGroup],
        ['Land_vn_concrete_smallwall_8m_f', [-14.0923,23.9199,0.00515938], 175.414, _nullGroup],
        [selectRandom _repairTrucks, [39.0,-2,   0.1], 218, _nullGroup],
        [selectRandom _ammoTrucks,   [28.5,-5.6, 0.1], 204, _nullGroup],
        [selectRandom _fuelTrucks,   [19.1,-1.1, 0.1], 335, _nullGroup]
    ];
    private _t1 = if (random 1 < 0.33) then {selectRandom _apcs} else {selectRandom _tanks};
    private _t2 = if (random 1 < 0.33) then {selectRandom _apcs} else {selectRandom _tanks};
    private _vehData = [
        [selectRandom _smallHelis, [-0.380859,-28.6143,0.0179024], 4.61953, _nullGroup],
        [selectRandom _smallHelis, [-19.7676,-26.6865,0.0719547], 12.1186, _nullGroup],
        [selectRandom _largeHelis, [-7.5542,6.48633,0.0370693], 358.471, _nullGroup],
        [selectRandom _largeHelis, [-30.5225,4.61621,0.0672569], 5.00935, _nullGroup],
        [_t1,                      [69.7642,17.7988,0.163095], 259.804, _nullGroup],
        [_t2,                      [68.8794,4.47363,0.155767], 278.018, _nullGroup],
        [selectRandom _cars, [62.1431,-17.6123,0.0293083], 294.167, _nullGroup],
        [selectRandom _transportTrucks, [59.8633,-24.0078,0.0403709], 294.167, _nullGroup],
        [selectRandom _transportTrucks, [56.9893,-30.3604,0.109091], 293.665, _nullGroup]
    ];
    
    private _menData = [];
    private _wayPointData = [];
    private _markerData = [
        [_baseName,[0,0,0],'Solid','colorBLUE',0,'ICON',[0.5,0.5],'loc_Frame',1]
    ];
    

    // Player spawn point
    _pos = ([[25.1812,-28.6465,0.0],_center,_angle] call _rotatePos);
    [west, _pos, _baseName] call BIS_fnc_addRespawnPosition;
    _baseInfo pushBack _pos; // ITW_BASE_P_SPAWN
    
    // move players to a safe pos in the base
    private _dangerSize = _size - 10;
    private _nearbyPlayers = (playableUnits + ITW_AI_UNITS) select {_x distance _center < _size && {(getPosATL vehicle _x)#2 < 2}};
    private _nearbyPlayerVehs = _nearbyPlayers select {vehicle _x != _x} apply {vehicle _x};
    _nearbyPlayers = _nearbyPlayers select {vehicle _x == _x};
    _nearbyPlayerVehs = _nearbyPlayerVehs arrayIntersect _nearbyPlayerVehs; // remove duplicates
    {
        _x setPosATL _pos;
    } forEach _nearbyPlayers;
    {
        private _vDir = (-_angle) + 180 + (_forEachIndex * 10);
        [_x,_vDir + 180] remoteExec ["setDir",_x];
        sleep 0.2;
        private _vPos = (_center getPos [_size - 10,_vDir]);
        _vPos set [2,2];
        _x setPosATL _vPos;
    } forEach _nearbyPlayerVehs;
    
    
    // AI spawn point
    _aiSpawnPt = [_center, 90, 120, 4, 0, 20, 0] call BIS_fnc_findSafePos;
    if (count _aiSpawnPt == 3) then {
        _aiSpawnPt = _center getPos [95, random 360];
    } else {
        _aiSpawnPt pushBack 0;
    };
    _baseInfo pushBack _aiSpawnPt; // ITW_BASE_A_SPAWN
    [_aiSpawnPt,20] remoteExec ["ITW_RemoveTerrainObjects",0,true];
    
    //["CamoNet_INDP_open_Curator_F",_aiSpawnPt,random 360] call ITW_BaseSimpleObject;
  
    //if (isNil "BILLBOARD") then {
    //    _pos = ([[29,-34,0.0],_center,_angle] call _rotatePos);
    //    _pos set [2,-0.6];
    //    _veh = "Land_Billboard_02_blank_F" createVehicle _spawnPt;
    //    _veh setDir (135 - _angle);      
    //    _veh setPosATL _pos;
    //    _veh setObjectTextureGlobal [0, "images\BaseLayout.jpg"];
    //    BILLBOARD = _veh;
    //} else {
    //    _pos = ([[29,-34,0.0],_center,_angle] call _rotatePos);
    //    _pos set [2,-0.6];
    //    BILLBOARD setDir (135 - _angle);      
    //    BILLBOARD setPosATL _pos;
    //};
    
    // Duty Officer
    if (isNil "ITW_BaseOfficerTypes") then {
        private _unitTypes = [ITW_PlayerFaction,["Rifleman"],false,call FACTION_UNIT_FALLBACK_SUBF_BLU] call FactionUnits;
        private _leaders = (_unitTypes select {"officer" in _x || "_SL" in _x});
        if !(_leaders isEqualTo []) then {_unitTypes = _leaders};
        ITW_BaseOfficerTypes = _unitTypes;
    };
    _pos = ([[17.5,-27.6,0.0],_center,_angle] call _rotatePos);
    _veh = selectRandom ITW_BaseOfficerTypes createVehicle _spawnPt;
    _veh setDir (90 - _angle);
    _veh setPosATL _pos;
    [_veh] call ITW_BaseOfficerSetup;    
    
    // Mechanic
    if (isNil "ITW_BaseMechanicTypes") then {
        private _unitTypes = [ITW_PlayerFaction,["Sapper"],false,call FACTION_UNIT_FALLBACK_SUBF_BLU] call FactionUnits;
        ITW_BaseMechanicTypes = _unitTypes;
    };   
    _pos = ([[30.0,0.6,0.0],_center,_angle] call _rotatePos);
    _veh = selectRandom ITW_BaseMechanicTypes createVehicle _spawnPt;
    _veh setDir (5 - _angle);
    _veh setPosATL _pos;
    [_veh] call ITW_BaseMechanicSetup;
    
    _pos = ([[17.3,-27.6,1.0],_center,_angle] call _rotatePos);
    ["Land_MapBoard_01_Wall_F",_pos,90 - _angle] call ITW_BaseSimpleObject;
    
    // Garages
    if (_placeGarage) then {
        // we only need to place the garage on loading saved games
        [_baseInfo#0,_baseInfo#1,false] call ITW_BasePlaceGarage;
    };
    _baseInfo pushBack _garagePos; // ITW_BASE_GARAGE_POS
   
    //// Rest of base ////
    // aresnals
    private _va = [];
    {
        _x params ['_type','_relPos','_dir','_groupId'];
        _pos = [_relPos,_center,_angle] call _rotatePos;
        _veh = _type createVehicle _spawnPt;
        _veh setDir (_dir - _angle);
        _veh setPosATL _pos;
        _va pushBack _veh;
        _veh enableSimulationGlobal false;
    } count _vaData;
    [_va] remoteExec ["CustomArsenal_AddVAs",0,true];
    [_va] remoteExec ["ITW_BaseVaActions",0,true];
    // lamps
    {
        _x params ['_type','_relPos','_dir','_groupId'];
        _pos = [_relPos,_center,_angle] call _rotatePos;
        _veh = _type createVehicle _spawnPt;
        _veh allowDamage false;
        _veh setDir (_dir - _angle);
        _veh setPosATL _pos;
    } count _lampData;
    // repair pt
    {
        _x params ['_type','_relPos','_dir','_groupId'];
        _pos = [_relPos,_center,_angle] call _rotatePos;
        _elevation = [_pos,_dir - _angle] call ITW_BasePlatformWide;
        _pos set [2,_elevation];
        _veh = [_pos,"square",_dir - _angle] call ITW_fnc_HelipadObject;
        [_pos,25] call ITW_vehRepairPoint;
        false
    } count _repairPtData;
    _baseInfo pushBack _pos; // ITW_BASE_REPAIR_PT
    // objects
    {
        _x params ['_type','_relPos','_dir','_groupId'];
        _pos = [_relPos,_center,_angle] call _rotatePos;
        [_type,_pos,_dir - _angle] call ITW_BaseSimpleObject;
        false
    } count _objectData;
    // vehicles
    _vehSpawnInfo = [];
    {
        _x params ['_type','_relPos','_dir','_groupId'];
        _pos = [_relPos,_center,_angle] call _rotatePos;
        _dir = _dir - _angle;
        private _typeStr = if (typeName _type isEqualTo "ARRAY") then {_type#0} else {_type};
        if (_typeStr isKindOf "Air") then {
            _elevation = [_pos,_dir] call ITW_BasePlatform;
            _pos set [2,_elevation];
            _dir = [[sin _dir, cos _dir, 0], [0,0,1]];
        };      
        _vehSpawnInfo pushBack [_type,_pos,_dir,1,true];
        false
    } count _vehData;
    // men
    {
        _x params ['_type','_relPos','_dir','_groupId'];
        private _pos = [_relPos,_center,_angle] call _rotatePos;
        BASE_UNIT = nil;
        _type createUnit [_pos, _groupId, "BASE_UNIT = this"];
        waitUntil {!isNil "BASE_UNIT"};
        private _unit = BASE_UNIT;
        BASE_UNIT = nil;
        _unit setFormDir (_dir - _angle);
        _unit setDir (_dir - _angle);
        _unit setPosATL _pos;
        _unit doMove _pos;
        _cobj = _cobj + [_unit];
    } count _menData;

    {
        _x params ['_groupid','_wpArray'];
        if (count _wpArray > 1) then {
            {
                _x params ['_relPos', '_completeR', '_behavior', '_combatMode', '_formation', '_speed', '_wpType', '_timeout'];
                private _pos = [_relPos,_center,_angle] call _rotatePos;
                private _idx = _groupid addWaypoint [_pos,_completeR];
                _idx setWaypointBehaviour _behavior;
                _idx setWaypointCombatMode _combatMode;
                _idx setWaypointFormation _formation;
                _idx setWaypointSpeed _speed;
                _idx setWaypointType _wpType;
                _idx setWaypointTimeout _timeout;
            } count _wpArray;
        } else {
            {doStop _x} count units _groupId;
        };
        _groups pushBack _groupid;
        false
    } count _wayPointData;
    // markers
    {
        _x params ['_name', '_relPos', '_brush', '_color', '_dir', '_shape', '_size', '_type', '_alpha'];
        private _pos = [_relPos,_center,_angle] call _rotatePos;
        private _mrkr = createMarkerLocal [_name,_pos];
        _mrkr setMarkerBrushLocal _brush;
        _mrkr setMarkerColorLocal _color;
        _mrkr setMarkerDirLocal _dir;
        _mrkr setMarkerShapeLocal _shape;
        _mrkr setMarkerSizeLocal _size;
        _mrkr setMarkerTypeLocal _type;
        _mrkr setMarkerAlpha _alpha;
    } count _markerData;
    
    { _x addCuratorEditableObjects [_cobj, true] } count allCurators;
    
    // delay the spawning in of vehicles a short amount
    _vehSpawnInfo spawn {
        scriptName "ITW_VehSpawner";
        sleep 5;
        {_x call ITW_VehSpawn; false} count _this;
    };
    _baseInfo pushBack true; // ITW_BASE_SPAWNED
    
    _baseInfo
};

ITW_BasePlaceGarage = {
    params ["_center","_angle",["_addBoard",false]];
    
    private _rotatePos = { 
        params ['_offset','_center','_angle'];
        private _vect = [_offset, _angle] call BIS_fnc_rotateVector2D;
        private _newPos = _center vectorAdd _vect;
        _newPos
    };
    
    _center set [2,0];
    _angle = -_angle;
    
    private _dir = 0; // garage needs to be at zero direction since the garage function places objects at dir 0
    private _pos = ([[38.0,-51.0,0.0],_center,_angle] call _rotatePos);
    private _elevation = [_pos,_dir] call ITW_BasePlatform;
    _pos set [2,_elevation];
    
    private _board = objNull;
    if (_addBoard) then {
        private _bpos = _pos getPos [8, _dir + 90];
        _board = createVehicle [ITW_BASE_PLACARD,_bpos];
        _board setPosATL _bpos;
        _board setDir (_dir - 90);
        _board enableSimulationGlobal false;
        _board allowDamage false;

        // add the repair point
        private _flag = ([_pos,ITW_OWNER_UNDEFINDED] call ITW_ObjGetNearest)#ITW_OBJ_FLAG;
        private _repairInfo = [_pos,25,{_this getVariable ['ITW_FlagIsPlayer',false] && {_this getVariable ['ITW_FlagPhase',0] > 0.98}},_flag];
        _repairInfo call ITW_vehRepairPoint;
        _board setVariable ["itwrepair",_repairInfo];
        
        // add a map marker for the garage location 
        private _mrkr = createMarkerLocal [GARAGE_MARKER_NAME(_flag),_pos];
        _mrkr setMarkerTypeLocal "loc_car";
        _mrkr setMarkerColorLocal "ColorGrey"; 
        _mrkr setMarkerAlpha 0;
        
        [_pos,25,[ITW_BASE_PLACARD,FLAG_TYPE]] remoteExec ["ITW_RemoveTerrainObjects",0,true];
    };
    [_pos,_board] remoteExec ["ITW_BaseAddGarageMP",0,true];
    
    _pos
};

ITW_BaseSimpleObject = {
    params ["_type","_pos","_dir"];
    // vehicles need to settle to the ground
    private _texture = false;
    private _anim = false;
    if (typeName _type == "ARRAY") then {
        _texture = _type#1;
        if (count _type > 2) then {_anim = _type#2};
        _type = _type#0;
    };
    private _settle = _type isKindOf "LandVehicle";
    if (_settle) then {
        _pos set [2,_pos#2+1];
        private _veh = _type createVehicleLocal _pos;
        [_veh,_texture,_anim] call BIS_fnc_initVehicle;
        _veh allowDamage false;
        _veh setDir _dir;
        _veh setVectorUp surfaceNormal _pos;
        _veh setPosATL _pos;
        private _makeSimple = {
            params ["_veh"];
            // set the vehicle upright
            private _up = surfaceNormal getPosATL _veh; 
            if ((_up vectorCos (vectorUp _veh)) < 0.8) then {              
                _veh setVectorUp _up;
            };
            // gm vehicles get an error if I convert them immediately, so wait a moment
            //_veh enableSimulation false;
            sleep 2;
            //_veh enableSimulation true;
            [_veh] call BIS_fnc_replaceWithSimpleObject;
        };
        [[_veh],_makeSimple,8] call ITW_FncDelayCall;
    } else {
        private _simpleObj = createSimpleObject [_type,ATLToASL _pos];
        private _simpleVect = [[sin _dir,cos _dir,0], surfaceNormal _pos];
        [_simpleObj,_simpleVect] remoteExec ["setVectorDirAndUp",0];
    };
};

ITW_BaseAddMP = {
    // call on all clients
    ITW_Bases pushBack _this;
};

ITW_BaseAddGarageMP = {
    // call on all clients
    params ["_pos","_board"];
    ITW_Garages pushBack _pos;
    waitUntil {!isNil "ITW_ParamVirtualGarage"};
    if (isNull _board) then {ITW_VehFTPoints pushBack _pos};
    if (ITW_ParamVirtualGarage > 0 && {!isNull _board}) then {
        _lightPos = getPosATL _board;
        _lightPos set [2,2];
        private _light = "#lightpoint" createVehicleLocal _lightPos;
        _light setLightIntensity 500;
        _light setLightAmbient [0,0,0]; 
        _light setLightColor [0.3,0.3,0.3];
        _light lightAttachObject [_board,[0,0,2]];
        _board addAction ["Open Garage",{
                params ["_board", "_player", "_actionId", "_arguments"];
                private _flag = ([getPosATL _board] call ITW_ObjGetNearest)#ITW_OBJ_FLAG;
                if (flagTexture _flag isEqualTo 'a3\data_f\flags\flag_blue_co.paa' && {flagAnimationPhase _flag > 0.99}) then {
                    [_board,false] call ITW_BaseOpenGarage;
                } else {
                    hint "Flag is not captured";
                };
            },nil,10,true,true,"","true",6];
        _board addAction ["Fast travel to flag",{
            params ["_board", "_player", "_actionId", "_arguments"];
            private _flag = ([getPosATL _board] call ITW_ObjGetNearest)#ITW_OBJ_FLAG;
            if (flagTexture _flag isEqualTo 'a3\data_f\flags\flag_blue_co.paa' && {flagAnimationPhase _flag > 0.9}) then {
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
                private _pos = getPosATL _flag;
                _player allowDamage false;
                _player setDir 0;
                _pos = _pos getPos [2,180];
                _pos set [2,0.2];
                _player setPosATL _pos;
                _bringUnits apply {_x setPosASL _pos};
                _player allowDamage true;
            } else {
                hint "Flag is not captured";
            };
        },nil,10,true,true,"","vehicle _this == _this",6];
    };
};

ITW_BaseMechanicSetup = {
    params ["_mechanic"];
    _mechanic allowDamage false;
    removeAllWeapons _mechanic;
    removeBackpack _mechanic;
    _mechanic forceAddUniform "U_C_WorkerCoveralls";
    {_mechanic removeMagazines _x} count magazines _mechanic;
    [_mechanic, "AidlPercMstpSnonWnonDnon_AI"] remoteExec ["switchMove",0,true];
    private _nvgs = [_mechanic] call ITW_FncGetNVGs;
    {_mechanic unassignItem _x} count _nvgs; 
    if (selectMax ( (configProperties [configFile >> "cfgWeapons" >> (headgear _mechanic) >> "ItemInfo" >> "HitpointsProtectionInfo","true",true]) apply {getNumber(_x>>"armor")}) > 2) then {removeHeadgear _mechanic}; 
    [_mechanic] remoteExec ["ITW_BaseMechanicActions",0,true];
    _mechanic spawn {sleep 10; _this enableSimulationGlobal false}; // clients weren't getting uniform update
    _mechanic disableAI "all";
};

ITW_BaseMechanicActions = {
    // call on all clients to add actions
    if (!hasInterface) exitWith {};
    params ["_mechanic"];
    waitUntil {!isNil "ITW_ParamFriendlyAiCntAdjustment"};

    private _pos = getPosATL _mechanic getPos [1,getDir _mechanic];
    _pos set [2,0.5];
    private _light = "#lightpoint" createVehicleLocal _pos;
    _light setLightIntensity  1500;
    _light setLightAmbient [0,0,0]; 
    _light setLightColor [0.3,0.3,0.3];
           
    _mechanic addAction ["<t color='#aaaadd'>Store vehicle</t>", {
            params ["_mechanic", "_player", "_actionId", "_arguments"];
            // have server get closest repair point, and closest vehicle, then store and remove it
            private _pos = _mechanic call ITW_BaseGetRepairPt;        
            private _allVehicles = vehicles select {count crew _x == 0 && {!isSimpleObject  _x && {(_x isKindOf "Air" || _x isKindOf "Land") && {alive _x && {speed _x < 1}}}}};
            private _closestVeh = objNull;
            _minDist = 1e5;
            {
                private _dist = _x distance _pos;    
                if (_dist < _minDist) then {
                    _closestVeh = _x;
                    _minDist = _dist;
                };
            } count _allVehicles;
            if !(isNull _closestVeh) then {
                private _vehName = getText ((configOf _closestVeh) >> "DisplayName");
                ITW_YesNoMenu1Answer = false;
                ITW_YesNoMenu1 = [
                    [format ["Store %1",_vehName], true],
                    ["Yes", [], "", -5, [["expression","ITW_YesNoMenu1Answer = true"]], "1", "1"],
                    ["No",  [], "", -5, [["expression", "hint 'Operation canceled'"]], "1", "1"]
                ];
                showCommandingMenu "#USER:ITW_YesNoMenu1";
                waitUntil {!(commandingMenu isEqualTo "")};
                waitUntil {commandingMenu isEqualTo ""};   
                if (ITW_YesNoMenu1Answer) then {
                    hint 'Vehicle stored';
                    ITW_StoredVehicles pushBack typeOf _closestVeh;
                    deleteVehicle _closestVeh;
                };
            } else {
                hint "no vehicle found on repair pad";
            };
        },nil,10,false,true,"","ITW_ParamVirtualGarage > 0",3];
    _mechanic addAction ["<t color='#aaaadd'>Retrieve vehicle</t>",{
            params ["_mechanic", "_player", "_actionId", "_arguments"];
            if (count ITW_StoredVehicles == 0) exitWith {hint "No stored vehicles"};
            private _mechanicPos = getPosATL _mechanic;
            private _mechanicDir = getDir _mechanic;
            private _header = [["Retrieve vehicle", true]];
            ITW_RetriveVehMenu = +_header;
            private _idx = 2;
            private _menuId = 1;
            ITW_RetriveVeh = objNull;
            {
                private _vehType = _x;
                if (_idx > 10) then {
                    ITW_RetriveVehMenu pushBack ["MORE",[_idx], format ["#USER:ITW_RetriveVehMenu_%1",_menuId+1], -4, [["expression",""]], "1", "1"];
                    ITW_RetriveVehMenu pushBack ["BACK",[16], "", -4, [["expression",""]], "1", "1"];
                    call compile format ["ITW_RetriveVehMenu_%1 = +ITW_RetriveVehMenu",_menuId];
                    _menuId = _menuId + 1;
                    _idx = 2;
                    ITW_RetriveVehMenu = +_header;
                };
                private _vehName = getText (configFile >> "CfgVehicles" >> _vehType >> "DisplayName");
                ITW_RetriveVehMenu pushBack [_vehName,  [_idx], "", -5, [["expression", format ["['%1',%2,%3] spawn ITW_RetrieveVeh",_vehType,_mechanicPos,_mechanicDir]]], "1", "1"];
                _idx = _idx + 1;
            } count ITW_StoredVehicles;
            ITW_RetriveVehMenu pushBack ["BACK",[16], "", -4, [["expression",""]], "1", "1"];
            call compile format ["ITW_RetriveVehMenu_%1 = +ITW_RetriveVehMenu",_menuId];
            showCommandingMenu "#USER:ITW_RetriveVehMenu_1";
        },nil,10,false,true,"","true",3];
    _mechanic addAction ["<t color='#aaaadd'>Request airfield construction container</t>",{
            params ["_mechanic", "_player", "_actionId", "_arguments"];
            if (allAirports#0 isEqualTo []) exitWith {
                cutText ["<t size='3'>No airports found on this map.</t>", "PLAIN", -1, true, true];
            };
            private _pos = _mechanic call ITW_BaseGetRepairPt;
            [_pos] remoteExec ["ITW_AirfieldSpawnCrate",2]; 
        },nil,10,false,true,"","isNull ITW_AirfieldBase",3];  
    _mechanic addAction ["<t color='#aaaadd'>Recall airfield container</t>",{ 
            if (player == leader player) then {
                ITW_YesNoMenu2 = [
                    ["Recall airfield container", true],
                    ["No",  [], "", -5, [["expression", "hint 'Operation canceled'"]], "1", "1"],
                    ["Yes, this may remove the airfield garage", [], "", -5, [["expression", 
                        "hint 'Airfield container recalled';
                        call ITW_AirfieldDelete;"
                    ]], "1", "1"]
                ];
                showCommandingMenu "#USER:ITW_YesNoMenu2";
            } else {
                hint "Only squad leader can destroy the airfield container";
            };
        },nil,10,false,true,"","!isNull ITW_AirfieldBase",3]; 
};
          
ITW_RetrieveVeh = {
    params ["_vehType","_mechanicPos","_mechanicDir"];
    private _closestRepair = _mechanicPos call ITW_BaseGetRepairPt;        
    private _nearbyVehs = nearestObjects [_closestRepair,["Air","LandVehicle","Ship","Box_Cargo_Sand_RF"],12];
    {
        if (!alive _x) then {
            deleteVehicle _x;
            _nearbyVehs deleteAt _forEachIndex;
            sleep 0.5;
        };
    } forEachReversed _nearbyVehs;
    private _nearestVeh = if (count _nearbyVehs > 0) then {_nearbyVehs#0} else {objNull};
    if (_nearestVeh distance _closestRepair > 10) then {
        private _veh = _vehType createVehicle _closestRepair;
        _veh allowDamage false;
        _veh setDir (_mechanicDir - 60);
        _veh setPos _closestRepair;
        _index = ITW_StoredVehicles find _vehType;
        if (_index >= 0) then {
            ITW_StoredVehicles deleteAt _index;
        };
        sleep 5;
        _veh allowDamage true;
    } else {
        playSoundUI ["A3\UI_F\data\Sound\CfgNotifications\addItemFailed.wss"];
        hint "Spawn location is blocked";
    };
};

ITW_BaseOfficerSetup = {
    params ["_officer"];
    _officer allowDamage false;
    removeAllWeapons _officer;
    removeBackpack _officer;
    {_officer removeMagazines _x} count magazines _officer;
    [_officer, "AidlPercMstpSnonWnonDnon_AI"] remoteExec ["switchMove",0,true];
    private _nvgs = [_officer] call ITW_FncGetNVGs;
    {_officer unassignItem _x} count _nvgs; 
    [_officer] remoteExec ["ITW_BaseOfficerActions",0,true];
    _officer enableSimulationGlobal false;
    _officer disableAI "all";
};

ITW_BaseOfficerActions = {
    // call on all clients to add actions
    if (!hasInterface) exitWith {};
    params ["_officer"];
    waitUntil {!isNil "ITW_ParamFriendlyAiCntAdjustment"};

    private _pos = getPosATL _officer getPos [1,getDir _officer];
    _pos set [2,0.5];
    private _light = "#lightpoint" createVehicleLocal _pos;
    _light setLightIntensity  3000;
    _light setLightAmbient [0,0,0]; 
    _light setLightColor [0.3,0.3,0.3];
           
    _officer addAction ["<t color='#ffffcc'>Open garage</t>", {
        params ["_officer", "_player", "_actionId", "_arguments"];
        [_officer,true] call ITW_BaseOpenGarage;
        },nil,10,true,true,"","ITW_ParamVirtualGarage > 0",3];
    _officer addAction ["<t color='#ffffcc'>Fast travel</t>",{
            params ["_officer", "_player", "_actionId", "_arguments"];
            [] spawn ITW_RadioFastTravel;
        },nil,10,false,true,"","vehicle _this == _this",3];
    _officer addAction ["<t color='#ffffcc'>Choose role</t>",{
            params ["_officer", "_player", "_actionId", "_arguments"];
            call ITW_BaseShowRoleMenu;
        },nil,10,true,true,"","true",3];     
    _officer addAction ["<t color='#ffffcc'>Set view distance</t>",{
            params ["_officer", "_player", "_actionId", "_arguments"];
            showCommandingMenu "#USER:ITW_VIEW_DIST_MENU";
        },nil,10,false,true,"","true",3];

    _officer addAction ["<t color='#ffff00'>-- Player Squad Options --</t>",{},nil,10,false,false,"","true",3];
    _officer addAction ["<t color='#ffffcc'>Request squad leader role</t>",{
            params ["_officer", "_player", "_actionId", "_arguments"];
            [_player] spawn ITW_RadioLeaderRequest;
        },nil,10,false,true,"","player != leader player",3];
    _officer addAction ["<t color='#ffffcc'>Split into new squad</t>",{
            params ["_officer", "_player", "_actionId", "_arguments"];
            isNil {[_player] joinSilent createGroup (side player)};
        },nil,10,false,true,"","player != leader player",3];
    _officer addAction ["<t color='#ffffcc'>Join other squad</t>",{
            params ["_officer", "_player", "_actionId", "_arguments"];
            [] spawn ITW_RadioSquadJoin;
        },nil,10,false,true,"","player != leader player && {{group _x != group player} count (call BIS_fnc_listPlayers) > 0}",3];
    _officer addAction ["<t color='#ffffcc'>Merge into another squad</t>",{
            params ["_officer", "_player", "_actionId", "_arguments"];
            [] spawn ITW_RadioSquadMerge;
        },nil,10,false,true,"","player == leader player && {{group _x != group player} count (call BIS_fnc_listPlayers) > 0}",3];
    _officer addAction ["<t color='#ffffcc'>Recruit ai squad mate</t>",{
            params ["_officer", "_player", "_actionId", "_arguments"];
            private _aiCnt = {!isPlayer _x && {alive _x}} count units group _player;
            if (_aiCnt >= ITW_ParamFriendlySquadSize) then {
                hint "OPERATION CANCELLED\nMax squad size reached.";
            } else {
                [_player] remoteExec ["ITW_AllyRecruit",2];
                hint "A unit was added to your squad.";
            };
        },nil,10,false,false,"","player == leader player",3];
    _officer addAction ["<t color='#ffffcc'>Dismiss ai squad mate</t>",{
            params ["_officer", "_player", "_actionId", "_arguments"];
            [_player] call ITW_AllyDismiss;
            hint "A unit was removed from your squad.";
        },nil,10,false,false,"","player == leader player && {alive _x && !(isPlayer _x)} count units group player > 0",3];
    _officer addAction ["<t color='#ffffcc'>Relinquish leadership of squad</t>",{
            params ["_officer", "_player", "_actionId", "_arguments"];
            private _allPlayers = call BIS_fnc_listPlayers - [_player];
            ITW_LEADER_LIST = _allPlayers;
            ITW_LEADER_MENU = [["Choose new leader", false]];
            {
                ITW_LEADER_MENU pushBack [name _x,[_forEachIndex + 2], "", -5, [["expression", format ["_unit = ITW_LEADER_LIST#%1;[[group _unit, _unit],'selectLeader', group _unit] call ITW_FncRemoteLocalGroup;",_forEachIndex]]], "1", "1"];
            } forEach _allPlayers;
            ITW_LEADER_MENU pushBack ["",   [], "", -1, [["expression", ""]], "1", "1"];
            ITW_LEADER_MENU pushBack ["Cancel",[16], "", -3, [["expression", ""]], "1", "1"];
            showCommandingMenu "#USER:ITW_LEADER_MENU";
        },nil,10,false,true,"","player == leader player && {{isPlayer _x}count units group player > 1}",3];
    _officer addAction ["<t color='#ffffcc'>Swap into AI squad mate</t>",{
            params ["_officer", "_player", "_actionId", "_arguments"];
            [_player] call ITW_TeammateReplace;
        },nil,10,false,false,"","{alive _x && !(isPlayer _x)} count units group player > 0",3];

    _officer addAction ["<t color='#ffff00'>-- Squad Leader Options --</t>",{},nil,10,false,false,"","player == leader player",3];
    _officer addAction ["<t color='#ffffcc'>Adjust friendly ai unit count</t>" ,{
            0 call ITW_BaseAllyCountChange;
        },nil,10,false,false,"","player == leader player",3];
    _officer addAction ["<t color='#ffffcc'>Adjust friendly ai vehicle count</t>" ,{
            0 call ITW_BaseAllyVehCountChange;
        },nil,10,false,false,"","player == leader player",3];
    _officer addAction ["<t color='#ffffcc'>Recall ally squad</t>",{
            0 call ITW_BaseAllyRecall;
        },nil,10,false,true,"","player == leader player",3];
    _officer addAction ["<t color='#ffffcc'>Skip time</t>",{
            params ["_officer", "_player", "_actionId", "_arguments"];
            showCommandingMenu "#USER:ITW_SLEEP_MENU";
        },nil,10,false,true,"","player == leader player",3];
    _officer addAction ["<t color='#ffffcc'>Clean Up (delete all abandoned vehicles, dead units)</t>",{
            params ["_officer", "_player", "_actionId", "_arguments"];
            [] remoteExec ["ITW_BaseCleanUp",2];
        },nil,10,false,true,"","player == leader player",3];
    _officer addAction ["<t color='#ff0000'>Save game</t>",{
            params ["_officer", "_player", "_actionId", "_arguments"];
            ["autoSave"] call ITW_SaveGame;
            hint "GAME SAVED\nAutosaves every 10 minutes\nAutosave when objectives captured.";
        },nil,10,false,true,"","player == leader player",3];
};

ITW_BaseOpenGarage = {
    params ["_officer","_isAtBase"];  
    [] call ITW_GaragePreload;
    private _pos = [ITW_Garages, _officer] call BIS_fnc_nearestPosition;
    
    if (isnil "BIS_fnc_garage_center") then {BIS_fnc_garage_center = objNull};
    if (BIS_fnc_garage_center distance _pos < 10 && {!(crew BIS_fnc_garage_center isEqualTo [])}) exitWith {
            playSoundUI ["A3\UI_F\data\Sound\CfgNotifications\addItemFailed.wss"];
            hint "Previous garage vehicle has crew and is still in the way.";
    };
    if (BIS_fnc_garage_center distance _pos >= 10 || {!(crew BIS_fnc_garage_center isEqualTo [])}) then {
        BIS_fnc_garage_center = objNull;
    };
    private _opened = true;
    private _nearbyVehs = nearestObjects [_pos,["Air","LandVehicle","Ship","RoadCone_F"],12];
    {
        if (!alive _x || {typeOf _x isEqualTo "RoadCone_F"}) then {
            deleteVehicle _x;
            _nearbyVehs deleteAt _forEachIndex;
        };
    } forEachReversed _nearbyVehs;
    private _nearestVeh = if (count _nearbyVehs > 0) then {_nearbyVehs#0} else {objNull};
    if (_nearestVeh distance _pos > 10 || {_nearestVeh == BIS_fnc_garage_center}) then {
        // okay to spawn new vehicle 
        if (_nearestVeh != BIS_fnc_garage_center) then {
            BIS_fnc_garage_center = createVehicleLocal ["RoadCone_F", _pos, [], 0, "CAN_COLLIDE"]; 
        };                 
        ["Open", false] call ITW_Garage;
    } else {
        if (!(_nearestVeh isKindOf "CAManBase") && 
            {{alive _x} count crew _nearestVeh == 0}) then {
            // use nearby vehicle as garage vehicle start point
            deleteVehicle _nearestVeh;
            BIS_fnc_garage_center = createVehicleLocal ["RoadCone_F", _pos, [], 0, "CAN_COLLIDE"]; 
            ["Open", false] call ITW_Garage;
        } else {
            // Garage is blocked
            playSoundUI ["A3\UI_F\data\Sound\CfgNotifications\addItemFailed.wss"];
            hint "Garage location is blocked (by vehicle or unit)";
            _opened = false;
        };
    };
    if (_opened) then {
        sleep 1;
        hint format ["The garage is to the %1. %2",
            ["north","north east","east","south east","south","south west","west","north west","north"] select 
            round ((player getDir _pos) / 45),if(_isAtBase) then {""} else {"Check your map."}];
    };
};

ITW_BaseAllyCountChange = {
    private _curr = [];
    _curr resize [8,""];
    _curr set [ITW_ParamFriendlyAiCntAdjustment+4,"*"];
    ITW_ALLY_RECOUNT = [
        ["Num friendly vs enemy AI", false],
        ["Hardly any"   +(_curr#0),[2], "", -5, [["expression", "ITW_ParamFriendlyAiCntAdjustment=-4; publicVariable 'ITW_ParamFriendlyAiCntAdjustment';"]], "1", "1"],
        ["Much less"    +(_curr#1),[3], "", -5, [["expression", "ITW_ParamFriendlyAiCntAdjustment=-3; publicVariable 'ITW_ParamFriendlyAiCntAdjustment';"]], "1", "1"],
        ["Less"         +(_curr#2),[4], "", -5, [["expression", "ITW_ParamFriendlyAiCntAdjustment=-2; publicVariable 'ITW_ParamFriendlyAiCntAdjustment';"]], "1", "1"],
        ["Slightly less"+(_curr#3),[5], "", -5, [["expression", "ITW_ParamFriendlyAiCntAdjustment=-1; publicVariable 'ITW_ParamFriendlyAiCntAdjustment';"]], "1", "1"],
        ["Balanced"     +(_curr#4),[6], "", -5, [["expression", "ITW_ParamFriendlyAiCntAdjustment= 0; publicVariable 'ITW_ParamFriendlyAiCntAdjustment';"]], "1", "1"],
        ["Slightly more"+(_curr#5),[7], "", -5, [["expression", "ITW_ParamFriendlyAiCntAdjustment= 1; publicVariable 'ITW_ParamFriendlyAiCntAdjustment';"]], "1", "1"],
        ["More"         +(_curr#6),[8], "", -5, [["expression", "ITW_ParamFriendlyAiCntAdjustment= 2; publicVariable 'ITW_ParamFriendlyAiCntAdjustment';"]], "1", "1"],
        ["Much more"    +(_curr#7),[9], "", -5, [["expression", "ITW_ParamFriendlyAiCntAdjustment= 3; publicVariable 'ITW_ParamFriendlyAiCntAdjustment';"]], "1", "1"],
        ["Cancel",[16], "", -3, [["expression", ""]], "1", "1"]
    ];
    showCommandingMenu "#USER:ITW_ALLY_RECOUNT";
};

ITW_BaseAllyVehCountChange= {
    private _curr = [];
    _curr resize [7,""];
    _curr set [[0.1,0.4,0.7,1.0,1.3,1.6,1.9] find ITW_ParamVehicleSideAdjustment,"*"];
    ITW_ALLY_RECOUNT = [
        ["Num friendly vs enemy vehicles", false],
        ["Much less"    +(_curr#0),[3], "", -5, [["expression", "ITW_ParamVehicleSideAdjustment=0.1; publicVariable 'ITW_ParamVehicleSideAdjustment'"]], "1", "1"],
        ["Less"         +(_curr#1),[4], "", -5, [["expression", "ITW_ParamVehicleSideAdjustment=0.4; publicVariable 'ITW_ParamVehicleSideAdjustment'"]], "1", "1"],
        ["Slightly less"+(_curr#2),[5], "", -5, [["expression", "ITW_ParamVehicleSideAdjustment=0.7; publicVariable 'ITW_ParamVehicleSideAdjustment'"]], "1", "1"],
        ["Balanced"     +(_curr#3),[6], "", -5, [["expression", "ITW_ParamVehicleSideAdjustment=1.0; publicVariable 'ITW_ParamVehicleSideAdjustment'"]], "1", "1"],
        ["Slightly more"+(_curr#4),[7], "", -5, [["expression", "ITW_ParamVehicleSideAdjustment=1.3; publicVariable 'ITW_ParamVehicleSideAdjustment'"]], "1", "1"],
        ["More"         +(_curr#5),[8], "", -5, [["expression", "ITW_ParamVehicleSideAdjustment=1.6; publicVariable 'ITW_ParamVehicleSideAdjustment'"]], "1", "1"],
        ["Much more"    +(_curr#6),[9], "", -5, [["expression", "ITW_ParamVehicleSideAdjustment=1.9; publicVariable 'ITW_ParamVehicleSideAdjustment'"]], "1", "1"],
        ["Cancel",[16], "", -3, [["expression", ""]], "1", "1"]
    ];
    showCommandingMenu "#USER:ITW_ALLY_RECOUNT";
};

ITW_BaseAllyRecall = {  
    if (player getSlotItemName 608 != "" || {player getSlotItemName 612 != ""}) then { // player has map or gps
        // choose on map
        showMap true; 
        openMap [true,false];
        private _timeout = time + 1;
        waitUntil {visibleMap || {time > _timeout}};
        // jump through some hoops to block ctrl clicks
        ITW_MAPCLICK_TIME = 0;
        ITW_RECALL_LEADERS = ITW_AllyGroups apply {leader _x};
        private _ehMbdId = findDisplay 12 displayAddEventHandler ["MouseButtonDown", 
            {
                params ["_control", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];
                // 0 is left button
                if (!_alt and !_shift and !_ctrl and _button == 0) then {
                    ITW_MAPCLICK_TIME = time;
                };
                false
            }];
        private _ehMscId = addMissionEventHandler ["MapSingleClick", {
            params ["_units", "_pos", "_alt", "_shift"];
            if (!_alt && !_shift) then {
                _delta = time-ITW_MAPCLICK_TIME;   
                if (_delta < 0.8) then {
                    private _nearestLeader = [_pos,ITW_RECALL_LEADERS] call ITW_FncClosest;
                    private _dist = _pos distance2D _nearestLeader;
                    if (_dist < 100) then {
                        playSoundUI ["A3\UI_F\data\Sound\CfgNotifications\addItemFailed.wss"];
                        private _groups = [group _nearestLeader];
                        if !(vehicle _nearestLeader isEqualTo _nearestLeader) then {
                            {
                                _groups pushBackUnique group _x;
                            } forEach crew vehicle _nearestLeader;
                        };
                        private _groupNames = "";
                        {
                            _groupName = str _x;
                            [_groupName] remoteExec ['ITW_AllyRecall',2];
                            _groupNames = _groupNames + " " + _groupName;
                        } forEach _groups;
                        "recall" cutText [format ["<t size='2' color='#aaaa88'><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/>%1 recalled</t>",_groupNames],"PLAIN",1,true,true]; 
                    };
                };
            }}];
        private _timeout = 0;
        while {visibleMap} do {
            if (time > _timeout) then {
                hintSilent "Select squads to recall\nClose map when done";
                _timeout = time + 15;
            };
        };
        removeMissionEventHandler ["MapSingleClick", _ehMscId];
        findDisplay 12 displayRemoveEventHandler ["MouseButtonDown",_ehMbdId];
        "recall" cutText ["","PLAIN",0.001];
        hintSilent "";
    } else {
        // choose from list
        private _groups = allGroups select {side _x == west && {group player != _x && {!(getPosATL leader _x isEqualTo [0,0,0])}}};
        ITW_ALLY_RECALL_0 = [["Recall Squad", false]];
        private _menu = ITW_ALLY_RECALL_0;
        private _menuIdx = 0;
        private _keyIdx = 2;
        if (isNil "ITW_RECALL_NAMES") then {ITW_RECALL_NAMES = createHashMap};
        {
            private _name = str _x;
            if (time - (ITW_RECALL_NAMES getOrDefault [_name,0]) < 15) then {_name = _name + " (recalled)"};
            if (_keyIdx > 11) then {
                _keyIdx = 2;
                if (_menuIdx > 0) then {
                    private _prevMenuName = format ["ITW_ALLY_RECALL_%1",_menuIdx-1];
                    _menu pushBack ["Prev",[25],"#USER:"+_prevMenuName, -5, [["expression", ""]], "1", "1"];
                };
                _menuIdx = _menuIdx + 1;
                private _menuName = format ["ITW_ALLY_RECALL_%1",_menuIdx];
                _menu pushBack ["Next",[49],"#USER:"+_menuName, -5, [["expression", ""]], "1", "1"];
                _menu pushBack ["",[], "", -1, [["expression", ""]], "1", "1"];
                _menu pushBack ["Cancel",[16], "", -3, [["expression", ""]], "1", "1"];
                call compile format ["%1 = [['Recall Squad', false]];_menu = %1;",_menuName];
            };
            _menu pushBack [_name,[_keyIdx], "", -5, [["expression", format["
                ['%1'] remoteExec ['ITW_AllyRecall',2];
                ITW_RECALL_NAMES set ['%1',time];
                0 spawn ITW_BaseAllyRecall;
            ",_name]]], "1", "1"];
            _keyIdx = _keyIdx + 1;
        } forEach _groups;
        if (_menuIdx > 0) then {
            private _prevMenuName = format ["ITW_ALLY_RECALL_%1",_menuIdx-1];
            _menu pushBack ["Prev",[25],"#USER:"+_prevMenuName, -5, [["expression", ""]], "1", "1"];
        };
        _menu pushBack ["",[], "", -1, [["expression", ""]], "1", "1"];
        _menu pushBack ["Cancel",[16], "", -3, [["expression", ""]], "1", "1"];
        showCommandingMenu "#USER:ITW_ALLY_RECALL_0";
    };
};

ITW_BaseCleanUp = {
    {
        if (vehicle _x == _x) then {deleteVehicle _x} else {vehicle _x deleteVehicleCrew _x};
    } count allDead; 
    private _keepVehicles = ITW_PlayerVehiclesList apply {_x#0};
    _keepVehicles = _keepVehicles + ITW_Statics;
    {   
        if (_x isKindOf "WeaponHolderSimulated") then {deleteVehicle _x; continue};
        if !(_x isKindOf "AllVehicles") then {continue};
        if (count crew _x > 0) then {continue};
        if (_x isKindOf "CAManBase") then {continue};
        if (_x in _keepVehicles) then {continue};
        deleteVehicle _x;
    } count vehicles;
};

ITW_ALLY_WAIT_MENU = [
	["Ally wait behavior", false],
	["Never",                     [2], "", -5, [["expression", "0 call ITW_BaseWait;"]], "1", "1"],
	["Players at base",           [3], "", -5, [["expression", "1 call ITW_BaseWait;"]], "1", "1"],
	["Players at base/In heli",   [4], "", -5, [["expression", "2 call ITW_BaseWait;"]], "1", "1"],
	["Always",                    [5], "", -5, [["expression", "3 call ITW_BaseWait;"]], "1", "1"],
    ["",   [], "", -1, [["expression", ""]], "1", "1"],
	["Cancel",                    [16], "", -3, [["expression", ""]], "1", "1"]
];

ITW_VIEW_DIST_MENU = [
	["View Distance", false],
	["2000", [3], "", -5, [["expression", "setViewDistance  2000;setObjectViewDistance 1000"]], "1", "1"],
	["3000", [4], "", -5, [["expression", "setViewDistance  3000;setObjectViewDistance 1500"]], "1", "1"],
	["4000", [5], "", -5, [["expression", "setViewDistance  4000;setObjectViewDistance 2000"]], "1", "1"],
	["5000", [6], "", -5, [["expression", "setViewDistance  5000;setObjectViewDistance 2500"]], "1", "1"],
	["6000", [7], "", -5, [["expression", "setViewDistance  6000;setObjectViewDistance 3000"]], "1", "1"],
	["7000", [8], "", -5, [["expression", "setViewDistance  7000;setObjectViewDistance 3500"]], "1", "1"],
	["8000", [9], "", -5, [["expression", "setViewDistance  8000;setObjectViewDistance 4000"]], "1", "1"],
	["9000", [10],"", -5, [["expression", "setViewDistance  9000;setObjectViewDistance 4500"]], "1", "1"],
	["10000",[11],"", -5, [["expression", "setViewDistance 10000;setObjectViewDistance 5000"]], "1", "1"],
    ["",   [], "", -1, [["expression", ""]], "1", "1"],
	["Cancel",   [16], "", -3, [["expression", ""]], "1", "1"]
];

ITW_SLEEP_MENU = [
	["Rest Until", false],
	["Sunrise",  [2], "", -5, [["expression", "0 call ITW_BaseSleep;"]], "1", "1"],
	["Noon",     [3], "", -5, [["expression", "1 call ITW_BaseSleep;"]], "1", "1"],
	["Sunset",   [4], "", -5, [["expression", "2 call ITW_BaseSleep;"]], "1", "1"],
	["Midnight", [5], "", -5, [["expression", "3 call ITW_BaseSleep;"]], "1", "1"],
    ["",   [], "", -1, [["expression", ""]], "1", "1"],
	["Cancel",   [16], "", -3, [["expression", ""]], "1", "1"]
];

ITW_BaseWait = {
    // change ally wait behavior
    private _desc = ["No Wait","Player Wait","Player/Heli Wait","Always Wait"] select _this;
    if (_this != ITW_ParamFriendlySquadWait) then {
        ITW_ParamFriendlySquadWait = _this;
        publicVariable "ITW_ParamFriendlySquadWait";
        hint format ["Ally wait changed to %1",_desc];
    } else {
        hint format ["Ally wait kept at %1",_desc];
    };
};

ITW_BaseSleep = {
    private _index = _this;
    private _date = date;
    _date params ["_year", "_month", "_day", "_hours", "_minutes"];
    _date call BIS_fnc_sunriseSunsetTime params ["_dawnHr","_duskHr"];
    private _origHrs = _hours;
    switch (_index) do {
        case 0: {
            _dawnHr = _dawnHr - 0.4;
            _hours = floor _dawnHr;
            _minutes = round ((_dawnHr - _hours) * 60);
        };
        case 1: {
            _hours = 12;
            _minutes = 0;
        };
        case 2: {
            _duskHr = _duskHr + 0.4;
            _hours = floor _duskHr;
            _minutes = round ((_duskHr - _hours) * 60);
        };
        case 3: {
            _hours = 0;
            _minutes = 0;
        };
        default {_year = 0};
    };
    if (_year == 0) exitWith {};
    if (_hours < _origHrs) then {_day = _day + 1};
    [_year,_month,_day,_hours,_minutes] remoteExec ["ITW_BaseSleepMP",0];
};

ITW_BaseSleepMP = {
    // call on all clients
    private "_time";
    switch (true) do {
        case (_this#3==0):  {_time = "midnight"};
        case (_this#3==12): {_time = "noon"};
        case (_this#3<12):  {_time = "sunrise"};
        default             {_time = "sunset"};
    };
    private _text = format ["Resting until %1",_time];
    if (hasInterface) then {cutText [_text,"BLACK OUT",2]};
    sleep 2;
    setDate _this;
    sleep 1;
    if (hasInterface) then {cutText [_text,"BLACK IN",2]};
};

ITW_BaseShowRoleMenu = {
    private _roleText = {
        params ["_role","_text"];
        private _roles = player getVariable ["ITW_Roles",[]];
        if (_role in _roles) then {
            _text = format ["ENABLED:  %1",_text];
        };
        _text
    };
    ITW_ROLE_MENU = [
        ["Choose roles", false],
        [[0,"Medic (heal faster and to 100%%)"               ] call _roleText,[2], "", -5, [["expression","[0] call ITW_BaseRoleToggle;[] spawn ITW_BaseShowRoleMenu"]], "1", "1"],
        [[1,"Engineer (repair vehicle with toolkit)"         ] call _roleText,[3], "", -5, [["expression","[1] call ITW_BaseRoleToggle;[] spawn ITW_BaseShowRoleMenu"]], "1", "1"],
        [[2,"High commander (control squads)"                ] call _roleText,[4], "", -5, [["expression","[2] call ITW_BaseRoleToggle;[] spawn ITW_BaseShowRoleMenu"]], "1", "1"],
        [[3,"UAV operator (hack UAVs/UAGs with UAV Terminal)"] call _roleText,[5], "", -5, [["expression","[3] call ITW_BaseRoleToggle;[] spawn ITW_BaseShowRoleMenu"]], "1", "1"],
        ["RemoveAll",[6], "", -5, [["expression","[] call ITW_BaseResetRoles;[] spawn ITW_BaseShowRoleMenu"]], "1", "1"],
        ["",   [], "", -1, [["expression", ""]], "1", "1"],
        ["Done",   [16,1], "", -3, [["expression", ""]], "1", "1"]
    ];
    showCommandingMenu "#USER:ITW_ROLE_MENU";
};

ITW_BaseRoleToggle = {
    // call on client
    params ["_role",["_force",-1]]; // _force 1 for on, 0 for off, -1 for toggle
    
    private _roles = player getVariable ["ITW_Roles",[]];
    private _enable = switch (_force) do {
            case 0: {false};
            case 1: {true};
            default {!(_role in _roles)};
        };
        
    if (!_enable) then {
        // disable role
        _roles = _roles - [_role];
        switch (_role) do {
            case 0: {player setUnitTrait ["Medic",false]};
            case 1: {player setUnitTrait ["Engineer",false]};
            case 2: {[player,false] remoteExec ["ITW_AllyHighCmdr",2]};
            case 3: {player setUnitTrait ["UAVHacker",false]};
        };
    } else {
        // enable role        
        _roles = player getVariable ["ITW_Roles",[]];
        _roles pushBackUnique _role;      
        switch (_role) do {
            case 0: {player setUnitTrait ["Medic",true]};
            case 1: {player setUnitTrait ["Engineer",true]};
            case 2: {[player,true] remoteExec ["ITW_AllyHighCmdr",2]};
            case 3: {player setUnitTrait ["UAVHacker",true]};
        };        
    };
    player setVariable ["ITW_Roles",_roles];
    profileNamespace setVariable [format["ITW_Roles%1",worldName],_roles];
};

ITW_BaseResetRoles = {
    // call on client
    _roles = _this;
    
    profileNamespace setVariable [format["ITW_Roles%1",worldName],[]];
    
    // disable roles
    {
        [_x,0] call ITW_BaseRoleToggle;
    } count ([0,1,2,3] - _roles);
    
    // enable requested roles
    {
        [_x,1] call ITW_BaseRoleToggle;
    } count _roles;
};

ITW_BaseRoleCheck = {
    params ["_vehicle","_role"];       
    if (_role == "cargo") exitWith {true}; // cargo is always allowed
    
    private _allow = true;
    private _type = "";
    if (_vehicle isKindOf "Tank") then {
        _allow = player getVariable ["ITW_Crew",false];
        _type = "crewman";
    };
    if (_vehicle isKindOf "Car") then {
        private _edSubcat = ((configFile >> "CfgVehicles" >> typeOf _vehicle >> "editorSubcategory") call BIS_fnc_getCfgData);
        if (["apc", _edSubcat, false] call BIS_fnc_inString) then {
            _allow = player getVariable ["ITW_Crew",false];
            _type = "crewman";
        };
    };
                
    if (_vehicle isKindOf "Air") then {
        if (_role == "driver") then {
            _allow = player getVariable ["ITW_Pilot",false];
        } else {
            private _vehRole = assignedVehicleRole player;
            if (count _vehRole > 0 && {count ((vehicle player) weaponsTurret (_vehRole#1)) > 1}) then { 
                _allow = player getVariable ["ITW_Pilot",false];
            };
        };
        _type = "pilot";
    };
    if (!_allow) then {
        hint format ["You are not allowed to operate this vehicle.  See the officer to choose a %1 role",_type];
    };   
    _allow
};

ITW_BaseFindNewPos = {
    // if (_adjustWhitelist) then: _whitelist 1st element should be [_center,_size].  _size will try for 1x, but will move to 2x if needed
    params ["_whitelist","_blacklist","_adjustWhitelist"];
    private _size = _whitelist#0#1;
    private _codeRoad = {
            private _pt = _this;
            private _pts = [_this,_this getPos [60,0],_this getPos [70,90],_this getPos [70,180],_this getPos [70,270]];
            private _elevs = [getTerrainHeightASL (_pts#0),
                              getTerrainHeightASL (_pts#1),
                              getTerrainHeightASL (_pts#2),
                              getTerrainHeightASL (_pts#3),
                              getTerrainHeightASL (_pts#4)];
            private _okay = (selectMax _elevs - (selectMin _elevs)) < _baseElevRange;
            if (_okay) then {
                private _inWater = surfaceIsWater (_pts#0) || {
                                   surfaceIsWater (_pts#1) || {
                                   surfaceIsWater (_pts#2) || {
                                   surfaceIsWater (_pts#3) || {
                                   surfaceIsWater (_pts#4)}}}};
                _okay = ! _inWater;
            };
            _okay
        };
    private _codeNoRoad = {
            private _pt = _this;
            private _okay = false;
            private _nearestRoad = [_pt,70] call BIS_fnc_nearestRoad;
            if (isNull _nearestRoad) then {
                private _pts = [_this,_this getPos [60,0],_this getPos [70,90],_this getPos [70,180],_this getPos [70,270]];
                private _elevs = [getTerrainHeightASL (_pts#0),
                                  getTerrainHeightASL (_pts#1),
                                  getTerrainHeightASL (_pts#2),
                                  getTerrainHeightASL (_pts#3),
                                  getTerrainHeightASL (_pts#4)];
                _okay = (selectMax _elevs - (selectMin _elevs)) < _baseElevRange;
                if (_okay) then {
                    private _inWater = surfaceIsWater (_pts#0) || {
                                       surfaceIsWater (_pts#1) || {
                                       surfaceIsWater (_pts#2) || {
                                       surfaceIsWater (_pts#3) || {
                                       surfaceIsWater (_pts#4)}}}};
                    _okay = ! _inWater;
                };
            };
            _okay
        };
    
    private _baseElevRange = 0;
    private _pos = [0,0];
    private _tries = 100;
    while {count _pos == 2 && {_tries > 0}} do {
        switch (_tries % 3) do {
            case 0: {
                if (_adjustWhitelist) then {_whitelist#0 set [1,_size]};
                _baseElevRange = _baseElevRange + 2;
            };
            case 2: { if (_adjustWhitelist) then {_whitelist#0 set [1,_size*1.5]}; };
            case 1: { if (_adjustWhitelist) then {_whitelist#0 set [1,_size*2]}; };
        };
        private _code = if (_tries > 50) then {_codeNoRoad} else {_codeRoad};
        _pos = [_whitelist,_blacklist,_code] call BIS_fnc_randomPos;
        _tries = _tries - 1;
    };

    if (count _pos == 2) then { _pos = [_whitelist,_blacklist] call BIS_fnc_randomPos };
    if (count _pos == 2) then { _pos = [_whitelist,["water"]] call BIS_fnc_randomPos };
    if (count _pos == 2) then { _pos = [[],["water"]] call BIS_fnc_randomPos };
    
    _pos set [2,0];
    _pos
};

ITW_BaseShipSpawnPt = {  
    ITW_SELECT_POS = nil;
    cutText ["", "PLAIN",0.001];
    
    // get user selected position 
    private _ehId = addMissionEventHandler ["MapSingleClick", {
        params ["_units", "_pos", "_alt", "_shift"];
        if (!_alt && !_shift) then {
            ITW_SELECT_POS = _pos;
            openMap false; 
        };
    }];                 
    
    private _hint = "Click on water to choose where to spawn the boat.  Close map to cancel spawning boat.";
    private _isWater = false;
    while {!_isWater} do {
        showMap true; 
        openMap true;
        waitUntil {visibleMap};
        private _hintTime = -100;
        while {visibleMap} do {
            if (time - _hintTime > 25) then {
                _hintTime = time;
                hintSilent _hint; 
            };
        };
        hintSilent "";
        if (isNil "ITW_SELECT_POS") then {
            ITW_SELECT_POS = [];
            _isWater = true;
        } else {
            _isWater = surfaceIsWater ITW_SELECT_POS;
        };
    };
    removeMissionEventHandler ["MapSingleClick", _ehId];
    private _pos = ITW_SELECT_POS;
    private _seaDepth = getTerrainHeightASL _pos;
    if (_seaDepth < 0) then {_pos set [2,abs _seaDepth]};
    _pos
};

ITW_BasePlatform = {
    // run on server, returns elevation of platform above terrain at _pos
                     
    params ["_pos","_angle",["_elevationASL",-1e10]];
    
    #define P_TYPE   "BlockConcrete_F"
    #define P_LENGTH 8.9
    #define P_WIDTH  4.9
    #define P_HEIGHT 2.0    
    #define P_HEIGHT_OFF_GROUND 0.1    
    #define P_EDGE_TO_CENTER_DIST       5.08  // sqrt( (P_LENGTH/2)^2 + (P_WIDTH/2)^2 )
    #define P_EDGE_TO_CENTER_ANGLE      29    // arctan ( (P_WIDTH/2)/(P_LENGTH/2) )
    #define P_EDGE_TO_CENTER_DIST_X2    10.16 // P_EDGE_TO_CENTER_DIST * 2
    #define P_EDGE_TO_CENTER_WIDE_DIST  13.24 // sqrt( (P_LENGTH)^2 + (P_WIDTH*2)^2 )
    #define P_EDGE_TO_CENTER_WIDE_ANGLE 47.8 // arctan( (P_WIDTH*2)/(P_LENGTH) )
    if (_elevationASL < -1e5) then {
        private _maxElevation = getTerrainHeightASL _pos;
        {
            _x params ["_dir","_dist"];
            private _pt = _pos getPos [_dist,_angle + _dir];
            private _elev = getTerrainHeightASL _pt;
            if (_elev > _maxElevation) then {_maxElevation = _elev};
        } count [
            [0,                         P_LENGTH],
            [P_EDGE_TO_CENTER_ANGLE,    P_EDGE_TO_CENTER_DIST_X2],
            [90,                        P_WIDTH],
            [180-P_EDGE_TO_CENTER_ANGLE,P_EDGE_TO_CENTER_DIST_X2],
            [180,                       P_LENGTH],
            [180+P_EDGE_TO_CENTER_ANGLE,P_EDGE_TO_CENTER_DIST_X2],
            [270,                       P_WIDTH],
            [360-P_EDGE_TO_CENTER_ANGLE,P_EDGE_TO_CENTER_DIST_X2]
        ];
        _elevationASL = _maxElevation-P_HEIGHT+P_HEIGHT_OFF_GROUND;
    };       
    private _fn_PlacePlatform = {
        params ["_pos","_dir","_dist","_angle","_elevation"];
        _platform = P_TYPE createVehicle _pos;
        private _pt = _pos getPos [_dist,_dir + _angle];
        _pt set [2,_elevation];
        _platform setDir (90+_dir);
        _platform setPosASL _pt;    
        // place one upside down so you can't see through it
        _platform = P_TYPE createVehicle _pos;
        private _pt = _pos getPos [_dist,_dir + _angle];
        _pt set [2,_elevation - P_HEIGHT - 0.5];
        _platform setDir (90+_dir);
        _platform setPosASL _pt;
        _platform setVectorUp [0,0,-1];
     };
     
     [_pos,_angle, P_EDGE_TO_CENTER_DIST, P_EDGE_TO_CENTER_ANGLE,_elevationASL] call _fn_PlacePlatform;
     [_pos,_angle, P_EDGE_TO_CENTER_DIST,-P_EDGE_TO_CENTER_ANGLE,_elevationASL] call _fn_PlacePlatform;
     [_pos,_angle,-P_EDGE_TO_CENTER_DIST, P_EDGE_TO_CENTER_ANGLE,_elevationASL] call _fn_PlacePlatform;
     [_pos,_angle,-P_EDGE_TO_CENTER_DIST,-P_EDGE_TO_CENTER_ANGLE,_elevationASL] call _fn_PlacePlatform;
 
     _elevationASL + P_HEIGHT - (getTerrainHeightASL _pos)
};

ITW_BasePlatformWide = {
    // run on server, returns elevation of platform above terrain at _pos
                     
    params ["_pos","_angle"];
    
    private _elevationASL = getTerrainHeightASL _pos;
    {
        _x params ["_dir","_dist"];
        private _pt = _pos getPos [_dist,_angle + _dir];
        private _elev = getTerrainHeightASL _pt;
        if (_elev > _elevationASL) then {_elevationASL = _elev};
    } count [
        [0,                               P_LENGTH],
        [P_EDGE_TO_CENTER_WIDE_ANGLE,     P_EDGE_TO_CENTER_WIDE_DIST],
        [90,                              2*P_WIDTH],
        [180-P_EDGE_TO_CENTER_WIDE_ANGLE, P_EDGE_TO_CENTER_WIDE_DIST],
        [180,                             P_LENGTH],
        [180+P_EDGE_TO_CENTER_WIDE_ANGLE, P_EDGE_TO_CENTER_WIDE_DIST],
        [270,                             2*P_WIDTH],
        [360-P_EDGE_TO_CENTER_WIDE_ANGLE, P_EDGE_TO_CENTER_WIDE_DIST]
    ];
    _elevationASL = _elevationASL-P_HEIGHT+P_HEIGHT_OFF_GROUND;
    
    [_pos getPos [P_WIDTH,_angle+90],_angle,_elevationASL] call ITW_BasePlatform;
    [_pos getPos [P_WIDTH,_angle-90],_angle,_elevationASL] call ITW_BasePlatform;
    
     _elevationASL + P_HEIGHT - (getTerrainHeightASL _pos)
};

ITW_BaseVaActions = {
    params ["_vas"];
    // call on all clients
    if (!hasInterface) exitWith {};
    // add option to switch to a default loadout
    if (isNil "ITW_LoadoutMenu_1") then {
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
                    _menu pushBack ["MORE",[31], format ["#USER:ITW_LoadoutMenu_%1",_index+1], -5, [["expression",""]], "1", "1"];
                    call compile format ["ITW_LoadoutMenu_%1 = _menu;",_index];
                };
                _menu = +_header;
                _cnt = 0;
                _index = _index + 1;
                if (_index == 1) then {
                    _menu pushBack ["Random Loadout",[_cnt+2], "", -5, [["expression","0 spawn {[player,(selectRandom ITW_AllyUnitTypes) call ITW_FncGetLoadoutFromClass] call ITW_FncSetUnitLoadout};"]], "1", "1"];
                    _cnt = _cnt + 1;
                };
            } else {
                _cnt = _cnt + 1;
            };    
            _menu pushBack [_name,[_cnt+2], "", -5, [["expression",format ["0 spawn {[player,'%1' call ITW_FncGetLoadoutFromClass] call ITW_FncSetUnitLoadout};",_x]]], "1", "1"];
        } forEach ITW_AllyUnitTypes;
        _menu pushBack ["BACK",[17], "", -4, [["expression",""]], "1", "1"];
        call compile format ["ITW_LoadoutMenu_%1 = _menu;",_index];
    };
    {
        _x addAction ["Select a default loadout",{showCommandingMenu "#USER:ITW_LoadoutMenu_1"},nil,1.1,false,false,"","true",4];
        _x addAction ["Teammate arsenal",{[] call ITW_TeammateArsenal},nil,1.1,false,false,"","leader player isEqualTo player && {{!isPlayer _x} count units group player > 0}",4];
        _x addAction ["Save teammates",{[] spawn ITW_TeammateSaveLocal},nil,1.1,false,false,"","leader player isEqualTo player && {{!isPlayer _x} count units group player > 0}",4];
        _x addAction ["Load teammates",{[] spawn ITW_TeammateLoadLocal},nil,1.1,false,false,"","leader player isEqualTo player",4];
    } forEach _vas;
};

ITW_BaseLoad = {
    params ["_bases"];
    ITW_Bases = _bases;
    publicVariable "ITW_Bases";
    // ITW_CreateBases will be called after objectives are loaded to create captured bases
};

["ITW_BaseNearest"] call SKL_fnc_CompileFinal;
["ITW_BaseEnsure"] call SKL_fnc_CompileFinal;
["ITW_BaseGetCenterPt"] call SKL_fnc_CompileFinal;
["ITW_BaseGetDir"] call SKL_fnc_CompileFinal;
["ITW_BaseGetPlayerSpawnPt"] call SKL_fnc_CompileFinal;
["ITW_BaseVehicleSelector"] call SKL_fnc_CompileFinal;
["ITW_BasePlace"] call SKL_fnc_CompileFinal;
["ITW_BaseSimpleObject"] call SKL_fnc_CompileFinal;
["ITW_BaseAddMP"] call SKL_fnc_CompileFinal;
["ITW_BaseAddGarageMP"] call SKL_fnc_CompileFinal;
["ITW_BaseOfficerSetup"] call SKL_fnc_CompileFinal;
["ITW_BaseOfficerActions"] call SKL_fnc_CompileFinal;
["ITW_BaseCleanUp"] call SKL_fnc_CompileFinal;
["ITW_BaseWait"] call SKL_fnc_CompileFinal;
["ITW_BaseSleep"] call SKL_fnc_CompileFinal;
["ITW_BaseSleepMP"] call SKL_fnc_CompileFinal;
["ITW_BaseShowRoleMenu"] call SKL_fnc_CompileFinal;
["ITW_BaseRoleToggle"] call SKL_fnc_CompileFinal;
["ITW_BaseResetRoles"] call SKL_fnc_CompileFinal;
["ITW_BaseRoleCheck"] call SKL_fnc_CompileFinal;
["ITW_BaseShipSpawnPt"] call SKL_fnc_CompileFinal;
["ITW_BaseLoad"] call SKL_fnc_CompileFinal;
["ITW_BaseVehFallbacks"] call SKL_fnc_CompileFinal;
["ITW_BasePlatform"] call SKL_fnc_CompileFinal;
["ITW_BasePlatformWide"] call SKL_fnc_CompileFinal;
["ITW_BaseFindNewPos"] call SKL_fnc_CompileFinal;
["ITW_BaseAllyRecall"] call SKL_fnc_CompileFinal;
["ITW_CreateBases"] call SKL_fnc_CompileFinal;
["ITW_BaseNext"] call SKL_fnc_CompileFinal;
["ITW_BaseGetRepairPt"] call SKL_fnc_CompileFinal;
["ITW_BaseMechanicSetup"] call SKL_fnc_CompileFinal;
["ITW_BaseMechanicActions"] call SKL_fnc_CompileFinal;
["ITW_RetrieveVeh"] call SKL_fnc_CompileFinal;
["ITW_BaseAllyCountChange"] call SKL_fnc_CompileFinal;
["ITW_BasePlaceGarage"] call SKL_fnc_CompileFinal;
["ITW_BaseOpenGarage"] call SKL_fnc_CompileFinal;
["ITW_BaseVaActions"] call SKL_fnc_CompileFinal;
