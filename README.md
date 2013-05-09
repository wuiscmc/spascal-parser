spascal-parser
==============

Semantic parser for a pascal based programming language. 

Language specifications
-----------------------

Besides the basic structure of a programme, the parser accepts as well: 

- Constants definition
- Custom user types 
- Nested functions
- Datatype **Lista**
- entero/real basic operations compatibility. 

Special datatype Lista
----------------------

So far, **Lista** is only able to handle elements of type entero (and compatible user defined types).

**List element handling**

  Append an element to the list:

      list << element

  Check for element in list:

      list?(element)
    
  Element getter:

      list?(element)
    

**List operations**

  Check if the list is empty:

      list?
    
  Concatenate two lists:

      list1 + list2
    
  Difference of lists:

      list1 - list2
    
Requirements
------------

- Flex 2.3
- Byacc (Berkley Yacc) 9/9/90
- GCC 4.6.2 (Mingw)
- Windows XP SP3

Run instructions
----------------

 1.  Put the binary files (flex.exe & byacc.exe) in bin/
 2.  Modify test/doomtest (optional)
 3.  Run launcher.bat

