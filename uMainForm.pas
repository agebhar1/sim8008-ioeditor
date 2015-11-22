unit uMainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, StdCtrls, ExtCtrls, Grids, ComCtrls, Buttons, ImgList, FileCtrl,
  uIOClasses, uResourceStrings, uView, uEditForm, uProcessor, ShellAPI;

type
  TMainForm = class(TForm, ILanguage, IRadixView)
    MainMenu: TMainMenu;
    sgData: TStringGrid;
    pNavigateItem: TPanel;
    miFile: TMenuItem;
    StatusBar: TStatusBar;
    sbDelete: TSpeedButton;
    sbAdd: TSpeedButton;
    sbInsert: TSpeedButton;
    LRowText: TLabel;
    LRow: TLabel;
    SaveDialog: TSaveDialog;
    OpenDialog: TOpenDialog;
    miNew: TMenuItem;
    miIPortfile: TMenuItem;
    miOPortfile: TMenuItem;
    miOpen: TMenuItem;
    miSave: TMenuItem;
    miSaveAs: TMenuItem;
    N1: TMenuItem;
    N2: TMenuItem;
    miClose: TMenuItem;
    miSetup: TMenuItem;
    miRadix: TMenuItem;
    miOctal: TMenuItem;
    miDecimal: TMenuItem;
    miHexadecimal: TMenuItem;
    miBinary: TMenuItem;
    miLanguage: TMenuItem;
    N3: TMenuItem;
    miGerman: TMenuItem;
    miEnglish: TMenuItem;
    miMHelp: TMenuItem;
    miHelp: TMenuItem;
    miInfo: TMenuItem;
    ImageList: TImageList;
    LPortText: TLabel;
    LPort: TLabel;
    miCloseFile: TMenuItem;
    Bevel: TBevel;
    sbReplicate: TSpeedButton;
    miNegDecimal: TMenuItem;
    procedure sgDataDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure FormCreate(Sender: TObject);
    procedure sgDataSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure sgDataDblClick(Sender: TObject);
    procedure sgDataKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormDestroy(Sender: TObject);
    procedure sbAddClick(Sender: TObject);
    procedure sbInsertClick(Sender: TObject);
    procedure sbDeleteClick(Sender: TObject);
    procedure miIPortfileClick(Sender: TObject);
    procedure miOPortfileClick(Sender: TObject);
    procedure miSaveClick(Sender: TObject);
    procedure miCloseClick(Sender: TObject);
    procedure miOctalClick(Sender: TObject);
    procedure miDecimalClick(Sender: TObject);
    procedure miHexadecimalClick(Sender: TObject);
    procedure miBinaryClick(Sender: TObject);
    procedure miGermanClick(Sender: TObject);
    procedure miEnglishClick(Sender: TObject);
    procedure miHelpClick(Sender: TObject);
    procedure miInfoClick(Sender: TObject);
    procedure miSaveAsClick(Sender: TObject);
    procedure miOpenClick(Sender: TObject);
    procedure StatusBarDrawPanel(StatusBar: TStatusBar;
      Panel: TStatusPanel; const Rect: TRect);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure miCloseFileClick(Sender: TObject);
    procedure sbReplicateClick(Sender: TObject);
    procedure miNegDecimalClick(Sender: TObject);
  private
    _IOPortfile: Ti8008IOPortfile;
    _ARow, _ACol: Integer;
    _Block: Boolean;
    _Radix: TRadix;
    _LanguageList: TLanguageList;
    _ViewList: TViewList;
    _EditForm: TEditForm;
    _InitProgressBar: Boolean;
    _ProgressBar: TProgressBar;
    procedure SetVisibility;
    procedure OnAdd(Sender: TObject);
    procedure OnInsert(Sender: TObject; Row: Integer);
    procedure OnDelete(Sender: TObject; Row: Integer);
    procedure OnEdit(Sender: TObject; Row: Integer; Col: Byte; Value: Byte);
    procedure OnOpen(Sender: TObject);
    procedure OnModified(Sender: TObject);
    procedure OnStartProgress(Sender: TObject; Min: Integer; Max: Integer);
    procedure OnProgress(Sender: TObject; Progress: Integer);
    procedure OnEndProgress(Sender: TObject);
  public
    procedure setLanguage(Language: TLanguage);
    procedure setRadix(Radix: TRadix);
    procedure Open(Filename: TFilename);
    procedure LoadLanguage;
    procedure RadixChange(Radix: TRadix; View: TView);
    property IOPortfile: Ti8008IOPortfile read _IOPortfile;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  uInfoForm, XPMan;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  // Progressbar
  _InitProgressBar:= false;
  _ProgressBar:= TProgressBar.Create(StatusBar);
  _ProgressBar.Parent:= StatusBar;
  // i8008 I/O Portfile
  _IOPortfile:= Ti8008IOPortfile.Create;
  IOPortfile.OnAdd:= OnAdd;
  IOPortfile.OnInsert:= OnInsert;
  IOPortfile.OnReplicate:= OnInsert;
  IOPortfile.OnDelete:= OnDelete;
  IOPortfile.OnEdit:= OnEdit;
  IOPortfile.OnOpen:= OnOpen;
  IOPortfile.OnClose:= OnOpen;
  IOPortfile.OnModified:= OnModified;
  IOPortfile.OnStartProgress:= OnStartProgress;
  IOPortfile.OnProgress:= OnProgress;
  IOPortfile.OnEndProgress:= OnEndProgress;
  SetVisibility;
  // Data
  LRow.Caption:= '';
  LPort.Caption:= '';
  sgData.Visible:= false;
  _EditForm:= TEditForm.Create(Self);
  _Block:= false;
  // Listener Lists
  _LanguageList:= TLanguageList.Create;
  _ViewList:= TViewList.Create;
  // Add Listener
  _LanguageList.AddListener(_EditForm);
  _LanguageList.AddListener(Self);
  _ViewList.AddListener(Self);
  _ViewList.Radix:= rOctal;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose:= not IOPortfile.Modified;
  if not CanClose then
    case MessageDlg(getString(rsSaveChanges),mtConfirmation,[mbYes,mbNo,mbCancel],0) of
      mrYes    : begin
                   case IOPortfile.Save of
                     FILE_SAVE_ERROR : MessageDlg(getString(rs_io_Save_Error),mtError,[mbOk],0);
                     else              CanClose:= true;
                   end;
                 end;
      mrNo     : CanClose:= true;
      mrCancel : CanClose:= false;
    end;  
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  _LanguageList.Free;
  _ViewList.Free;
  _EditForm.Free;
  IOPortFile.Free;
  _ProgressBar.Free;
