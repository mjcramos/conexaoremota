object fMain: TfMain
  Left = 0
  Top = 0
  Caption = 'Servidor'
  ClientHeight = 485
  ClientWidth = 807
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Logs_Memo: TMemo
    Left = 0
    Top = 360
    Width = 807
    Height = 125
    Align = alBottom
    Lines.Strings = (
      'Exceptions Log:'
      '')
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 0
  end
  object Connections_ListView: TListView
    Left = 0
    Top = 25
    Width = 807
    Height = 335
    Align = alClient
    Columns = <
      item
        Caption = 'HandleConnection'
        Width = 100
      end
      item
        Caption = 'IP'
        Width = 140
      end
      item
        Caption = 'ID'
        Width = 100
      end
      item
        Caption = 'Password'
        Width = 100
      end
      item
        Caption = 'Target ID'
        Width = 100
      end
      item
        Caption = 'Ping'
        Width = 80
      end
      item
        Caption = 'Apelido'
        Width = 80
      end
      item
        Caption = 'Data/Hora '
        Width = 90
      end
      item
        Caption = 'Versao S.O.'
        Width = 90
      end>
    GridLines = True
    ReadOnly = True
    RowSelect = True
    TabOrder = 1
    ViewStyle = vsReport
    ExplicitHeight = 229
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 807
    Height = 25
    Align = alTop
    TabOrder = 2
    object chExibir: TCheckBox
      Left = 1
      Top = 1
      Width = 288
      Height = 23
      Align = alLeft
      Caption = 'Exibir Conex'#245'es'
      TabOrder = 0
      OnClick = chExibirClick
    end
  end
  object Ping_Timer: TTimer
    Interval = 5000
    OnTimer = Ping_TimerTimer
    Left = 384
    Top = 72
  end
end
