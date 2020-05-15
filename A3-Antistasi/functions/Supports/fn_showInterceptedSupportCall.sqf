params ["_reveal", "_position", "_side", "_supportType", "_marker", "_textMarker"];

/*  Shows the intercepted radio message to the players

    Execution on: Server

    Scope: Internal

    Parameters:
        _reveal: NUMBER : Decides how much of the info will be revealed
        _position: POSITION : The position where the support is called to
        _side: SIDE : The side which called in the support
        _supportType: NAME : The name of the support (not the callsign!!)
        _marker: MARKER : The marker which covers the area of the attack
        _textMarker: MARKER : The marker which is holding the text of the support

    Returns:
        Nothing
*/

//If you have found a key before, you get the full message if it is somewhere around your HQ
if(_position distance2D (getMarkerPos "Synd_HQ") < distanceMission) then
{
    if(_side == Occupants) then
    {
        if(occupantsRadioKeys > 0) then
        {
            occupantsRadioKeys = occupantsRadioKeys - 1;
            publicVariable "occupantsRadioKeys";
            _reveal = 1;
        };
    }
    else
    {
        if(occupantsRadioKeys > 0) then
        {
            invaderRadioKeys = invaderRadioKeys - 1;
            publicVariable "occupantsRadioKeys";
            _reveal = 1;
        };
    };
};

//Nothing will be revealed
if(_reveal <= 0.1) exitWith {};

private _text = "";
private _sideName = if(_side == Occupants) then {nameOccupants} else {nameInvaders};
if (_reveal <= 0.5) then
{
    //Side and call is reveal
    _text = format ["%1 called in for an unknown support", _sideName];
}
else
{
    if(_reveal <= 0.8) then
    {
        //Side, type and call is revealed
        _text = format ["%1 called in %2 support", _sideName, _supportType];
    }
    else
    {
        //Side, type, call and marker revealed
        _text = format ["%1 called in %2 support at the marked position", _sideName, _supportType];
        _marker setMarkerAlpha 0.35;
        _textMarker setMarkerAlpha 1;
    };
};

//Broadcast message to nearby players
private _nearbyPlayers = allPlayers select {(_x distance2D _position) <= 2000};
["RadioIntercepted", [_text]] remoteExec ["BIS_fnc_showNotification",_nearbyPlayers];
