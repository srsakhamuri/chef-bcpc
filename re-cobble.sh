names=( $@ )
if [ -z "${names}" ] ; then exit 1 ; fi

sudo chef-client -o recipe[bcpc::cobbler]
for n in ${names[@]} ; do
	sudo cobbler system edit --name ${n} --netboot=1
done
