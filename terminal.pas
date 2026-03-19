program terminal;
{$mode objfpc}

uses
    crt, SysUtils;

function GetUserName: string;
begin
    {$IFDEF WINDOWS}
    Result := GetEnvironmentVariable('USERNAME');
    {$ELSE}
    Result := GetEnvironmentVariable('USER');
    {$ENDIF}

    if Result = '' then
        Result := 'user';
end;

function GetCurrentFolderName: string;
begin
  Result := ExtractFileName(GetCurrentDir);

  if Result = '' then
    Result := GetCurrentDir;
end;

procedure ShowPrompt;
begin
  Write(GetUserName, ' ', GetCurrentFolderName, ' $ ');
end;

begin
    ShowPrompt;
    writeln;
end.
