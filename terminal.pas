program terminal;
{$mode objfpc}

uses
    crt, SysUtils, Classes;

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
const
  Tabulation = #9;
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
          if (FileInfo.Name <> '.') and (FileInfo.Name <> '..') then
            writeln(FileInfo.Name);
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
        writeln('rf <FILE>                  - remove a file');
        writeln('pwd                        - show current directory');
        writeln('touch <FILE>               - create a file');
        writeln('cat                        - read a file');
        writeln('clear                      - clear the screen');
        writeln('exit                       - exit terminal');
        writeln('mkdir <DIR>                - create a directory');
        writeln('rmdir <DIR>                - remove a directory');
        writeln('rm <DIRECTORY>             - remove a (non-empty) directory');
        exit;
    end;
end;

procedure CmdMkDir(const DirName: string);
begin
  if DirectoryExists(DirName) then
  begin
    writeln('Directory already exists.');
    exit;
  end;
  if not ForceDirectories(DirName) then
  begin
    writeln('Failed to create directory.');
    exit;
  end;
end;

procedure CmdRmDir(const DirName: string);
begin
  if not DirectoryExists(DirName) then
  begin
    writeln('Directory does not exist.');
    exit;
  end;
  if not RemoveDir(DirName) then
  begin
    writeln('Failed to remove directory. Check if the directory is empty.');
    exit;
  end;
end;

procedure CmdRm(const DirName: string);
var
  Files: TSearchRec;
begin
  if not DirectoryExists(DirName) then
  begin
    writeln('Directory does not exist.');
    exit;
  end;
  if FindFirst(IncludeTrailingPathDelimiter(DirName) + '*', faAnyFile, Files) = 0 then
    begin
      try
        repeat
          if (Files.Name <> '.') and (Files.Name <> '..') then
          begin
            if (Files.Attr and faDirectory <> 0) then
              CmdRm(IncludeTrailingPathDelimiter(DirName) + Files.Name)
            else
              DeleteFile(IncludeTrailingPathDelimiter(DirName) + Files.Name);
          end;
        until FindNext(Files) <> 0;
      finally
        FindClose(Files);
      end;
    end;
    RemoveDir(DirName);
  end;

function JoinStrings(const List: TStringList; const Delimiter: string): string;
var
  i: integer;
begin
  Result := '';
  for i := 0 to List.Count - 1 do
  begin
    if i > 0 then
      Result := Result + Delimiter;
    Result := Result + List[i];
  end;
end;

procedure ParseCommand(const Input: string; out Cmd: string; out Args: TStringList);
var
  i, StartPos: Integer;
  CleanInput: string;
begin
  Args := TStringList.Create;
  CleanInput := Trim(Input);
  if CleanInput = '' then exit;

  StartPos := 1;
  for i := 1 to Length(CleanInput) do
  begin
    if CleanInput[i] = ' ' then
    begin
      if StartPos < i then
        Args.Add(Copy(CleanInput, StartPos, i - StartPos));
      StartPos := i + 1;
    end;
  end;

  if StartPos <= Length(CleanInput) then
    Args.Add(Copy(CleanInput, StartPos, Length(CleanInput) - StartPos + 1));

  Cmd := Args[0];
  Args.Delete(0);
end;

procedure ExecuteCommand(const input: string);
var
  Cmd: string;
  Args: TStringList;
begin
  ParseCommand(input, Cmd, Args);

  if Cmd = '' then
  begin
    Args.Free;
    exit;
  end;

  case Cmd of
    'echo': if Args.Count > 0 then CmdEcho(JoinStrings(Args, ' '));
    'write': if Args.Count > 0 then CmdWriteFile(Args[0], JoinStrings(Args, ' '));
    'touch': if Args.Count > 0 then CmdTouch(Args[0]);
    'cat': if Args.Count > 0 then CmdCat(Args[0]);
    'ls': if Args.Count > 0 then CmdLs(Args[0]) else CmdLs('');
    'pwd': CmdPwd;
    'cd': if Args.Count > 0 then CmdCd(Args[0]) else CmdCd('');
    'rf': if Args.Count > 0 then CmdRf(Args[0]);
    'rename': if Args.Count > 1 then CmdRename(Args[0], Args[1]);
    'help': if Args.Count > 0 then CmdHelp(Args[0]) else CmdHelp('');
    'clear': ClrScr;
    'mkdir': if Args.Count > 0 then CmdMkDir(Args[0]);
    'rmdir': if Args.Count > 0 then CmdRmDir(Args[0]);
    'rm': if Args.Count > 0 then CmdRm(Args[0]);
  else
    writeln('Command not found: ', Cmd);
  end;

  Args.Free;
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
