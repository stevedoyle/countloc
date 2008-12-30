Introduction
------------

Contents:
~~~~~~~~
1. Overview
2. Installation
3. Usage


1. Overview
-----------
CountLOC is a utility program, implemented in Ruby that provides support for 
generating LOC metrics for source code.

Initial releases will support counting lines of code in Ruby source code.
Subsequent releases will add support for other programming languages such as
Python, C, C++, C#, Java, Perl, etc. ...


2. Installation
---------------
CountLOC is packaged as a Ruby gem and as a .zip file. 

Gem:
	ruby gem install countloc.gem
	
zip:
	unzip countloc.zip
 

3. Usage
--------
For full listing of options and usage:
	countloc --help
	
To get the LOC metrics for a single Ruby file:
	countloc some_file.rb
	