if (not isServer and hasInterface) exitWith {};

/*  Creates the bombs for airstrikes, should be started 100 meters before the actual bomb run


*/

params ["_plane", "_bombType", "_bombCount", "_bombRunLength"];
private _filename = "fn_airbomb";

private _ammo = "";
switch (_bombType) do
{
    case ("HE"):
    {
        _ammo = "Bo_Mk82";
    };
	case ("CLUSTER"):
    {
        _ammo = "BombCluster_03_Ammo_F";
	};
	case ("NAPALM"):
    {
		_ammo = "ammo_Bomb_SDB";
	};
	default
    {
		[1, format ["Invalid bomb type, given was %1", _bombType], _filename] call A3A_fnc_log;
	};
};

if(_ammo == "") exitWith {};

private _speedInMeters = (speed _plane) / 3.6;

private _metersPerBomb = _bombRunLength / _bombCount;
private _offset = _metersPerBomb / 2;

private _timeBetweenBombs = _metersPerBomb / _speedInMeters;
private _timeOffset = _offset / _speedInMeters;

sleep _timeOffset;

for "_i" from 1 to _bombCount do
{
	sleep _timeBetweenBombs;
	if (alive _plane) then
	{
        private _bombPos = (getPos _plane) vectorAdd [0, 0, -5];
		_bomb = _ammo createvehicle _bombPos;
		waituntil {!isnull _bomb};
		_bomb setDir (getDir _plane);
		_bomb setVelocity [0,0,-50];
		if (_bombType == "NAPALM") then
		{
			[_bomb] spawn
			{
				private _bomba = _this select 0;
				private _pos = [];
				while {!isNull _bomba} do
				{
					_pos = getPosASL _bomba;
					sleep 0.1;
				};
				[_pos] remoteExec  ["A3A_fnc_napalm"];
			};
		};
	};
};
//_bomba is used to track when napalm bombs hit the ground in order to call the napalm script on the correct position