end;

procedure TMainForm.sgDataDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
begin
  if (ARow = 0) or (ACol = 0) then
    sgData.Canvas.Brush.Color:= sgData.FixedColor
  else
    if (ARow > 0) and (ACol > 0) and (ARow mod 2 = 0) then
      sgData.Canvas.Brush.Color:= clBtnHighlight
    else
      sgData.Canvas.Brush.Color:= sgData.Color;
  sgData.Canvas.FillRect(Rect);

  if (ARow = 0) or (ACol = 0) then
    sgData.Canvas.Font.Style:= [fsBold]
  else
    sgData.Canvas.Font.Style:= [];

  Rect.Top:= Rect.Top + ((sgData.RowHeights[ARow] -
                          sgData.Canvas.TextHeight(sgData.Cells[ACol,ARow]))) div 2;
  if ARow = 0 then
    Rect.Left:= Rect.Left + (sgData.ColWidths[ACol] -
                  sgData.Canvas.TextWidth(sgData.Cells[ACol,ARow])) div 2
  else
    Rect.Left:= Rect.Right - 4 - sgData.Canvas.TextWidth(sgData.Cells[ACol,ARow]);
                  sgData.Canvas.TextOut(Rect.Left,Rect.Top,sgData.Cells[ACol,ARow]);

