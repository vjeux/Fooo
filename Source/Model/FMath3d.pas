unit FMath3d;

interface
uses
  Windows, Math, FOpenGL, FStructure;

type
  Matrix = PGLFLoat;

  // Quaternion
procedure NormalizeQuaternion(var q : Float4);
function QuaternionDotProduct(v0, v1 : Float4) : Float;
function QuaternionSlerp(v0, v1 : Float4; t : Float) : Float4;
function QuaternionToMatrix(q : Float4) : PGLFloat;
function TransformVector(v : Float3; m : PGLFloat) : Float3;

  // Interpolation
function Interpolate(t, t1, t2 : integer; v1, v2 : Float; interpolation : Dword) : Float;

  // Matrix
procedure AddMatrix(var m1 : PGLFloat; m2 : PGLFloat);
procedure MultMatrix(var m : PGLFLoat; v : Float);

const
  DefaultTranslation : Float3 = (0, 0, 0);
  DefaultRotation : Float3 = (1, 1, 1);
  DefaultScaling : Float3 = (1, 1, 1);
  DefaultColor : Float3 = (1, 1, 1);
  DefaultQuaternion : Float4 = (0, 0, 0, 1);
  IdentityMatrix : Matrix = (1, 0, 0, 0,
                             0, 1, 0, 0,
                             0, 0, 1, 0,
                             0, 0, 0, 1);
  NullMatrix : Matrix =     (0, 0, 0, 0,
                             0, 0, 0, 0,
                             0, 0, 0, 0,
                             0, 0, 0, 0);
                             
implementation

procedure NormalizeQuaternion(var q : Float4);
var
  i : integer;
  m : Float;
begin
  m := 0;
  for i := 0 to 3 do
    m := m + q[i] * q[i];
  m := Sqrt(m);
  for i := 0 to 3 do
    q[i] := q[i] / m;
end;

function QuaternionDotProduct(v0, v1 : Float4) : Float;
var
  i : integer;
begin
  Result := 0;
  for i := 0 to 3 do
    Result := Result + v0[i] * v1[i];
end;

function QuaternionSlerp(v0, v1 : Float4; t : Float) : Float4;
var
  halfTheta, sinHalfTheta, cosHalfTheta, ratioA, ratioB : Float;
  i : integer;
begin
  cosHalfTheta := QuaternionDotProduct(v0, v1);
  if (cosHalfTheta < 0) then begin
    for i := 0 to 3 do
      v1[i] := -v1[i];
    cosHalfTheta := -cosHalfTheta;
  end;

	if (abs(cosHalfTheta) >= 1.0) then begin
    Result := v0;
  end else begin
    halfTheta := ArcCos(cosHalfTheta);
    sinHalfTheta := sqrt(1.0 - sqr(cosHalfTheta));
    if (abs(sinHalfTheta) < 0.001) then begin
      for i := 0 to 3 do
        Result[i] := (v0[i] + v1[i]) / 2;
    end else begin
      ratioA := sin((1 - t) * halfTheta) / sinHalfTheta;
      ratioB := sin(t * halfTheta) / sinHalfTheta;
      for i := 0 to 3 do
        Result[i] := v0[i] * ratioA + v1[i] * ratioB;
    end;
  end;
end;

function Interpolate(t, t1, t2 : integer; v1, v2 : Float; interpolation : Dword) : Float;
begin
  // 0 : None    1 : Linear    2 : Hermite    3 : Bezier
  if t2 = t1 then
    Result := v1
  else
    Result := v1 + ( (t - t1) / (t2 - t1) )  * (v2 - v1);
end;

function QuaternionToMatrix(q : Float4) : PGLFloat;
var
	x, y, z, w, xs, ys, zs, xx, yy, yz, xy, xz, zz, x2, y2, z2 : single;
begin
	x := q[0];
	y := q[1];
	z := q[2];
	w := q[3];

	x2 := x * 2;
	y2 := y * 2;
	z2 := z * 2;

	xx := x * x2;
	xy := x * y2;
	xz := x * z2;
	xs := w * x2;

	yy := y * y2;
	yz := y * z2;
	ys := w * y2;

	zz := z * z2;
	zs := w * z2;

	Result[0]  := 1 - (yy + zz);
	Result[4]  :=     (xy - zs);
	Result[8]  :=     (xz + ys);

	Result[1]  :=     (xy + zs);
	Result[5]  := 1 - (xx + zz);
	Result[9]  :=     (yz - xs);

	Result[2]  :=     (xz - ys);
	Result[6]  :=     (yz + xs);
	Result[10] := 1 - (xx + yy);

	Result[3]  := 0;
	Result[7]  := 0;
	Result[11] := 0;

	Result[12] := 0;
	Result[13] := 0;
	Result[14] := 0;
	Result[15] := 1;
end;

function TransformVector(v : Float3; m : PGLFloat) : Float3;
begin
  Result[0] := v[0] * m[0] + v[1] * m[4] + v[2] * m[8]  + m[12];
  Result[1] := v[0] * m[1] + v[1] * m[5] + v[2] * m[9]  + m[13];
  Result[2] := v[0] * m[2] + v[1] * m[6] + v[2] * m[10] + m[14];
end;


procedure AddMatrix(var m1 : PGLFloat; m2 : PGLFloat);
begin
  m1[0] := m1[0] + m2[0];
  m1[1] := m1[1] + m2[1];
  m1[2] := m1[2] + m2[2];
  m1[4] := m1[4] + m2[4];
  m1[5] := m1[5] + m2[5];
  m1[6] := m1[6] + m2[6];
  m1[8] := m1[8] + m2[8];
  m1[9] := m1[9] + m2[9];
  m1[10] := m1[10] + m2[10];
  m1[12] := m1[12] + m2[12];
  m1[13] := m1[13] + m2[13];
  m1[14] := m1[14] + m2[14];
end;

procedure MultMatrix(var m : PGLFLoat; v : Float);
begin
  m[0] := m[0] * v;
  m[1] := m[1] * v;
  m[2] := m[2] * v;
  m[4] := m[4] * v;
  m[5] := m[5] * v;
  m[6] := m[6] * v;
  m[8] := m[8] * v;
  m[9] := m[9] * v;
  m[10] := m[10] * v;
  m[12] := m[12] * v;
  m[13] := m[13] * v;
  m[14] := m[14] * v;
end;

end.
