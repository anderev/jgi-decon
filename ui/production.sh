echo $1
if [ -z "$1" ]
then
  op='start'
else
  op=$1
fi

NODE_ENV=production bash -c "forever $op --uid \"production\" -a -o log.txt -e error.txt -l forever.txt app.js"

