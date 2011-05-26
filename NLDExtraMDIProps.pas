{ *************************************************************************** }
{                                                                             }
{ NLDExtraMDIProps  -  www.nldelphi.com Open Source designtime component      }
{                                                                             }
{ Initiator: Albert de Weerd (aka NGLN)                                       }
{ License: Free to use, free to modify                                        }
{ Website: http://www.nldelphi.com/forum/forumdisplay.php?f=128               }
{ SVN path: http://svn.nldelphi.com/nldelphi/opensource/ngln/nldextramdiprops }
{                                                                             }
{ *************************************************************************** }
{                                                                             }
{ Edit by: Albert de Weerd                                                    }
{ Date: May 28, 2008                                                          }
{ Version: 2.0.0.2                                                            }
{ Last edit: May 27, 2011                                                     }
{                                                                             }
{ *************************************************************************** }

unit NLDExtraMDIProps;

interface

uses
  Classes, Windows, Graphics, Messages, Forms, Math, SysUtils, Contnrs;

type
  TNLDPicture = class(TComponent)
  private
    FBitmap: TBitmap;
    FBitmapResName: String;
    FFileName: String;
    FOnChange: TNotifyEvent;
    FPicture: TPicture;
    procedure PictureChanged(Sender: TObject);
    procedure SetBitmapResName(const Value: String);
    procedure SetFileName(const Value: String);
    procedure SetPicture(Value: TPicture);
  protected
    procedure Changed; virtual;
  public
    procedure Assign(Source: TPersistent); override;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Empty: Boolean; virtual;
    property Bitmap: TBitmap read FBitmap;
  published
    property BitmapResName: String read FBitmapResName write SetBitmapResName;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property FileName: String read FFileName write SetFileName;
    property Picture: TPicture read FPicture write SetPicture;
  end;

  TNLDExtraMDIProps = class(TComponent)
  private
    FBGPicture: TNLDPicture;
    FBrush: HBRUSH;
    FChilds: TList;
    FCleverMaximizing: Boolean;
    FClientWnd: HWND;
    FOldClientWndProc: TFarProc;
    FOnChange: TNotifyEvent;
    FShowScrollBars: Boolean;
    FShowClientEdge: Boolean;
    procedure BackgroundPictureChanged(Sender: TObject);
    procedure NewClientWndProc(var Message: TMessage);
    procedure SetBackgroundPicture(Value: TNLDPicture);
    procedure SetShowClientEdge(Value: Boolean);
    procedure SetShowScrollBars(Value: Boolean);
    procedure SortChildsByArea;
  protected
    procedure Changed; virtual;
    procedure Notification(AComponent: TComponent; Operation: TOperation);
      override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property BackgroundPicture: TNLDPicture read FBGPicture
      write SetBackgroundPicture stored True;
    property CleverMaximizing: Boolean read FCleverMaximizing write
      FCleverMaximizing default False;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property ShowClientEdge: Boolean read FShowClientEdge
      write SetShowClientEdge default True;
    property ShowScrollBars: Boolean read FShowScrollBars
      write SetShowScrollBars default True;
  end;

implementation

type
  TWind = (N, E, S, W);

function RectArea(const ARect: TRect): Integer;
begin
  Result := (ARect.Right - ARect.Left) * (ARect.Bottom - ARect.Top);
end;

function RectWidth(const ARect: TRect): Integer;
begin
  Result := ARect.Right - ARect.Left;
end;

function RectHeight(const ARect: TRect): Integer;
begin
  Result := ARect.Bottom - ARect.Top;
end;

function BiggestSpareRect(const BigRect, SmallRect: TRect): TRect;
var
  Area: array[TWind] of Integer;
  Wind: TWind;
  BiggestArea: TWind;
begin
  Area[N] := RectWidth(BigRect) *
    Min(RectHeight(BigRect), SmallRect.Top - BigRect.Top);
  Area[E] := Min(RectWidth(BigRect), BigRect.Right - SmallRect.Right) *
    RectHeight(BigRect);
  Area[S] := RectWidth(BigRect) *
    Min(RectHeight(BigRect), BigRect.Bottom - SmallRect.Bottom);
  Area[W] := Min(RectWidth(BigRect), SmallRect.Left - BigRect.Left) *
    RectHeight(BigRect);
  BiggestArea := N;
  for Wind := N to W do
    if Area[Wind] > Area[BiggestArea] then
      BiggestArea := Wind;
  CopyRect(Result, BigRect);
  case BiggestArea of
    N: Result.Bottom := Min(BigRect.Bottom, SmallRect.Top);
    E: Result.Left := Max(BigRect.Left, SmallRect.Right);
    S: Result.Top := Max(BigRect.Top, SmallRect.Bottom);
    W: Result.Right := Min(BigRect.Right, SmallRect.Left);
  end;
end;

{ TNLDPicture }

procedure TNLDPicture.Assign(Source: TPersistent);
begin
  if Source is TNLDPicture then
  begin
    FBitmapResName := TNLDPicture(Source).FBitmapResName;
    FFileName := TNLDPicture(Source).FFileName;
    FOnChange := TNLDPicture(Source).FOnChange;
    FPicture.Assign(TNLDPicture(Source).FPicture);
  end
  else
    inherited Assign(Source);
end;

procedure TNLDPicture.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

constructor TNLDPicture.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPicture := TPicture.Create;
  FBitmap := TBitmap.Create;
  FPicture.OnChange := PictureChanged;
  if AOwner is TNLDExtraMDIProps then
  begin
    Name := 'SubPicture';
    SetSubcomponent(True);
  end;
end;

destructor TNLDPicture.Destroy;
begin
  FBitmap.Free;
  FPicture.Free;
  inherited Destroy;
end;

function TNLDPicture.Empty: Boolean;
begin
  Result := not Assigned(FPicture.Graphic);
  if not Result then
    Result := FPicture.Graphic.Empty;
end;

procedure TNLDPicture.PictureChanged(Sender: TObject);
begin
  if Empty then
  begin
    FBitmap.Width := 0;
    FBitmap.Height := 0;
  end
  else
  begin
    FBitmap.Width := FPicture.Width;
    FBitmap.Height := FPicture.Height;
    FBitmap.Canvas.Draw(0, 0, FPicture.Graphic);
    if not (csDesigning in ComponentState) then
    begin
      FFileName := '';
      FBitmapResName := '';
    end;
  end;
  Changed;
end;

procedure TNLDPicture.SetBitmapResName(const Value: String);
begin
  if FBitmapResName <> Value then
  begin
    FFileName := '';
    if csDesigning in ComponentState then
    begin
      FBitmapResName := Value;
      if Assigned(FPicture.Graphic) then
        FPicture.Graphic := nil;
    end
    else
      FPicture.Bitmap.LoadFromResourceName(HInstance, Value);
  end;
end;

procedure TNLDPicture.SetFileName(const Value: String);
begin
  if FFileName <> Value then
  begin
    FBitmapResName := '';
    if csDesigning in ComponentState then
    begin
      FFileName := Value;
      if Assigned(FPicture.Graphic) then
        FPicture.Graphic := nil;
    end
    else
      FPicture.LoadFromFile(Value);
  end;
end;

procedure TNLDPicture.SetPicture(Value: TPicture);
begin
  FPicture.Assign(Value);
  if Assigned(FPicture.Graphic) then
  begin
    FBitmapResName := '';
    FFileName := '';
  end;
end;

{ TNLDExtraMDIProps }

type
  TChildInfo = class(TObject)
  private
    FBounds: TRect;
    FChild: HWND;
    FMDIProps: TNLDExtraMDIProps;
    FOldWndProc: Pointer;
    procedure NewWndProc(var Message: TMessage);
  end;

procedure TChildInfo.NewWndProc(var Message: TMessage);
var
  MaxRect: TRect;
  i: Integer;
  WindowPlacement: TWindowPlacement;
begin
  if FMDIProps.CleverMaximizing then
    if Message.Msg = WM_SYSCOMMAND then
      if ((Message.WParam and $FFF0) = SC_MAXIMIZE) and
          (Hi(GetKeyState(VK_SHIFT)) <> 0) then
        begin
          FMDIProps.SortChildsByArea;
          GetClientRect(FMDIProps.FClientWnd, MaxRect);
          for i := 0 to FMDIProps.FChilds.Count - 1 do
            if TChildInfo(FMDIProps.FChilds[i]) <> Self then
              MaxRect := BiggestSpareRect(MaxRect,
                TChildInfo(FMDIProps.FChilds[i]).FBounds);
          if not (EqualRect(FBounds, MaxRect) or IsRectEmpty(MaxRect)) then
          begin
            WindowPlacement.Length := SizeOf(TWindowPlacement);
            GetWindowPlacement(FChild, @WindowPlacement);
            WindowPlacement.rcNormalPosition := MaxRect;
            SetWindowPlacement(FChild, @WindowPlacement);
            Exit;
          end;
        end;
  with Message do
    Result := CallWindowProc(FOldWndProc, FChild, Msg, WParam, LParam);
end;

function GetChildInfo(Childs: TList; AChild: HWND): TChildInfo;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Childs.Count - 1 do
    if TChildInfo(Childs[i]).FChild = AChild then
    begin
      Result := TChildInfo(Childs[i]);
      Break;
    end;
end;

{Remark: this version of NLDExtraMDIProps simply expects AOwner.FormStyle to
remain fsMDIForm. To be notified when the FormStyle property changes, you
would need an AOwner.WndProc-hook and catch CM_SHOWINGCHANGED.}

procedure TNLDExtraMDIProps.BackgroundPictureChanged(Sender: TObject);
begin
  PostMessage(FClientWnd, WM_PAINT, 0, 0);
  Changed;
end;

procedure TNLDExtraMDIProps.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

constructor TNLDExtraMDIProps.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBGPicture := TNLDPicture.Create(Self);
  FBGPicture.FreeNotification(Self);
  FBGPicture.OnChange := BackgroundPictureChanged;
  FShowScrollBars := True;
  FShowClientEdge := True;
  if Assigned(AOwner) then
    if AOwner is TForm then
      if TForm(AOwner).FormStyle = fsMDIForm then
      begin
        TForm(AOwner).HandleNeeded;
        FClientWnd := TForm(AOwner).ClientHandle;
        FOldClientWndProc := Pointer(GetWindowLong(FClientWnd, GWL_WNDPROC));
        SetWindowLong(FClientWnd, GWL_WNDPROC,
          Integer(MakeObjectInstance(NewClientWndProc)));
        FBrush := TForm(AOwner).Brush.Handle;
        FChilds := TObjectList.Create(True);
      end;
end;

destructor TNLDExtraMDIProps.Destroy;
begin
  if FChilds <> nil then
    FChilds.Free;
  SetWindowLong(FClientWnd, GWL_WNDPROC, Integer(FOldClientWndProc));
  inherited Destroy;
end;

procedure TNLDExtraMDIProps.NewClientWndProc(var Message: TMessage);
const
  ScrollStyle = WS_HSCROLL or WS_VSCROLL;
  EdgeStyle = WS_EX_CLIENTEDGE;
var
  DC: HDC;
  R: TRect;
  Left: Integer;
  Top: Integer;
  Right: Integer;
  Bottom: Integer;
  Style: Integer;
  ChildInfo: TChildInfo;
begin
  case Message.Msg of
    WM_ERASEBKGND:
      begin
        if Assigned(FBGPicture) then
          Message.Result := 1
        else
          Message.Result := 0;
        Exit;
      end;
    WM_PAINT:
      if Assigned(FBGPicture) then
      begin
        DC := GetDC(FClientWnd);
        try
          GetClientRect(FClientWnd, R);
          if not FBGPicture.Empty then
          begin
            Left := (R.Right - FBGPicture.Bitmap.Width) div 2;
            Top := (R.Bottom - FBGPicture.Bitmap.Height) div 2;
            Right := Left + FBGPicture.Bitmap.Width;
            Bottom := Top + FBGPicture.Bitmap.Height;
            BitBlt(DC, Left, Top, Right - Left, Bottom - Top,
              FBGPicture.Bitmap.Canvas.Handle, 0, 0, SRCCOPY);
            ExcludeClipRect(DC, Left, Top, Right, Bottom);
          end;
          FillRect(DC, R, FBrush);
        finally
          ReleaseDC(FClientWnd, DC);
        end;
      end;
    WM_NCCALCSIZE:
      begin
        Style := GetWindowLong(FClientWnd, GWL_STYLE);
        if not FShowScrollBars and ((Style and ScrollStyle) <> 0) then
          SetWindowLong(FClientWnd, GWL_STYLE, Style and not ScrollStyle);
        Style := GetWindowLong(FClientWnd, GWL_EXSTYLE);
        if not FShowClientEdge and ((Style and EdgeStyle) <> 0) then
          SetWindowLong(FClientWnd, GWL_EXSTYLE, Style and not EdgeStyle);
      end;
    WM_MDICREATE:
      with Message do
      begin
        Result := CallWindowProc(FOldClientWndProc, FClientWnd, Msg, WParam,
          LParam);
        if Result <> 0 then
        begin
          ChildInfo := TChildInfo.Create;
          ChildInfo.FChild := Result;
          ChildInfo.FMDIProps := Self;
          ChildInfo.FOldWndProc := Pointer(GetWindowLong(Result, GWL_WNDPROC));
          SetWindowLong(Result, GWL_WNDPROC,
            Integer(MakeObjectInstance(ChildInfo.NewWndProc)));
          FChilds.Add(ChildInfo);
        end;
        Exit;
      end;
    WM_MDIDESTROY:
      begin
        ChildInfo := GetChildInfo(FChilds, Message.WParam);
        if ChildInfo <> nil then
        begin
          SetWindowLong(ChildInfo.FChild, GWL_WNDPROC,
            Integer(ChildInfo.FOldWndProc));
          FChilds.Remove(ChildInfo);
        end;
      end;
  end;
  with Message do
    Result := CallWindowProc(FOldClientWndProc, FClientWnd, Msg, WParam,
      LParam);
end;

procedure TNLDExtraMDIProps.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (AComponent = FBGPicture) and (Operation = opRemove) then
    FBGPicture := nil;
end;

procedure TNLDExtraMDIProps.SetBackgroundPicture(Value: TNLDPicture);
begin
  if Assigned(FBGPicture) then
    FBGPicture.Assign(Value);
end;

procedure TNLDExtraMDIProps.SetShowClientEdge(Value: Boolean);
begin
  if FShowClientEdge <> Value then
  begin
    FShowClientEdge := Value;
    PostMessage(FClientWnd, WM_NCCALCSIZE, 0, 0);
    Changed;
  end;
end;

procedure TNLDExtraMDIProps.SetShowScrollBars(Value: Boolean);
begin
  if FShowScrollBars <> Value then
  begin
    FShowScrollBars := Value;
    PostMessage(FClientWnd, WM_NCCALCSIZE, 0, 0);
    Changed;
  end;
end;

function CompareChildArea(Item1, Item2: Pointer): Integer;
begin
  with TChildInfo(Item1) do
  begin
    GetWindowRect(FChild, FBounds);
    ScreenToClient(FMDIProps.FClientWnd, FBounds.TopLeft);
    ScreenToClient(FMDIProps.FClientWnd, FBounds.BottomRight);
  end;
  with TChildInfo(Item2) do
  begin
    GetWindowRect(FChild, FBounds);
    ScreenToClient(FMDIProps.FClientWnd, FBounds.TopLeft);
    ScreenToClient(FMDIProps.FClientWnd, FBounds.BottomRight);
    Result := RectArea(FBounds) - RectArea(TChildInfo(Item1).FBounds);
  end;
end;

procedure TNLDExtraMDIProps.SortChildsByArea;
begin
  FChilds.Sort(CompareChildArea);
end;

end.
