params ["_mortar", "_crew", "_supportName"];

sleep (random (300 - (27 * tierWar));


//Decrease number of rounds and time alive
private _sideAggression = if(side (group (_crew select 0)) == Occupants) then {aggressionOccupants} else {aggressionInvaders};
private _numberOfRound = 32;
private _timeAlive = 1800;

if(_sideAggression < 70) then
{
    if(_sideAggression < 30) then
    {
        _numberOfRound = 16;
        _timeAlive = 900;
    }
    else
    {
        if((30 + (random 40)) < _sideAggression) then
        {
            _numberOfRound = 16;
            _timeAlive = 900;
        };
    };
};