end;

procedure TMainForm.StatusBarDrawPanel(StatusBar: TStatusBar;
  Panel: TStatusPanel; const Rect: TRect);
var
  h, w: Integer;
begin
  if Panel.Index = 0 then
    begin
      StatusBar.Canvas.Font.Style:= [];
      h:= Rect.Top +(((Rect.Bottom-Rect.Top)-StatusBar.Canvas.TextHeight(Panel.Text)) div 2);
      w:= Rect.Left+(((Rect.Right-Rect.Left)-StatusBar.Canvas.TextWidth(Panel.Text)) div 2);
      StatusBar.Canvas.TextOut(w,h,Panel.Text);
    end
  else
    if (Panel.Index = 1) and (not _InitProgressBar) then
      begin
        _ProgressBar.Left:= Rect.Left-1;
        _ProgressBar.Top:= Rect.Top-1;
        _ProgressBar.Width:= Rect.Right-Rect.Left+2;
        _ProgressBar.Height:= Rect.Bottom-Rect.Top+2;
        _InitProgressBar:= true;
      end
    else
      if Panel.Index = 2 then
        begin
          h:= Rect.Top +(((Rect.Bottom-Rect.Top)-StatusBar.Canvas.TextHeight(Panel.Text)) div 2);
          StatusBar.Canvas.TextOut(Rect.Left+1,h,
                                   MinimizeName(Panel.Text,
                                                StatusBar.Canvas,
                                                Rect.Right-Rect.Left-3));
        end;
end;

procedure TMainForm.sgDataSelectCell(Sender: TObject; ACol, ARow: Integer;
  var CanSelect: Boolean);
begin
  _ARow:= ARow;
  _ACol:= ACol;
  LRow.Caption:= IntToStr(ARow)+' ['+IntToStr(IOPortfile.Rows)+']';
  LPort.Caption:= sgData.Cells[ACol,0];
end;

procedure TMainForm.sgDataDblClick(Sender: TObject);
var
  P: TPoint;
begin
  if (_ACol > 0) and (_ACol > 0) then
    begin
      P.X:= Mouse.CursorPos.X;
      P.Y:= Mouse.CursorPos.Y;
      _EditForm.Value:= IOPortFile.Items[_ARow-1,_ACol-1];
      if _EditForm.ShowModal(_Radix,vLong,8,P) = mrOk then
        IOPortFile.Items[_ARow-1,_ACol-1]:= _EditForm.Value;
    end;
end;

procedure TMainForm.sgDataKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_RETURN : sgDataDblClick(nil);
    VK_DELETE : sbDeleteClick(nil);
    Ord('A'),
    Ord('a')  : if Shift = [ssCtrl] then
                  sbAddClick(nil);
    Ord('I'),
    Ord('i')  : if Shift = [ssCtrl] then
                  sbInsertClick(nil);
    Ord('R'),
    Ord('r')  : if Shift = [ssCtrl] then
                  sbReplicateClick(nil);
  end;
end;

procedure TMainForm.sbAddClick(Sender: TObject);
begin
  IOPortFile.Add;
end;

procedure TMainForm.sbInsertClick(Sender: TObject);
begin
  IOPortFile.Insert(_ARow-1);
end;

procedure TMainForm.sbReplicateClick(Sender: TObject);
begin
  IOPortFile.Replicate(_ARow-1);
end;

procedure TMainForm.sbDeleteClick(Sender: TObject);
begin
  IOPortFile.Delete(_ARow-1);
end;

procedure TMainForm.miIPortfileClick(Sender: TObject);
var
  Filename: TFilename;
  result: Integer;
