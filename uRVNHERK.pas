unit uRVNHERK;

interface

uses
  Windows, Forms, SysUtils, StdCtrls, Controls, Classes, LargeArrays, AdoSets,
  Vcl.ExtDlgs, SelectAdoSetDialog, Vcl.Dialogs, SpinFloat, Vcl.ExtCtrls,{ uProgSetRVNHERK,}
  OpWString, uError, DUtils;

type
  TMainForm = class(TForm)
    Memo1: TMemo;
    LabeledEditTriwacoGrid: TLabeledEdit;
    OpenDialogTriwacoGrid: TOpenDialog;
    LabeledEditTroFile: TLabeledEdit;
    OpenDialogTroFileName: TOpenDialog;
    CheckBoxAreaNumbersSpecified: TCheckBox;
    SelectRealAdoSetDialogAreaNrs: TSelectRealAdoSetDialog;
    GroupBoxAreaNrs: TGroupBox;
    LabeledEditAreaNrs: TLabeledEdit;
    LabeledEditSelAreaNrFile: TLabeledEdit;
    OpenDialogSelAreaNrsFile: TOpenDialog;
    SpinFloatEditMinQrch: TSpinFloatEdit;
    LabelMinQrch: TLabel;
    Button1: TButton;
    SaveHerkAdoFileDialog: TSaveTextFileDialog;
    AreaNrsSet: TRealAdoSet;
    X_StartSet: TRealAdoSet;
    Y_StartSet: TRealAdoSet;
    X_DestSet: TRealAdoSet;
    Y_DestSet: TRealAdoSet;
    NIASet: TRealAdoSet;
    BoundNodeSet: TRealAdoSet;
    QrchSet: TRealAdoSet;
    DestCodeSet: TRealAdoSet;
    BoundNodeIDSSet: TRealAdoSet;
    HerkSet: TIntegerAdoSet;
    procedure FormCreate(Sender: TObject);
    procedure LabeledEditTriwacoGridClick(Sender: TObject);
    procedure LabeledEditTroFileClick(Sender: TObject);
    procedure CheckBoxAreaNumbersSpecifiedClick(Sender: TObject);
    procedure LabeledEditAreaNrsClick(Sender: TObject);
    procedure LabeledEditSelAreaNrFileClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation
{$R *.DFM}

Const
    cIni_Files = 'FILES';
    cOptions = 'OPTIONS';
    cIni_InputTriwacoGridFileName = 'TriwacoGrid';
    cIni_InputTroFileName = 'TroFile';
    cIni_AreaNrsFileName = 'AreaNrs';
    cOPT_AreaNrsSpecified = 'AreaNrsSpec';
    cIni_SelectedAreaNrsFile = 'SelctAreaNrsFile';
    MaxKwelOrInfAreaNr = 500;

var
  AllNodes, Initiated: Boolean;
  HerkFileStr, HerkSetStr, AreaSetStr, AreaFileStr, LineFileStr: String;
  f: TextFile;
  LineNr: LongWord;
  NrNodes, NrBoundNodes, BNodIDDefaultValue, SelAreaNr, KwelAreaNr, InfAreaNr,
     DefaultValue, AreaNr: Integer;
  DestCode, MinQrch, Qrch: Double;
  KwelInfTot, KwlArea: Array[ 1..3, 1..MaxKwelOrInfAreaNr ] of Double;
  AreaNrs: Array[ 1..3, 1..MaxKwelOrInfAreaNr ] of Word;
  NrKwelNds: Array[ 1..2, 1..MaxKwelOrInfAreaNr ] of Word;
  i, NrAreas, DestNodeNr, BoundNodeNr: Word;

Function KwelInNode( CurrentNodeNr: Word ): Boolean;
var Qrch: Double;
begin
  Qrch := MainForm.QrchSet[ CurrentNodeNr ];
  KwelInNode := ( Qrch > MinQrch );
