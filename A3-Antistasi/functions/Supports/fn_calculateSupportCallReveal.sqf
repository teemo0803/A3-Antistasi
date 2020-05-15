params ["_pos", "_side"];

/*  Calculates the reveal chance for the call from the given position and side

    Execution on: Server

    Scope: Internal

    Params:
        _pos: POSITION : The position from where the call originates
        _side: SIDE : The side which is doing the call

    Returns:
        _result: NUMBER : A number between 0 and 1
*/

private _result = 0;

//Hard value is the reveal you always get, softValue is a chance to get this amount of reveal
private _hardValue = 0;
private _softValue = 20;

if(_pos distance2D (getMarkerPos "Synd_HQ") < 1000) then
{
    _hardValue = 20;
    _softValue = _softValue + 20;
};
if(_pos distance2D (getMarkerPos "Synd_HQ") < 2500) then
{
    _softValue = _softValue + 20;
};

private _nearestAirport = [airportsX, _pos] call BIS_fnc_nearestPosition;
if(sidesX getVariable [_nearestAirport, sideUnknown] == teamPlayer) then
{
    _softValue = _softValue + 20;
    if((getMarkerPos _nearestAirport) distance2D _pos < 1500) then
    {
        _hardValue = _hardValue + 10;
        _softValue = _softValue + 10;
    };
};

private _nearestAntenna = [antennas, _pos] call BIS_fnc_nearestPosition;
private _antennaMarker = [outposts + airportsX, _pos] call BIS_fnc_nearestPosition;
if(sidesX getVariable [_antennaMarker, sideUnknown] == teamPlayer) then
{
    _hardValue = _hardValue + 10;
    _softValue = _softValue + 20;
    if((getMarkerPos _antennaMarker) distance2D _pos < 2000) then
    {
        _hardValue = _hardValue + 20;
        _softValue = _softValue + 10;
    };
};

_result = _hardValue + (round (random _softValue));
_result = (_result / 100) min 1;

_result;
