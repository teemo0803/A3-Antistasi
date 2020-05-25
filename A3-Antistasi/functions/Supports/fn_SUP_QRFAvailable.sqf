params ["_side", "_position"];

//Do a quick check for at least one available airport
private _index = airportsX findIf
{
    sidesX getVariable [_x, sideUnknown] == _side &&
    {(getMarkerPos _x) distance2D _position < distanceForAirAttack &&
    {[_x, true] call A3A_fnc_airportCanAttack}}
};
if(_index != -1) exitWith
{
    0;
};
//No airport found, search for bases
_index = outposts findIf
{
    sidesX getVariable [_x, sideUnknown] == _side &&
    {(getMarkerPos _x) distance2D _position < distanceForLandAttack &&
    {[_x, true] call A3A_fnc_airportCanAttack &&
    {[getMarkerPos _x, _position] call A3A_fnc_isTheSameIsland}}}
};
if(_index != -1) then
{
    0;
};

-1;