end;

Procedure IncreaseKwelTot( CurrentNodeNr: Word );
var NIA, Qrch: Real;
begin
  NIA := MainForm.NIASet[ CurrentNodeNr ];
  Qrch := MainForm.QrchSet[ CurrentNodeNr ];
  KwelInfTot[ 1, KwelAreaNr ] := KwelInfTot[ 1, KwelAreaNr ] + NIA * Qrch;
  WriteToLogFileFmt( '1 %g %d %s %s', [KwelAreaNr, CurrentNodeNr, GetAdoGetal( NIA ) + ' ' + GetAdoGetal( Qrch )]);
  Inc( NrKwelNds[ 1, KwelAreaNr ] );
end;

Function OriginIsInModel( NodeNr: Word ): Boolean;
Const
  RiverReached    = -1;
  VertOutOfSystem = -0.5;
  SourceReached   = 1;
begin
  DestCode := MainForm.DestCodeSet[ NodeNr ];
  OriginIsInModel := ( DestCode <= RiverReached ) or
                     ( DestCode  = VertOutOfSystem ) or
                     ( DestCode >= SourceReached );
end;

Function OneOfSelAreaNr( AreaNr:Integer ): Boolean;
var bResult: Boolean;
    i: Integer;
begin
  if ( not AllNodes ) then begin
    bResult := False; i := 1;
    While ( ( not bResult ) and ( i <= NrAreas ) ) do begin
      SelAreaNr  := AreaNrs[ 1, i ];
      KwelAreaNr := AreaNrs[ 2, i ];
      InfAreaNr  := AreaNrs[ 3, i ];
      Inc( i );
      bResult := ( AreaNr = SelAreaNr );
    end;
  end else begin
    SelAreaNr  := 1;
    KwelAreaNr := 1;
    InfAreaNr  := 2;
    bResult     := True;
  end;
  OneOfSelAreaNr := bResult;
end;


Procedure CalcDeelGebAreas_Q_Recharge;
  {-Bepaal v.d. deelgebieden het totale oppervlak (DeelGebArea) en de gem.
    Q-Recharge (Q_Recharge)}
var NIA, Qrch: Double;
    i: Word;
begin
  for i:=1 to MaxKwelOrInfAreaNr do begin
    KwlArea[ 1, i ] := 0; kwlArea[ 2, i ] := 0; kwlArea[ 3, i ] := 0;
  end;
  for i:=1 to NrNodes do begin
    if ( not AllNodes ) then
      AreaNr := Trunc( MainForm.AreaNrsSet[ i ] );
    if OneOfSelAreaNr( AreaNr ) then begin
      NIA :=  MainForm.NIASet[ i ];
      Qrch := MainForm.QrchSet[ i ];
      KwlArea[ 1, KwelAreaNr ] := KwlArea[ 1, KwelAreaNr ] + NIA * Qrch;
      KwlArea[ 2, KwelAreaNr ] := KwlArea[ 2, KwelAreaNr ] + NIA;
    end;
  end;
  for i:=1 to MaxKwelOrInfAreaNr do
    if ( KwlArea[ 1, i ] <> 0 ) then
      if ( KwlArea[ 2, i ] <> 0 ) then
        KwlArea[ 1, i ] := KwlArea[ 1, i ] / KwlArea[ 2, i ]
      else
        KwlArea[ 1, i ] := 0;
end;

Function Distance( x1, y1, x2, y2: Double ): Double;
begin
  Distance := sqrt( ( sqr( x1 - x2 ) ) + ( sqr( y1 - y2 ) ) );
end;

Function GetDestNodeNr( CurrentNodeNr: Word ): Word;
var
  x, y, X_Dest, Y_Dest, Dist, NwDist, Qrch: Double;
  j, NodeSel: Word;
