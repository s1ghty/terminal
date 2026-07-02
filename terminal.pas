program terminal;
{$mode objfpc}

uses
    crt, SysUtils, Classes, Process;

const
  MaxHistory = 1000;
var
  SaveDir: string = '';
  CommandHistory: array[1..MaxHistory] of string;
  HistoryCount: integer = 0;

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

function GetComputerName: string;
begin
  Result := GetEnvironmentVariable('HOSTNAME');
end;

function GetCurrentFolderName: string;
begin
  Result := ExtractFileName(GetCurrentDir);

  if Result = '' then
    Result := GetCurrentDir;
end;

function PromptLength: integer;
begin
  Result := Length(GetUserName) + 1 + Length(GetCurrentFolderName) + 3;
end;

function ConfirmDelete(const Path: string): boolean;
var
  Answer: string;
begin
  write('Are you sure you want to delete "', Path, '" and everything inside? [y/N] ');
  readln(Answer);
  Answer := LowerCase(Trim(Answer));
  Result := (Answer = 'y') or (Answer = 'yes');
end;

procedure CmdEcho(const UserInput: string);
begin
    writeln(UserInput);
end;

procedure CmdPwd;
begin
    writeln(GetCurrentDir);
end;

procedure CmdRmFile(const FileName: string);
begin
  if FileName = '' then
    begin
    writeln('Usage: rm <FILE>');
    exit;
    end;
  if not FileExists(FileName) then
    begin
      writeln('File not found: ', FileName);
      exit;
    end;
    if DeleteFile(FileName) then
      writeln('File deleted successfully.')
    else
      writeln('Failed to delete file.');
end;

procedure CmdCd(const Path: string);
var
  CurrentDir: string;
begin
  CurrentDir := GetCurrentDir;

  if Path = '' then
    begin
    SaveDir := CurrentDir;
    ChDir(GetUserDir);
    end
  else if Path = '-' then
    begin
      if SaveDir = '' then
        writeln('No previous directory.')
      else
      begin
        ChDir(SaveDir);
        SaveDir := CurrentDir;
      end;
    end
  else if DirectoryExists(Path) then
  begin
    SaveDir := CurrentDir;
    ChDir(Path);
  end
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
          if (FileInfo.Name <> '.') and (FileInfo.Name <> '..') then
          begin
            if (FileInfo.Attr and faDirectory) <> 0 then
              writeln('[DIR] ', FileInfo.Name)
            else
              writeln('      ', FileInfo.Name);
          end;
        until FindNext(FileInfo) <> 0;
        FindClose(FileInfo);
    end;
end;

procedure CmdCopy(const Source, Destination: string);
var
  SL: TStringList;
begin
  if not FileExists(Source) then
  begin
    writeln('File not found: ', Source);
    exit;
  end;
  SL := TStringList.Create;
  try
    SL.LoadFromFile(Source);
    SL.SaveToFile(Destination);
    writeln('Copied to ', Destination);
  finally
    SL.Free;
  end;
end;

procedure CmdMoveFile(const Source, Destination: string);
begin
  if not FileExists(Source) then
    begin
      writeln('File not found: ', Source);
      exit;
    end;
  CmdCopy(Source, Destination);
  DeleteFile(Source);
  writeln('Moved to ', Destination);
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
    if FileName = '' then
    begin
        writeln('Usage: touch <FILE>');
        exit;
    end;
    if FileExists(FileName) then
    begin
        writeln('File already exists: ', FileName);
        exit;
    end;

    assign(MyFile, FileName);
    rewrite(MyFile);
    close(MyFile);

    writeln('File created: ', FileName);
end;

