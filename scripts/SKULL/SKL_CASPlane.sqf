// Modified version of the CAS module
// Sends a CAS plane to bomb the target.
// If plane doesn't support bombs, the missiles and/or machine guns will be used

// Arguments:
//   _caller:     player who will receive audio acknowledgements
//   _targetATL:  position to attack
//   _dir:        direction attack craft will be heading as it attacks
//   _side:       side aircraft will be on
//   _planeClass: plane's cfgVehicle class
//   _delay:      extra delay time 

params ["_caller","_targetATL","_dir",["_side",west],["_planeClass",""],["_delay",20]];

if !(isserver) exitwith {diag_log format ["Error Pos: SKL_CASPlane: Called on client (%1)",_this]; false};

if (_planeClass isEqualTo "") then {_planeClass = "B_Plane_CAS_01_F"};

private _sayMessage = {
    params ["_player","_sentence"];
	private _speaker = (side _player) call bis_fnc_moduleHQ;
	if (isnull _speaker) then {isNil {_speaker = (creategroup [west,true]) createunit ["ModuleHQ_F",[10,10,10],[],0,"none"]}};
	[_speaker,speaker _speaker] remoteExec ["setspeaker",_player];
	[_speaker,1] remoteExec ["setpitch",_player];
	_speaker setbehaviour behaviour _speaker;
    [_speaker,_sentence] remoteExec ["globalRadio",_player];
};

private _planeCfg = configfile >> "cfgvehicles" >> _planeClass;
if !(isclass _planeCfg) exitwith {
    diag_log format ["SKL_CASPlane: Vehicle class '%1' not found",_planeClass]; 
    [_caller,"SentUnitDestroyedHQCASBombing"] call _sayMessage;
    hint "CAS Plane doesn't exist";
    false
};

//--- Detect gun
private _weaponCategories = [["bomblauncher"],["missilelauncher","machinegun"]]; // in search order, first found is used
private _weaponTypes = ["bomblauncher","machinegun","missilelauncher"];
private _weapons = [];
{
    private _wpnTypes = _x;
    {  
        private _planeWeapon = _x;
        if (tolower ((_planeWeapon call bis_fnc_itemType) select 1) in _wpnTypes) then {
            _modes = getarray (configfile >> "cfgweapons" >> _planeWeapon >> "modes");
            if (count _modes > 0) then {
                _mode = _modes select 0;
                if (_mode == "this") then {_mode = _planeWeapon};
                _weapons set [count _weapons,[_planeWeapon,_mode]];
            };
        };
        if !(_weapons isEqualTo []) exitWith {_weaponTypes = _wpnTypes};
    } foreach (_planeClass call bis_fnc_weaponsEntityType);
    if !(_weapons isEqualTo []) exitWith {};
} foreach _weaponCategories;
if (count _weapons == 0) exitwith {
    diag_log format ["SKL_CASPlane: No weapon of types %2 found on '%1'",_planeClass,_weaponCategories]; 
    [_caller,"SentUnitDestroyedHQCASBombing"] call _sayMessage;
    hint "CAS Plane unable to comply";
    false
};
private _isBombing = "bomblauncher" in _weaponTypes;

//--- Play radio
[_caller,"CuratorModuleCAS"] call _sayMessage;

sleep _delay;

private _posATL = _targetATL;
private _pos = +_posATL;
_pos set [2,(_pos select 2) + getterrainheightasl _pos];

private _dis = 3000;
private _alt = 1000;
private _speed = 400 / 3.6;
private _duration = ([0,0] distance [_dis,_alt]) / _speed;

//--- Create plane
private _planePos = _pos getPos [_dis,_dir + 180];
_planePos set [2,(_pos select 2) + _alt];
private _planeSide = _side;
private _planeArray = [_planePos,_dir,_planeClass,_planeSide] call bis_fnc_spawnVehicle;
private _plane = _planeArray select 0;
_plane setposasl _planePos;
_plane move (_pos getPos [_dis,_dir]);
_plane disableai "move";
_plane disableai "target";
_plane disableai "autotarget";
_plane setcombatmode "blue";

