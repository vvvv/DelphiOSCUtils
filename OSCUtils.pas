//////project name
//OSCUtils

//////description
//Utility library to encode/decode osc-packets
//inspired by original OSC reference implementation (OSC-Kit)
//and OSC.Net library as shipped with the TUIO-CSharp sample
//from http://reactable.iua.upf.edu/?software

//////licence
//GNU Lesser General Public License (LGPL)
//english: http://www.gnu.org/licenses/lgpl.html
//german: http://www.gnu.de/lgpl-ger.html

//////language/ide
//delphi

//////initial author
//joreg -> joreg@vvvv.org

//additions for FreePascal
//simon -> simonmoscrop@googlemail.com

//////instructions
////for use with FreePascal
//define: FPC

////encoding a single message:
//first create a message: msg := TOSCMessage.Create(address)
//then call msg.AddFloat(value)... to add any number of arguments
//with msg.ToOSCBytes you get the TBytes you can send via an indy10 TidUDPClient.SendBuffer

////encoding a bundle:
//first create a bundle: bundle := TOSCBundle.Create(nil)
//then add any number of packets (i.e. message, bundle) via bundle.Add(packet)
//with bundle.ToOSCBytes you get the TBytes you can send via an indy10 TidUDPClient.SendBuffer

////decoding a string
//use TOSCPacket.Unpack(bytes, Length(bytes)) to create
//TOSCPackets of your osc-bytes (those can be either bundles or single
//messages. if you want to decode several packets at once you can create
//a container bundle first and add the packets you create like this.
//then use msg := FPacket.MatchAddress(address) to find a message with the
//according address in your packet-structure.
//before you now can access the arguments and typetags of a message you have
//to call msg.Decode
//voila.


unit OSCUtils;

interface

uses Classes, Contnrs, SysUtils, System.Generics.Collections;

type
  TOSCPacket = class;
  TOSCMessage = class;

  TOSCPacket = class (TObject)
  private
  protected
    FBytes: TBytes;
    function MatchBrackets(pMessage, pAddress: PChar): Boolean;
    function MatchList(pMessage, pAddress: PChar): Boolean;
    function MatchPattern(pMessage, pAddress: PChar): Boolean;
  public
    constructor Create(Bytes: TBytes);
    function MatchAddress(Address: String): TOSCMessage; virtual; abstract;
    function ToOSCBytes: TBytes; virtual; abstract;
    procedure Unmatch; virtual; abstract;
    class function Unpack(Bytes: TBytes; Count: Integer): TOSCPacket; overload;
    class function Unpack(Bytes: TBytes; Offset, Count: Integer; TimeTag: Extended
        = 0): TOSCPacket; overload; virtual;
  end;

  TOSCMessage = class(TOSCPacket)
  private
    FAddress: string;
    FArguments: TList<TBytes>;
    FIsDecoded: Boolean;
    FMatched: Boolean;
    FTimeTag: Extended;
    FTypeTagOffset: Integer;
    FTypeTags: string;
    function GetArgument(Index: Integer): TBytes;
    function GetArgumentAsFloat(Index: Integer): Single;
    function GetArgumentAsInt(Index: Integer): Integer;
    function GetArgumentCount: Integer;
    function GetTypeTag(Index: Integer): string;
  public
    constructor Create(Address: string); overload;
    constructor Create(Bytes: TBytes); overload;
    destructor Destroy; override;
    function AddAsBytes(const TypeTag: Char; const Value: String; const fs:
        TFormatSettings): HResult;
    procedure AddFloat(Value: Single);
    procedure AddInteger(Value: Integer);
    procedure AddString(Value: String);
    procedure Decode;
    function MatchAddress(Address: String): TOSCMessage; override;
    function ToOSCBytes: TBytes; override;
    procedure Unmatch; override;
    class function Unpack(Bytes: TBytes; PacketOffset, Count: Integer; TimeTag:
        Extended = 0): TOSCPacket; overload; override;
    property Address: string read FAddress write FAddress;
    property Argument[Index: Integer]: TBytes read GetArgument;
    property ArgumentAsFloat[Index: Integer]: Single read GetArgumentAsFloat;
    property ArgumentAsInt[Index: Integer]: Integer read GetArgumentAsInt;
    property ArgumentCount: Integer read GetArgumentCount;
    property IsDecoded: Boolean read FIsDecoded write FIsDecoded;
    property Matched: Boolean read FMatched write FMatched;
    property TimeTag: Extended read FTimeTag write FTimeTag;
    property TypeTag[Index: Integer]: String read GetTypeTag;
    property TypeTagOffset: Integer read FTypeTagOffset write FTypeTagOffset;
  end;

  TOSCBundle = class(TOSCPacket)
  private
    FPackets: TObjectList;
  public
    constructor Create(Bytes: TBytes);
    destructor Destroy; override;
    procedure Add(const Packet: TOSCPacket);
    function MatchAddress(Address: String): TOSCMessage; override;
    function ToOSCBytes: TBytes; override;
    procedure Unmatch; override;
    class function Unpack(Bytes: TBytes; PacketOffset, Count: Integer; TimeTag:
        Extended = 0): TOSCPacket; overload; override;
  end;