begin
  SaveDialog.Options:= SaveDialog.Options - [ofOverwritePrompt];
  SaveDialog.Title:= getString(rs_io_SaveCreateDialog)+'...';
  SaveDialog.Filter:= getString(rs_p_OpenFilter);
  if SaveDialog.Execute then
    begin
      Filename:= ChangeFileExt(SaveDialog.Filename,'.pin');
      result:= IOPortfile.Open(Filename);
      case result of
        FILE_OPEN_ERROR   : MessageDlg(getString(rs_io_Open_Error),mtError,[mbOk],0);
        FILE_CREATE_ERROR : MessageDlg(getString(rs_io_Create_Error),mtError,[mbOk],0);
      end;
    end;
end;

procedure TMainForm.miOPortfileClick(Sender: TObject);
var
  Filename: TFilename;
  result: Integer;
begin
  SaveDialog.Options:= SaveDialog.Options - [ofOverwritePrompt];
  SaveDialog.Title:= getString(rs_io_SaveCreateDialog)+'...';
  SaveDialog.Filter:= getString(rs_p_SaveFilter);
  if SaveDialog.Execute then
    begin
      Filename:= ChangeFileExt(SaveDialog.Filename,'.pout');
      result:= IOPortfile.Open(Filename);
      case result of
        FILE_OPEN_ERROR   : MessageDlg(getString(rs_io_Open_Error),mtError,[mbOk],0);
        FILE_CREATE_ERROR : MessageDlg(getString(rs_io_Create_Error),mtError,[mbOk],0);
      end;
    end;
end;

procedure TMainForm.miOpenClick(Sender: TObject);
var
  result: Integer;
begin
  OpenDialog.Title:= getString(rs_p_OpenDialog)+'...';
  OpenDialog.Filter:= getString(rs_io_AllPortFilter);
  if OpenDialog.Execute then
    begin
      result:= IOPortfile.Open(OpenDialog.Filename);
      case result of
        FILE_OPEN_ERROR   : MessageDlg(getString(rs_io_Open_Error),mtError,[mbOk],0);
        FILE_CREATE_ERROR : MessageDlg(getString(rs_io_Create_Error),mtError,[mbOk],0);
      end;
    end;
end;

procedure TMainForm.miSaveClick(Sender: TObject);
var
  result: Integer;
begin
  result:= IOPortfile.Save;
  case result of
    FILE_SAVE_ERROR : MessageDlg(getString(rs_io_Save_Error),mtError,[mbOk],0);
  end;
end;

procedure TMainForm.miSaveAsClick(Sender: TObject);
var
  result: Integer;
  Exec: Boolean;
begin
  SaveDialog.Options:= SaveDialog.Options + [ofOverwritePrompt];
  case IOPortfile.Porttype of
    ptIN  : begin
              SaveDialog.DefaultExt:= 'pin';
              SaveDialog.Title:= getString(rs_p_SaveDialog)+'...';
              SaveDialog.Filter:= getString(rs_p_OpenFilter);
              Exec:= SaveDialog.Execute;
            end;
    ptOUT : begin
              SaveDialog.DefaultExt:= 'pout';
              SaveDialog.Title:= getString(rs_p_SaveDialog)+'...';
              SaveDialog.Filter:= getString(rs_p_SaveFilter);
              Exec:= SaveDialog.Execute;
            end;
    else    Exec:= false;
  end;
  if Exec then
    begin
      result:= IOPortfile.SaveAs(SaveDialog.Filename);
      case result of
        FILE_SAVE_ERROR : MessageDlg(getString(rs_io_Save_Error),mtError,[mbOk],0);
      end;
    end;
end;

procedure TMainForm.miCloseFileClick(Sender: TObject);
var
  CanClose: Boolean;
begin
  CanClose:= not IOPortfile.Modified;
  if not CanClose then
    case MessageDlg(getString(rsSaveChanges),mtConfirmation,[mbYes,mbNo,mbCancel],0) of
      mrYes    : begin
                   case IOPortfile.Save of
                     FILE_SAVE_ERROR : MessageDlg(getString(rs_io_Save_Error),mtError,[mbOk],0);
                     else              CanClose:= true;
                   end;
                 end;
      mrNo     : CanClose:= true;
      mrCancel : CanClose:= false;
    end;
  if CanClose then
    begin
      _Block:= true;
      IOPortfile.Close;
      _Block:= false;
    end
