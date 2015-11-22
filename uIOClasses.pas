unit uIOClasses;

interface

uses
  Classes, SysUtils, uProcessor;

type

  TDeleteEvent = procedure(Sender: TObject; Index: Integer) of object;
  TInsertEvent = procedure(Sender: TObject; Index: Integer) of object;
  TReplicateEvent = procedure(Sender: TObject; Index: Integer) of object;
  TEditEvent = procedure(Sender: TObject; Row: Integer; Col: Byte; Value: Byte) of object;

  TStartProgressEvent = procedure(Sender: TObject; Min: Integer; Max: Integer) of object;
  TProgressEvent = procedure(Sender: TObject; Progress: Integer) of object;
  TEndProgressEvent = procedure(Sender: TObject) of object;

  Ti8008IOPortfile = class(TObject)
  private
    _IOData: TList;
    _Error: Boolean;
    _Filename: TFilename;
    _Stream: TFileStream;
    _Porttype: TPorttype;
    _Modified: Boolean;
    _OnAdd: TNotifyEvent;
    _OnInsert: TInsertEvent;
    _OnReplicate: TReplicateEvent;
    _OnDelete: TDeleteEvent;
    _OnEdit: TEditEvent;
    _OnOpen: TNotifyEvent;
    _OnClose: TNotifyEvent;
    _OnModified: TNotifyEvent;
    _OnStartProgress: TStartProgressEvent;
    _OnProgress: TProgressEvent;
    _OnEndProgress: TEndProgressEvent;
    property Stream: TFileStream read _Stream write _Stream;
  protected
    procedure setItems(Row: Integer; Col: Byte; Value: Byte);
    procedure setModified(Value: Boolean);
    function getRows: Integer;
    function getCols: Byte;
    function getItems(Row: Integer; Col: Byte): Byte;
  public
    constructor Create;
    destructor Destroy; override;
    function Open(Filename: TFilename): Integer;
    procedure Close;
    procedure Add;
    procedure Insert(Row: Integer);
    procedure Replicate(Row: Integer);
    procedure Delete(Row: Integer);
    procedure Clear;
    function Save: Integer;
    function SaveAs(Filename: TFilename): Integer;
    property Error: Boolean read _Error;
    property Filename: TFilename read _Filename;
    property Porttype: TPorttype read _Porttype;
    property Rows: Integer read getRows;
    property Cols: Byte read getCols;
    property Items[Row: Integer; Col: Byte]: Byte read getItems write setItems;
    property Modified: Boolean read _Modified write setModified;
    property OnAdd: TNotifyEvent read _OnAdd write _OnAdd;
    property OnInsert: TInsertEvent read _OnInsert write _OnInsert;
    property OnReplicate: TReplicateEvent read _OnReplicate write _OnReplicate;
    property OnDelete: TDeleteEvent read _OnDelete write _OnDelete;
    property OnEdit: TEditEvent read _OnEdit write _OnEdit;
    property OnOpen: TNotifyEvent read _OnOpen write _OnOpen;
    property OnClose: TNotifyEvent read _OnClose write _OnClose;
    property OnModified: TNotifyEvent read _OnModified write _OnModified;
    property OnStartProgress: TStartProgressEvent read _OnStartProgress write _OnStartProgress;
    property OnProgress: TProgressEvent read _OnProgress write _OnProgress;
    property OnEndProgress: TEndProgressEvent read _OnEndProgress write _OnEndProgress;
  end;

  TByteRow = class(TObject)
  private
    _Size: Byte;
    _List: array of Byte;
  protected
    procedure setItems(Index: Byte; Value: Byte); virtual;
    function getItems(Index: Byte): Byte; virtual;
    procedure SaveToStream(Stream: TStream); virtual;
  public
    constructor Create(Size: Byte); overload;
    constructor Create(ByteRow: TByteRow); overload;
    constructor Create(Size: Byte; Stream: TStream); overload;
    destructor Destroy; override;
    property Items[Index: Byte]: Byte read getItems write setItems;
    property Size: Byte read _Size;
  end;

const
  NO_ERROR          = 0;
  FILE_CREATE_ERROR = 1;
  FILE_OPEN_ERROR   = 2;
  FILE_SAVE_ERROR   = 3;

implementation

{ ***** Ti8008IOPortfile ****** }
procedure Ti8008IOPortfile.setItems(Row: Integer; Col: Byte; Value: Byte);
var
  Item: TByteRow;
begin
  if (Row >= 0) and (Row < Rows) and (Col < Cols) then
    begin
      Item:= _IOData.Items[Row];
      if Assigned(Item) then
        begin
          Item.Items[Col]:= Value;
          if Assigned(OnEdit) then
            OnEdit(Self,Row,Col,Value);
          Modified:= true;  
        end;
    end;
end;

procedure Ti8008IOPortfile.setModified(Value: Boolean);
begin
  _Modified:= Value;
  if Assigned(OnModified) then
    OnModified(Self);
end;

function Ti8008IOPortfile.getRows: Integer;
begin
  result:= _IOData.Count;
end;