begin
  X_Dest := MainForm.X_DestSet[ CurrentNodeNr ];
  Y_Dest := MainForm.Y_DestSet[ CurrentNodeNr ];
  Dist := 1E+20;
  for j:=1 to NrNodes do
    if ( j <> CurrentNodeNr ) then begin
      Qrch := MainForm.QrchSet[ j ];
      if ( Qrch < 0 ) then begin {-Infiltratie in node j}
         x := MainForm.X_StartSet[ j ];
         y := MainForm.Y_StartSet[ j ];
        NwDist := Distance( X_Dest, Y_Dest, x, y );
        if ( NwDist < Dist ) then begin
          Dist    := NwDist;
          NodeSel := j;
        end;
      end;
    end;
  GetDestNodeNr := NodeSel;
  {-Dist: afstand van eindpunt stroombaan tot gevonden node (DestNodeNr)}
  {WriteToLogFile(  'CurrentNodeNr, Dist = ', CurrentNodeNr, ',  '+ GetAcoGetal( Dist ) );}
end;

Procedure IncreaseInfTot( CurrentNodeNr: Word );
var NIA, Qrch: Double;
begin
  NIA := MainForm.NIASet[ CurrentNodeNr ];
  Qrch := MainForm.QrchSet[ CurrentNodeNr ];
  KwelInfTot[ 2, KwelAreaNr ] := KwelInfTot[ 2, KwelAreaNr ] + NIA * Qrch;
  WriteToLogFileFmt( '2 %g %d %s %s', [InfAreaNr,CurrentNodeNr, GetAdoGetal( NIA ),
  GetAdoGetal( Qrch )] );
  KwlArea[ 3, KwelAreaNr ] := KwlArea[ 3 , KwelAreaNr ] + NIA; {-Inf.opp.}
  {-Zet NIA in de inf.knoop op 0 om te voorkomen dat de infiltratie in
    de knoop meer dan 1 keer wordt opgeteld }
  NIA := 0; MainForm.NIASet[ CurrentNodeNr ] := NIA;
  Inc( NrKwelNds[ 2, KwelAreaNr ] );
end;

Procedure WriteOrgDestLine( OrgNodeNr, DestNodeNr: Word );
var X_Dest, Y_Dest, X_Org, Y_Org: Real;
begin
  X_Org := MainForm.X_StartSet[ OrgNodeNr ];
  Y_Org := MainForm.Y_StartSet[ OrgNodeNr ];
  X_Dest := MainForm.X_StartSet[ DestNodeNr ];
  Y_Dest := MainForm.Y_StartSet[ DestNodeNr ];
  Writeln( f, KwelAreaNr );
  Writeln( f, X_Org:9:2,  ',', Y_Org:9:2 );
  Writeln( f, X_Dest:9:2, ',', Y_Dest:9:2 );
  Writeln( f, 'END' );
end;

Function HorOutOfModel( NodeNr: Word ): Boolean;
Const
  HorOutOfSystem  =  0.5;
begin
  DestCode := MainForm.DestCodeSet[ NodeNr ];
  HorOutOfModel := ( DestCode = HorOutOfSystem );
end;

Function GetBoundNodeNr( CurrentNodeNr: Word ): Word;
var
  x, y, X_Dest, Y_Dest, Dist, NwDist: Double;
  j, NodeSel: Word;
  BoundNodeNr: Integer;
begin
  X_Dest := MainForm.X_DestSet[ CurrentNodeNr ];
  Y_Dest := MainForm.Y_DestSet[ CurrentNodeNr ];
  Dist := 1E+20;
  for j:=1 to NrBoundNodes do begin
    BoundNodeNr := Trunc( MainForm.BoundNodeSet[ j ] );
    x := MainForm.X_StartSet[ BoundNodeNr ];
    y := MainForm.Y_StartSet[ BoundNodeNr ];
    NwDist := Distance( X_Dest, Y_Dest, x, y );
    if ( NwDist < Dist ) then begin
      Dist    := NwDist;
      NodeSel := j;
    end;
  end;
  GetBoundNodeNr := NodeSel;
  {-Dist: afstand van eindpunt stroombaan tot gevonden node (DestNodeNr)}
  {WriteToLogFile(  'Boundary: CurrentNodeNr, Dist = ', CurrentNodeNr, ',  '+ GetAcoGetal( Dist ) );}
