params ["_side", "_targetArea"];

/*  This function tells all friendly units to move out of the target area of an areal support

    Execution on: Server

    Scope: Internal

    Params:
        _side: SIDE : The side of the support
        _targetArea: MARKER : The target marker of the support

    Returns:
        Nothing
*/

private _targetPoint = getMarkerPos _targetArea;
private _targetSize = getMarkerSize _targetArea;
_targetSize = (_targetSize select 0) max (_targetSize select 1);

{
    if((_side == side (group _x)) && {_x inArea _targetArea}) then
    {
        private _dir = _targetPoint getDir (getPos _x);
        private _pos = _x getPos [_dir, (_targetSize + 10 + random 25)];
        _x doMove _pos;
    };
} forEach allUnits;
