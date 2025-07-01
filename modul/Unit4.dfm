object Form4: TForm4
  Left = 0
  Top = 0
  Caption = 'Work in CMD console'
  ClientHeight = 485
  ClientWidth = 851
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 851
    Height = 121
    Align = alTop
    TabOrder = 0
    object Button1: TButton
      Left = 32
      Top = 49
      Width = 121
      Height = 25
      Caption = #1042#1099#1087#1086#1083#1085#1080#1090#1100
      TabOrder = 0
      OnClick = Button1Click
    end
    object Edit1: TEdit
      Left = 32
      Top = 16
      Width = 121
      Height = 21
      TabOrder = 1
      Text = 'ping 8.8.8.8 -t'
    end
    object Button2: TButton
      Left = 192
      Top = 49
      Width = 153
      Height = 25
      Caption = #1054#1089#1090#1072#1085#1086#1074#1080#1090#1100
      Enabled = False
      TabOrder = 2
      OnClick = Button2Click
    end
  end
  object Memo1: TMemo
    Left = 0
    Top = 121
    Width = 851
    Height = 364
    Align = alClient
    Color = clBlack
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
    ReadOnly = True
    TabOrder = 1
    WordWrap = False
    ExplicitTop = 127
  end
end
