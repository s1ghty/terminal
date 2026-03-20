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

procedure CmdPwd;
begin
    writeln(GetCurrentDir);
end;

{ Needs to be finished!!!
procedure CmdCd(const Path: string);
begin
    SetCurrentDir(Path);
end;
}

{ Make Cat with Readln(filename, text) showmessage(text)
procedure CmdCat;
begin
    while not eof(MyFile) do
    begin
        readln(MyFile, text);
        ShowMessage(text)
    end;
end;
}

procedure CmdTouch(const FileName: string);
var
    MyFile: TextFile;

begin
    if FileExists(FileName) then
    begin
        writeln('File already exists: ', FileName);
        exit;
    end;
    if FileName = '' then
    begin
        writeln('Invalid file name. Use a proper file name');
        exit;
    end;

    AssignFile(MyFile, FileName);
    Rewrite(MyFile);
    CloseFile(MyFile);

    writeln('File created: ', FileName);
end;

procedure CmdHelp;
begin
    writeln('Available commands: ');
    writeln('clear      - clear the screen');
    writeln('pwd        - show current directory');
    writeln('touch FILE - create a file');
    writeln('exit       - exit terminal');
end;

procedure ShowPrompt;
begin
  Write(GetUserName, '@', GetCurrentFolderName, ' $ ');
end;
var
    cmd, arg, input: string;
    SpacePos, ArgStart, ArgLength: integer;

begin
    ClrScr;
    repeat
        ShowPrompt;
        readln(input);

        { Separates the command and the argument }
        input := Trim(input);
        SpacePos := Pos(' ', input);

        if SpacePos > 0 then
        begin
            cmd := Copy(input, 1, SpacePos - 1);
            ArgStart := SpacePos + 1;
            ArgLength := Length(input) - SpacePos;
            arg := Trim(Copy(input, ArgStart, ArgLength));
        end
        else
        begin
            cmd := input;
            arg := '';
        end;

        Case cmd of
            'help': CmdHelp;
            'clear': ClrScr;
            'pwd': CmdPwd;
            'touch': CmdTouch(arg);
        end;
    until cmd = 'exit';
end.
