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

procedure CmdEcho(const UserInput: string);
begin
    writeln(UserInput);
end;

procedure CmdPwd;
begin
    writeln(GetCurrentDir);
end;

procedure CmdRf(const FileName: string);
var
  MyFile: TextFile;
begin
  if not FileExists(FileName) then
  begin
    writeln('File not found: ', FileName);
    exit;
  end;
  assign(MyFile, FileName);
  erase(MyFile);
end;

procedure CmdCd(const Path: string);
begin
    if Path = '' then
        ChDir(GetUserDir)
    else
        ChDir(Path);
end;

procedure CmdCat(const FileName: string);
var
    MyFile: TextFile;
    text: string;
begin
    if not FileExists(FileName) then
    begin
        writeln('File not found: ', FileName);
        exit;
    end;

    assign(MyFile, FileName);
    reset(MyFile);

    while not eof(MyFile) do
    begin
        readln(MyFile, text);
        writeln(text)
    end;
end;


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

    assign(MyFile, FileName);
    rewrite(MyFile);
    close(MyFile);

    writeln('File created: ', FileName);
end;

procedure CmdRename(const FileName, NewFileName: string);
var
  MyFile: TextFile;
begin
  assign(MyFile, FileName);
  if FileExists(FileName) then
    rename(MyFile, NewFileName)
  else
  begin
    writeln('File does not exist: ', FileName);
    exit;
  end;
  writeln('Successfully renamed the file!');
end;

procedure CmdWriteFile(const FileName, UserText: string);
var
  MyFile: TextFile;
begin
  assign(MyFile, FileName);
  if FileExists(FileName) then
    append(MyFile)
  else
  begin
    writeln('File does not exist. Creating one');
    rewrite(MyFile);
  end;
  writeln(MyFile, UserText);
  close(MyFile);
end;

procedure CmdHelp(const Topic: string);
begin
    if Topic = 'cd' then
    begin
      writeln('cd        - change directory');
      writeln('cd ..     - go up one directory');
      exit;
    end;
    if Topic = '' then
    begin
        writeln('Available commands: ');
        writeln('write <FILE> <TEXT> - write text to a file');
        writeln('cd                  - change directory');
        writeln('pwd                 - show current directory');
        writeln('touch <FILE>        - create a file');
        writeln('cat                 - read a file');
        writeln('clear               - clear the screen');
        writeln('exit                - exit terminal');
        exit;
    end;
end;

procedure ShowPrompt;
begin
  Write(GetUserName, '@', GetCurrentFolderName, ' $ ');
end;

const
    FirstCharPos = 1;
var
    cmd, arg, arg2, input: string;
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
            cmd := Copy(input, FirstCharPos, SpacePos - FirstCharPos);
            ArgStart := SpacePos + FirstCharPos;
            ArgLength := Length(input) - SpacePos;
            arg := Trim(Copy(input, ArgStart, ArgLength));
            SpacePos := Pos(' ', arg);
            if SpacePos > 0 then
              begin
                ArgStart := SpacePos + FirstCharPos;
                ArgLength := Length(arg) - SpacePos;
                arg2 := Trim(Copy(arg, ArgStart, ArgLength));
                arg := Copy(arg, FirstCharPos, SpacePos - FirstCharPos);
              end
            else
              arg2 := '';
        end
        else
        begin
            cmd := input;
            arg := '';
            arg2 := '';
        end;

        Case cmd of
          'rename': CmdRename(arg, arg2);
          'rf': CmdRf(arg);
          'write': CmdWriteFile(arg, arg2);
          'echo': CmdEcho(arg);
          'cd': CmdCd(arg);
          'cat': CmdCat(arg);
          'help': CmdHelp(arg);
          'clear': ClrScr;
          'pwd': CmdPwd;
          'touch': CmdTouch(arg);
        end;
    until cmd = 'exit';
end.
