watch( 'spec/.*spec\.rb' )  {|md| system("ruby #{md[0]}") }
watch( 'lib/(.*)\.rb' )      {|md| system("ruby spec/#{md[1]}_spec.rb") }