end;

Procedure WriteBoundNodeIDS;
var
  j: Word;
  BoundNodeNr: Integer;
  BoundNodeIDSStr: String;
  f: Text;
  x, y: Double;
  ID: Integer;
begin
  BoundNodeIDSStr := ChangeFileExt( HerkFileStr, '.bnd' );
  AssignFile( f, BoundNodeIDSStr ); Rewrite( f );
  for j:=1 to NrBoundNodes do begin
    BoundNodeNr := Trunc( MainForm.BoundNodeSet[ j ] );
    x := MainForm.X_StartSet[ BoundNodeNr ];
    y := MainForm.Y_StartSet[ BoundNodeNr ];
    ID := Trunc( MainForm.BoundNodeIDSSet[ BoundNodeNr ] );
    if ( ID <> BNodIDDefaultValue ) then
      Writeln( f, ID+100, ',', x:9:2, ',', y:9:2 );
  end;
  Writeln( f, 'END' ); Writeln( f, 'END' );
  CloseFile( f );
end;

Procedure WriteKwelTotAndInfTot;
var
  i: Integer;
  f: Text;
  KwelTotAndInfTotStr: String;
  Kwel, Inf, Perc, Q_Recharge, DeelGebArea, InfGebArea, Q_RechargeInfGeb: Double;
begin
  KwelTotAndInfTotStr := ChangeFileExt( HerkFileStr, '.kwl' );
  AssignFile( f, KwelTotAndInfTotStr ); Rewrite( f );
  for i:=1 to MaxKwelOrInfAreaNr do begin
    Kwel := KwelInfTot[ 1, i ];
    if ( Kwel <> 0 ) then begin
      Inf  := KwelInfTot[ 2, i ];
      Perc := Abs( 100 * Inf / Kwel );
      Q_Recharge  := KwlArea[ 1, i ];
      DeelGebArea := KwlArea[ 2, i ];
      InfGebArea  := KwlArea[ 3, i ];
      if ( InfGebArea > 0 ) then
        Q_RechargeInfGeb := Inf / InfGebArea
      else
        Q_RechargeInfGeb := 0;
      Writeln( f, i:3, ' ' + GetAdoGetal( Kwel ) + ' ' + GetAdoGetal( Inf  ) + ' ' + GetAdoGetal( Perc  )
               + ' ' + GetAdoGetal( Q_Recharge ) + ' ' + GetAdoGetal( Q_RechargeInfGeb )
               + ' ' + GetAdoGetal( DeelGebArea ) + ' ' + GetAdoGetal( InfGebArea ) + ' ',
               NrKwelNds[ 1, i ], ' ',  NrKwelNds[ 2, i ] );
    end;
  end;
  CloseFile( f );
end;

