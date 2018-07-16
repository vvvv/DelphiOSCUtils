unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, IdSocketHandle, IdUDPServer, IdGlobal,
  IdBaseComponent, IdComponent, IdUDPBase, IdUDPClient, Vcl.StdCtrls;

type
  TForm1 = class(TForm)
    FUDPClient: TIdUDPClient;
    FUDPServer: TIdUDPServer;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    ReceiveAddressEdit: TEdit;
    Label2: TLabel;
    ReceiveArgumentsEdit: TEdit;
    Label3: TLabel;
    SendAddressEdit: TEdit;
    Label4: TLabel;
    SendArgumentsEdit: TEdit;
    SendButton: TButton;
    procedure FUDPServerUDPRead(AThread: TIdUDPListenerThread; AData:
        TIdBytes; ABinding: TIdSocketHandle);
    procedure SendButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses OSCUtils;

{$R *.dfm}

procedure TForm1.FUDPServerUDPRead(AThread: TIdUDPListenerThread; AData:
    TIdBytes; ABinding: TIdSocketHandle);
var
  packet        : TOSCPacket;
  msg           : TOSCMessage;
  i             : Integer;
  typetag, arg  : String;
  formatSettings: TFormatSettings;
begin
  packet := TOSCPacket.Unpack(TBytes(AData), Length(AData));
  msg    := packet.MatchAddress(ReceiveAddressEdit.Text);
  if Assigned(msg) then
  begin
    msg.Decode;

    formatSettings := TFormatSettings.Create(LOCALE_INVARIANT);
    ReceiveArgumentsEdit.Text := '';
    for i := 0 to msg.ArgumentCount - 1 do
    begin
      typetag := msg.TypeTag[i];
      if typetag = 's' then
        arg := TEncoding.UTF8.GetString(msg.Argument[i])
      else if typeTag = 'f' then
        arg := FloatToStr(msg.ArgumentAsFloat[i], formatSettings)
      else if typeTag = 'i' then
        arg := IntToStr(msg.ArgumentAsInt[i])
      else
        arg := 'UNKNOWN_TYPETAG';

      ReceiveArgumentsEdit.Text := ReceiveArgumentsEdit.Text + arg + ' ';
    end;
  end;
end;

procedure TForm1.SendButtonClick(Sender: TObject);
var
  msg   : TOSCMessage;
  bundle: TOSCBundle;
begin
  // create a bundle
  bundle := TOSCBundle.Create(nil);

  // create a message
  msg := TOSCMessage.Create(SendAddressEdit.Text);

  // add arguments to the message
  msg.AddString(SendArgumentsEdit.Text);

  // add message to the bundle
  bundle.Add(msg);

  // send bundle as bytes
  FUDPClient.SendBuffer(TIdBytes(bundle.ToOSCBytes));
end;

end.
