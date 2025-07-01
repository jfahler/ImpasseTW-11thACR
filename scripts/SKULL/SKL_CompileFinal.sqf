
   /*
    Modifed from code by Killzone_Kid

    Description:
    Recompiles existing code to final

    Parameter(s):
    0: STRING 
        - name of the variable containing code
        - variables containing no code are ignored

    1: NAMESPACE (Optional)
        - namespace of the variable containing code
        - if no namespace provided missionNamespace is assumed
        
    Returns: BOOL
        - true on success 
        - false on failure

    Example 1:
        myCode = {
            hint "This is my code!"
        };
        //recompile myCode to final
        ["myCode"] call BIS_fnc_compileFinal;
    
    Example 2:
        with uiNamespace do {
            myCode2 = {
                hint "This is my code too!"
            }
        };
        //recompile myCode2 to final and alert on success
        if (["myCode2",uiNamespace] call BIS_fnc_compileFinal) then {
            hint "Success!"
        };
*/
params [["_var","",[""]], ["_ns",missionNamespace,[missionNamespace]]];
private _code = _ns getVariable [_var, 0];
if (typeName _code != typeName {}) exitWith {false};
private _codestr = str _code;
_codestr = _codestr select [1,count _codestr - 2]; // remove begin and end parenthesizes 
_code = compileFinal _codestr;
_ns setVariable [_var, _code];
true