procedure TMainForm.Button1Click(Sender: TObject);
begin
  Try
    Try
    if not FileExists( LabeledEditTriwacoGrid.text ) then
       raise Exception.CreateFmt( 'File [%s] does not exist.', [LabeledEditTriwacoGrid.text] );
    if not FileExists( LabeledEditTroFile.text ) then
       raise Exception.CreateFmt( 'File [%s] does not exist.', [LabeledEditTroFile.text] );

    with SaveHerkAdoFileDialog do begin
      if execute then begin
         HerkFileStr := ExpandFileName( FileName );
         HerkSetStr := JustName( HerkFileStr );
         if CheckBoxAreaNumbersSpecified.Checked then begin
           SplitFileAndSetStr( LabeledEditAreaNrs.text, AreaFileStr, AreaSetStr );
           if not FileExists( AreaFileStr ) then
             raise Exception.CreateFmt( 'File [%s] does not exist.', [AreaFileStr] );
           if not FileExists( LabeledEditSelAreaNrFile.text ) then
              raise Exception.CreateFmt( 'File [%s] does not exist.', [LabeledEditSelAreaNrFile.text] );
         end;
         AllNodes := not CheckBoxAreaNumbersSpecified.Checked;

         if not AllNodes then begin
            AssignFile( f, AreaFileStr ); Reset( f );
            AreaNrsSet := TRealAdoSet.InitFromOpenedTextFile( f, AreaSetStr, self, LineNr, Initiated );
            if not Initiated then
               raise Exception.CreateFmt('Could not initialise ado set from file [%s].', [AreaFileStr] );
            CloseFile( f );
         end;

         AssignFile( f, LabeledEditTroFile.text ); Reset( f );
         X_StartSet := TRealAdoSet.InitFromOpenedTextFile( f, 'X-STARTPNTS', self, LineNr, Initiated );
         if not Initiated then
            raise Exception.CreateFmt('Could not initialise ado set [%S] from file [%s].', ['X-STARTPNTS', LabeledEditTroFile.text] );
         reset( f ); Y_StartSet := TRealAdoSet.InitFromOpenedTextFile( f, 'Y-STARTPNTS', self, LineNr, Initiated );
         if not Initiated then
            raise Exception.CreateFmt('Could not initialise ado set [%S] from file [%s].', ['Y-STARTPNTS', LabeledEditTroFile.text] );
         reset( f ); X_DestSet := TRealAdoSet.InitFromOpenedTextFile( f, 'X-DESTINATION', self, LineNr, Initiated );
         if not Initiated then
            raise Exception.CreateFmt('Could not initialise ado set [%S] from file [%s].', ['X-DESTINATION', LabeledEditTroFile.text] );
         reset( f ); Y_DestSet := TRealAdoSet.InitFromOpenedTextFile( f, 'Y-DESTINATION', self, LineNr, Initiated );
         if not Initiated then
            raise Exception.CreateFmt('Could not initialise ado set [%S] from file [%s].', ['Y-DESTINATION', LabeledEditTroFile.text] );
         reset( f ); NIASet := TRealAdoSet.InitFromOpenedTextFile( f, 'NODE INFLUENCE AREA=', self, LineNr, Initiated );
         if not Initiated then
            raise Exception.CreateFmt('Could not initialise ado set [%S] from file [%s].', ['NODE INFLUENCE AREA=', LabeledEditTroFile.text] );
         reset( f ); QrchSet := TRealAdoSet.InitFromOpenedTextFile( f, 'Q-RECHARGE', self, LineNr, Initiated );
         if not Initiated then
            raise Exception.CreateFmt('Could not initialise ado set [%S] from file [%s].', ['Q-RECHARGE', LabeledEditTroFile.text] );
         reset( f ); DestCodeSet := TRealAdoSet.InitFromOpenedTextFile( f, 'DESTINATION', self, LineNr, Initiated );
         if not Initiated then
            raise Exception.CreateFmt('Could not initialise ado set [%S] from file [%s].', ['DESTINATION', LabeledEditTroFile.text] );
         CloseFile( f );

         AssignFile( f, LabeledEditTriwacoGrid.text ); Reset( f );
         BoundNodeSet := TRealAdoSet.InitFromOpenedTextFile( f, 'LIST BOUNDARY NODES=', self, LineNr, Initiated );
         if not Initiated then
            raise Exception.CreateFmt('Could not initialise ado set [%S] from file [%s].', ['LIST BOUNDARY NODES=', LabeledEditTroFile.text] );
         CloseFile( f );
         NrNodes := X_StartSet.NrOfElements;
         NrBoundNodes := BoundNodeSet.NrOfElements;
         BNodIDDefaultValue := 0;
         BoundNodeIDSSet :=  TRealAdoSet.CreateF( NrBoundNodes, 'BndNdIDS', BNodIDDefaultValue, self );

         {-Als MinQrch < 0, klap dan het teken van de QrchSet om}
         MinQrch := SpinFloatEditMinQrch.Value;
         if ( MinQrch < 0 ) then begin
           MinQrch := -MinQrch;
           QrchSet.Negate;
         end;

         {-Lees AreaNrs}
         NrAreas := 0;
         if ( not AllNodes ) then begin
            WriteToLogFile(  Format( 'Read file [%s]', [LabeledEditSelAreaNrFile.text] ) );
            AssignFile( f, LabeledEditSelAreaNrFile.text ); Reset( f );
            i := 0;
            While ( not EOF( f ) ) do begin
               {$I-} Readln( f, SelAreaNr, KwelAreaNr, InfAreaNr ); {$I+}
               if ( IOResult <> 0 ) then
                  Raise Exception.CreateFmt( 'Error reading [%s]', [LabeledEditSelAreaNrFile.text] );
               if ( KwelAreaNr <= 0 ) or ( KwelAreaNr > MaxKwelOrInfAreaNr ) or
                  ( InfAreaNr <= 0 ) or ( InfAreaNr > MaxKwelOrInfAreaNr ) then
                  Raise Exception.CreateFmt(  'KwelAreaNr en/of InfAreaNr niet geldig: max = %d ', [MaxKwelOrInfAreaNr] );
               Inc( i );
               AreaNrs[ 1, i ] := SelAreaNr;
               AreaNrs[ 2, i ] := KwelAreaNr;
               AreaNrs[ 3, i ] := InfAreaNr;
            end;
            NrAreas := i;
            CloseFile( f );
            WriteToLogFile(  Format( 'File [%s] read. NrAreas = [%d] ', [LabeledEditSelAreaNrFile.text, NrAreas ] ) );
         end else {-if ( not AllNodes )}
            NrAreas := 1;

         {-Initialiseer NrKwelNds}
         for i:=1 to MaxKwelOrInfAreaNr do begin
            NrKwelNds[ 1, i ] := 0; {-Aant. knopen met kwel}
            NrKwelNds[ 2, i ] := 0; {-idem, waarvan inf.pnt binnen model is gevonden}
         end;

         CalcDeelGebAreas_Q_Recharge;

         for i:=1 to MaxKwelOrInfAreaNr do begin
            KwelInfTot[ 1, i ] := 0; KwelInfTot[ 2, i ] := 0;
         end;

         DefaultValue := 0;
         HerkSet := TIntegerAdoSet.CreateF( NrNodes, HerkSetStr, DefaultValue, self );

         LineFileStr := ChangeFileExt( HerkFileStr, '.lns');
         AssignFile( f, LineFileStr ); Rewrite( f );

         for i:=1 to NrNodes do begin
            if ( not AllNodes ) then
               AreaNr := Trunc( AreaNrsSet[ i ] );
            if KwelInNode( i ) then begin
               if OneOfSelAreaNr( AreaNr ) then begin
                  HerkSet[ i ] := KwelAreaNr;
                  IncreaseKwelTot( i );
                  if OriginIsInModel( i ) then begin
                     DestNodeNr := GetDestNodeNr( i );
                     HerkSet[ DestNodeNr ] := InfAreaNr;
                     IncreaseInfTot( DestNodeNr );
                     WriteOrgDestLine( i, DestNodeNr );
                  end else if HorOutOfModel( i ) then begin
                     BoundNodeNr := GetBoundNodeNr( i );
                     BoundNodeIDSSet[ BoundNodeNr ] := InfAreaNr;
                     WriteOrgDestLine( i, BoundNodeNr );
                  end;
               end;
            end; {-if KwelInNode( i )}
         end; {-for i:=1 to NrNodes}

         Write( f, 'END' ); CloseFile( f );

         AssignFile( f, HerkFileStr ); Rewrite( f );
         HerkSet.ExportToOpenedTextFile( f );
         CloseFile( f );

         WriteBoundNodeIDS;
         WriteKwelTotAndInfTot;

         ShowMessage( 'Ready' );

      end; {-if execute}
    end;
    Except
      On E: Exception do begin
            HandleError( E.Message, True );
      end;
    End;
  Finally
     {$I-} CloseFile( f ); {$I+}
  End;