function Ti8008IOPortfile.getCols: Byte;
begin
  case Porttype of
    ptIN  : result:= Ti8008IPorts.Count;
    ptOUT : result:= Ti8008OPorts.Count;
    else    result:= 0;
  end;
end;

function Ti8008IOPortfile.getItems(Row: Integer; Col: Byte): Byte;
var
  Item: TByteRow;
begin
  if (Row >= 0) and (Row < Rows) and (Col < Cols) then
    begin
      Item:= _IOData.Items[Row];
      if Assigned(Item) then
        result:= Item.Items[Col]
      else
        result:= 0;
    end
  else
    result:= 0;
end;

constructor Ti8008IOPortfile.Create;
begin
  inherited Create;
  _IOData:= TList.Create;
  _Porttype:= ptUnknown;
  _Filename:= '';
  Modified:= false;
  _Stream:= nil;
  OnAdd:= nil;
  OnInsert:= nil;
  OnDelete:= nil;
  OnEdit:= nil;
  OnOpen:= nil;
  OnClose:= nil;
  OnModified:= nil;
end;

destructor Ti8008IOPortfile.Destroy;
begin
  Close;
  _IOData.Free;
  inherited;
end;

function Ti8008IOPortfile.Open(Filename: TFilename): Integer;
var
  Ext: String;
  tmpStream: TFileStream;
  tmpPorttype: TPorttype;
begin
  result:= NO_ERROR;
  Ext:= LowerCase(ExtractFileExt(Filename));
  if Ext = '.pin' then
    _Porttype:= ptIN
  else
    if Ext = '.pout' then
      _Porttype:= ptOUT
    else
      _Porttype:= ptUnknown;
  tmpPorttype:= Porttype;
  if Porttype <> ptUnknown then
    if FileExists(Filename) then
      begin
        // Open
        try
          tmpStream:= TFileStream.Create(Filename,fmOpenReadWrite,fmShareExclusive);
          Close;
          _Stream:= tmpStream;
          _Filename:= Filename;
          _Porttype:= tmpPorttype;
          if Assigned(OnOpen) then
            OnOpen(Self);
          // Read Data
          Stream.Position:= 0;
          if Assigned(OnStartProgress) then
            OnStartProgress(Self,0,Stream.Size div Cols);
          while Stream.Position < Stream.Size do
            begin
              _IOData.Add(TByteRow.Create(Cols,Stream));
              if Assigned(OnAdd) then
                OnAdd(Self);
              if Assigned(OnProgress) then
                OnProgress(Self,Stream.Position div Cols);
            end;
          if Assigned(OnEndProgress) then
            OnEndProgress(Self);
          Modified:= false;
        except
          result:= FILE_OPEN_ERROR;
        end;
      end
    else
      begin
        // Create
        try
          tmpStream:= TFileStream.Create(Filename,fmCreate,fmShareExclusive);
          Close;
          _Stream:= tmpStream;
          _Filename:= Filename;
          _Porttype:= tmpPorttype;          
          if Assigned(OnOpen) then
            OnOpen(Self);
          Modified:= false;
        except
          result:= FILE_CREATE_ERROR;
        end;
      end;
  _Error:= result <> NO_ERROR;
end;

procedure Ti8008IOPortfile.Close;
begin
  Clear;
  _Error:= false;
  _Filename:= '';
  _Porttype:= ptUnknown;
  Modified:= false;
  if Assigned(Stream) then
    begin
      Stream.Free;
      _Stream:= nil;
    end;
  if Assigned(OnClose) then
    OnClose(Self);
end;

procedure Ti8008IOPortfile.Add;
begin
  case Porttype of
    ptIN  : begin
              _IOData.Add(TByteRow.Create(Ti8008IPorts.Count));
              if Assigned(OnAdd) then
                OnAdd(Self);
              Modified:= true;
            end;
    ptOUT : begin
              _IOData.Add(TByteRow.Create(Ti8008OPorts.Count));
              if Assigned(OnAdd) then
                OnAdd(Self);
              Modified:= true;                
            end;
  end;
end;

procedure Ti8008IOPortfile.Insert(Row: Integer);
begin
  if (Row >= 0) and (Row < Rows) then
    case Porttype of
      ptIN  : begin
                _IOData.Insert(Row+1,TByteRow.Create(Ti8008IPorts.Count));
                if Assigned(OnInsert) then
                  OnInsert(Self,Row+1);
                Modified:= true;
              end;
      ptOUT : begin
                _IOData.Insert(Row+1,TByteRow.Create(Ti8008OPorts.Count));
                if Assigned(OnInsert) then
                  OnInsert(Self,Row+1);
                Modified:= true;
              end;
    end;
end;

procedure Ti8008IOPortfile.Replicate(Row: Integer);
var
  ByteRow: TByteRow;
begin
  if (Row >= 0) and (Row < Rows) then
    case Porttype of
      ptIN  : begin
                ByteRow:= _IOData.Items[Row];
                if Assigned(ByteRow) then
                  begin
                    _IOData.Insert(Row+1,TByteRow.Create(ByteRow));
                    if Assigned(OnReplicate) then
                      OnReplicate(Self,Row+1);
                    Modified:= true;
                  end;
              end;
      ptOUT : begin
                ByteRow:= _IOData.Items[Row];
                if Assigned(ByteRow) then
                  begin
                    _IOData.Insert(Row+1,TByteRow.Create(ByteRow));
                    if Assigned(OnReplicate) then
                      OnReplicate(Self,Row+1);
                    Modified:= true;
                  end;
              end;
    end;
