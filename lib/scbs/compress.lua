
-- squeeze all whitespace and delete comments
-- so that user can format the code, add comments, etc. without rebuilding
return function(code)
    code = code:gsub("/%*.*%*/", " ")
    code = code:gsub("[\r\n]", "\n");
    code = code:gsub("[ \t]", " ");
    code = code:gsub("//.*\n", "\n")
    
    -- note that all /* */ comments are replaced with space
    -- because the following
    -- 'foo/*comment*/bar'
    -- doesn't actually mean 'foobar'
    -- so the spaces are shrunk after that
    
    return code
end