procedure CmdRename(const FileName, NewFileName: string);
begin
  if not FileExists(FileName) then
    begin
    writeln('File does not exist: ', FileName);
    exit;
  end;
  if RenameFile(FileName, NewFileName) then
    writeln('Successfully renamed the file!')
  else
    writeln('Failed to rename the file.');
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
      writeln('cd -      - go to previous directory');
      exit;
    end;
    if Topic = '' then
    begin
        writeln('Available commands: ');
        writeln('rename <OLDNAME> <NEWNAME> - renames a file');
        writeln('write <FILE> <TEXT>        - write text to a file');
        writeln('cd                         - change directory');
        writeln('ls <DIR>                   - list files in current directory');
        writeln('pwd                        - show current directory');
        writeln('touch <FILE>               - create a file');
        writeln('cat <FILE>                 - read a file');
        writeln('cp <SOURCE> <DEST>         - copy a file');
        writeln('mv <SOURCE> <DEST>         - move/rename a file');
        writeln('clear                      - clear the screen');
        writeln('history                    - show command history');
        writeln('exit                       - exit terminal');
        writeln('mkdir <DIR>                - create a directory');
        writeln('rmdir <DIR>                - remove a directory');
        writeln('rm <FILE>                  - remove a file');
        writeln('rm -r <DIR>                - remove a directory and everything inside');
        writeln('whoami                     - show current user');
        writeln('vim <FILE>                 - open file in vim');
        exit;
    end;
end;

procedure CmdMkDir(const DirName: string);
begin
  if DirName = '' then
  begin
    writeln('Usage: mkdir <DIR>');
    exit;
  end;
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

procedure CmdRmRecursive(const DirName: string);
var
  Files: TSearchRec;
  FullName: string;
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
          FullName := IncludeTrailingPathDelimiter(DirName) + Files.Name;

          if (Files.Attr and faDirectory) <> 0 then
            CmdRmRecursive(FullName)
          else
            DeleteFile(FullName);
        end;
      until FindNext(Files) <> 0;
    finally
      FindClose(Files);
    end;
  end;

  if RemoveDir(DirName) then
    writeln('Directory deleted: ', DirName)
  else
    writeln('Failed to delete directory: ', DirName);
end;

procedure CmdRmCommand(const Args: TStringList);
begin
  if Args.Count = 0 then
  begin
    writeln('Usage: rm <FILE>');
    writeln('       rm -r <DIR>');
    exit;
  end;

  if Args[0] = '-r' then
  begin
    if Args.Count < 2 then
    begin
      writeln('Usage: rm -r <DIR>');
      exit;
    end;

    if not DirectoryExists(Args[1]) then
    begin
      writeln('Directory does not exist: ', Args[1]);
      exit;
    end;

    if ConfirmDelete(Args[1]) then
      CmdRmRecursive(Args[1])
    else
      writeln('Canceled.');

    exit;
  end;

  if FileExists(Args[0]) then
  begin
    CmdRmFile(Args[0]);
    exit;
  end;

  if DirectoryExists(Args[0]) then
  begin
    writeln('Cannot remove directory without -r.');
    writeln('Use: rm -r ', Args[0]);
    exit;
  end;

  writeln('File or directory not found: ', Args[0]);
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

function JoinFromIndex(const List: TStringList; StartIndex: integer; const Delimiter: string): string;
var
  i: integer;
begin
  Result := '';
  for i := StartIndex to List.Count - 1 do
  begin
    if i > StartIndex then
      Result := Result + Delimiter;
    Result := Result + List[i];
  end;
end;

function FindOnPath(const ExeName: string): string;
var
  PathVar, Dir: string;
  Dirs: TStringList;
  i: integer;
  Candidate: string;
begin
  Result := '';
  PathVar := GetEnvironmentVariable('PATH');
  if PathVar = '' then exit;

  Dirs := TStringList.Create;
  try
    {$IFDEF WINDOWS}
    Dirs.Delimiter := ';';
    {$ELSE}
    Dirs.Delimiter := ':';
    {$ENDIF}
    Dirs.StrictDelimiter := True;
    Dirs.DelimitedText := PathVar;

    for i := 0 to Dirs.Count - 1 do
    begin
      Dir := Dirs[i];
      if Dir = '' then continue;
      Candidate := IncludeTrailingPathDelimiter(Dir) + ExeName;
      {$IFDEF WINDOWS}
      if FileExists(Candidate + '.exe') then
      begin
        Result := Candidate + '.exe';
        exit;
      end;
      {$ENDIF}
      if FileExists(Candidate) then
      begin
        Result := Candidate;
        exit;
      end;
    end;
  finally
    Dirs.Free;
  end;
