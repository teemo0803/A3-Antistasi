

_landPos = [_posDestination,_pos,false,_landPosBlacklist] call A3A_fnc_findSafeRoadToUnload;

switch (true) do
{
    case (_vehicle isKindOf "APC"):
    {
        {_x disableAI "MINEDETECTION"} forEach (units _groupVeh);
        (units _groupX) joinSilent _groupVeh;
        deleteGroup _groupX;
        _groupVeh spawn A3A_fnc_attackDrillAI;
        //_groups pushBack _groupX;
        [_base,_landPos,_groupVeh] call A3A_fnc_WPCreate;
        _Vwp0 = (wayPoints _groupVeh) select 0;
        _Vwp0 setWaypointBehaviour "SAFE";
        _Vwp0 = _groupVeh addWaypoint [_landPos,count (wayPoints _groupVeh)];
        _Vwp0 setWaypointType "TR UNLOAD";
        //_Vwp0 setWaypointStatements ["true", "(group this) spawn A3A_fnc_attackDrillAI"];
        //_Vwp0 setWaypointStatements ["true", "[vehicle this] call A3A_fnc_smokeCoverAuto"];
        _Vwp1 = _groupVeh addWaypoint [_posDestination, count (wayPoints _groupVeh)];
        _Vwp1 setWaypointType "SAD";
        _Vwp1 setWaypointStatements ["true","{if (side _x != side this) then {this reveal [_x,4]}} forEach allUnits"];
        _Vwp1 setWaypointBehaviour "COMBAT";
        [_veh,"APC"] spawn A3A_fnc_inmuneConvoy;
        _veh allowCrewInImmobile true;
    };
    case (_vehicle isKindOf "Tank"):
    {
        {_x disableAI "MINEDETECTION"} forEach (units _groupVeh);
        [_base,_posDestination,_groupVeh] call A3A_fnc_WPCreate;
        _Vwp0 = (wayPoints _groupVeh) select 0;
        _Vwp0 setWaypointBehaviour "SAFE";
        _Vwp0 = _groupVeh addWaypoint [_posDestination, count (waypoints _groupVeh)];
        [_veh,"Tank"] spawn A3A_fnc_inmuneConvoy;
        _Vwp0 setWaypointType "SAD";
        _Vwp0 setWaypointBehaviour "AWARE";
        _Vwp0 setWaypointStatements ["true","{if (side _x != side this) then {this reveal [_x,4]}} forEach allUnits"];
        _veh allowCrewInImmobile true;
    };
    case (_vehicle isKindOf "Plane"):
    {

    };
    case (_vehicle isKindOf "Helicopter" && {(typeof _vehicle) in vehTransportAir}):
    {
        //Transport helicopter
        _landPos = [_posDestination, 300, 550, 10, 0, 0.20, 0,[],[[0,0,0],[0,0,0]]] call BIS_fnc_findSafePos;
        if !(_landPos isEqualTo [0,0,0]) then
        {
            _landPos set [2, 0];
            _pad = createVehicle ["Land_HelipadEmpty_F", _landpos, [], 0, "NONE"];
            _vehiclesX pushBack _pad;
            _wp0 = _groupVeh addWaypoint [_landpos, 0];
            _wp0 setWaypointType "TR UNLOAD";
            _wp0 setWaypointStatements ["true", "(vehicle this) land 'GET OUT';[vehicle this] call A3A_fnc_smokeCoverAuto"];
            _wp0 setWaypointBehaviour "CARELESS";
            _wp3 = _groupX addWaypoint [_landpos, 0];
            _wp3 setWaypointType "GETOUT";
            _wp3 setWaypointStatements ["true", "(group this) spawn A3A_fnc_attackDrillAI"];
            _wp0 synchronizeWaypoint [_wp3];
            _wp4 = _groupX addWaypoint [_posDestination, 1];
            _wp4 setWaypointType "MOVE";
            _wp4 setWaypointStatements ["true","{if (side _x != side this) then {this reveal [_x,4]}} forEach allUnits"];
            _wp2 = _groupVeh addWaypoint [_posOrigin, 1];
            _wp2 setWaypointType "MOVE";
            _wp2 setWaypointStatements ["true", "deleteVehicle (vehicle this); {deleteVehicle _x} forEach thisList"];
            [_groupVeh,1] setWaypointBehaviour "AWARE";
        }
        else
        {
            if (_typeVehX in vehFastRope) then
            {
                [_veh,_groupX,_posDestination,_posOrigin,_groupVeh] spawn A3A_fnc_fastrope;
            }
            else
            {
                [_veh,_groupX,_destination,_side] spawn A3A_fnc_airdrop;
            };
        };
    };
    case (_vehicle isKindOf "Helicopter" && {!(typeof _vehicle) in vehTransportAir}):
    {
        //Attack helicopter
        _Hwp0 = _groupVeh addWaypoint [_posDestination, 0];
        _Hwp0 setWaypointBehaviour "AWARE";
        _Hwp0 setWaypointType "SAD";
        //[_veh,"Air Attack"] spawn A3A_fnc_inmuneConvoy;
    };
    case ((typeof _vehicle) in vehTransportAir && {!(_vehicle isKindOf "Helicopter")}):
    {
        //Dropship with para units
        [_veh,_groupX,_destination,_side] spawn A3A_fnc_airdrop;
    };
    default
    {
        (units _groupX) joinSilent _groupVeh;
        deleteGroup _groupX;
        _groupVeh spawn A3A_fnc_attackDrillAI;
        if (count units _groupVeh > 1) then {_groupVeh selectLeader (units _groupVeh select 1)};
        [_base,_landPos,_groupVeh] call A3A_fnc_WPCreate;
        _Vwp0 = (wayPoints _groupVeh) select 0;
        _Vwp0 setWaypointBehaviour "SAFE";
        /*
        _Vwp0 = (wayPoints _groupVeh) select ((count wayPoints _groupVeh) - 1);
        _Vwp0 setWaypointType "GETOUT";
        */
        _Vwp0 = _groupVeh addWaypoint [_landPos, count (wayPoints _groupVeh)];
        _Vwp0 setWaypointType "GETOUT";
        //_Vwp0 setWaypointStatements ["true", "(group this) spawn A3A_fnc_attackDrillAI"];
        _Vwp1 = _groupVeh addWaypoint [_posDestination, count (wayPoints _groupVeh)];
        _Vwp1 setWaypointStatements ["true","{if (side _x != side this) then {this reveal [_x,4]}} forEach allUnits"];
        if (_isMarker) then
            {

            if ((count (garrison getVariable [_destination, []])) < 4) then
                {
                _Vwp1 setWaypointType "MOVE";
                _Vwp1 setWaypointBehaviour "AWARE";
            }
            else
            {
                _Vwp1 setWaypointType "SAD";
                _Vwp1 setWaypointBehaviour "COMBAT";
            };
        }
        else
        {
            _Vwp1 setWaypointType "SAD";
            _Vwp1 setWaypointBehaviour "COMBAT";
        };
        [_veh,"Inf Truck."] spawn A3A_fnc_inmuneConvoy;
    };
};
