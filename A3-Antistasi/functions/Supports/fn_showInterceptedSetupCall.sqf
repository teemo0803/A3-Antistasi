params ["_reveal", "_side", "_supportType"];

/*  Shows the intercepted radio setup message to the players

    Execution on: Server

    Scope: Internal

    Parameters:
        _reveal: NUMBER : Decides how much of the info will be revealed
        _side: SIDE : The side which called in the support
        _supportType: NAME : The name of the support (not the callsign!!)

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
if (_reveal <= 0.7) then
{
    //Side and setup is revealed
    _text = format ["%1 is setting up an unknown support", _sideName];
}
else
{
    //Side, type and setup is revealed
    _text = format ["%1 is setting up %2 support", _sideName, _supportType];
};

//Broadcast message to nearby players
private _nearbyPlayers = allPlayers select {(_x distance2D _position) <= 2000};
["RadioIntercepted", [_text]] remoteExec ["BIS_fnc_showNotification",_nearbyPlayers];
