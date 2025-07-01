// Vehicle Chooser
//
// _vehsArray = 0 call VehicleChooser - to have user select vehicles - call on server
//
// [_vehsArray, "type","includeTextureAnim"] call VehicleChooser_Get - to get the vehicles
//
//
// _vehsArray: [Tanks,Apcs,Cars,Helicopters,Planes,Statics,Naval,UavUgv]
//    each type will contain arrays of [vehClassName,texture,animation], 
//    or [] if no vehicles of that type selected selected
//        texture and anim are arrays of [texture,probability,...] or [anim,probability,...]
//
// The texture/anim can be applied with [_veh,_texture,_anim] call BIS_fnc_initVehicle;

#include "\A3\Ui_f\hpp\defineResinclDesign.inc" 

#define TANK_ID   0
#define APC_ID    1
#define CAR_ID    2
#define HELI_ID   3
#define PLANE_ID  4
#define STATIC_ID 5
#define NAVAL_ID  6
#define UAV_ID    7
#define ID_COUNT  8

VehicleChooser = {;
    // call on server only
    // Allows player to choose vehicles using the garage interface
    // parameters:
    //   multiselect:    true to allow player to choose multiple vehicles
    //   playerToChoose: player who will choose, or objNull for vehicleChooser to select someone
    
    params [["_multiselect",false],["_msg",""],["_playerToChoose",objNull]];
    if (! isServer) exitWith { diag_log "Error: VehicleChooser called from non-server"; };
    
    missionNamespace setVariable ["VEHICLE_CHOOSER_SELECTED",nil];
    
    if (isNull _playerToChoose) then {
        if (isDedicated) then {        
            // if using a dedicated server, use a the first player to choose faction
            waitUntil {count (call BIS_fnc_listPlayers) > 0};
            private _playerClient = owner ((call BIS_fnc_listPlayers)#0);
            [] remoteExec ["VehicleChooser_Wait",-(_playerClient),true];
            [_multiselect,_msg] remoteExec ["VehicleChooser_Start",_playerClient];
        } else {
            // hosted server, so just let the host choose faction
            [] remoteExec ["VehicleChooser_Wait",-2,true];
            [_multiselect,_msg] call VehicleChooser_Start;
        };
    } else {
        [] remoteExec ["VehicleChooser_Wait",-(owner _playerToChoose),true];
        [_multiselect,_msg] remoteExec ["VehicleChooser_Start",_playerToChoose];
    };
    
    private _allVehicles = [];
    waitUntil {_allVehicles = missionNamespace getVariable ["VEHICLE_CHOOSER_SELECTED",""]; typeName _allVehicles isEqualTo "ARRAY"};
    missionNamespace setVariable ["VEHICLE_CHOOSER_SELECTED",nil,true];
    
    private _vehArray = 
        if (_allVehicles isEqualTo []) then {
            [];
        } else {
            [_allVehicles] call VehicleChooser_Sort;
        };
    missionnamespace setvariable ["bis_fnc_garage_data",[]];
    _vehArray
};

VehicleChooser_Get = {
    params ["_vehArray","_type",["_includeTextureAnim",false]];
    // return: if_includeTextureAnim is false: array of classnames
    //         if_includeTextureAnim is true: array of [vehClassName,[texture,proability],[animation,probability,...]] 
    //         or [] if no vehicles of that type were selected
    //
    // _type is one of "Tanks","Apcs","Cars","Helicopters","Planes","Statics","Naval","UavUgv" ( only first letter is actually used )
    if (count _vehArray != ID_COUNT) exitWith {[]};
    
    private _result = 
        switch (toUpperANSI (_type select [0,1])) do {
            case "T": { _vehArray#TANK_ID   };
            case "A": { _vehArray#APC_ID    };
            case "C": { _vehArray#CAR_ID    };
            case "H": { _vehArray#HELI_ID   };
            case "P": { _vehArray#PLANE_ID  };
            case "S": { _vehArray#STATIC_ID };
            case "N": { _vehArray#NAVAL_ID  };
            case "U": { _vehArray#UAV_ID    };
            default {diag_log format ["Error Pos: VehicleChooser_Get called with invalid type (%1)",_type]};
        };
    if !(_includeTextureAnim) then {
        _result = _result apply {_x#0};
    };
    _result
};

VehicleChooser_Wait = {
    // Can be called on extra clients while other player selects factions  
    waitUntil {sleep 1; missionNamespace getVariable ["FACTION_DONE",false]};
};

VehicleChooser_Start = {
    params ["_multiselect","_msg"];
    
    VehicleChooser_multiSelect = _multiselect; 
    VehicleChooser_vehArray = [];
    
    private _done = false;
    private _ehID = [missionNamespace, "garageClosed", {missionNamespace setVariable ["VEHICLE_CHOOSER_CLOSED",true]}] call BIS_fnc_addScriptedEventHandler;
    missionNamespace setVariable ["VEHICLE_CHOOSER_CLOSED",false];
    
    private _emptyType = "RoadCone_F";
    // find flat ground somewhere for garage
    private _pos = getArray(configfile >> "CfgWorlds" >> worldName >> "ilsPosition" );
    if (_pos isEqualTo []) then {
        private _mapRadius = worldSize/2;
        _pos = [_mapRadius, _mapRadius, 0] findEmptyPosition [0,_mapRadius,"B_Heli_Transport_03_unarmed_F"];
        if (_pos isEqualTo []) then {_pos = [_mapRadius, _mapRadius, 0]};
    };
    BIS_fnc_garage_center  = createVehicle ["RoadCone_F", _pos, [], 0, "CAN_COLLIDE"];
    ["Open",[true,BIS_fnc_garage_center]] call BIS_fnc_garage;
    
    #define VC_LIST_BOX_ID  552211
    private _display = displayNull;
    waitUntil {_display = uinamespace getvariable ["bis_fnc_arsenal_display", displaynull];! isNull _display};
    private _ctrlButtonHide = _display displayctrl IDC_RSCDISPLAYARSENAL_CONTROLSBAR_BUTTONINTERFACE;
    private _cehid = _ctrlButtonHide ctrladdeventhandler ["buttonclick",
        'params ["_control"];
        playSoundUI ["Click", 0.75, 1];
        private _textureAnim = [BIS_fnc_arsenal_center] call BIS_fnc_getVehicleCustomization;
        private _type = typeOf BIS_fnc_arsenal_center;
        VehicleChooser_vehArray pushBack [_type,_textureAnim#0,_textureAnim#1];
        if (VehicleChooser_multiSelect) then {
            private _listBox = (_control getVariable ["ListboxCtrl",ctrlNull]);
            _listBox lbAdd getText (configFile >> "CfgVehicles" >> _type >> "DisplayName");
            _listBox ctrlSetScrollValues [1, 0];
        } else {
            with uinamespace do {["buttonClose",[ctrlparent (_this select 0)]] call bis_fnc_arsenal;};
        };
        true'];
    private _oldText = ctrlText _ctrlButtonHide;
    _ctrlButtonHide ctrlSetText "Select";
            
    if (VehicleChooser_multiSelect) then {
        // add list showing selected vehicles
        private _x = safezoneX + safezoneW - 17.5 * (((safezoneW / safezoneH) min 1.2) / 40);
        private _w = 17.0 *                         (((safezoneW / safezoneH) min 1.2) / 40);
        private _y = 10.0 *                         ((((safezoneW / safezoneH) min 1.2) / 1.2) / 25);
        private _h = 15.5 *                         ((((safezoneW / safezoneH) min 1.2) / 1.2) / 25);
        
        private _frame = _display ctrlCreate ["RscFrame",VC_LIST_BOX_ID+1];
        _frame ctrlSetPosition [_x,_y,_w,_h];
        _frame ctrlSetForegroundColor [0,0,0,1];
        private _listBox = _display ctrlCreate ["RscListBox", VC_LIST_BOX_ID];
        _listBox ctrlSetPosition [_x,_y,_w,_h];
        _frame ctrlCommit 0;
        _listBox ctrlCommit 0;
        _ctrlButtonHide setVariable ["ListboxCtrl",_listBox];
    };
    
    // add message
    "VehicleChooser" cuttext ["<t size='2'><br/><br/><br/><br/><br/><br/><br/><br/>" + _msg + "<br/>Use 'Select' button to choose vehicle</t>","PLAIN",-1,true,true];
    
    private _cnt = 0;
    waitUntil {
        private _curCnt = count VehicleChooser_vehArray;
        if (_curCnt != _cnt) then {
            _cnt = _curCnt;
            "VehicleChooser" cuttext ["<t size='2'><br/><br/><br/><br/><br/><br/><br/><br/>" + _msg + "<br/>Use 'Select' button to choose more vehicles.<br/>Use 'Close' button when done choosing.</t>","PLAIN",-1,true,true];
        };
        missionNamespace getVariable ["VEHICLE_CHOOSER_CLOSED",false]
    };
    _ctrlButtonHide ctrlRemoveEventHandler ["buttonclick",_cehid];
    _ctrlButtonHide ctrlSetText _oldText;
    deleteVehicle BIS_fnc_garage_center;
    
    missionNamespace setVariable ["VEHICLE_CHOOSER_SELECTED",VehicleChooser_vehArray,true];
    VehicleChooser_vehArray = nil;
    VehicleChooser_multiSelect = nil;
    
    "VehicleChooser" cuttext ["","PLAIN",-1];
};

VehicleChooser_Sort = {
    params ["_allVehicles"];
    _result = [];
    for "_i" from 1 to ID_COUNT do {_result pushBack []};
    {
        private _className = _x#0;
        private _cfg = configFile >> "CfgVehicles" >> _className;
        if (getNumber (_cfg >> "isUav") != 0) then {
            _result#UAV_ID pushBack _x;
        } else {
            switch (true) do {
                case (_className isKindOf "Helicopter"):  {_result#HELI_ID   pushBack _x};
                case (_className isKindOf "Plane"):       {_result#PLANE_ID  pushBack _x};
                case (_className isKindOf "Ship"):        {_result#NAVAL_ID  pushBack _x};
                case (_className isKindOf "Tank"):        {
                    if (getnumber (_cfg >> "maxspeed") > 0) then { _result#TANK_ID   pushBack _x}
                    else {                                         _result#STATIC_ID pushBack _x};
                };
                case (_className isKindOf "LandVehicle"): {
                    if (getnumber (_cfg >> "maxspeed") == 0) then { _result#STATIC_ID pushBack _x}
                    else {
                        private _cat = (_cfg >> "editorSubcategory") call BIS_fnc_getCfgData;
                        if (["apc", _cat, false] call BIS_fnc_inString) then {_result#APC_ID pushBack _x}
                        else {                                                _result#CAR_ID pushBack _x};
                    };
                };
            };
        };
    } forEach _allVehicles;
    
    _result;
};
    
VehicleChooser_Debug = {
    private _garageData = missionnamespace getvariable ["bis_fnc_garage_data",[]];
    if (_garageData isEqualTo []) then {
        ["Preload"] call BIS_fnc_garage;
        _garageData = missionnamespace getvariable ["bis_fnc_garage_data",[]];
    };
    0 setOvercast 0;
    0 setFog 0;
    0 setRain 0;
    forceWeatherChange;
    private _date = date;
    _date set [3,12]; // set to noon
    setDate _date;
    private _allVehicles = [];
    {
        private _subData = _x;
        {
            if (typeName _x == "ARRAY") then {
                {
                    _allVehicles pushBack [(configName _x),[]];
                } forEach _x;
            };
        } forEach _subData;
    } forEach _garageData;
    
    private _vehData = [_allVehicles] call VehicleChooser_Sort;
    private _names = ["TANK","APC","CAR","HELI","PLANE","STATIC","NAVAL","UAV"];
    if (count _names != ID_COUNT) exitWith {diag_log "ERROR POS: VehicleChooser_Debug name array wrong size"};
    
    diag_log "--------VehicleChooser_Debug---------";
    {
        diag_log (_names # _forEachIndex);
        {     
            diag_log format ["  %1",getText(configFile >> "CfgVehicles" >> _x#0 >> "DisplayName")];
        } forEach _x;
    } forEach _vehData;
    diag_log "------------------------------";
    
    #define SPACING 15
    if (worldName isEqualTo "Altis") then {
        private _pos =[23122,17278,0];
        if (isNil "TEST_VEHS") then {TEST_VEHS = []} else {{deleteVehicle _x} forEach TEST_VEHS};
        {
            {
                _configName = _x#0;
                private _veh = _configName createVehicle [0,0,200];
                _veh enableSimulation false;
                _veh setPosATL _pos;
                TEST_VEHS pushBack (_veh);
                _pos set [1,_pos#1 + SPACING]; 
                if (_pos#1 > 18119) then {
                    _pos set [1,17278];
                    _pos set [0,_pos#0 + SPACING];
                };
            } forEach _x;
            _pos set [1,17278];
            _pos set [0,_pos#0 + (SPACING*2)];
        } forEach _vehData;
        { _x addCuratorEditableObjects [TEST_VEHS, true]; } forEach allCurators;
    };
};

private _compileFinal = {
    params [["_var","",[""]], ["_ns",missionNamespace,[missionNamespace]]];
    private _code = _ns getVariable [_var, 0];
    if (typeName _code != typeName {}) exitWith {};
    _codestr = str _code;
    _codestr = _codestr select [1,count _codestr - 2]; // remove begin and end parenthesizes 
    _code = compileFinal _codestr;
    _ns setVariable [_var, _code];
};
["VehicleChooser"] call _compileFinal;
["VehicleChooser_Get"] call _compileFinal;
["VehicleChooser_Wait"] call _compileFinal;
["VehicleChooser_Start"] call _compileFinal;
["VehicleChooser_Sort"] call _compileFinal;
["VehicleChooser_Debug"] call _compileFinal;
