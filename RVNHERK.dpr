program RVNHERK;

uses
  Forms,
  Sysutils,
  Dialogs,
  uRVNHERK in 'uRVNHERK.pas' {MainForm},
  uError,
  System.UITypes,
  USelectAdoSetDialog in '..\..\ServiceComponents\Triwaco\AdoSets\SelectAdoSetDialog\USelectAdoSetDialog.pas' {AdoSetsForm};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TAdoSetsForm, AdoSetsForm);
  Try
    Try
      if ( Mode = Interactive ) then begin
        Application.Run;
      end else begin
        {MainForm.GoButton.Click;}
      end;
    Except
      Try WriteToLogFileFmt( 'Error in application: [%s].', [Application.ExeName] ); except end;
      MessageDlg( Format( 'Error in application: [%s].', [Application.ExeName] ), mtError, [mbOk], 0);
    end;
  Finally
  end;

end.
