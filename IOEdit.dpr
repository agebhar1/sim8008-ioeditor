program IOEdit;

uses
  Forms, Windows, SysUtils, Dialogs,
  uMainForm in 'uMainForm.pas' {MainForm},
  uIOClasses in 'uIOClasses.pas',
  uProcessor in '..\shared\uProcessor.pas',
  uAssembler in '..\shared\uAssembler.pas',
  uResourceStrings in '..\shared\uResourceStrings.pas',
  uASMProgress in '..\shared\uASMProgress.pas' {ASMProgressForm},
  uTimer in '..\shared\uTimer.pas',
  uEditForm in '..\shared\uEditForm.pas' {EditForm},
  uView in '..\shared\uView.pas',
  uInfoForm in 'uInfoForm.pas' {InfoForm},
  uFileVersion in '..\shared\uFileVersion.pas';

{$R *.res}

var
  Mutex: THandle;
//  Splash: TInfoForm;
  i: Integer;
  Str: String;

begin
  Application.Initialize;
  Application.Title := '8008 I/O Editor';
  Application.CreateForm(TMainForm, MainForm);
  Mutex:= CreateMutex(nil,true,'Sim8008-V2');
//  if GetLastError <> ERROR_ALREADY_EXISTS then
//    begin
//      Splash:= TInfoForm.Create(nil);
//      Splash.ShowSplash;
//      Splash.Free;
//      ReleaseMutex(Mutex);
//    end;
  if GetLastError = ERROR_ALREADY_EXISTS then
    begin
      if (ParamCount > 0) then
        begin
          i:= 2;
          while i <= ParamCount do
            begin
              Str:= LowerCase(ParamStr(i));
              if Copy(Str,1,2) = '-l' then    // Language
                begin
                  Delete(Str,1,2);
                  if Str = 'ger' then
                    MainForm.setLanguage(lGerman)
                  else
                    if Str = 'eng' then
                      MainForm.setLanguage(lEnglish);
                end
              else
                if Copy(Str,1,2) = '-r' then  // Radix
                  begin
                    Delete(Str,1,2);
                    if Str = 'oct' then
                      MainForm.setRadix(rOctal)
                    else
                      if Str = 'dec' then
                        MainForm.setRadix(rDecimal)
                      else
                        if Str = 'hex' then
                          MainForm.setRadix(rHexadecimal)
                        else
                          if Str = 'bin' then
                            MainForm.setRadix(rBinary)
                  end;
              Inc(i);
            end;
          if FileExists(ParamStr(1)) then
            MainForm.Open(ParamStr(1));
        end;
      Application.Run;
    end
  else
    ReleaseMutex(Mutex);  
end.
