#!/bin/bash
# https://stackoverflow.com/a/49480688
git log -50 --format=%H > /tmp/gits
# https://www.cyberciti.biz/faq/unix-howto-read-line-by-line-from-file/
while read -r line
do
    # echo $line
    git diff-tree --no-commit-id --name-only -r $line > ${line}.file
    git show -s $line --pretty='format:%B' > ${line}.txt
    echo "#!/bin/bash" > command.sh
    echo "" >> command.sh
    echo "cd $src" >> command.sh
    echo "git checkout $line" >> command.sh
    echo "" >> command.sh
    echo "while read -r line" >> command.sh
    echo "do" >> command.sh
    echo "    dname=\$(basename \"$dest/$line\")" >> command.sh
    echo "    mkdir -p \$dname" >> command.sh
    echo "    cp -rf $line $dest/$line" >> command.sh
    echo "done < ${line}.file" >> command.sh
    git show -s $line --pretty='format:--author="%an <%ae>" --date="%ad" --file=%H' >> command.sh
    bash command.sh
    if [ "$line" == "<hash>" ]; then
        break
    fi
done < /tmp/gits
