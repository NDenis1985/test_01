object Form2: TForm2
  Left = 0
  Top = 0
  Caption = #1055#1086#1080#1089#1082' '#1092#1072#1081#1083#1072' '#1074' '#1082#1072#1090#1072#1083#1086#1075#1072#1093' '#1080' '#1087#1086#1076#1082#1072#1090#1072#1083#1086#1075#1072#1093
  ClientHeight = 222
  ClientWidth = 462
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 462
    Height = 105
    Align = alTop
    TabOrder = 0
    ExplicitWidth = 357
    object Button1: TButton
      Left = 24
      Top = 59
      Width = 154
      Height = 25
      Caption = #1053#1072#1081#1090#1080
      TabOrder = 0
      OnClick = Button1Click
    end
    object Edit1: TEdit
      Left = 24
      Top = 16
      Width = 121
      Height = 21
      TabOrder = 1
      Text = 'c:\windows'
    end
    object Button2: TButton
      Left = 200
      Top = 59
      Width = 153
      Height = 25
      Caption = #1054#1089#1090#1072#1085#1086#1074#1080#1090#1100' '#1087#1086#1080#1089#1082
      TabOrder = 2
      OnClick = Button2Click
    end
    object Edit2: TEdit
      Left = 175
      Top = 16
      Width = 121
      Height = 21
      TabOrder = 3
      Text = '*'
    end
  end
  object Memo1: TMemo
    Left = 0
    Top = 105
    Width = 462
    Height = 117
    Align = alClient
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 1
    WordWrap = False
    ExplicitWidth = 357
  end
end