end;

function FindAndOutsideQuotes(const S: string): integer;
var
  i: integer;
  InQuotes: boolean;
begin
  Result := 0;
  InQuotes := False;
  for i := 1 to Length(S) - 1 do
  begin
    if S[i] = '"' then
      InQuotes := not InQuotes
    else if (not InQuotes) and (S[i] = '&') and (S[i + 1] = '&') then
    begin
      Result := i;
      exit;
    end;
  end;
end;

procedure ParseCommand(const Input: string; out Cmd: string; out Args: TStringList);
var
  i: Integer;
  CleanInput, CurrentToken: string;
  InQuotes: Boolean;
  ch: Char;
begin
  Args := TStringList.Create;
  Cmd := '';
  CleanInput := Trim(Input);
  if CleanInput = '' then exit;

  CurrentToken := '';
  InQuotes := False;

  for i := 1 to Length(CleanInput) do
  begin
    ch := CleanInput[i];
    if ch = '"' then
      InQuotes := not InQuotes
    else if (ch = ' ') and not InQuotes then
    begin
      if CurrentToken <> '' then
      begin
        Args.Add(CurrentToken);
        CurrentToken := '';
      end;
    end
    else
      CurrentToken := CurrentToken + ch;
  end;

  if CurrentToken <> '' then
    Args.Add(CurrentToken);

  if Args.Count = 0 then exit;

  Cmd := LowerCase(Args[0]);
  Args.Delete(0);
end;

procedure ExecuteCommand(const input: string);
var
  Cmd: string;
  Args: TStringList;
  VimPath: string;
begin
  ParseCommand(input, Cmd, Args);

  if Cmd = '' then
  begin
    Args.Free;
    exit;
  end;

  case Cmd of
    'echo': if Args.Count > 0 then CmdEcho(JoinStrings(Args, ' '));
    'write':
    begin
      if Args.Count > 1 then
        CmdWriteFile(Args[0], JoinFromIndex(Args, 1, ' '))
      else
        writeln('Usage: write <FILE> <TEXT>');
    end;
    'touch': if Args.Count > 0 then CmdTouch(Args[0]) else writeln('Usage: touch <FILE>');
    'cat': if Args.Count > 0 then CmdCat(Args[0]) else writeln('Usage: cat <FILE>');
    'ls': if Args.Count > 0 then CmdLs(Args[0]) else CmdLs('');
    'pwd': CmdPwd;
    'cd': if Args.Count > 0 then CmdCd(Args[0]) else CmdCd('');
    'rename': if Args.Count > 1 then CmdRename(Args[0], Args[1]) else writeln('Usage: rename <OLDNAME> <NEWNAME>');
    'help': if Args.Count > 0 then CmdHelp(Args[0]) else CmdHelp('');
    'clear', 'cls': ClrScr;
    'mkdir': if Args.Count > 0 then CmdMkDir(Args[0]) else writeln('Usage: mkdir <DIR>');
    'rmdir': if Args.Count > 0 then CmdRmDir(Args[0]) else writeln('Usage: rmdir <DIR>');
    'rm': CmdRmCommand(Args);
    'cp': if Args.Count > 1 then CmdCopy(Args[0], Args[1]) else writeln('Usage: cp <SOURCE> <DESTINATION>');
    'mv': if Args.Count > 1 then CmdMoveFile(Args[0], Args[1]) else writeln('Usage: mv <SOURCE> <DESTINATION>');
    'vim':
    begin
      VimPath := FindOnPath('vim');
      if VimPath = '' then
        writeln('vim not found in PATH.')
      else if Args.Count > 0 then
        ExecuteProcess(VimPath, Args[0])
      else
        ExecuteProcess(VimPath, '');
    end;
    'whoami': writeln(GetUserName);
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
  AndPos := FindAndOutsideQuotes(UserInput);

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
  Write(GetUserName, '@', GetCurrentFolderName,' $ ');
