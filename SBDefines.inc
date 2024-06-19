{$IFDEF FPC}
  {$DEFINE XE2}
{$ELSE}

{$IF compilerversion = 20}
  {$DEFINE DELPHI2009}
{$IFEND}

{$IF compilerversion >= 20}
  {$DEFINE DELPHI2009_UP}
{$IFEND}


{$IF compilerversion >= 23}
  {$DEFINE XE2}
  {$DEFINE XE2_UP}
{$IFEND}
{$IF compilerversion >= 24}
  {$DEFINE XE3}
  {$DEFINE XE3_UP}
{$IFEND}
{$IF compilerversion >= 25}
  {$DEFINE XE4}
{$IFEND}
{$IF compilerversion >= 26}
  {$DEFINE XE5}
  {$DEFINE XE5_UP}
{$IFEND}
{$IF compilerversion >= 27}
  {$DEFINE XE6}
{$IFEND}
{$IF compilerversion >= 28}
  {$DEFINE XE7}
{$IFEND}
{$IF compilerversion >= 29}
  {$DEFINE XE8}
  {$DEFINE XE8_UP}
{$IFEND}
{$IF compilerversion >= 30} // Delphi 10.0
  {$DEFINE XE9_UP}
  {$DEFINE DX100_UP}
{$IFEND}
{$IF compilerversion >= 31}  // Delphi 10.1
  {$DEFINE DX101_UP}
{$IFEND}
{$IF compilerversion >= 32}  // Delphi 10.2
  {$DEFINE DX102_UP}
{$IFEND}
{$IF compilerversion >= 34} // Delphi 10.4
  {$DEFINE DX104_UP}
{$IFEND}
{$IF compilerversion >= 35} // Delphi 11.0
  {$DEFINE DX110_UP}
{$IFEND}
{$IF compilerversion >= 36} // Delphi 12.0
  {$DEFINE DX120_UP}
{$IFEND}



{$IF defined(MACOS) and not defined(IOS)}
  {$DEFINE VCL_MAC}
{$IFEND}

{$ENDIF}