end;

procedure TMainForm.miCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.miOctalClick(Sender: TObject);
begin
  _ViewList.Radix:= rOctal;
end;

procedure TMainForm.miDecimalClick(Sender: TObject);
begin
  _ViewList.Radix:= rDecimal;
end;

procedure TMainForm.miNegDecimalClick(Sender: TObject);
begin
  _ViewList.Radix:= rDecimalNeg;
end;

procedure TMainForm.miHexadecimalClick(Sender: TObject);
begin
  _ViewList.Radix:= rHexadecimal;
end;

procedure TMainForm.miBinaryClick(Sender: TObject);
begin
  _ViewList.Radix:= rBinary;
end;

procedure TMainForm.miGermanClick(Sender: TObject);
begin
  uResourceStrings.setLanguage(lGerman);
  _LanguageList.Update;
end;

procedure TMainForm.miEnglishClick(Sender: TObject);
begin
  uResourceStrings.setLanguage(lEnglish);
  _LanguageList.Update;
end;

procedure TMainForm.miHelpClick(Sender: TObject);
var
  Directory: String;
begin
  Directory:= ExtractFileDir(ParamStr(0));
  if Directory[Length(Directory)] <> '\' then
    Directory:= Directory+'\';
  case getLanguage of
    lGerman  : Directory:= Directory+'help\german';
    lEnglish : Directory:= Directory+'help\english';
  end;
  ShellExecute(Handle,'open','index.html',nil,PChar(Directory),SW_MAXIMIZE);
end;

procedure TMainForm.miInfoClick(Sender: TObject);
var
  _Info: TInfoForm;
begin
  _Info:= TInfoForm.Create(Self);
  _Info.ShowInfo;
  _Info.Free;
end;

procedure TMainForm.SetVisibility;
var
  TextWidth: Integer;
begin
  miSave.Enabled:= (not IOPortFile.Error) and not (IOPortfile.Porttype = ptUnknown) and (IOPortfile.Filename <> '');
  miSaveAs.Enabled:= (not IOPortFile.Error) and not (IOPortfile.Porttype = ptUnknown) and (IOPortfile.Filename <> '');
  miCloseFile.Enabled:= (not IOPortFile.Error) and not (IOPortfile.Porttype = ptUnknown) and (IOPortfile.Filename <> '');
  sbAdd.Enabled:= (not IOPortFile.Error) and (IOPortfile.Filename <> '');
  sbInsert.Enabled:= (IOPortFile.Rows > 0) and not IOPortFile.Error;
  sbReplicate.Enabled:= (IOPortFile.Rows > 0) and not IOPortFile.Error;
  sbDelete.Enabled:= (IOPortFile.Rows > 0) and not IOPortFile.Error;
  sgData.Visible:= (IOPortFile.Rows > 0) and not IOPortFile.Error;
  LRowText.Visible:= sgData.Visible;
  LRow.Visible:= sgData.Visible;
  LPortText.Visible:= sgData.Visible;
  LPort.Visible:= sgData.Visible;
  if Visible and sgData.Visible then
    sgData.SetFocus;
  TextWidth:= sgData.Canvas.TextWidth(sgData.Cells[0,sgData.RowCount-1]);
  if sgData.ColWidths[0] < TextWidth+10 then
    sgData.ColWidths[0]:= TextWidth+10;
end;

procedure TMainForm.OnAdd(Sender: TObject);
var
  j: Integer;
