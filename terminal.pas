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
  writeln('File deleted successfully');
end;

procedure CmdCd(const Path: string);
begin
    if Path = '' then
      ChDir(GetUserDir)
    else if DirectoryExists(Path) then
      ChDir(Path)
    else
      writeln('Directory does not exist.');
end;

procedure CmdLs(const Path: string);
var
  FullPath: string;
  FileInfo: TSearchRec;
begin
    FullPath := Path;
    if Path = '' then
      FullPath := GetCurrentDir;
    if not DirectoryExists(FullPath) then
    begin
        writeln('Directory does not exist.');
        exit;
    end;

    if FindFirst(FullPath + '/*', faAnyFile, FileInfo) = 0 then
    begin
        repeat
            writeln(FileInfo.Name + #9 + IntToStr(FileInfo.Size));
        until FindNext(FileInfo) <> 0;
        FindClose(FileInfo);
    end;
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
    close(MyFile);
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
        writeln('rename <OLDNAME> <NEWNAME> - renames a file');
        writeln('write <FILE> <TEXT>        - write text to a file');
        writeln('cd                         - change directory');
        writeln('ls <DIRECTORY>             - list files in current directory');
        writeln('pwd                        - show current directory');
        writeln('touch <FILE>               - create a file');
        writeln('cat                        - read a file');
        writeln('clear                      - clear the screen');
        writeln('exit                       - exit terminal');
        exit;
    end;
end;

procedure ExecuteCommand(const input: string);
const
  FirstCharPos = 1;
var
    cmd, arg, arg2, CleanInput: string;
    SpacePos, ArgStart, ArgLength: integer;
begin
  CleanInput := Trim(input);
  if CleanInput = '' then
    exit;

  SpacePos := Pos(' ', CleanInput);

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
    'ls': CmdLs(arg);
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
end;

procedure ExecuteLine(const UserInput: string);
const
  FirstCharPos = 1;
  CmdBreak = 2;
var
  AndPos: integer;
  CurrentCmd, Rest: string;
begin
  AndPos := Pos('&&', UserInput);

  if AndPos > 0 then
  begin
    CurrentCmd := Trim(Copy(UserInput, FirstCharPos, AndPos - FirstCharPos));
    Rest := Trim(Copy(UserInput, AndPos + CmdBreak, Length(UserInput)));

    if CurrentCmd <> '' then
      ExecuteCommand(CurrentCmd);

    if Rest <> '' then
      ExecuteLine(Rest);
  end
  else
  begin
    if Trim(UserInput) <> '' then
      ExecuteCommand(Trim(UserInput));
  end;
end;

procedure ShowPrompt;
begin
  Write(GetUserName, '@', GetCurrentFolderName, ' $ ');
end;

var
  UserInput: string;
begin
    ClrScr;
    repeat
        ShowPrompt;
        readln(UserInput);
        UserInput := Trim(UserInput);

        if UserInput = 'exit' then
          break;
        ExecuteLine(UserInput);
    until false;
end.