function MakeOSCFloat(value: Single): TBytes;

function MakeOSCInt(value: Integer): TBytes;

function MakeOSCString(value: String): TBytes;

function UnpackInt(Bytes: TBytes; var Offset: Integer): TBytes;

function UnpackString(Bytes: TBytes; var Offset: Integer): TBytes;

function UnpackFloat(Bytes: TBytes; var Offset: Integer): TBytes;

function UnpackAndReturnInt(Bytes: TBytes; var Offset: Integer): Integer;

function UnpackAndReturnFloat(Bytes: TBytes; var Offset: Integer): Single;

  const
    OSC_OK = 0;
    OSC_UNRECOGNIZED_TYPETAG = 1;
    OSC_CONVERT_ERROR = 2;


implementation

uses
  Math, IdGlobal {$IFNDEF FPC}, WinSock {$ENDIF};

function MakeOSCFloat(value: Single): TBytes;
var
  intg: Integer;
begin
  intg := PInteger(@value)^;

  {$IFDEF FPC}
  intg := BEtoN(intg);
  {$ELSE}
  intg := htonl(intg);
  {$ENDIF}

  Result := TBytes(IdGlobal.RawToBytes(intg, SizeOf(intg)));
end;

function MakeOSCInt(value: Integer): TBytes;
begin
  {$IFDEF FPC}
  value := BEtoN(value);
  {$ELSE}
  value := htonl(value);
  {$ENDIF}
  Result := TBytes(IdGlobal.RawToBytes(value, SizeOf(value)));
end;

function MakeOSCString(value: String): TBytes;
var i, ln: Integer;
begin
  ln := TEncoding.UTF8.GetByteCount(value);
  ln := ln + (4 - ln mod 4);
  SetLength(Result, ln);
  ln := TEncoding.UTF8.GetBytes(value, 1, Length(value), Result, 0);
  for i := ln to High(Result) do
    result[i] := 0;
end;

function UnpackInt(Bytes: TBytes; var Offset: Integer): TBytes;
var
  i: Integer;
begin
  SetLength(Result, SizeOf(Integer));
  // Copy bytes and change byte order
  for i := 0 to High(Result) do
    Result[i] := Bytes[Offset + High(Result) - i];
  Inc(Offset, SizeOf(Integer));
end;

function UnpackString(Bytes: TBytes; var Offset: Integer): TBytes;
var
  off: Integer;
begin
  // Strings are null terminated. Find position of null.
  off := Offset;
  while (off < Length(Bytes)) and (Bytes[off] <> 0) do
    Inc(off);
  // Retrieve the string.
  SetLength(Result, off - Offset);
  Move(Bytes[Offset], Result[0], Length(Result));
  // Increase the offset by a multiple of 4.
  Offset := off + (4 - off mod 4);
end;

function UnpackFloat(Bytes: TBytes; var Offset: Integer): TBytes;
var
  //value: Integer;
  i: Integer;
begin
  SetLength(Result, SizeOf(Single));
  // Copy bytes and change byte order
  for i := 0 to High(Result) do
  begin
    Result[i] := Bytes[Offset + High(Result) - i];
  end;
  Inc(Offset, SizeOf(Single));
end;

function UnpackAndReturnInt(Bytes: TBytes; var Offset: Integer): Integer;
var
  resultBytes: TBytes;
