object Form1: TForm1
  Left = 0
  Top = 0
  BorderStyle = bsSingle
  Caption = 'Form1'
  ClientHeight = 93
  ClientWidth = 497
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 0
    Top = 49
    Width = 497
    Height = 44
    Align = alClient
    Caption = 'OSC Receiver'
    TabOrder = 0
    ExplicitTop = 184
    ExplicitWidth = 566
    ExplicitHeight = 167
    object Label1: TLabel
      Left = 8
      Top = 16
      Width = 39
      Height = 13
      Caption = 'Address'
    end
    object Label2: TLabel
      Left = 180
      Top = 16
      Width = 52
      Height = 13
      Caption = 'Arguments'
    end
    object ReceiveAddressEdit: TEdit
      Left = 53
      Top = 13
      Width = 121
      Height = 21
      TabOrder = 0
      Text = '/test'
    end
    object ReceiveArgumentsEdit: TEdit
      Left = 238
      Top = 13
      Width = 252
      Height = 21
      TabOrder = 1
    end
  end
  object GroupBox2: TGroupBox
    Left = 0
    Top = 0
    Width = 497
    Height = 49
    Align = alTop
    Caption = 'OSC Sender'
    TabOrder = 1
    object Label3: TLabel
      Left = 8
      Top = 24
      Width = 39
      Height = 13
      Caption = 'Address'
    end
    object Label4: TLabel
      Left = 180
      Top = 24
      Width = 52
      Height = 13
      Caption = 'Arguments'
    end
    object SendAddressEdit: TEdit
      Left = 53
      Top = 21
      Width = 121
      Height = 21
      TabOrder = 0
      Text = '/test'
    end
    object SendArgumentsEdit: TEdit
      Left = 238
      Top = 21
      Width = 171
      Height = 21
      TabOrder = 1
      Text = 'foo bar'
    end
    object SendButton: TButton
      Left = 415
      Top = 19
      Width = 75
      Height = 25
      Caption = 'Send'
      TabOrder = 2
      OnClick = SendButtonClick
    end
  end
  object FUDPClient: TIdUDPClient
    Active = True
    Host = 'localhost'
    Port = 4444
    Left = 352
    Top = 24
  end
  object FUDPServer: TIdUDPServer
    Active = True
    Bindings = <>
    DefaultPort = 5555
    OnUDPRead = FUDPServerUDPRead
    Left = 280
    Top = 24
  end
end
