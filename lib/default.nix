{
  readDirRecursively = dir:
    with builtins; let
      files = readDir dir;
      processEntry = name: type:
        if type == "directory" then
          readDirRecursively (dir + "/${name}")
        else if type == "regular" then
          { ${name} = readFile (dir + "/${name}"); }
        else
          { };
    in
    foldl' (res: entry: res // processEntry (baseNameOf entry) (typeOf entry)) { } (attrNames files);
}