end;

procedure AddToHistory(const Command: string);
var
  i: integer;
begin
  if Trim(Command) = '' then
      exit;

  if HistoryCount < MaxHistory then
  begin
    Inc(HistoryCount);
    CommandHistory[HistoryCount] := Command;
  end
  else
  begin
    for i := 1 to MaxHistory - 1 do
      CommandHistory[i] := CommandHistory[i + 1];
    CommandHistory[MaxHistory] := Command;
  end;
end;

function ReadUserInput: string;
var
  Key: char;
  UserInput: string;
  CursorPos: integer;
  HistoryIndex: integer;

  procedure RedrawLine;
  begin
    Write(#13);
    ClrEol;
    ShowPrompt;
    Write(UserInput);
    GotoXY(PromptLength + CursorPos + 1, WhereY);
  end;

  procedure HistoryUp;
  begin
    if (HistoryCount > 0) and (HistoryIndex > 1) then
    begin
      Dec(HistoryIndex);
      UserInput := CommandHistory[HistoryIndex];
      CursorPos := Length(UserInput);
      RedrawLine;
    end;
  end;

  procedure HistoryDown;
  begin
    if HistoryIndex < HistoryCount then
    begin
      Inc(HistoryIndex);
      UserInput := CommandHistory[HistoryIndex];
    end
    else
    begin
      HistoryIndex := HistoryCount + 1;
      UserInput := '';
    end;
    CursorPos := Length(UserInput);
    RedrawLine;
  end;

begin
  UserInput := '';
  CursorPos := 0;
  HistoryIndex := HistoryCount + 1;

  while true do
  begin
    Key := ReadKey;

    case Key of
      #13:
      begin
        writeln;
        Result := UserInput;
        exit;
      end;

      #8, #127:
      begin
        if CursorPos > 0 then
        begin
          Delete(UserInput, CursorPos, 1);
          Dec(CursorPos);
          RedrawLine;
        end;
      end;

      #0:
      begin
        Key := ReadKey;
        case Key of
          #72: HistoryUp;

          #80: HistoryDown;

          #75:
          begin
            if CursorPos > 0 then
            begin
              Dec(CursorPos);
              GotoXY(PromptLength + CursorPos + 1, WhereY);
            end;
          end;

          #77:
          begin
            if CursorPos < Length(UserInput) then
            begin
              Inc(CursorPos);
              GotoXY(PromptLength + CursorPos + 1, WhereY);
            end;
          end;
        end;
      end;

      #27:
      begin
        Key := ReadKey;
        if Key = '[' then
        begin
          Key := ReadKey;
          case Key of
            'A': HistoryUp;

            'B': HistoryDown;

            'C':
            begin
              if CursorPos < Length(UserInput) then
              begin
                Inc(CursorPos);
                GotoXY(PromptLength + CursorPos + 1, WhereY);
              end;
            end;

            'D':
            begin
              if CursorPos > 0 then
              begin
                Dec(CursorPos);
                GotoXY(PromptLength + CursorPos + 1, WhereY);
              end;
            end;
          end;
        end;
      end;

    else
      if Key >= ' ' then
      begin
        Insert(Key, UserInput, CursorPos + 1);
        Inc(CursorPos);
        RedrawLine;
      end;
    end;
  end;
end;

var
  UserInput: string;
begin
  ClrScr;

  repeat
    ShowPrompt;
    UserInput := ReadUserInput;
    UserInput := Trim(UserInput);

    if UserInput = 'exit' then
      break;

    AddToHistory(UserInput);
    ExecuteLine(UserInput);
  until false;
end.
