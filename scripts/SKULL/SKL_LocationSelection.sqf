// SKL_SelectionLocation
//
// call on a player's client to select a location using map, bino/weapon aim, or at player's location
// returns a position

#define ITEM_TYPE_MAP   608
#define ITEM_TYPE_BINO  617

params [["_mapOnly",false]]; // only map allowed for choosing

private _locationType = "";
private _pos = [];

if (visibleMap || _mapOnly) then {_locationType = "MAP"} else {
if (cameraView == "GUNNER") then {_locationType = "BINO"} else {
if (_locationType isEqualTo "") then {
    SKL_LocSel = nil;
    private _binoOkay = (currentWeapon player != "" || {player getSlotItemName ITEM_TYPE_BINO != ""}); 
    private _mapOkay = player getSlotItemName ITEM_TYPE_MAP != "";
    private _menu = [
        ["Select location", false],
        ["On my location"     , [2], "", -5, [["expression", "SKL_LocSel = 'ONME'"]], "1", "1"],
        ["Use bino/weapon aim", [3], "", -5, [["expression", "SKL_LocSel = 'BINO'"]], "1", if (_binoOkay) then {"1"} else {"0"}],
        ["Use map"            , [4], "", -5, [["expression", "SKL_LocSel = 'MAP' "]], "1", if (_mapOkay ) then {"1"} else {"0"}],
        ["Cancel"             ,[16], "", -3, [["expression", ""]], "1", "1"]
    ];
    showCommandingMenu "#USER:_menu";
    waitUntil {commandingMenu == ""};
    if (!isNil "SKL_LocSel") then {_locationType = SKL_LocSel};
    SKL_LocSel = nil;
}}};
    
if !(_locationType isEqualTo "") then {
    switch (_locationType) do {
        case "ONME": {_pos = getPosATL player};
        case "BINO": {
            private _prevView = cameraView;
            private _bino = player getSlotItemName ITEM_TYPE_BINO;
            if (cameraView != "GUNNER" && {_bino != ""}) then {
                player selectWeapon _bino;
                sleep 2;
            };
            player switchCamera "GUNNER";
            private _menu = [
                ["Choose location", false],
                ["Select location"  , [2], "", -5, [["expression", "SKL_LocSel = terrainIntersectAtASL [eyePos player,eyePos player vectorAdd (player weaponDirection currentWeapon player vectorMultiply 3000)];"]], "1", "1"],
                ["Cancel"           ,[16], "", -3, [["expression", ""]], "1", "1"]
            ];
            showCommandingMenu "#USER:_menu";
            waitUntil {commandingMenu == "" || cameraView != "GUNNER"};
            if !(commandingMenu == "") then {showCommandingMenu ""};
            if (!isNil "SKL_LocSel" && {!(SKL_LocSel isEqualTo [0,0,0])}) then {_pos = SKL_LocSel};
            player switchCamera _prevView;
            SKL_LocSel = nil;
        };
        case "MAP": {
            SKL_LocSel = nil;                
            // get user selected position   
            private _ehId = addMissionEventHandler ["MapSingleClick", {
                params ["_units", "_pos", "_alt", "_shift"];
                if (!_alt && !_shift) then {
                    SKL_LocSel = _pos;
                    openMap false; 
                };
            }];         
            
            showMap true; 
            if (!visibleMap) then {openMap true};
            waitUntil {visibleMap};
            _hintTime = -100;
            while {visibleMap} do {
                if (time - _hintTime > 25) then {
                    _hintTime = time;
                    hintSilent "Click on map to choose location"; 
                };
            };
            removeMissionEventHandler ["MapSingleClick", _ehId];
            hintSilent "";
            if (isNil "SKL_LocSel") then {SKL_LocSel = []};
            _pos = SKL_LocSel;
        };
    };
};
_pos
