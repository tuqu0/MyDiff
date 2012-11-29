#! /bin/sh

declare -i n
declare -i i
declare -i f

n=${1:-1}
i=1
f=1
while [ $i -le $n ] ; do
	f=$((f * i))
	i=$((i + 1))
done

echo "$n! = $f"

