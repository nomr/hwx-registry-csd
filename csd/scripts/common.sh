
if [ ! -z ${COMMON_SCRIPT+x} ]; then
    . ${COMMON_SCRIPT}
fi

export PATH=$CFSSL_HOME/bin:$PATH

append_and_delete() {
    local in=$1
    local out=$2
    if [ -e $in ]; then
      cat $in >> $out
      rm -f $in
    fi
}

mv_if_exists() {
    if [ -e $1 ]; then
      mv $1 $2
    fi
}

get_peers() {
    local file=$1

    cat $1.pvars \
        | cut -d: -f 1 \
        | sort \
        | uniq
}

get_property() {
    local file=$1
    local key=$2

    for suffix in properties pvars; do
        if [ -f "${file}.${suffix}" ]; then
            file="${file}.${suffix}"
            break
        fi
    done
    local line=$(grep "$key=" ${file} | tail -1)

    echo "${line/$key=/}"
}

envsubst_all() {
    local var_prefix=$1
    local filename_prefix=${2:-}

    local shell_format="\$CONF_DIR,\$ZK_QUORUM"
    for i in $(eval "echo \${!${var_prefix}*}"); do
        shell_format="${shell_format},\$$i"
    done

    for i in $(find . -maxdepth 1 -type f -name "${filename_prefix}*.envsubst*"); do
        cat $i | envsubst $shell_format > ${i/\.envsubst/}
        rm -f $i
    done
}

base64_to_hex() {
    echo $1 \
      | base64 -d \
      | od -t x8 \
      | cut -s -d' ' -f2- \
      | sed -e ':a;N;$!ba;s/\n/ /g' \
      | sed -e 's/ //g'
    # do not join the last two sed lines
}

load_vars() {
    local prefix=$1
    local file=$2.vars

    eval $(sed -e 's/ /\\ /g' \
               -e 's/"/\\"/g' \
               -e 's/^/export ${prefix}_/' $file)
}
