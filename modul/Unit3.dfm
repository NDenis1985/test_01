object Form3: TForm3
  Left = 0
  Top = 0
  Caption = #1055#1086#1080#1089#1082' '#1074' '#1092#1072#1081#1083#1077
  ClientHeight = 299
  ClientWidth = 716
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
    Width = 716
    Height = 161
    Align = alTop
    TabOrder = 0
    object Label1: TLabel
      Left = 16
      Top = 16
      Width = 89
      Height = 13
      Caption = #1060#1072#1081#1083' '#1076#1083#1103' '#1087#1086#1080#1089#1082#1072' '
    end
    object Edit1: TEdit
      Left = 16
      Top = 40
      Width = 409
      Height = 21
      TabOrder = 0
      Text = 'd:\work\1\exemple.txt'
    end
    object Memo1: TMemo
      Left = 16
      Top = 67
      Width = 409
      Height = 73
      Lines.Strings = (
        #1040' '#1084#1086#1078#1077#1090' '#1090#1077#1073#1077' '#1076#1072#1090#1100' '#1077#1097#1105' '#1082#1083#1102#1095' '#1086#1090' '#1082#1074#1072#1088#1090#1080#1088#1099', '#1075#1076#1077' '#1076#1077#1085#1100#1075#1080' '#1083#1077#1078#1072#1090'?'
        
          #1057#1090#1091#1076#1077#1085#1090#1082#1072', '#1082#1086#1084#1089#1086#1084#1086#1083#1082#1072', '#1089#1087#1086#1088#1090#1089#1084#1077#1085#1082#1072', '#1085#1072#1082#1086#1085#1077#1094', '#1086#1085#1072' '#1087#1088#1086#1089#1090#1086' '#1082#1088#1072#1089#1072#1074#1080#1094 +
          #1072)
      TabOrder = 1
      WordWrap = False
    end
    object Button1: TButton
      Left = 447
      Top = 115
      Width = 75
      Height = 25
      Caption = #1055#1086#1080#1089#1082
      TabOrder = 2
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 528
      Top = 115
      Width = 121
      Height = 25
      Caption = #1054#1089#1090#1072#1085#1086#1074#1080#1090#1100' '#1087#1086#1080#1089#1082
      Enabled = False
      TabOrder = 3
      OnClick = Button2Click
    end
  end
  object Memo2: TMemo
    Left = 0
    Top = 161
    Width = 716
    Height = 121
    Align = alClient
    ReadOnly = True
    TabOrder = 1
    WordWrap = False
  end
  object ProgressBar1: TProgressBar
    Left = 0
    Top = 282
    Width = 716
    Height = 17
    Align = alBottom
    TabOrder = 2
  end
end
