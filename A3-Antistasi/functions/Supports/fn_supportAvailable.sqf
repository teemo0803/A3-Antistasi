params ["_supportType", "_side", "_position"];

/*  Checks if the given support is available for use

    Execution on: Server

    Scope: External

    Params:
        _supportType: STRING : The type of support that should be checked
        _side: SIDE : The side for which the availability should be checked

    Returns:
        -1 if not available, the index of the timer otherwise
*/

private _timerIndex = -1;
switch (_supportType) do
{
    case ("QRF"):
    {
        //Do a quick check for at least one available airport
        private _index = airportsX findIf
        {
            sidesX getVariable [_x, sideUnknown] == _side &&
            {(getMarkerPos _x) distance2D _position < distanceForAirAttack &&
            {[_x, true] call A3A_fnc_airportCanAttack}}
        };
        if(_index != -1) exitWith
        {
            _timerIndex = -1;
        };
        //No airport found, search for bases
        private _index = outposts findIf
        {
            sidesX getVariable [_x, sideUnknown] == _side &&
            {(getMarkerPos _x) distance2D _position < distanceForLandAttack &&
            {[_x, true] call A3A_fnc_airportCanAttack &&
            {[getMarkerPos _x, _position] call A3A_fnc_isTheSameIsland}}}
        };
        if(_index != -1) then
        {
            _timerIndex = -1;
        };
    };
    case ("AIRSTRIKE"):
    {
        _timerIndex = -1;
        //_timerIndex = [_side] call A3A_fnc_SUP_airstrikeAvailable;
    };
    case ("MORTAR"):
    {
        _timerIndex = [_side] call A3A_fnc_SUP_mortarAvailable;
    };
    default
    {
        //If unknown, set not available
        _timerIndex = -1;
    };
};

[
    3,
    format ["Support check for %1 returns %2", _supportType, _timerIndex],
    "supportAvailable"
] call A3A_fnc_log;

_timerIndex;