begin
  sgData.RowCount:= IOPortfile.Rows+1;
  sgData.Cells[0,sgData.RowCount-1]:= IntToStr(IOPortfile.Rows);
  for j:= 1 to sgData.ColCount-1 do
    sgData.Cells[j,IOPortfile.Rows]:= WordToRadix(IOPortfile.Items[IOPortfile.Rows-1,j-1],_Radix,vLong,8);
    
  sgData.Row:= IOPortfile.Rows;
  sgData.Col:= 1;
  sgData.FixedRows:= 1;
  sgData.FixedCols:= 1;
  SetVisibility;
end;

procedure TMainForm.OnInsert(Sender: TObject; Row: Integer);
var
  i, j: Integer;
begin
  sgData.RowCount:= IOPortfile.Rows+1;
  for i:= sgData.RowCount-1 downto Row+2 do
    begin
      sgData.Cells[0,i]:= IntToStr(i);
      for j:= 1 to sgData.ColCount-1 do
        sgData.Cells[j,i]:= sgData.Cells[j,i-1];
    end;
  sgData.Cells[0,Row+1]:= IntToStr(Row+1);
  for j:= 1 to sgData.ColCount-1 do
    sgData.Cells[j,Row+1]:= WordToRadix(IOPortfile.Items[Row,j-1],_Radix,vLong,8);

  sgData.Row:= Row+1;
  sgData.Col:= 1;
  SetVisibility;
end;

procedure TMainForm.OnDelete(Sender: TObject; Row: Integer);
var
  i, j: Integer;
begin
  if not _Block then
    begin
      for i:= Row+1 to sgData.RowCount-2 do
        begin
          sgData.Cells[0,i]:= IntToStr(i);
          for j:= 1 to sgData.ColCount-1 do
            sgData.Cells[j,i]:= sgData.Cells[j,i+1];
        end;
      sgData.RowCount:= IOPortfile.Rows+1;

      if Row > IOPortfile.Rows-1 then
        Dec(Row);
      if Row > 0 then
        sgData.Row:= Row;
      sgData.Col:= 1;
      SetVisibility;
    end;  
end;

procedure TMainForm.OnEdit(Sender: TObject; Row: Integer; Col: Byte; Value: Byte);
begin
  sgData.Cells[Col+1,Row+1]:= WordToRadix(Value,_Radix,vLong,8);
end;

procedure TMainForm.OnOpen(Sender: TObject);
var
  i, si, bits: Integer;
begin
  sgData.ColCount:= IOPortfile.Cols+1;
  SetVisibility;
  StatusBar.Panels[2].Text:= IOPortfile.Filename;
  case IOPortfile.Porttype of
    ptIN  : begin
              StatusBar.Panels[0].Text:= 'IN';
              si:= Ti8008IPorts.FirstPortNo;
              bits:= 3;
            end;
    ptOUT : begin
              StatusBar.Panels[0].Text:= 'OUT';
              si:= Ti8008OPorts.FirstPortNo;
              bits:= 5;
            end;
    else    begin
              StatusBar.Panels[0].Text:= '';
              si:= 0;
              bits:= 8;
            end;
  end;
  for i:= 1 to sgData.ColCount-1 do
    sgData.Cells[i,0]:= WordToRadix(si+i-1,_Radix,vLong,bits);
end;

procedure TMainForm.OnModified(Sender: TObject);
begin
  with (Sender as Ti8008IOPortfile) do
    if Modified then
      StatusBar.Font.Style:= [fsBold]
    else
      StatusBar.Font.Style:= [];
end;

procedure TMainForm.OnStartProgress(Sender: TObject; Min: Integer; Max: Integer);
begin
  _ProgressBar.Min:= Min;
  _ProgressBar.Max:= Max;
  _ProgressBar.Position:= Min;
end;

procedure TMainForm.OnProgress(Sender: TObject; Progress: Integer);
begin
  _ProgressBar.Position:= Progress;
  Application.ProcessMessages;
end;

procedure TMainForm.OnEndProgress(Sender: TObject);
begin
  _ProgressBar.Position:= _ProgressBar.Min;
end;

procedure TMainForm.setLanguage(Language: TLanguage);
begin
  uResourceStrings.setLanguage(Language);
  _LanguageList.Update;
