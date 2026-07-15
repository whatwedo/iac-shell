findup() {
  local name=$1
  local dir=$PWD
  local found
  while [ ! -z "$dir" -a "$dir" != '/' -a -z "$found" ]; do
    [ -e "$dir/$name" ] && found="$dir/$name"
    dir=`dirname $dir`
  done
  if [ -n "$found" ]; then
    echo "$found"
    return 0
  else
    return 1
  fi
}

cdup() {
  dir=$(findup $1)
  if [[ -n "$dir" ]]; then
    dir=$(dirname $dir)
    cd $dir
  fi
}

cdg() {
  cdup .git
}
