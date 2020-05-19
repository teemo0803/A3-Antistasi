params ["_side", "_timerIndex", "_supportPos", "_supportName"];

/*  Sets up the data for the airstrike support

    Execution on: Server

    Scope: Internal

    Params:
        _side: SIDE : The side of which the airstrike should be send
        _timerIndex: NUMBER :  The number of the support timer
        _supportPos: POSITION : The position to which the airstrike should be carried out
        _supportName: STRING : The callsign of the support

    Returns:
        The name of the target marker, empty string if not created
*/

private _fileName = "SUP_airstrike";
private _airport = [_destination, _side] call A3A_fnc_findAirportForAirstrike;

if(_airport == "") exitWith
{
    [
        2,
        format ["No airport found for %1 support", _supportName],
        _fileName
    ] call A3A_fnc_log;
    ""
};

private _plane = if (_side == Occupants) then {vehNATOPlane} else {vehCSATPlane};
private _crewUnits = if(_side == Occupants) then {NATOCrew} else {CSATCrew};
private _bombType = "";

private _targetMarker = createMarker [format ["%1_coverage"], _supportPos];

_targetMarker setMarkerShape "ELLIPSE";
_targetMarker setMarkerBrush "Grid";
_targetMarker setMarkerSize [100, 25];

private _dir = _airport getDir _supportPos;
_targetMarker setMarkerDir _dir;

if(_side == Occupants) then
{
    _targetMarker setMarkerColor colorOccupants;
};
if(_side == Invaders) then
{
    _targetMarker setMarkerColor colorInvaders;
};

private _enemies = allUnits select
{
    (alive _x) &&
    {(side (group _x) != _side) && (side (group _x) != civilian) &&
    {((getPos _x) inArea _targetMarker)}}
};

if(isNil "napalmEnabled") then
{
    [
        1,
        "napalmEnabled does not containes a value, assuming false",
        _fileName
    ] call A3A_fnc_log;
    napalmEnabled = false;
};

private _bombType = if (napalmEnabled) then {"NAPALM"} else {"CLUSTER"};
{
    if (vehicle _x isKindOf "Tank") then
    {
        _bombType = "HE";
    }
    else
    {
        if (vehicle _x != _x) then
        {
            if !(vehicle _x isKindOf "StaticWeapon") then {_bombType = "CLUSTER"};
        };
    };
    if (_bombTypeX == "HE") exitWith {};
} forEach _enemies;

[
    2,
    format ["%1 will be an airstrike with bombType %2", _supportName, _bombType],
    _fileName
] call A3A_fnc_log;

//Blocks the airport from spawning in other planes while the support is waiting
//to avoid spawning planes in each other and sudden explosions
[_airport, 10] call A3A_fnc_addTimeForIdle;

private _spawnParams = [_airport] call A3A_fnc_getRunwayTakeoffForAirportMarker;

_spawnParams params ["_spawnPos", "_spawnDir"];
private _strikePlane = _plane createVehicle _spawnPos;
_strikePlane setDir _spawnDir;
[_strikePlane] spawn A3A_fnc_AIVEHinit;

private _strikeGroup = createGroup _side;
private _pilot = [_strikeGroup, _crewUnits, _spawnPos] call A3A_fnc_createUnit;
_pilot moveInDriver _strikePlane;

[_pilot] call A3A_fnc_NATOinit;


//