begin
  resultBytes := UnpackInt(Bytes, Offset);
  Result := PInteger(Pointer(resultBytes))^;
end;

function UnpackAndReturnFloat(Bytes: TBytes; var Offset: Integer): Single;
var
  resultBytes: TBytes;
begin
  resultBytes := UnpackFloat(Bytes, Offset);
  Result := PSingle(Pointer(resultBytes))^;
end;


constructor TOSCMessage.Create(Address: string);
begin
  FAddress := Address;
  Create(nil);
end;

constructor TOSCMessage.Create(Bytes: TBytes);
begin
  inherited;

  FTypeTags := ',';
  FArguments := TList<TBytes>.Create;
  FIsDecoded := false;
end;

destructor TOSCMessage.Destroy;
begin
  FArguments.Free;
  inherited;
end;

function TOSCMessage.AddAsBytes(const TypeTag: Char; const Value: String; const
    fs: TFormatSettings): HResult;
begin
  Result := OSC_OK;

  try
    if TypeTag = 'f' then
      AddFloat(StrToFloat(Value, fs))
    else if TypeTag = 'i' then
      AddInteger(StrToInt(Value))
    else if TypeTag = 's' then
      AddString(Value)
    else
      Result := OSC_UNRECOGNIZED_TYPETAG;
  except on EConvertError do
    Result := OSC_CONVERT_ERROR;
  end;
end;

procedure TOSCMessage.AddFloat(Value: Single);
begin
  FTypeTags := FTypeTags + 'f';
  FArguments.Add(MakeOSCFloat(Value));
end;

procedure TOSCMessage.AddInteger(Value: Integer);
begin
  FTypeTags := FTypeTags + 'i';
  FArguments.Add(MakeOSCInt(Value));
end;

procedure TOSCMessage.AddString(Value: String);
begin
  FTypeTags := FTypeTags + 's';
  FArguments.Add(MakeOSCString(Value));
end;

procedure TOSCMessage.Decode;
var
  i, offset: Integer;
begin
  if FIsDecoded then
    exit;

  offset := FTypeTagOffset;
  FTypeTags := TEncoding.ASCII.GetString(UnpackString(FBytes, offset));

  for i := 1 to Length(FTypeTags) - 1 do
  begin
    if FTypeTags[i+1] = 's' then
      FArguments.Add(UnpackString(FBytes, offset))
    else if FTypeTags[i+1] = 'i' then
      FArguments.Add(UnpackInt(FBytes, offset))
    else if FTypeTags[i+1] = 'f' then
      FArguments.Add(UnpackFloat(FBytes, offset));
  end;

  FIsDecoded := true;
end;

function TOSCMessage.GetArgument(Index: Integer): TBytes;
begin
  Result := FArguments[Index];
end;

function TOSCMessage.GetArgumentAsFloat(Index: Integer): Single;
begin
  Result := PSingle(Pointer(FArguments[Index]))^;
end;

function TOSCMessage.GetArgumentAsInt(Index: Integer): Integer;
begin
  Result := PInteger(Pointer(FArguments[Index]))^;
end;

function TOSCMessage.GetArgumentCount: Integer;
begin
  Result := FArguments.Count;
end;

function TOSCMessage.GetTypeTag(Index: Integer): string;
begin
  Result := FTypeTags[Index + 2];
end;

function TOSCMessage.MatchAddress(Address: String): TOSCMessage;
begin
  if not FMatched
  and MatchPattern(PChar(FAddress), PChar(Address)) then
  begin
    FMatched := true;
    Result := Self
  end
  else
    Result := nil;
end;

function TOSCMessage.ToOSCBytes: TBytes;
var
  i: Integer;
  resultList: TList<Byte>;
begin
  resultList := TList<Byte>.Create;
  resultList.AddRange(MakeOSCString(FAddress));
  resultList.AddRange(MakeOSCString(FTypeTags));

  for i := 0 to FArguments.Count - 1 do
    resultList.AddRange(FArguments[i]);
  Result := resultList.ToArray();
  resultList.Free;
end;

procedure TOSCMessage.Unmatch;
begin
  FMatched := false;
end;

class function TOSCMessage.Unpack(Bytes: TBytes; PacketOffset, Count: Integer;
    TimeTag: Extended = 0): TOSCPacket;