private _vectorDir = [_planePos,_pos] call bis_fnc_vectorFromXtoY;
private _velocity = [_vectorDir,_speed] call bis_fnc_vectorMultiply;
_plane setvectordir _vectorDir;
[_plane,-90 + atan (_dis / _alt),0] call bis_fnc_setpitchbank;
private _vectorUp = vectorup _plane;

//--- Remove all other weapons;
private _currentWeapons = weapons _plane;
{
    if !(tolower ((_x call bis_fnc_itemType) select 1) in (_weaponTypes + ["countermeasureslauncher"])) then {
        _plane removeweapon _x;
    };
} foreach _currentWeapons;

//--- Cam shake
private _ehFired = _plane addeventhandler [
    "fired",
    {
        _this spawn {
            _plane = _this select 0;
            _plane removeeventhandler ["fired",_plane getvariable ["ehFired",-1]];
            _projectile = _this select 6;
            waituntil {isnull _projectile};
            [[0.005,4,[_plane getvariable ["target",objnull],200]],"bis_fnc_shakeCuratorCamera"] call bis_fnc_mp;
        };
    }
];
_plane setvariable ["ehFired",_ehFired];
_plane setvariable ["target",_targetATL];

//--- Approach
private _didFire = false;
private _fire = [] spawn {waituntil {false}};
private _fireNull = true;
private _time = time;
private _offset = if ({_x == "missilelauncher"} count _weaponTypes > 0) then {20} else {0};
waituntil {
    private _fireProgress = _plane getvariable ["fireProgress",0];

    //--- Set the plane approach vector
    _plane setVelocityTransformation [
        _planePos, [_pos select 0,_pos select 1,(_pos select 2) + _offset + _fireProgress * 12],
        _velocity, _velocity,
        _vectorDir,_vectorDir,
        _vectorUp, _vectorUp,
        (time - _time) / _duration
    ];
    _plane setvelocity velocity _plane;

    //--- Fire!
    if ((getposasl _plane) distance _pos < 1000 && _fireNull) then {

        //--- Create laser target
        private _targetType = if (_planeSide getfriend west > 0.6) then {"LaserTargetW"} else {"LaserTargetE"};
        private _target = ((_targetATL nearEntities [_targetType,250])) param [0,objnull];
        if (isnull _target) then {
            _target = createvehicle [_targetType,_targetATL,[],0,"none"];
        };
        _plane reveal lasertarget _target;
        _plane dowatch lasertarget _target;
        _plane dotarget lasertarget _target;

        _fireNull = false;
        terminate _fire;
        _fire = [_plane,_weapons,_target,_isBombing] spawn {
            private _plane = _this select 0;
            private _planeDriver = driver _plane;
            private _weapons = _this select 1;
            private _target = _this select 2;
            private _isBombing = _this select 3;
            private _duration = 3;
            private _time = time + _duration;
            waituntil {
                {
                    _planeDriver fireattarget [_target,(_x select 0)];
                } foreach _weapons;
                _plane setvariable ["fireProgress",(1 - ((_time - time) / _duration)) max 0 min 1];
                sleep 0.1;
                time > _time || _isBombing || isnull _plane 
            };
            sleep 1;
        };
        _didFire = true;
    };

    sleep 0.01;
    scriptdone _fire || isnull _plane
};
_plane setvelocity velocity _plane;
_plane flyinheight _alt;

//--- Fire CM
if ({_x == "bomblauncher"} count _weaponTypes == 0) then {
    for "_i" from 0 to 1 do {
        driver _plane forceweaponfire ["CMFlareLauncher","Burst"];
        _time = time + 1.1;
        waituntil {time > _time || isnull _plane};
    };
};

waituntil {_plane distance _pos > _dis || !alive _plane};

if (!alive _plane && !_didFire) then {[_caller,"SentUnitDestroyedHQCASBombing"] call _sayMessage;};

//--- Delete plane
if (alive _plane) then {
    private _group = group _plane;
    private _crew = crew _plane;
    deleteVehicleCrew _plane;
    deletevehicle _plane;
    deletegroup _group;
};
true