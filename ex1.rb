# \A : 文字列の先頭
# \s : 空白
# \S : 空白以外
print "input a line : "
line = gets
until line.empty? do
    case line
    when /\A\s+/
        puts "space (skip)"
    when /\A(\S+)/
        puts "word (#{$1})"
    end
    # remaining of the matched string
    line = $'
end
