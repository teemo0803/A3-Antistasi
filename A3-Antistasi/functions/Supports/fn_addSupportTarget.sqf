params ["_supportObject", "_targetParams"];

/*  Adds the given target command to the given support unit

    Execution on: Server

    Scope: Internal

    Params:
        _supportObject: STRING : The identifier of the support object
        _targetParams: ARRAY : The target parameter for the support
*/

//Wait until no targets are changing
if(supportTargetsChanging) then
{
    waitUntil {!supportTargetsChanging};
};
supportTargetsChanging = true;

private _targetList = server getVariable [format ["%1_targets", _supportObject], []];
_targetList pushBack [_targetParams, 0];
server setVariable [format ["%1_targets", _supportObject], _targetList, true];

supportTargetsChanging = false;

[
    3,
    format ["Added fire order %1 to %2s target list", _targetParams, _supportObject],
    "addSupportTarget"
] call A3A_fnc_log;