end;

procedure TMainForm.setRadix(Radix: TRadix);
begin
  _ViewList.Radix:= Radix;
end;

procedure TMainForm.Open(Filename: TFilename);
var
  result: Integer;
begin
  result:= IOPortfile.Open(Filename);
  case result of
    FILE_OPEN_ERROR   : MessageDlg(getString(rs_io_Open_Error),mtError,[mbOk],0);
    FILE_CREATE_ERROR : MessageDlg(getString(rs_io_Create_Error),mtError,[mbOk],0);
  end;
end;

procedure TMainForm.LoadLanguage;
begin
  miGerman.Checked:= getLanguage = lGerman;
  miEnglish.Checked:= getLanguage = lEnglish;
  LPortText.Caption:= getString(rs_io_Port);
  LRowText.Caption:= getString(rs_io_Row);
  sbAdd.Hint:= getString(rs_io_Add);
  sbInsert.Hint:= getString(rs_io_Insert);
  sbReplicate.Hint:= getString(rs_io_Replicate);
  sbDelete.Hint:= getString(rs_io_Delete);
  miFile.Caption:= getString(rs_m_File);
  miNew.Caption:= getString(rs_m_New)+'...';
  miIPortfile.Caption:= getString(rs_io_IN_Portfile);
  miOPortfile.Caption:= getString(rs_io_OUT_Portfile);
  miOpen.Caption:= getString(rs_p_Open)+'...';
  miSave.Caption:= getString(rs_p_Save);
  miSaveAs.Caption:= getString(rs_io_SaveAs)+'...';
  miCloseFile.Caption:= getString(rs_io_CloseFile);
  miClose.Caption:= getString(rs_m_Close);
  miSetup.Caption:= getString(rs_m_Setup);
  miRadix.Caption:= getString(rs_m_Radix);
  miOctal.Caption:= getString(rs_m_Octal);
  miDecimal.Caption:= getString(rs_m_Decimal);
  miHexadecimal.Caption:= getString(rs_m_Hexadecimal);
  miBinary.Caption:= getString(rs_m_Binary);
  miLanguage.Caption:= getString(rs_m_Language);
  miGerman.Caption:= 'Deutsch';
  miEnglish.Caption:= 'English';
  miMHelp.Caption:= getString(rs_m_Help);
  miHelp.Caption:= getString(rs_m_Help)+'...';
  miInfo.Caption:= 'Info...';
end;

procedure TMainForm.RadixChange(Radix: TRadix; View: TView);
var
  i, j, si, bits: Integer;
begin
  _Radix:= Radix;
  miOctal.Checked:= Radix = rOctal;
  miDecimal.Checked:= Radix = rDecimal;
  miNegDecimal.Checked:= Radix = rDecimalNeg;
  miHexadecimal.Checked:= Radix = rHexadecimal;
  miBinary.Checked:= Radix = rBinary;
  for i:= 1 to sgData.RowCount-1 do
    for j:= 1 to sgData.ColCount-1 do
      sgData.Cells[j,i]:= WordToRadix(IOPortFile.Items[i-1,j-1],_Radix,vLong,8);
  case IOPortfile.Porttype of
    ptIN  : begin
              si:= Ti8008IPorts.FirstPortNo;
              bits:= 3;
            end;
    ptOUT : begin
              si:= Ti8008OPorts.FirstPortNo;
              bits:= 5;
            end;
    else    begin
              si:= 0;
              bits:= 8;
            end;
  end;
  for i:= 1 to sgData.ColCount-1 do
    if Radix = rDecimalNeg then sgData.Cells[i,0]:= WordToRadix(si+i-1,rDecimal,vLong,bits)
    else sgData.Cells[i,0]:= WordToRadix(si+i-1,_Radix,vLong,bits);
  if _ACol > 0 then
    LPort.Caption:= sgData.Cells[_ACol,0]
  else
    LPort.Caption:= '';
end;

end.