end;

procedure TMainForm.CheckBoxAreaNumbersSpecifiedClick(Sender: TObject);
begin
  fini.WriteBool( cOptions, cOPT_AreaNrsSpecified, CheckBoxAreaNumbersSpecified.checked );
  GroupBoxAreaNrs.Visible :=  CheckBoxAreaNumbersSpecified.checked;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  S, aFileName, SetIdStr: String;
begin
  InitialiseLogFile;
  Caption :=  ChangeFileExt( ExtractFileName( Application.ExeName ), '' );
  with fini do begin
    S := ReadString( cIni_Files, cIni_InputTriwacoGridFileName, '' );
    if FileExists( S ) then LabeledEditTriwacoGrid.Text := ExpandFileName( S );
    S := ReadString( cIni_Files, cIni_InputTroFileName, '' );
    if FileExists( S ) then LabeledEditTroFile.Text := ExpandFileName( S );
    CheckBoxAreaNumbersSpecified.checked := fini.ReadBool( cOptions, cOPT_AreaNrsSpecified, false );
    GroupBoxAreaNrs.Visible :=  CheckBoxAreaNumbersSpecified.checked;
    S := fini.ReadString( cIni_Files, cIni_AreaNrsFileName, '' );
    SplitFileAndSetStr( S, aFileName, SetIdStr );
    if FileExists( aFileName ) then
      LabeledEditAreaNrs.Text := S;
    S := fini.ReadString( cIni_Files, cIni_SelectedAreaNrsFile, '' );
    if FileExists( S ) then LabeledEditSelAreaNrFile.Text := S;
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
FinaliseLogFile;
end;