begin
  Result := TOSCMessage.Create(Bytes);
  //for now decode address only
  (Result as TOSCMessage).Address := TEncoding.ASCII.GetString(UnpackString(Bytes, PacketOffset));
  (Result as TOSCMessage).TimeTag := TimeTag;

  //save offset for later decoding on demand
 (Result as TOSCMessage).TypeTagOffset := PacketOffset;
 (Result as TOSCMessage).IsDecoded := false;
end;

constructor TOSCBundle.Create(Bytes: TBytes);
begin
  inherited;
  FPackets := TObjectList.Create;
  FPackets.OwnsObjects := true;
end;

destructor TOSCBundle.Destroy;
begin
  FPackets.Free;
  inherited;
end;

procedure TOSCBundle.Add(const Packet: TOSCPacket);
begin
  FPackets.Add(Packet);
end;

function TOSCBundle.MatchAddress(Address: String): TOSCMessage;
var
  i: Integer;
begin
  Result := nil;

  for i := 0 to FPackets.Count - 1 do
  begin
    Result := (FPackets[i] as TOSCPacket).MatchAddress(Address);
    if Assigned(Result) then
      break;
  end;
end;

function TOSCBundle.ToOSCBytes: TBytes;
var
  i: Integer;
  packet: TBytes;
  resultList: TList<Byte>;
