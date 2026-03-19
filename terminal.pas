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

procedure ShowDir;
begin
    write(GetUserName, ' ', GetCurrentDir, '$');
end;
begin
    writeln(ShowDir)
end.
