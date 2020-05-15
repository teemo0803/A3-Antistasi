params ["_side", "_supportType", "_supportPos", "_precision", "_revealCall"];

/*  Creates an support type that attacks areas

    Execution on: Server

    Scope: Internal

    Parameters:
        _side: SIDE: The side of the support unit
        _supportType: STRING : The type of support to send
        _supportPos: POSITION : The position which will be attack
        _precision: NUMBER : How precise the target info is
*/

private _fileName = "createArealSupport";

//Selecting the first available name of support type
private _supportIndex = 0;
private _supportName = format ["%1%2", _supportType, _supportIndex];
while {(server getVariable [format ["%1_targets", _supportName], -1]) isEqualType []} do
{
    _supportIndex = _supportIndex + 1;
    _supportName = format ["%1%2", _supportType, _supportIndex];
};

[
    3,
    format ["New support name will be %1", _supportName],
    _fileName
] call A3A_fnc_log;

private _supportMarker = createMarker [format ["%1_marker", _supportName], _supportPos];
_supportMarker setMarkerShape "ELLIPSE";
_supportMarker setMarkerSize [250, 250];
_supportMarker setMarkerBrush "Grid";
_supportMarker setMarkerAlpha 0.35;
_supportMarker setMarkerColor "ColorWEST";

switch (_supportType) do
{
    case ("QRF"):
    {
        ["RadioIntercepted", ["QRF incoming"]] remoteExec ["BIS_fnc_showNotification", teamPlayer];
        //_supportMarker setMarkerText "QRF";
    };
    case ("AIRSTRIKE"):
    {
        ["RadioIntercepted", ["Airstrike incoming"]] remoteExec ["BIS_fnc_showNotification", teamPlayer];
        //_supportMarker setMarkerText "Airstrike";
    };
    case ("MORTAR"):
    {
        ["RadioIntercepted", ["Mortar incoming"]] remoteExec ["BIS_fnc_showNotification", teamPlayer];
        //_supportMarker setMarkerText "Mortar";
    };
};

server setVariable [format ["%1_targets", _supportName], [[_supportPos, _precision], _revealCall], true];
if (_side == Occupants) then
{
    occupantsSupports pushBack [_supportType, _supportMarker, _supportName];
};
if(_side == Invaders) then
{
    invadersSupports pushBack [_supportType, _supportMarker, _supportName];
};