end;

procedure Ti8008IOPortfile.Delete(Row: Integer);
var
  Item: TObject;
begin
  if (Row >= 0) and (Row < Rows) then
    begin
      Item:= _IOData.Items[Row];
      if Assigned(Item) then
        Item.Free;
      _IOData.Delete(Row);
      if Assigned(OnDelete) then
        OnDelete(Self,Row);
      Modified:= true;        
    end;
end;

procedure Ti8008IOPortfile.Clear;
var
  Item: TObject;
begin
  while _IOData.Count > 0 do
    begin
      Item:= _IOData.Items[_IOData.Count-1];
      if Assigned(OnDelete) then
        OnDelete(Self,_IOData.Count-1);
      if Assigned(Item) then
        Item.Free;
      _IOData.Delete(_IOData.Count-1);
      Modified:= true;      
    end;
end;

function Ti8008IOPortfile.Save: Integer;
var
  i: Integer;
  Item: TByteRow;
begin
  if Assigned(Stream) then
    try
      Stream.Position:= 0;
      Stream.Size:= 0;
      if Assigned(OnStartProgress) then
        OnStartProgress(Self,0,_IOData.Count);
      for i:= 0 to _IOData.Count-1 do
        begin
          Item:= _IOData.Items[i];
          if Assigned(Item) then
            Item.SaveToStream(Stream);
          if Assigned(OnProgress) then
            OnProgress(Self,i+1);
        end;
      if Assigned(OnEndProgress) then
        OnEndProgress(Self);
      Modified:= false;
      result:= NO_ERROR;
    except
      result:= FILE_SAVE_ERROR;
    end
  else
    result:= NO_ERROR;
  _Error:= result <> NO_ERROR;  
end;

function Ti8008IOPortfile.SaveAs(Filename: TFilename): Integer;
var
  Ext: String;
  tmpStream: TFileStream;
begin
  result:= NO_ERROR;
  Ext:= LowerCase(ExtractFileExt(Filename));
  if Ext = '.pin' then
    _Porttype:= ptIN
  else
    if Ext = '.pout' then
      _Porttype:= ptOUT
    else
      _Porttype:= ptUnknown;
  if Porttype <> ptUnknown then
    if FileExists(Filename) then
      begin
        // Open
        try
          tmpStream:= TFileStream.Create(Filename,fmOpenReadWrite,fmShareExclusive);
          if Assigned(Stream) then
            Stream.Free;
          _Stream:= tmpStream;
          _Filename:= Filename;
          // Save Data
          Stream.Position:= 0;
          Stream.Size:= 0;
          result:= Save;
          if Assigned(OnOpen) then
            OnOpen(Self);
        except
          result:= FILE_SAVE_ERROR;
        end;
      end
    else
      begin
        // Create
        try
          tmpStream:= TFileStream.Create(Filename,fmCreate,fmShareExclusive);
          if Assigned(Stream) then
            Stream.Free;
          _Stream:= tmpStream;
          _Filename:= Filename;
          // Save Data
          Stream.Position:= 0;
          Stream.Size:= 0;
          result:= Save;
          if Assigned(OnOpen) then
            OnOpen(Self);          
        except
          result:= FILE_CREATE_ERROR;
        end;
      end;
  _Error:= result <> NO_ERROR;
end;
{ ***** Ti8008IOPortFile ****** }
{ ********* TByteRow ********** }
procedure TByteRow.setItems(Index: Byte; Value: Byte);
begin
  if Index < Size then
    _List[Index]:= Value;
end;

function TByteRow.getItems(Index: Byte): Byte;
begin
  if Index < Size then
    result:= _List[Index]
  else
    result:= 0;
end;

procedure TByteRow.SaveToStream(Stream: TStream);
var
  i: Byte;
begin
  if Assigned(Stream) then
    for i:= 0 to Size-1 do
      Stream.Write(_List[i],SizeOf(_List[i]));
end;

constructor TByteRow.Create(Size: Byte);
begin
  inherited Create;
  _Size:= Size;
  SetLength(_List,_Size);
end;

constructor TByteRow.Create(Size: Byte; Stream: TStream);
var
  i: Byte;
begin
  Create(Size);
  if Assigned(Stream) then
    for i:= 0 to Size-1 do
      Stream.Read(_List[i],SizeOf(_List[i]));
end;

constructor TByteRow.Create(ByteRow: TByteRow);
var
  i: Byte;
begin
  if Assigned(ByteRow) then
    begin
      Create(ByteRow.Size);
      for i:= 0 to Size-1 do
        _List[i]:= ByteRow.Items[i];
    end
  else
    Create(1);
end;

destructor TByteRow.Destroy;
begin
  SetLength(_List,0);
  inherited;
end;
{ ********* TByteRow ********** }
end.
