object EditorModelView: TEditorModelView
  Left = 617
  Top = 0
  BorderStyle = bsDialog
  Caption = 'EditorModelView'
  ClientHeight = 842
  ClientWidth = 808
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PopupMode = pmAuto
  Position = poDesigned
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 26
    Height = 13
    Caption = 'Unit :'
  end
  object TLabel
    Left = 8
    Top = 56
    Width = 54
    Height = 13
    Caption = 'Animation :'
  end
  object EditorModelFrame: TPanel
    Left = 8
    Top = 128
    Width = 769
    Height = 705
    Cursor = crArrow
    BevelOuter = bvNone
    Color = clBlack
    Ctl3D = False
    DragCursor = crArrow
    ParentBackground = False
    ParentCtl3D = False
    TabOrder = 0
    OnMouseDown = EditorModelFrameMouseDown
    OnMouseEnter = EditorModelFrameMouseEnter
    OnMouseLeave = EditorModelFrameMouseLeave
    OnMouseMove = EditorModelFrameMouseMove
    OnMouseUp = EditorModelFrameMouseUp
  end
  object ModelListBox: TComboBox
    Left = 8
    Top = 27
    Width = 169
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 1
    OnChange = ModelListBoxChange
  end
  object AnimationListBox: TComboBox
    Left = 8
    Top = 75
    Width = 169
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 2
    OnChange = AnimationListBoxChange
  end
end