begin
  resultList := TList<Byte>.Create;
  resultList.AddRange(MakeOSCString('#bundle'));
  resultList.AddRange(TEncoding.UTF8.GetBytes(#0#0#0#0#0#0#0#1)); //immediately

  for i := 0 to FPackets.Count - 1 do
  begin
    packet := (FPackets[i] as TOSCPacket).ToOSCBytes;
    resultList.AddRange(MakeOSCInt(Length(packet)));
    resultList.AddRange(packet);
  end;

  Result := resultList.ToArray();
  resultList.Free;
end;

procedure TOSCBundle.Unmatch;
var
  i: Integer;
begin
  for i := 0 to FPackets.Count - 1 do
    (FPackets[i] as TOSCPacket).UnMatch;
end;

class function TOSCBundle.Unpack(Bytes: TBytes; PacketOffset, Count: Integer;
    TimeTag: Extended = 0): TOSCPacket;
var
  packetLength: Integer;
  tt1, tt2: Cardinal;
begin
  Result := TOSCBundle.Create(Bytes);

  //advance the '#bundle' string
  UnpackString(Bytes, PacketOffset);

  //advance the timestamp
  tt1 := Cardinal(UnpackAndReturnInt(Bytes, PacketOffset));
  tt2 := Cardinal(UnpackAndReturnInt(Bytes, PacketOffset));

  TimeTag := tt1 + tt2 / power(2, 32);

  while PacketOffset < Count do
  begin
    packetLength := UnpackAndReturnInt(Bytes, PacketOffset);
    //note: PacketOffset is always from the very beginning of Bytes!
    //not the beginning of the current packet.
    (Result as TOSCBundle).Add(TOSCPacket.Unpack(Bytes, PacketOffset, PacketOffset + packetLength, TimeTag));
    Inc(PacketOffset, packetLength);
  end;
end;

constructor TOSCPacket.Create(Bytes: TBytes);
begin
  FBytes := Bytes;
end;

// we know that pattern[0] == '[' and test[0] != 0 */
function TOSCPacket.MatchBrackets(pMessage, pAddress: PChar): Boolean;
var
  negated: Boolean;
  p, p1, p2: PChar;
begin
  p := pMessage;
  Result := false;
  negated := false;

  Inc(pMessage);
  if pMessage^ = #0 then
  begin
    //LogWarningFMT('Unterminated [ in message: %s', [FInput[0]]);
    Dec(pMessage);
    exit;
  end;

  if pMessage^ = '!' then
  begin
    negated := true;
    Inc(p);
  end;

  Dec(pMessage);

  Result := negated;

  while p^ <> ']' do
  begin
    if p^ = #0 then
    begin
      //LogWarningFMT('Unterminated [ in message: %s', [FInput[0]]);
      exit;
    end;

    p1 := p + 1; // sizeOf(PChar);
    p2 := p1 + 1; //sizeOf(PChar);

    if (p1^ = '-')
    and (p2^ <> #0) then
      if (Ord(pAddress^) >= Ord(p^))
      and (Ord(pAddress^) <= Ord(p2^)) then
      begin
        Result := not negated;
        break;
      end;

    if p^ = pAddress^ then
    begin
      Result := not negated;
      break;
    end;

    Inc(p);
  end;

  if Result = false then
    exit;

  while p^ <> ']' do
  begin
    if p^ = #0 then
    begin
      //LogWarningFMT('Unterminated [ in message: %s', [FInput[0]]);
      exit;
    end;

    Inc(p);
  end;

  Inc(p);
  pMessage := p;
  Inc(pAddress);
  Result := MatchPattern(p, pAddress);
end;

function TOSCPacket.MatchList(pMessage, pAddress: PChar): Boolean;
var
  p, tp: PChar;
begin
  Result := false;

  p := pMessage;
  tp := pAddress;

  while p^ <> '}' do
  begin
    if p^ = #0 then
    begin
      //LogWarningFMT('Unterminated { in message: %s', [FInput[0]]);
      exit;
    end;

    Inc(p);
  end;


// for(restOfPattern = pattern; *restOfPattern != '}'; restOfPattern++) {
//  if (*restOfPattern == 0) {
//    OSCWarning("Unterminated { in pattern \".../%s/...\"", theWholePattern);
//    return FALSE;
//  }
//}

  Inc(p); // skip close curly brace
  Inc(pMessage); // skip open curly brace

  while true do
  begin
    if pMessage^ = ',' then
    begin
      if MatchPattern(p, tp) then
      begin
        Result := true;
        pMessage := p;
        pAddress := tp;
        exit;
      end
      else
      begin
        tp := pAddress;
        Inc(pMessage);
      end;
    end
    else if pMessage^ = '}' then
    begin
      Result := MatchPattern(p, tp);
      pMessage := p;
      pAddress := tp;
      exit;
    end
    else if pMessage^ = tp^ then
    begin
      Inc(pMessage);
      Inc(tp);
    end
    else
    begin
      tp := pAddress;
      while (pMessage^ <> ',')
        and (pMessage^ <> '}') do
          Inc(pMessage);

      if pMessage^ = ',' then
        Inc(pMessage);
    end;
  end;
end;

function TOSCPacket.MatchPattern(pMessage, pAddress: PChar): Boolean;
begin
  if (pMessage = nil)
  or (pMessage^ = #0) then
  begin
    Result := pAddress^ = #0;
    exit;
  end;

  if pAddress^ = #0 then
  begin
    if pMessage^ = '*' then
    begin
      Result := MatchPattern(pMessage + 1, pAddress);
      exit;
    end
    else
    begin
      Result := false;
      exit;
    end;
  end;

  case pMessage^ of
  #0 : Result := pAddress^ = #0;
  '?': Result := MatchPattern(pMessage + 1, pAddress + 1);
  '*':
  begin
      if MatchPattern(pMessage + 1, pAddress) then
        Result := true
      else
        Result := MatchPattern(pMessage, pAddress + 1);
  end;
  ']','}':
  begin
    //LogWarningFMT('Spurious %s in message: %s', [pMessage^, FInput[0]]);
    Result := false;
  end;
  '[': Result := MatchBrackets(pMessage, pAddress);
  '{': Result := MatchList(pMessage, pAddress);
  {'\\':
  begin
    if pMessage^ + 1 = #0 then
      Result := pAddress^ = #0
    else if pMessage^ + 1 = pAddress^
      Result := MatchPattern(pMessage + 2, pAddress + 1)
    else
      Result := false;
  end;   }
  else
  if pMessage^ = pAddress^ then
    Result := MatchPattern(pMessage + 1,pAddress + 1)
  else
    Result := false;
  end;
end;

class function TOSCPacket.Unpack(Bytes: TBytes; Count: Integer): TOSCPacket;
begin
  Result := UnPack(Bytes, 0, Count);
end;

class function TOSCPacket.Unpack(Bytes: TBytes; Offset, Count: Integer;
    TimeTag: Extended = 0): TOSCPacket;
begin
  if Char(Bytes[Offset]) = '#' then
    Result := TOSCBundle.UnPack(Bytes, Offset, Count)
  else
    Result := TOSCMessage.UnPack(Bytes, Offset, Count, TimeTag);
end;

end.