procedure TMainForm.LabeledEditAreaNrsClick(Sender: TObject);
var
  SetNames: TStringList;
begin
  SetNames := TStringList.Create;
  with SelectRealAdoSetDialogAreaNrs do begin
    if execute( 1, false, SetNames ) then begin
      LabeledEditAreaNrs.Text := expandFileName( FileName ) + '$' + SetNames[0];
      fini.WriteString( cIni_Files, cIni_AreaNrsFileName, LabeledEditAreaNrs.Text );
    end;
  end;
  SetNames.Free;
end;

procedure TMainForm.LabeledEditSelAreaNrFileClick(Sender: TObject);
begin
   with OpenDialogSelAreaNrsFile do begin
     if execute then begin
        LabeledEditSelAreaNrFile.Text := ExpandFileName( FileName );
        fini.WriteString( cIni_Files, cIni_SelectedAreaNrsFile,
           LabeledEditSelAreaNrFile.Text );
     end;
   end;
end;

procedure TMainForm.LabeledEditTriwacoGridClick(Sender: TObject);
begin
   with OpenDialogTriwacoGrid do begin
      if Execute then begin
         LabeledEditTriwacoGrid.Text := ExpandFileName( FileName );
         fini.WriteString( cIni_Files, cIni_InputTriwacoGridFileName,
         LabeledEditTriwacoGrid.Text );
      end;
   end;
end;

procedure TMainForm.LabeledEditTroFileClick(Sender: TObject);
begin
   with OpenDialogTroFileName do begin
     if Execute then begin
        LabeledEditTroFile.Text := ExpandFileName( FileName );
        fini.WriteString( cIni_Files, cIni_InputTroFileName,
        LabeledEditTroFile.Text );
     end;
   end;
end;

end.
