

ITW_vehRepairPoint = {
    // call only on server to initialize a repair point
    if (!isServer) exitWith {};
    
    params ["_pos","_radius",["_enableCode",{true}],["_enableArg",objNull]];
    
    if (isNil "ITW_VehRepairArray") then {
        ITW_VehRepairArray = [];
        [] spawn ITW_vehRepairTask;
    };
    ITW_VehRepairArray pushBack [_pos,_radius,_enableCode,_enableArg];
    publicVariable "ITW_VehRepairArray";
    
};

ITW_vehRepairPointRemove = {
    // call only on server to initialize a repair point
    if (!isServer) exitWith {};
    
    params ["_pos","_radius",["_enableCode",{true}],["_enableArg",objNull]];
    
    if !(isNil "ITW_VehRepairArray") then {
        ITW_VehRepairArray = ITW_VehRepairArray - [[_pos,_radius,_enableCode,_enableArg]];
        publicVariable "ITW_VehRepairArray";
    };
};

ITW_vehRepairTask = {
    // task to handle veh repair points, spawn on server only
    scriptName "ITW_vehRepairTask";
    ITW_VehRepairRunning = true;
    while {true} do {
        while {LV_PAUSE} do {sleep 5};
        sleep 8;
        private _vehRepairArray = ITW_VehRepairArray; 
        private _allVehicles = vehicles select {{isPlayer _x} count crew _x > 0 && {!isSimpleObject  _x && {(_x isKindOf "Air" || _x isKindOf "Land") && {alive _x && {speed _x < 2}}}}};
        _vehiclesRepairing = false;
        {
            _x params ["_pos","_radius","_enableCode","_enableArg"];
            if !(_enableArg call _enableCode) then {continue};
            {
                _x params ["_veh"];
                
                if !(_veh getVariable ["ITW_vehServing",false]) then {
                    private _fuel = fuel _veh;
                    private _damage = damage _veh;
                    private _ammo = 1;
                    private _mags = createHashMap;
                    { 
                        _x params ["_classname","_tpath","_ammoCnt"];
                        private _ammoFull = getNumber (configFile >> "CfgMagazines" >> _classname >> "count");
                        if (_classname in _mags) then {
                            _mags get _classname params ["_cnt","_full"];
                            _mags set [_classname,[_ammoCnt+_cnt,_ammoFull+_full]];
                        } else {
                            _mags set [_classname,[_ammoCnt,_ammoFull]];
                        };
                    } forEach magazinesAllTurrets _veh;
                    {
                        _y params ["_cnt","_max"];
                        if (_max > 0) then {
                            private _thisRatio = _cnt/_max;
                            if (_thisRatio < _ammo) then {
                                _ammo = _thisRatio;
                            };
                        };
                    } forEach _mags;
                    
                    if (_fuel < 0.9 || _ammo < 1 || _damage > 0) then {
                        // needs servicing
                        if (!isEngineOn _veh) then {
                            _veh setVariable ["ITW_vehServing",true];  
                            [_veh, _fuel,_ammo,_damage] remoteExec ["ITW_vehRepairExecute",0];
                        } else {
                            if (_veh getVariable ["ITW_repairHintTime",0] < time && {(getPosATL _veh)#2 < (_pos#2 + 4)}) then {
                                private _vehPlayers = allPlayers select {vehicle _x == _veh};
                                [3,_veh] remoteExec ["ITW_VehRepairSoundMP",_vehPlayers];
                                _veh setVariable ["ITW_repairHintTime",time + 30];
                            };
                        };
                    };
                };
            } forEach (_allVehicles select {_x distance2D _pos < _radius});
        } forEach _vehRepairArray;
    };
    ITW_VehRepairRunning = nil;
};

ITW_vehRepairExecute = {
    // run on all clients 
    params ["_veh","_fuel","_ammo","_damage"];
    #define FILL_PER_CYCLE 0.10
    #define CYCLE_TIME     2.7
    private _startPercent = _fuel min _ammo min (1 - _damage);
    _startPercent = floor (_startPercent*10)/10; // round to 0.1
    for "_i" from _startPercent to 0.99999 step FILL_PER_CYCLE do {
        [0,_veh] call ITW_VehRepairSoundMP;
        _veh vehicleChat format ["Servicing %1%2",_i * 100,"%"];
        [_veh,_i max _fuel, _i max _ammo max 0.75, (1-_i) min _damage] call ITW_VehRepairMP;
        sleep CYCLE_TIME;
        if (isEngineOn _veh) exitWith {
            _veh vehicleChat format ["Servicing canceled at %1%2",_i*100,"%"];
        };
    };
    if !(isEngineOn _veh) then {
        [_veh,1,1,0] call ITW_VehRepairMP;
        [1,_veh] call ITW_VehRepairSoundMP;
        sleep 1;
        _veh vehicleChat "Servicing 100%";
        sleep 1;
        [2,_veh] call ITW_VehRepairSoundMP;
        // ensure vehicle has a toolkit in inventory
        if !("ToolKit" in (getItemCargo _veh#0)) then {
            _veh addItemCargoGlobal ["ToolKit",1];
        };
    };
    if (isServer) then {_veh setVariable ["ITW_vehServing",false]};
};

ITW_VehRepairMP = {
    // call on all clients where vehicle or a turret is local
    params ["_veh","_fuel","_ammo","_damage"];                         
    if (local _veh) then {
        _veh setFuel _fuel;
        _veh setDamage _damage;
    };
    
    // if I set ammo to anything less than 100%, it will not refill reloads in the vehicle
    // setVehicleAmmoDef will reload the refils, but will remove any pylons.
    // So just don't show ammo filling up and it works
    if (_ammo == 1) then {
        _veh setVehicleAmmo _ammo; // must run where each turret is local, so do it everywhere
    };
};

ITW_VehRepairSoundMP = {
    // call on each client that should hear sound
    params ["_which","_veh"];
    if (!hasInterface) exitWith {};
    if (vehicle player != _veh) exitWith {};
    private _startOffset = 0;
    private _duration = -1;
    private "_sound";
    switch (_which) do {
        case 0: {
            _sound = "A3\Sounds_F\sfx\objects\upload_terminal\Terminal_antena_close.wss";
            _startOffset = 0.2;
        };  
        case 1: {
            _sound = "A3\Sounds_F\sfx\objects\upload_terminal\Terminal_antena_open.wss";
        };
        case 2: {
            _veh vehicleChat "We're good to go";
            _sound = "A3\Dubbing_F_oldman\oldman1\017_eve_mechanic_car_ready_b\oldman1_017_eve_mechanic_car_ready_b_MECHANIC_0_Processed.ogg"
        };
        case 3: {
            _veh vehicleChat "Power down for servicing";
            _sound = "A3\dubbing_f_bootcamp\boot_m01\d20_Shutdown\boot_m01_d20_shutdown_ADA_2.ogg";
            _startOffset = 1.6;
            _duration = 0.55;
        };
    };  
    private _sndId = playSound3D [_sound, player, true, getPosASL player, 10, 1, 20, _startOffset, true];
    if (_duration > 0) then {
        waitUntil {
            private _sndparams = soundParams _sndId;
            _sndparams isEqualTo [] || {_sndparams#1 >= _duration}
        };
        stopSound _sndId;
    };
};

["ITW_vehRepairPoint"] call SKL_fnc_CompileFinal;
["ITW_vehRepairPointRemove"] call SKL_fnc_CompileFinal;
["ITW_vehRepairExecute"] call SKL_fnc_CompileFinal;
["ITW_vehRepairTask"] call SKL_fnc_CompileFinal;
["ITW_VehRepairSoundMP"] call SKL_fnc_CompileFinal;
["ITW_VehRepairMP"] call SKL_fnc_CompileFinal;