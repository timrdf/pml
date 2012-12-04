# e.g. input:
#
# 8  x-fmt/1
# 11 x-fmt/2
# 13 x-fmt/3

{
   service="http://www.nationalarchives.gov.uk/PRONOM/Format/proFormatDetailListAction.aspx"
   local=$2;
   sub("/","__",local);
   print "echo "$1" from",service
   print "curl -s -F strAction=\"Save As XML\" -F strFileFormatID="$1,service" > source/"local".xml"
   print "sleep 1"
   print ""
}
