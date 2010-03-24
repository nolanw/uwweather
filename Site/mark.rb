#!/usr/bin/env ruby

if ARGV.empty?
  puts "Need a file to compile from Markdown to HTML."
  Process.exit
end

require 'rdiscount'
require 'rake'

path = ARGV[0]
File.open(path.ext('html'), 'w') do |out|
  out.printf(DATA.read, RDiscount.new(File.open(path, 'r').read).to_html)
end

__END__
<!DOCTYPE HTML>
<html>
  <head>
    <title>UW Weather Changelog</title>
  </head>
  <body>
    %s
  </body>
</html>
