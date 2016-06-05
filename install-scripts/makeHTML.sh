#!/bin/bash

rm LFS.html

# --- Create header
cat > LFS.html << "EOL"
<html>
<head>
<style type="text/css">
pre { 
   margin-left: 10px;
   padding-left: 10px;
   border-style: solid;
   border-width: 2px;
   border-color: black;
   background-color: #dddddd;
}
</style>
</head>
</body>
EOL

# --- Main body
markdown LFS-Instructions.md >> LFS.html

# --- End the HTML file
echo "</body>" >> LFS.html
echo "</html>" >> LFS.html

